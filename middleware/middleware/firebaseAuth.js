const admin = require('firebase-admin');

/**
 * Initializes Firebase Admin SDK using the service account JSON
 * stored in the FIREBASE_SERVICE_ACCOUNT_JSON environment variable.
 */
function initializeFirebase() {
  if (admin.apps.length > 0) return; // Prevent re-initialization

  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!serviceAccountJson) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON environment variable is not set.');
  }

  const serviceAccount = JSON.parse(serviceAccountJson);

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  console.log('🔥 Firebase Admin SDK initialized successfully.');
}

/**
 * Express middleware: Verifies the Firebase ID token from the Authorization header.
 * Attaches the decoded token to req.user on success.
 */
async function verifyFirebaseToken(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized: Missing or invalid Authorization header.' });
  }

  const idToken = authHeader.split('Bearer ')[1];

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.user = decodedToken; // { uid, email, ... }
    next();
  } catch (error) {
    console.error('Token verification failed:', error.message);
    return res.status(401).json({ error: 'Unauthorized: Invalid or expired token.' });
  }
}

module.exports = { initializeFirebase, verifyFirebaseToken, admin };
