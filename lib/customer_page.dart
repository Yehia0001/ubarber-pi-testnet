import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services_page.dart';
import 'register_page.dart';
import 'app_translations.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  final DatabaseReference rootRef = FirebaseDatabase.instance.ref();

  final Color bgColor = const Color(0xFF07111F);
  final Color cardColor = const Color(0xDD101B2D);
  final Color textColor = Colors.white;
  final Color subTextColor = const Color(0xFFC4D0E0);
  final Color greenColor = const Color(0xFF22C55E);
  final Color redColor = const Color(0xFFEF4444);

  String errorText = '';
  String currentLang = 'ar';

  @override
  void initState() {
    super.initState();
    loadLangAndEnter();
  }

  String t(String key) => tr(key, currentLang);

  Future<void> loadLangAndEnter() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;
    setState(() {
      currentLang = prefs.getString('lang') ?? 'ar';
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      enterAsGuest();
    });
  }

  Future<String?> getDefaultSalonId() async {
    final snapshot = await rootRef.child('salons').get();

    if (!snapshot.exists || snapshot.value == null) {
      return null;
    }

    final raw = Map<dynamic, dynamic>.from(snapshot.value as Map);
    if (raw.isEmpty) return null;

    return raw.keys.first.toString();
  }

  Future<void> saveGuestSession(String salonId) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('role', 'guest');
    await prefs.setString('userId', 'guest');
    await prefs.setString('name', currentLang == 'ar' ? 'زائر' : 'Guest');
    await prefs.setString('phone', '');
    await prefs.setString('email', '');
    await prefs.setString('salonId', salonId);
    await prefs.setBool('isGuest', true);
  }

  Future<void> enterAsGuest() async {
    if (!mounted) return;

    setState(() {
      errorText = '';
    });

    try {
      final salonId = await getDefaultSalonId();

      if (salonId == null || salonId.isEmpty) {
        if (!mounted) return;
        setState(() {
          errorText = t('no_salon_available');
        });
        return;
      }

      await saveGuestSession(salonId);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ServicesPage(salonId: salonId),
        ),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorText = t('guest_login_error');
      });
    }
  }

  void goBack() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterPage(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = currentLang == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/register_bg.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.62)),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: errorText.isNotEmpty
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: redColor,
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                errorText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: goBack,
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  label: Text(
                                    t('back'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: greenColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: greenColor),
                              const SizedBox(height: 20),
                              Text(
                                t('entering_as_guest'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t('guest_redirect_hint'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}