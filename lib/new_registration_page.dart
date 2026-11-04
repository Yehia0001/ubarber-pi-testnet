import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services_page.dart';
import 'app_translations.dart';

class NewRegistrationPage extends StatefulWidget {
  const NewRegistrationPage({super.key});

  @override
  State<NewRegistrationPage> createState() => _NewRegistrationPageState();
}

class _NewRegistrationPageState extends State<NewRegistrationPage> {
  final DatabaseReference rootRef = FirebaseDatabase.instance.ref();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();
final TextEditingController confirmPasswordController = TextEditingController();

  String currentLang = 'ar';
  bool loading = false;
  String errorText = '';

  bool hidePassword = true;
bool hideConfirmPassword = true;

  final Color bgColor = const Color(0xFF07111F);
  final Color greenColor = const Color(0xFF22C55E);
  final Color textColor = Colors.white;
  final Color subTextColor = const Color(0xFFC4D0E0);
  final Color fieldColor = const Color(0xFF13233A);
  final Color borderColor = const Color(0xFF304763);
  final Color redColor = const Color(0xFFEF4444);

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
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  bool isValidGmail(String email) {
    final value = normalizeEmail(email);
    return value.endsWith('@gmail.com') && value.contains('@');
  }

  bool isValidPhone(String phone) {
    return phone.trim().length >= 11;
  }

  Future<String?> getDefaultSalonId() async {
    final snapshot = await rootRef.child('salons').get();
    if (!snapshot.exists || snapshot.value == null) return null;

    final raw = Map<dynamic, dynamic>.from(snapshot.value as Map);
    if (raw.isEmpty) return null;

    return raw.keys.first.toString();
  }

  Future<void> saveSession({
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

  Future<void> registerCustomer() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = normalizeEmail(emailController.text);
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    setState(() => errorText = '');

    if (name.isEmpty) {
      setState(() => errorText = t('enter_name'));
      return;
    }

    if (!isValidPhone(phone)) {
      setState(() => errorText = t('enter_valid_phone'));
      return;
    }

    if (!isValidGmail(email)) {
      setState(() => errorText = t('enter_valid_gmail'));
      return;
    }  

    if (password.isEmpty) {
  setState(() => errorText = currentLang == 'ar'
      ? 'اكتب كلمة المرور'
      : 'Enter Password');
  return;
}

if (password.length < 6) {
  setState(() => errorText = currentLang == 'ar'
      ? 'كلمة المرور يجب ألا تقل عن 6 أحرف'
      : 'Password must be at least 6 characters');
  return;
}

if (confirmPassword.isEmpty) {
  setState(() => errorText = currentLang == 'ar'
      ? 'أكد كلمة المرور'
      : 'Confirm Password');
  return;
}

if (password != confirmPassword) {
  setState(() => errorText = currentLang == 'ar'
      ? 'كلمتا المرور غير متطابقتين'
      : 'Passwords do not match');
  return;
}

    setState(() => loading = true);

    try {
      final salonId = await getDefaultSalonId();

      if (salonId == null || salonId.isEmpty) {
        setState(() => errorText = t('no_salon_available'));
        return;
      }

      final usersSnapshot = await rootRef.child('users').get();

      if (usersSnapshot.exists && usersSnapshot.value != null) {
        final rawUsers = Map<dynamic, dynamic>.from(usersSnapshot.value as Map);

        for (final entry in rawUsers.entries) {
          final user = Map<dynamic, dynamic>.from(entry.value);

          final existingEmail =
              normalizeEmail(user['email']?.toString() ?? '');
          final existingPhone = user['phone']?.toString().trim() ?? '';

           if (existingEmail == email) {
            setState(() => errorText = t('account_exists'));
             return;
          }
        }
      }

final credential = await FirebaseAuth.instance
    .createUserWithEmailAndPassword(
  email: email,
  password: password,
);

    final newRef =
    rootRef.child('users').child(credential.user!.uid);

      await newRef.set({
        'id': credential.user!.uid,
        'name': name,
        'phone': phone,
        'email': email,
        'role': 'customer',
        'points': 0,
        'pointsHistory': [],
        'rating': 0,
        'isGuest': false,
        'welcomeDiscountUsed': false,
        'lastSalonId': salonId,
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });

      await saveSession(
        userId: newRef.key ?? '',
        name: name,
        phone: phone,
        email: email,
        salonId: salonId,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
      builder: (_) => ServicesPage(
  salonId: '-OyFyKbYR9lFUpoDPDQp',
),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint(e.toString());
      setState(() => errorText =e.toString() );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: subTextColor.withOpacity(0.85)),
      filled: true,
      fillColor: fieldColor.withOpacity(0.92),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor.withOpacity(0.9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: greenColor, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: redColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: redColor, width: 1.4),
      ),
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
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.transparent,
                      bgColor.withOpacity(0.90),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            isArabic
                                ? Icons.arrow_forward_ios_rounded
                                : Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 21,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.14),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: toggleLang,
                          icon: const Icon(
                            Icons.translate_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            currentLang == 'ar' ? 'EN' : 'AR',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),

Text(
  currentLang == 'ar'
      ? 'أنشئ حسابك الآن واستمتع بتجربة حلاقة احترافية'
      : 'Create your account now and enjoy a professional barber experience',
  textAlign: TextAlign.center,
  style: TextStyle(
    color: subTextColor,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  ),
),

const SizedBox(height: 150),

Align(
  alignment: Alignment.center,
  child: SizedBox(
    width: 430,
    child: Align(
      alignment:
          isArabic ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        t('create_account'),
        style: TextStyle(
          color: textColor,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  ),
),

const SizedBox(height: 16),

const SizedBox(height: 30),
Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(
      maxWidth: 430,
    ),
    child: Column(
      children: [
_buildField(
  controller: nameController,
  hint: t('enter_name'),
  icon: Icons.person_outline_rounded,
  keyboardType: TextInputType.name,
),

_buildField(
  controller: phoneController,
  hint: currentLang == 'ar'
      ? 'اكتب رقم التليفون'
      : 'Enter phone number',
  icon: Icons.phone_outlined,
  keyboardType: TextInputType.phone,
),

_buildField(
  controller: emailController,
  hint: currentLang == 'ar'
      ? 'اكتب Gmail'
      : 'Enter Gmail',
  icon: Icons.email_outlined,
  keyboardType: TextInputType.emailAddress,
),

_buildField(
  controller: passwordController,
  hint: currentLang == 'ar'
      ? 'اكتب كلمة المرور'
      : 'Enter Password',
  icon: Icons.lock_outline_rounded,
  keyboardType: TextInputType.visiblePassword,
 obscureText: hidePassword,
onToggleVisibility: () {
  setState(() {
    hidePassword = !hidePassword;
  });
},
),

_buildField(
  controller: confirmPasswordController,
  hint: currentLang == 'ar'
      ? 'تأكيد كلمة المرور'
      : 'Confirm Password',
  icon: Icons.lock_reset_outlined,
  keyboardType: TextInputType.visiblePassword,
 obscureText: hideConfirmPassword,
onToggleVisibility: () {
  setState(() {
    hideConfirmPassword = !hideConfirmPassword;
  });
},
),

if (errorText.isNotEmpty) ...[
  const SizedBox(height: 4),
  Text(
    errorText,
    textAlign: isArabic ? TextAlign.right : TextAlign.left,
    style: TextStyle(
      color: redColor,
      fontWeight: FontWeight.bold,
    ),
  ),
],

const SizedBox(height: 18),
Center(
  child:
SizedBox(
width: 260,
  child: ElevatedButton(
    onPressed: loading ? null : registerCustomer,
    style: ElevatedButton.styleFrom(
      backgroundColor: greenColor,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    child: Text(
      loading ? t('loading') : t('register'),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
),
),
],
    ),
  ),
),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildField({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  required TextInputType keyboardType,
  bool obscureText = false,
VoidCallback? onToggleVisibility,
}){
  final isArabic = currentLang == 'ar';

  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textAlign: isArabic ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        color: textColor,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: subTextColor,
        ),
        suffixIcon: onToggleVisibility != null
    ? IconButton(
        icon: Icon(
          obscureText
              ? Icons.visibility_off
              : Icons.visibility,
          color: subTextColor,
        ),
        onPressed: onToggleVisibility,
      )
    : null,
        border: UnderlineInputBorder(
          borderSide: BorderSide(
         color: Colors.lightBlueAccent.withOpacity(0.45),
          ),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
          color: Colors.lightBlueAccent.withOpacity(0.45),
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
          color: Colors.lightBlueAccent,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
        ),
        prefixIcon: isArabic
            ? null
            : Icon(
                icon,
                color: subTextColor,
              ),
      ),
    ),
  );
}
}