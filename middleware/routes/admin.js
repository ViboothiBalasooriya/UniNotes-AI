const express = require('express');
const { verifyFirebaseToken, admin } = require('../middleware/firebaseAuth');
const { requireAdmin } = require('../middleware/adminGuard');

const router = express.Router();

// Apply auth + admin guard to all /api/admin routes
router.use(verifyFirebaseToken, requireAdmin);

// ─── GET /api/admin/notes/pending ─────────────────────────────────────────────
// Returns all notes with status = 'pending' for admin review.
router.get('/notes/pending', async (req, res) => {
  try {
    const db = admin.firestore();
    const snapshot = await db.collection('notes')
      .where('status', '==', 'pending')
      .orderBy('uploadedAt', 'desc')
      .limit(50)
      .get();

    const notes = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      uploadedAt: doc.data().uploadedAt?.toDate()?.toISOString(),
    }));

    res.json({ success: true, notes, count: notes.length });
  } catch (error) {
    console.error('Get pending notes error:', error.message);
    res.status(500).json({ error: 'Failed to fetch pending notes.' });
  }
});

// ─── PATCH /api/admin/notes/:id/status ────────────────────────────────────────
// Updates a note's moderation status: 'approved' | 'flagged' | 'deleted'
// Body: { status: 'approved' | 'flagged' | 'deleted' }
router.patch('/notes/:id/status', async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  const allowedStatuses = ['approved', 'flagged', 'deleted'];
  if (!allowedStatuses.includes(status)) {
    return res.status(400).json({
      error: `Invalid status. Must be one of: ${allowedStatuses.join(', ')}`,
    });
  }

  try {
    const db = admin.firestore();
    const noteRef = db.collection('notes').doc(id);
    const noteDoc = await noteRef.get();

    if (!noteDoc.exists) {
      return res.status(404).json({ error: 'Note not found.' });
    }

    if (status === 'deleted') {
      // Delete from Firestore (file in Storage is separate — client handles cleanup)
      await noteRef.delete();
      return res.json({ success: true, message: `Note ${id} deleted.` });
    }

    await noteRef.update({
      status,
      moderatedAt: admin.firestore.FieldValue.serverTimestamp(),
      moderatedBy: req.user.uid,
    });

    res.json({ success: true, message: `Note ${id} status updated to '${status}'.` });
  } catch (error) {
    console.error('Update note status error:', error.message);
    res.status(500).json({ error: 'Failed to update note status.' });
  }
});

// ─── GET /api/admin/users ─────────────────────────────────────────────────────
// Returns all user roles for the Role Management screen.
router.get('/users', async (req, res) => {
  try {
    const db = admin.firestore();
    const snapshot = await db.collection('userRoles').orderBy('assignedAt', 'desc').get();
    const users = snapshot.docs.map(doc => ({ uid: doc.id, ...doc.data() }));
    res.json({ success: true, users });
  } catch (error) {
    console.error('Get users error:', error.message);
    res.status(500).json({ error: 'Failed to fetch users.' });
  }
});

// ─── POST /api/admin/roles/:uid ───────────────────────────────────────────────
// Assigns or revokes admin role for a user.
// Body: { role: 'admin' | 'student' }
router.post('/roles/:uid', async (req, res) => {
  const { uid } = req.params;
  const { role } = req.body;

  if (!['admin', 'student'].includes(role)) {
    return res.status(400).json({ error: "Role must be 'admin' or 'student'." });
  }

  // Prevent self-demotion
  if (uid === req.user.uid && role === 'student') {
    return res.status(400).json({ error: 'You cannot remove your own admin privileges.' });
  }

  try {
    const db = admin.firestore();
    await db.collection('userRoles').doc(uid).set({
      role,
      assignedAt: admin.firestore.FieldValue.serverTimestamp(),
      assignedBy: req.user.uid,
    }, { merge: true });

    res.json({ success: true, message: `User ${uid} role set to '${role}'.` });
  } catch (error) {
    console.error('Set role error:', error.message);
    res.status(500).json({ error: 'Failed to update user role.' });
  }
});

module.exports = router;
