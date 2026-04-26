/**
 * Wardly — FCM fan-out on new notes.
 *
 * Trigger: a new doc in /notes/{noteId}
 * Action:  push a notification to every user whose `wardIds` array
 *          contains the note's wardId — except the author.
 */
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

exports.onNoteCreated = onDocumentCreated(
  { document: 'notes/{noteId}', region: 'us-central1' },
  async (event) => {
    const note = event.data?.data();
    if (!note) return;

    const wardId = note.wardId;
    const authorId = note.authorId;
    if (!wardId) return;

    const db = getFirestore();
    const usersSnap = await db
      .collection('users')
      .where('wardIds', 'array-contains', wardId)
      .get();

    const tokens = [];
    usersSnap.forEach((doc) => {
      if (doc.id === authorId) return; // don't push to the author
      const arr = doc.data().fcmTokens;
      if (Array.isArray(arr)) tokens.push(...arr);
    });

    if (tokens.length === 0) return;

    const isUrgent = (note.priority || '').toLowerCase() === 'urgent';
    const title = isUrgent
      ? `🚨 Urgent · ${note.patientName || 'patient'}`
      : `Note · ${note.patientName || 'patient'}`;
    const body =
      `${note.authorName || 'Someone'}: ${(note.content || '').slice(0, 140)}`;

    const messaging = getMessaging();
    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: {
        noteId: event.params.noteId,
        wardId: String(wardId),
        priority: String(note.priority || 'Normal'),
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'wardly_notes',
          priority: isUrgent ? 'max' : 'high',
        },
      },
      apns: {
        payload: {
          aps: { sound: 'default', badge: 1 },
        },
      },
    });

    // Clean up dead tokens.
    const dead = [];
    response.responses.forEach((r, i) => {
      if (!r.success) {
        const code = r.error?.code;
        if (
          code === 'messaging/registration-token-not-registered' ||
          code === 'messaging/invalid-registration-token'
        ) {
          dead.push(tokens[i]);
        }
      }
    });
    if (dead.length) {
      const batch = db.batch();
      usersSnap.forEach((doc) => {
        const arr = doc.data().fcmTokens || [];
        const filtered = arr.filter((t) => !dead.includes(t));
        if (filtered.length !== arr.length) {
          batch.update(doc.ref, { fcmTokens: filtered });
        }
      });
      await batch.commit();
    }

    console.log(
      `Wardly FCM: sent ${response.successCount}/${tokens.length} for ward ${wardId}`,
    );
  },
);
