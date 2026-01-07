const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

async function getUserFcmTokens(userId) {
  const doc = await db.collection('users').doc(userId).get();
  if (!doc.exists) return [];
  const data = doc.data();
  return Array.isArray(data.fcm_tokens) ? data.fcm_tokens.filter(Boolean) : [];
}

async function getAdminsForZoo(zooId) {
  const snap = await db.collection('users').where('zoo_id', '==', zooId).where('role', '==', 'admin').get();
  const tokens = [];
  for (const d of snap.docs) {
    const t = d.data().fcm_tokens;
    if (Array.isArray(t)) tokens.push(...t);
  }
  return tokens.filter(Boolean);
}

// 1) Notify admin when a keeper creates a report
exports.onReportCreated = functions.firestore.document('reports/{reportId}').onCreate(async (snap, ctx) => {
  const data = snap.data();
  if (!data) return null;
  const zooId = data.zoo_id;
  const notes = data.notes || '(tanpa catatan)';

  const tokens = await getAdminsForZoo(zooId);
  if (tokens.length === 0) return null;

  const message = {
    notification: {
      title: 'Laporan dari keeper',
      body: notes.length > 120 ? notes.substr(0, 120) + '...' : notes,
    },
    data: {
      type: 'report',
      reportId: snap.id,
      zooId: String(zooId),
    },
  };

  try {
    await admin.messaging().sendToDevice(tokens, message);
  } catch (e) {
    console.error('Error sending report notification', e);
  }
  return null;
});

// 2) Notify keeper (or assigned keeper) when a feeding_history entry is created with status 'missed'
exports.onFeedingHistoryCreated = functions.firestore.document('feeding_history/{hid}').onCreate(async (snap, ctx) => {
  const data = snap.data();
  if (!data) return null;
  const status = data.status;
  if (status !== 'missed') return null;

  // Prefer to notify the keeper who fed (fed_by) or the assigned keeper for the animal
  let targetKeeperId = data.fed_by;
  if (!targetKeeperId && data.animal_id) {
    const animalRef = await db.collection('animals').doc(data.animal_id).get();
    if (animalRef.exists) {
      const ad = animalRef.data();
      if (ad && ad.assigned_keeper_id) targetKeeperId = ad.assigned_keeper_id;
    }
  }

  if (!targetKeeperId) return null;
  const tokens = await getUserFcmTokens(targetKeeperId);
  if (tokens.length === 0) return null;

  const title = 'Terlewat jadwal makan';
  const body = `${data.animal_name || 'Hewan'} terlewat jadwal makan pada ${data.time || ''}`;

  const message = {
    notification: { title, body },
    data: { type: 'missed_feeding', animalId: data.animal_id || '', zooId: data.zoo_id || '' },
  };

  try {
    await admin.messaging().sendToDevice(tokens, message);
  } catch (e) {
    console.error('Error sending missed feeding notification', e);
  }
  return null;
});

// 3) Scheduled function: send feeding reminders before scheduled times
// Use Cloud Scheduler to trigger this every minute or as desired.
exports.sendFeedingReminders = functions.pubsub.schedule('every 5 minutes').onRun(async (context) => {
  // Basic implementation: iterate zoos and their config, check animals and send reminders
  const zoosSnap = await db.collection('zoos').get();
  const now = new Date();

  for (const zooDoc of zoosSnap.docs) {
    const zoo = zooDoc.data();
    const reminderBeforeMinutes = (zoo.notification_config && zoo.notification_config.reminder_before_minutes) || 15;

    // Fetch animals in this zoo
    const animalsSnap = await db.collection('animals').where('zoo_id', '==', zooDoc.id).get();
    for (const a of animalsSnap.docs) {
      const ad = a.data();
      // Expect ad.next_feeding_time to be a Firestore Timestamp or ISO string
      let nextFeeding = ad.next_feeding_time;
      if (!nextFeeding) continue;
      if (nextFeeding._seconds) nextFeeding = new Date(nextFeeding._seconds * 1000);
      else if (typeof nextFeeding === 'string') nextFeeding = new Date(nextFeeding);

      if (!(nextFeeding instanceof Date)) continue;
      const diffMinutes = (nextFeeding - now) / (1000 * 60);
      if (diffMinutes > 0 && diffMinutes <= reminderBeforeMinutes) {
        // send reminder to assigned keeper(s)
        const keeperId = ad.assigned_keeper_id;
        if (!keeperId) continue;
        const tokens = await getUserFcmTokens(keeperId);
        if (tokens.length === 0) continue;

        const title = 'Pengingat: Hewan akan diberi makan';
        const body = `${ad.name || 'Hewan'} akan diberi makan dalam ${Math.round(diffMinutes)} menit`;
        const message = { notification: { title, body }, data: { type: 'feeding_reminder', animalId: a.id } };
        try {
          await admin.messaging().sendToDevice(tokens, message);
        } catch (e) {
          console.error('Error sending feeding reminder', e);
        }
      }
    }
  }
  return null;
});
