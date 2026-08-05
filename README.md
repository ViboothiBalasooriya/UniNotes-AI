# UniNotes AI

> **Academic Resource Sharing Platform with Embedded AI Study Assistant**  
> Built with Flutter (Android) + Firebase + Node.js + Google Gemini AI

---

## 🏗️ Project Structure

```
UniNotes AI/
├── middleware/              # Node.js + Express.js backend (Render.com)
│   ├── server.js
│   ├── routes/
│   │   ├── ai.js           # /api/ai/explain, /api/ai/summarize
│   │   └── admin.js        # /api/admin/* (JWT-protected)
│   ├── middleware/
│   │   ├── firebaseAuth.js  # Firebase ID token verification
│   │   └── adminGuard.js    # Admin role check
│   └── package.json
├── uninotes_ai/             # Flutter Android App
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/            # Theme, services, constants
│   │   ├── features/        # auth, courses, notes, bookmarks, admin
│   │   ├── shared/          # models, widgets
│   │   └── router/          # GoRouter navigation
│   ├── pubspec.yaml
│   └── .env
└── firebase/
    ├── firestore.rules      # Firestore Security Rules
    └── storage.rules        # Firebase Storage Rules
```

---

## 🚀 Setup Guide

### Step 1: Firebase Project Setup

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project: **UniNotes AI**
3. Enable the following services:
   - **Authentication** → Enable **Email/Password** and **Google Sign-In**
   - **Cloud Firestore** → Start in **Production Mode**
   - **Storage** → Default bucket

4. Register an **Android App**:
   - Package name: `com.uninotesai.uninotes_ai`
   - Download `google-services.json`
   - Place it in: `uninotes_ai/android/app/google-services.json`

5. Apply Security Rules:
   - Firestore Rules: Copy contents of `firebase/firestore.rules` → Firebase Console → Firestore → Rules
   - Storage Rules: Copy contents of `firebase/storage.rules` → Firebase Console → Storage → Rules

6. Generate a **Service Account Key** for the middleware:
   - Firebase Console → Project Settings → Service Accounts → Generate New Private Key
   - This downloads a JSON file — keep it secret!

---

### Step 2: Flutter App Configuration

1. Install Flutter SDK (Windows):
   ```bash
   # Option 1: Download from https://flutter.dev/docs/get-started/install/windows
   # Option 2: Extract zip to C:\flutter and add C:\flutter\bin to PATH
   ```

2. Verify installation:
   ```bash
   flutter doctor
   ```

3. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

4. Configure Firebase for Flutter:
   ```bash
   cd uninotes_ai
   flutterfire configure --project=your-firebase-project-id
   ```
   This generates `lib/firebase_options.dart` automatically.

5. Install dependencies:
   ```bash
   flutter pub get
   ```

6. Update `.env`:
   ```
   MIDDLEWARE_BASE_URL=https://your-app.onrender.com
   ```

---

### Step 3: Middleware Setup

1. Navigate to middleware:
   ```bash
   cd middleware
   npm install
   ```

2. Create `.env` (copy from `.env.example`):
   ```
   GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE
   PORT=3000
   FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account","project_id":"..."}
   ```
   > ⚠️ Paste your downloaded service account JSON as a **single-line string** (minified)

3. Test locally:
   ```bash
   npm run dev
   # → GET http://localhost:3000/api/health
   ```

---

### Step 4: Deploy Middleware to Render.com

1. Push `middleware/` folder to a GitHub repository
2. Go to [Render.com](https://render.com) → New → Web Service
3. Connect your GitHub repo
4. Settings:
   - **Build Command**: `npm install`
   - **Start Command**: `node server.js`
   - **Plan**: Free
5. Add Environment Variables in Render dashboard:
   - `GEMINI_API_KEY` = your Gemini API key
   - `FIREBASE_SERVICE_ACCOUNT_JSON` = minified JSON string of your service account

6. Copy your Render URL (e.g., `https://uninotes-ai.onrender.com`)
7. Update `uninotes_ai/.env`:
   ```
   MIDDLEWARE_BASE_URL=https://uninotes-ai.onrender.com
   ```

---

### Step 5: Build Android App

```bash
cd uninotes_ai

# Debug APK (for testing)
flutter build apk --debug

# Release APK
flutter build apk --release

# Release App Bundle (for Play Store)
flutter build appbundle --release
```

APK location: `uninotes_ai/build/app/outputs/flutter-apk/app-release.apk`

---

## 🔐 Default Admin Setup

After the first user registers, make them an admin:

1. Find their Firebase **UID** in Firebase Console → Authentication
2. In Firestore, create a document at `/userRoles/{uid}`:
   ```json
   {
     "role": "admin",
     "assignedAt": "<server timestamp>",
     "assignedBy": "system"
   }
   ```
3. The admin icon will appear in the app on next login.

---

## 📋 API Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/health` | Health check | Public |
| POST | `/api/ai/explain` | AI explanation | Authenticated |
| POST | `/api/ai/summarize` | Document summary | Authenticated |
| GET | `/api/admin/notes/pending` | Pending notes | Admin |
| PATCH | `/api/admin/notes/:id/status` | Update note status | Admin |
| GET | `/api/admin/users` | All user roles | Admin |
| POST | `/api/admin/roles/:uid` | Set user role | Admin |

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile App | Flutter (Dart) – Android |
| State Management | Riverpod |
| Navigation | GoRouter |
| Database | Firebase Firestore |
| Auth | Firebase Authentication |
| Storage | Firebase Storage |
| AI Backend | Node.js + Express (Render.com) |
| AI Model | Google Gemini 1.5 Flash |
| PDF Viewer | Syncfusion Flutter PDF Viewer |
| Design | Material 3, Inter + Outfit fonts |

---

## 🎨 UI Design System

- **Primary**: `#4F46E5` (Deep Indigo)
- **Accent**: `#7C3AED` (Violet)
- **Background (Dark)**: `#0F0F1A`
- **Surface (Dark)**: `#1A1A2E`
- **Typography**: Outfit (headings) + Inter (body)
- **Default Mode**: Dark (system-aware Light toggle)
