const { admin } = require('./firebaseAuth');

/**
 * Express middleware: Checks if the authenticated user has the 'admin' role.
 * Must be used AFTER verifyFirebaseToken middleware.
 * Reads the role from Firestore /userRoles/{uid}.
 */
async function requireAdmin(req, res, next) {
  const uid = req.user?.uid;

  if (!uid) {
    return res.status(401).json({ error: 'Unauthorized: No authenticated user.' });
  }

  try {
    const db = admin.firestore();
    const roleDoc = await db.collection('userRoles').doc(uid).get();

    if (!roleDoc.exists || roleDoc.data()?.role !== 'admin') {
      return res.status(403).json({ error: 'Forbidden: Admin privileges required.' });
    }

    req.isAdmin = true;
    next();
  } catch (error) {
    console.error('Admin role check failed:', error.message);
    return res.status(500).json({ error: 'Could not verify admin role.' });
  }
}

module.exports = { requireAdmin };
