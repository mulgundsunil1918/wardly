/**
 * Wardly — FCM fan-out on new notes.
 *
 * Trigger: a new doc in /notes/{noteId}
 * Action:  push a notification to every user whose `wardIds` array
 *          contains the note's wardId — except the author.
 *
 * Cost notes (Blaze pay-as-you-go):
 * - memory pinned at 256 MiB. The function does a small Firestore query
 *   plus an FCM multicast — there's no need for the v2 default of 256
 *   MiB to creep up; explicitly setting it locks in cost.
 * - minInstances: 0 → never keep a warm container. We accept a ~1s
 *   cold start in exchange for not paying for idle compute.
 * - concurrency: 80 → one container can fan out many notes at once,
 *   reducing total active container time.
 * - timeoutSeconds: 30 → bounded so a stuck FCM call can't burn budget.
 */
const {
  onDocumentCreated,
  onDocumentDeleted,
} = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

const COMMON_OPTS = {
  region: 'us-central1',
  memory: '256MiB',
  minInstances: 0,
  concurrency: 80,
  timeoutSeconds: 30,
};

exports.onNoteCreated = onDocumentCreated(
  { ...COMMON_OPTS, document: 'notes/{noteId}' },
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

/**
 * Wardly — clean up teammate wardIds when a ward is deleted.
 *
 * Trigger: a doc in /wards/{wardId} is deleted.
 * Action:  find every user whose `wardIds` array contains the dead
 *          ward id and remove it. The deleter handles their own doc
 *          client-side; this function takes care of every other member,
 *          which the security rules don't allow them to do directly.
 */
exports.onWardDeleted = onDocumentDeleted(
  { ...COMMON_OPTS, document: 'wards/{wardId}' },
  async (event) => {
    const wardId = event.params.wardId;
    if (!wardId) return;

    const db = getFirestore();
    const members = await db
      .collection('users')
      .where('wardIds', 'array-contains', wardId)
      .get();

    if (members.empty) {
      console.log(`Wardly cleanup: no stale wardIds for ${wardId}`);
      return;
    }

    const batch = db.batch();
    members.forEach((doc) => {
      batch.update(doc.ref, {
        wardIds: FieldValue.arrayRemove(wardId),
      });
    });
    await batch.commit();
    console.log(
      `Wardly cleanup: scrubbed ${wardId} from ${members.size} user docs`,
    );
  },
);
