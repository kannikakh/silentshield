# Backend Integration Guide - Call Analysis

## 🎯 What's Set Up

Your Flutter app can now:
- ✅ Send call transcripts to backend API
- ✅ Get risk score (0.0 - 1.0)
- ✅ Display alerts based on risk level
- ✅ Handle errors gracefully

---

## 📋 Risk Score Reference

| Risk Score | Meaning | Color | Action |
|-----------|---------|-------|--------|
| 0.0 - 0.3 | Safe ✅ | Green | Normal |
| 0.3 - 0.7 | Suspicious ⚠️ | Orange | Show warning |
| 0.7 - 1.0 | Scam 🚨 | Red | Show alert & SOS |

---

## 🚀 How to Use in Your Screens

### Option 1: Simple Implementation

```dart
import 'package:silentshield/services/call_analysis_service.dart';

// When you have call text:
final analysis = await CallAnalysisService.analyzeCallTranscript(
  "Send your OTP now or your account will be blocked"
);

// Display results
print('Risk: ${analysis.getRiskPercentage()}%');
print('Level: ${analysis.getRiskLevel()}');
print('Is Scam: ${analysis.isScamLikely()}');

// Show alert if scam
if (analysis.isScamLikely()) {
  // Show warning UI
}
```

### Option 2: In a StatefulWidget

```dart
class CallScreen extends StatefulWidget {
  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  CallAnalysisResponse? _analysis;
  bool _isLoading = false;

  void _analyzeCall(String transcriptText) async {
    setState(() => _isLoading = true);
    
    try {
      final analysis = await CallAnalysisService.analyzeCallTranscript(
        transcriptText
      );
      
      setState(() {
        _analysis = analysis;
        _isLoading = false;
      });

      // Trigger SOS if scam detected
      if (analysis.isScamLikely()) {
        _showScamAlert(analysis);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e')),
      );
    }
  }

  void _showScamAlert(CallAnalysisResponse analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${CallAnalysisService.getRiskEmoji(analysis.risk)} '
          '${analysis.getRiskLevel()}'
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Risk: ${analysis.getRiskPercentage()}%',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (analysis.scamPatterns != null) ...[
              const Text('Detected:'),
              ...analysis.scamPatterns!.map(
                (pattern) => Text('• $pattern'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              // Trigger SOS
              sosService.sendSos();
              Navigator.pop(context);
            },
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : YourCallUI(_analysis),
    );
  }
}
```

---

## 🔧 Backend URL Configuration

**Currently set to:** `http://localhost:8000`

⚠️ **IMPORTANT**: Change based on your setup:

### For Android Emulator:
```dart
static const String baseUrl = "http://10.0.2.2:8000";
```

### For iOS Simulator:
```dart
static const String baseUrl = "http://localhost:8000";
```

### For Real Device/Building:
```dart
static const String baseUrl = "http://<YOUR_PC_IP>:8000";
// Example: "http://192.168.1.100:8000"
```

**Find your PC IP:**
- Windows: Open Command Prompt, type `ipconfig`, look for IPv4 Address
- Make sure phone is on same WiFi network

---

## 📡 API Endpoint Format

### Request:
```json
POST http://localhost:8000/analyze-call
Content-Type: application/json

{
  "text": "Send your OTP now"
}
```

### Response (200 OK):
```json
{
  "transcript": "Send your OTP now",
  "risk": 0.85,
  "scamPatterns": [
    "Urgency tactics",
    "Information requesting"
  ],
  "confidenceScore": 92
}
```

### Error Response:
```
500 Internal Server Error
"Backend processor failed"
```

---

## 🐛 Debugging

### Check logs in VS Code:
Look for:
- `📱 API: Sending text to analyze:`
- `📊 API Response Code:`
- `✅ Analysis Complete`
- `❌ API Call Failed:`

### Common Issues:

**Issue:** "Connection refused" or "Network error"
- ✅ Backend is not running on `http://localhost:8000`
- ✅ Check your IP address (especially for real devices)
- ✅ Make sure backend is started: `python app/main.py`

**Issue:** "API timeout"
- ✅ Backend is taking too long (>30 seconds)
- ✅ Check CPU usage, model might be stuck
- ✅ Check internet connection

**Issue:** "API Error: 400"
- ✅ Wrong JSON format sent
- ✅ Empty text field

**Issue:** "API Error: 500"
- ✅ Backend crashed
- ✅ Model not loaded properly
- ✅ Check backend logs

---

## 📱 Integration Points

### When to call analysis:

1. **During call (real-time):**
   - Get live transcript from speech-to-text
   - Send every 30 seconds for update
   - Show live risk meter

2. **After call ends:**
   - Analyze full transcript
   - Show final risk assessment
   - Save to Firestore for history

3. **Test scenarios:**
   - Button press with sample text
   - Voice input converted to text
   - Incoming call interception

---

## 🚀 Next Steps

1. ✅ Backend is ready with your model
2. ✅ API service is configured
3. ✅ Response model is typed-safe
4. 📝 Integrate into your call detection screen
5. 📝 Connect with SOS service for alerts
6. 📝 Add real speech-to-text integration
7. 📝 Save analysis to Firestore history

---

## 📚 Files Created

- `lib/models/call_analysis_response.dart` - Response model
- `lib/services/api_service.dart` - API calls (updated)
- `lib/services/call_analysis_service.dart` - Helper service
- This guide: `BACKEND_INTEGRATION.md`

---

Done! Your backend integration is ready. 🎉
