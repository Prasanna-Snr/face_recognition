import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart'; // firebase options auto generate bhako

class AppInitService {
  // Yo function SplashScreen ko initState bata call garne
  // Background maa sab initialization kaam garna
  static Future<void> init() async {
    // Firebase initialize garnu
    // Firebase init nagari FCM, Firestore, etc. kaam garna sakinna
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // SharedPreferences load garnu
    // Yo bata login status, user info, settings fetch garna milcha
    final prefs = await SharedPreferences.getInstance();

    // Example: login status check garnu
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    // yo line optional ho, future maa logic add garna milcha

    // Optional: yaha FCM token fetch garna pani garna milcha
    // jasto ki FirebaseMessaging.instance.getToken()
    // tespachi backend ma register garna milcha
  }
}
