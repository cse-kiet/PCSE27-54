# Threat Detection & Voice-Activated SOS Implementation

## 📋 Overview

This implementation adds voice-based threat detection to the StreeHelp app. When a user activates SOS:
1. **Background service starts** continuously listening for voice
2. **Voice is analyzed** for threat keywords and emotional indicators
3. **If threat detected**, an email alert is sent to emergency contacts
4. **User location** is captured and included in the alert

---

## 🎯 Features Implemented

### 1. **Threat Detection Service** (`threat_detection_service.dart`)
- **Analyzes voice text** for threat keywords:
  - Help, emergency, danger, attack, rape, abuse, injury keywords
  - Severity indicators: screaming, bleeding, dying, police, ambulance, etc.
- **Threat scoring** (0.0 to 1.0):
  - 0.7+ = **CRITICAL** (immediate action)
  - 0.5+ = **HIGH** (send alert)
  - 0.3+ = **MEDIUM** (monitor)
  - <0.3 = **LOW** or **NONE**
- **Dual analysis**: Keyword detection + threat scoring

### 2. **Enhanced SOS Service** (`sos_service.dart`)
- **Continuous voice listening** in background
- **Auto-restart** if connection drops during listening
- **Threat-aware alerts** with detailed analysis
- **Dual trigger modes**:
  - Keyword-based (traditional SOS keywords)
  - Threat-based (analyzed voice patterns)

### 3. **Background Task Handler** (`sos_task_handler.dart`)
- **Runs in foreground service** (survives app backgrounding)
- **Continuous monitoring** with 15-second events
- **Alert throttling** (prevents spam: 30-second minimum between alerts)
- **Persistent notification** showing SOS is active

### 4. **Backend Threat Controller** (`threatController.js`)

#### Endpoint: `POST /api/threat/alert`
Sends immediate threat alert to emergency contacts with:
- High-priority email with color-coded urgency
- Threat analysis details (score, level, detected text)
- Live location with Google Maps link
- Contact notification list

#### Endpoint: `POST /api/threat/report`
Logs threat incidents for analytics and future improvement.

---

## 🚀 How It Works

### User Flow

```
1. User clicks SOS button or says "Help/Bachao"
                    ↓
2. App starts DUI-based background foreground task
                    ↓
3. Background service continuously listens for voice
                    ↓
4. Each detected speech is analyzed (keyword + threat detection)
                    ↓
5a. Keyword detected     5b. Threat detected (score ≥ 0.5)
      ↓                        ↓
   Send Alert          Analyze & Send Alert
      ↓                        ↓
   Email Contacts      Email Contacts (with threat details)
      ↓                        ↓
6. User can see status in UI (shows 🎤 Threat Detection Active)
                    ↓
7. SOS continues running until manual stop
```

### Detection Mechanism

**Example 1: Direct Keyword**
```
Detected: "Help, someone help me!"
Trigger: Keyword "help" found
Action: Send SOS alert immediately
```

**Example 2: Threat Analysis**
```
Detected: "There's someone following me, I'm running"
Keywords: "following" + "running"
Threat Indicators: danger-related words
Threat Score: 0.65 (HIGH)
Action: Send THREAT ALERT with analysis
Email Type: High-urgency with threat analysis
```

**Example 3: Low Threat**
```
Detected: "I need help with my homework"
Threat Score: 0.1
Action: Ignore (no alert)
```

---

## 📱 Backend Setup

### 1. **Gmail Configuration** (Required)

1. Go to [Gmail App Passwords](https://myaccount.google.com/apppasswords)
2. Enable 2-Step Verification first if not enabled
3. Select "Mail" and "Windows Computer"
4. Google will generate a 16-character password
5. Copy this password to `.env` file:

```env
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=aaaa bbbb cccc dddd  # 16-character app password
```

### 2. **Update `.env` File**

```bash
cp .env.example .env
# Edit .env and fill in:
# - MONGO_URI (MongoDB connection)
# - JWT_SECRET (any random string)
# - EMAIL_USER and EMAIL_PASS (from Gmail)
```

### 3. **Install Dependencies**

```bash
cd Backend
npm install
# Ensures: nodemailer already listed in package.json
```

### 4. **Start Backend**

```bash
npm start      # Production mode
# or
npm run dev    # Development with auto-reload
```

---

## 📱 Frontend Setup

### 1. **Update API Configuration**

Edit `frontend/lib/api_config.dart`:
```dart
static const String baseUrl = 'http://YOUR_BACKEND_IP:4000';
// Replace YOUR_BACKEND_IP with actual backend machine IP
```

### 2. **Permissions Required** (Android `AndroidManifest.xml`)

```xml
<!-- Microphone access for voice detection -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />

<!-- Location access for SOS alerts -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Background service permission -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### 3. **Update Dependencies** (Already in `pubspec.yaml`)

```yaml
dependencies:
  flutter_foreground_task: ^8.16.0  # Background service
  speech_to_text: ^7.0.0            # Voice recognition
  geolocator: ^13.0.2               # Location
  http: ^1.2.1                      # API calls
```

### 4. **Run Flutter App**

```bash
cd frontend
flutter pub get
flutter run
```

---

## 🔧 File Structure

```
Backend/
├── controllers/
│   ├── sosController.js         # Manual SOS alerts
│   └── threatController.js      # NEW: Threat-based alerts
├── routes/
│   ├── sosRoute.js              # Manual SOS routes
│   └── threatRoute.js           # NEW: Threat detection routes
├── server.js                    # Updated to include threatRoute
└── .env.example                 # NEW: Environment template

frontend/lib/
├── sos_service.dart             # Enhanced with threat detection
├── sos_task_handler.dart        # Updated with threat service
├── threat_detection_service.dart # NEW: Threat analysis
├── api_config.dart              # Updated endpoints
└── HomeScreen.dart              # Updated UI indicator
```

---

## 🎮 Testing the Feature

### Test Scenario 1: Automatic Threat Detection
1. **Start SOS**: Click the SOS button
2. **Say**: "Help! There's someone attacking me!"
3. **Expected**: 
   - Alert sent within 2 seconds
   - Email to contacts with threat analysis
   - UI shows 🎤 Threat Detection Active

### Test Scenario 2: Keyword Detection
1. **Start SOS**: Click the SOS button
2. **Say**: "Stop! Bachao!"
3. **Expected**: Immediate SOS alert (keyword-based)

### Test Scenario 3: False Positive Check
1. **Start SOS**: Click the SOS button
2. **Say**: "I need help finding my keys"
3. **Expected**: No alert (threat score < 0.5)

### Test Scenario 4: Background Monitoring
1. **Start SOS**: Activate SOS button
2. **Leave app**: Press home button to background app
3. **Speak**: "Help me, I'm in danger!"
4. **Expected**: Alert sent even while app backgrounded

---

## 📊 Threat Score Breakdown

The threat score is calculated by:

| Factor | Points | Examples |
|--------|--------|----------|
| Threat keyword | +0.15 | help, emergency, danger |
| Severity indicator | +0.25 | screaming, bleeding, dying |
| Context pattern | +0.10 | "they are attacking" |
| **Total Range** | **0.0 - 1.0** | - |

**Action Thresholds:**
- ≥ 0.7: CRITICAL - Immediate email alert
- ≥ 0.5: HIGH - Send threat alert with analysis
- < 0.5: No automatic alert (but keyword might trigger)

---

## 🔐 Security Considerations

1. **Email Security**: Uses Gmail App Password (not full account password)
2. **Token-based**: All API calls require JWT authentication
3. **Rate Limiting**: Alert throttling prevents abuse (30-second minimum)
4. **Local Threat Analysis**: No audio sent to external services (all processing local)
5. **Location**: Only sent when explicitly part of SOS alert

---

## 🐛 Troubleshooting

### Issue: Emails not sending
**Check:**
```
1. .env file has correct EMAIL_USER and EMAIL_PASS
2. Gmail App Password is 16 characters (not regular password)
3. Backend is running: npm start
4. Network connectivity to external mail server
```

### Issue: Voice not detected
**Check:**
```
1. Microphone permissions granted in app settings
2. Phone's mic is working (test in voice recorder)
3. speech_to_text plugin issues → run: flutter pub get
4. Background service running (check notification)
```

### Issue: Alerts not reaching contacts
**Check:**
```
1. Emergency contacts added to the app
2. Contacts have valid email addresses
3. Gmail spam folder (alerts may go there initially)
4. Check backend logs: npm run dev
```

---

## 📈 Future Enhancements

1. **ML-based voice analysis**: Replace keyword matching with ML model
2. **Sentiment analysis**: Detect emotional distress in voice tone
3. **Real-time location**: Continuous location tracking during SOS
4. **Emergency contact call**: Auto-call instead of just email
5. **Audio recording**: Save audio clips for evidence
6. **Trusted circle**: Expand beyond email to multiple contact methods

---

## 📞 Support

If you encounter issues:
1. Check the backend logs: `npm run dev` shows real-time errors
2. Verify `.env` configuration
3. Test email sending with a simple nodemailer script
4. Check Flutter's debug output for app-side issues

---

## ✅ Testing Checklist

- [ ] Gmail configured with App Password
- [ ] Backend running and accessible from phone
- [ ] Frontend IP/port pointing to correct backend
- [ ] App permissions granted (microphone, location, notifications)
- [ ] Manual SOS sends email properly
- [ ] Background service shows notification
- [ ] Voice detection starts automatically after SOS
- [ ] Threat keywords trigger alerts
- [ ] Non-threatening speech ignored
- [ ] Alerts include location link
- [ ] Email formatting displays correctly
