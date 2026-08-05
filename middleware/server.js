require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const aiRoutes = require('./routes/ai');
const adminRoutes = require('./routes/admin');
const { initializeFirebase } = require('./middleware/firebaseAuth');

// Initialize Firebase Admin SDK
initializeFirebase();

const app = express();
const PORT = process.env.PORT || 3000;

// ─── Security & Parsing Middleware ────────────────────────────────────────────
app.use(helmet());
app.use(cors({
  origin: '*', // Allow Flutter mobile app requests
  methods: ['GET', 'POST', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json({ limit: '10mb' })); // Allow large text payloads for PDF content

// ─── Routes ───────────────────────────────────────────────────────────────────
app.use('/api/ai', aiRoutes);
app.use('/api/admin', adminRoutes);

// ─── Health Check ─────────────────────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'UniNotes AI Middleware',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

// ─── 404 Handler ──────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// ─── Global Error Handler ─────────────────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error', message: err.message });
});

// ─── Start Server with Port Fallback ──────────────────────────────────────────
function startServer(portToUse) {
  const server = app.listen(portToUse, () => {
    console.log(`✅ UniNotes AI Middleware running on port ${portToUse}`);
  });

  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      console.warn(`⚠️ Port ${portToUse} is in use. Trying port ${portToUse + 1}...`);
      startServer(portToUse + 1);
    } else {
      console.error('Server error:', err);
    }
  });
}

startServer(Number(PORT));
