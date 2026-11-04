import 'forgot_password_page.dart';
import 'services/salon_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/widgets/app_text_field.dart';
import 'core/widgets/app_button.dart';
import 'core/theme/ubarber_colors.dart';
import 'core/widgets/app_background.dart';
import 'core/widgets/section_title.dart';



import 'services_page.dart';
import 'admin_page.dart';
import 'app_translations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final DatabaseReference rootRef = FirebaseDatabase.instance.ref();

  final TextEditingController emailController = TextEditingController();

final TextEditingController passwordController = TextEditingController();

bool hidePassword = true;

  bool loading = false;
  String errorText = '';
  String currentLang = 'ar';

  @override
  void initState() {
    super.initState();
    loadLang();
  }

  Future<void> loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      currentLang = prefs.getString('lang') ?? 'ar';
    });
  }

  Future<void> toggleLang() async {
    final prefs = await SharedPreferences.getInstance();
    final newLang = currentLang == 'ar' ? 'en' : 'ar';
    await prefs.setString('lang', newLang);

    if (!mounted) return;
    setState(() {
      currentLang = newLang;
    });
  }

  String t(String key) => tr(key, currentLang);

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  String normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  bool isValidGmail(String email) {
    final value = normalizeEmail(email);
    return value.endsWith('@gmail.com') && value.contains('@');
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

  Future<void> saveCustomerSession({
    required String userId,
    required String name,
    required String phone,
    required String email,
    required String salonId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', 'customer');
    await prefs.setString('userId', userId);
    await prefs.setString('name', name);
    await prefs.setString('phone', phone);
    await prefs.setString('email', email);
    await prefs.setString('salonId', salonId);
    await prefs.setBool('isGuest', false);
  }

  Future<void> saveSalonSession({
    required String salonId,
    required String salonName,
    required String phone,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', 'salon');
    await prefs.setString('userId', salonId);
    await prefs.setString('name', salonName);
    await prefs.setString('phone', phone);
    await prefs.setString('email', email);
    await prefs.setString('salonId', salonId);
    await prefs.setBool('isGuest', false);
  }

  Future<void> login() async {
    final email = normalizeEmail(emailController.text);

    setState(() {
      errorText = '';
    });

    if (!isValidGmail(email)) {
      setState(() => errorText = t('enter_valid_gmail'));
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final salonsSnapshot = await rootRef.child('salons').get();

      if (salonsSnapshot.exists && salonsSnapshot.value != null) {
        final rawSalons = Map<dynamic, dynamic>.from(salonsSnapshot.value as Map);

        for (final entry in rawSalons.entries) {
          if (entry.value is Map) {
            final salon = Map<dynamic, dynamic>.from(entry.value);
            final existingEmail =
                normalizeEmail(salon['ownerEmail']?.toString() ?? '');

            if (existingEmail == normalizeEmail(email)) {
              final salonId = entry.key.toString();

              await saveSalonSession(
                salonId: salonId,
                salonName: salon['name']?.toString() ?? t('salon'),
                phone: salon['phone']?.toString() ?? '',
                email: email,
              );

await SalonNotificationService.registerCurrentDeviceForSalon(salonId);

              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminPage(salonId: salonId),
                ),
                (route) => false,
              );
              return;
            }
          }
        }
      }

      final usersSnapshot = await rootRef.child('users').get();

      if (usersSnapshot.exists && usersSnapshot.value != null) {
        final rawUsers = Map<dynamic, dynamic>.from(usersSnapshot.value as Map);

        for (final entry in rawUsers.entries) {
          if (entry.value is Map) {
            final user = Map<dynamic, dynamic>.from(entry.value);
            final existingEmail =
                normalizeEmail(user['email']?.toString() ?? '');

            if (existingEmail == email) {
              final salonId = user['lastSalonId']?.toString().isNotEmpty == true
                  ? user['lastSalonId'].toString()
                  : (await getDefaultSalonId() ?? '');

              await rootRef.child('users').child(entry.key.toString()).update({
                'lastSalonId': salonId,
                'updatedAt': ServerValue.timestamp,
              });

              await saveCustomerSession(
                userId: entry.key.toString(),
                name: user['name']?.toString() ?? '',
                phone: user['phone']?.toString() ?? '',
                email: email,
                salonId: salonId,
              );

              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => ServicesPage(salonId: salonId),
                ),
                (route) => false,
              );
              return;
            }
          }
        }
      }

      setState(() {
        errorText = t('account_not_found');
      });
    } catch (e) {
      setState(() {
        errorText = t('login_error');
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final isArabic = currentLang == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: AppBackground(
      child: Scaffold(
       backgroundColor: UBarberColors.background,
        appBar: AppBar(
         backgroundColor: UBarberColors.background,
          elevation: 0,
         foregroundColor: UBarberColors.white,
          title: Text(t('login')),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton.icon(
                onPressed: toggleLang,
                icon: const Icon(
                  Icons.translate_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  currentLang == 'ar' ? 'EN' : 'AR',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: AppBackground(
  child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [                     
const SizedBox(height: 24),
const SizedBox(height: 10),

const SizedBox(height: 12),
                      Text(
                    t('enter_email'),
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                        style: TextStyle(
                          color: UBarberColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 120),
         SizedBox(
  width: 420,
  child: AppTextField(
    controller: emailController,
    hint: t('email'),
    keyboardType: TextInputType.emailAddress,
    prefixIcon: Icons.email_outlined,
  ),
), 
const SizedBox(height: 16),

SizedBox(
  width: 420,
  child: AppTextField(
  controller: passwordController,
  hint: t('password'),
  keyboardType: TextInputType.visiblePassword,
  obscureText: hidePassword,
  prefixIcon: Icons.lock_outlined,
  suffixIcon: Icon(
    hidePassword ? Icons.visibility_off : Icons.visibility,
  ),
  onSuffixPressed: () {
    setState(() {
      hidePassword = !hidePassword;
    });
  },
),
),
        if (errorText.isNotEmpty) ...[
  const SizedBox(height: 14),
  Text(
    errorText,
    textAlign: isArabic ? TextAlign.right : TextAlign.left,
    style: TextStyle(
      color: UBarberColors.error,
      fontSize: 15,
      fontWeight: FontWeight.bold,
    ),
  ),
],

const SizedBox(height: 20),

TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ForgotPasswordPage(),
      ),
    );
  },
  child: Text(
    t('forgot_password'),
    style: TextStyle(
     color: UBarberColors.primaryBlue,
      fontSize: 15,
      fontWeight: FontWeight.bold,
    ),
  ),
),

const SizedBox(height: 20),

Center(
  child: SizedBox(
    width: 260,
    child: AppButton(
      title: loading ? t('logging_in') : t('login'),
      onPressed: loading ? null : login,
    ),
  ),
),         
                    ],                 
                ),
              ),
            ),
          ),
        ),
      ),
      ),
      ),
    );
  }
}