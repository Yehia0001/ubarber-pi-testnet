import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/widgets/app_text_field.dart';
import 'core/widgets/app_button.dart';
import 'core/widgets/app_background.dart';
import 'core/theme/ubarber_colors.dart';

import 'admin_page.dart';
import 'app_translations.dart';

class SalonRegisterPage extends StatefulWidget {
  const SalonRegisterPage({super.key});

  @override
  State<SalonRegisterPage> createState() => _SalonRegisterPageState();
}

class _SalonRegisterPageState extends State<SalonRegisterPage> {
  final DatabaseReference rootRef = FirebaseDatabase.instance.ref();

  final TextEditingController salonNameController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
final TextEditingController confirmPasswordController = TextEditingController();

bool hidePassword = true;
bool hideConfirmPassword = true;

  final Color bgColor = const Color(0xFF07111F);
  final Color fieldColor = const Color(0xFF13233A);
  final Color borderColor = const Color(0xFF304763);
  final Color blueColor = const Color(0xFF3B82F6);
  final Color redColor = const Color(0xFFEF4444);
  final Color textColor = Colors.white;
  final Color subTextColor = const Color(0xFFC4D0E0);

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
    salonNameController.dispose();
    ownerNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    locationController.dispose();
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

  String normalizeWhatsappPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.startsWith('20')) return digits;
    if (digits.startsWith('0')) return '2$digits';

    return digits;
  }

  InputDecoration fieldDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: blueColor),
      hintText: hint,
      hintStyle: TextStyle(color: subTextColor.withOpacity(0.8)),
      filled: true,
      fillColor: fieldColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: blueColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Future<void> saveSession({
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

  Future<void> registerSalon() async {
    final salonName = salonNameController.text.trim();
    final ownerName = ownerNameController.text.trim();
    final phone = phoneController.text.trim();
    final email = normalizeEmail(emailController.text);
    final location = locationController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final bookingWhatsapp = normalizeWhatsappPhone(phone);

    setState(() => errorText = '');

    if (salonName.isEmpty) {
      setState(() => errorText = t('enter_salon_name'));
      return;
    }

    if (ownerName.isEmpty) {
      setState(() => errorText = t('enter_owner_name'));
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

    if (password.length < 6) {
  setState(() => errorText = t('password_too_short'));
  return;
}

if (password != confirmPassword) {
  setState(() => errorText = t('passwords_not_match'));
  return;
}

    setState(() => loading = true);

    try {
      final salonsSnapshot = await rootRef.child('salons').get();

      if (salonsSnapshot.exists && salonsSnapshot.value != null) {
        final rawSalons =
            Map<dynamic, dynamic>.from(salonsSnapshot.value as Map);

        for (final entry in rawSalons.entries) {
          if (entry.value is Map) {
            final salon = Map<dynamic, dynamic>.from(entry.value);
            final existingEmail =
                normalizeEmail(salon['ownerEmail']?.toString() ?? '');
            final existingPhone = salon['phone']?.toString().trim() ?? '';

            if (existingEmail == email || existingPhone == phone) {
              setState(() => errorText = t('salon_already_registered'));
              return;
            }
          }
        }
      }

      final newSalonRef = rootRef.child('salons').push();
      final salonId = newSalonRef.key ?? '';

      await newSalonRef.set({
        'id': salonId,
        'name': salonName,
        'ownerName': ownerName,
        'ownerEmail': email,
        'phone': phone,
        'bookingWhatsapp': bookingWhatsapp,
        'location': location,
        'ratingTotal': 0,
        'ratingCount': 0,
        'ratingAverage': 0,
        'profileImage': '',
        'workDays': {},
        'settings': {
          'enabled': false,
          'discount': 0,
        },
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });

      await saveSession(
        salonId: salonId,
        salonName: salonName,
        phone: phone,
        email: email,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => AdminPage(salonId: salonId),
        ),
        (route) => false,
      );
    } catch (_) {
      setState(() => errorText = t('salon_register_error'));
    } finally {
      if (mounted) setState(() => loading = false);
    }
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.arrow_back, color: textColor),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: toggleLang,
                          icon: Icon(Icons.translate, color: textColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Icon(
                      Icons.storefront_rounded,
                      color: blueColor,
                      size: 54,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t('create_salon_account'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      t('salon_register_subtitle'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildField(
                      salonNameController,
                      t('salon_name'),
                      Icons.store_rounded,
                    ),
                    _buildField(
                      ownerNameController,
                      t('owner_name'),
                      Icons.person_rounded,
                    ),
                    _buildField(
                      phoneController,
                      t('phone'),
                      Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildField(
                      emailController,
                      'Gmail',
                      Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildPasswordField(
  passwordController,
  t('password'),
  hidePassword,
  () {
    setState(() {
      hidePassword = !hidePassword;
    });
  },
),
_buildPasswordField(
  confirmPasswordController,
  t('confirm_password'),
  hideConfirmPassword,
  () {
    setState(() {
      hideConfirmPassword = !hideConfirmPassword;
    });
  },
),

                    _buildField(
                      locationController,
                      t('location_optional'),
                      Icons.location_on_rounded,
                    ),
                    if (errorText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorText,
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                        style: TextStyle(
                          color: redColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: loading ? null : registerSalon,
                        icon: loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.verified_rounded),
                        label: Text(
                          loading
                              ? t('registering')
                              : t('register_salon'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blueColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      t('salon_register_note'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: subTextColor.withOpacity(0.85),
                        fontSize: 13,
                        height: 1.5,
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
 Widget _buildPasswordField(
  TextEditingController controller,
  String hint,
  bool obscure,
  VoidCallback onPressed,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: AppTextField(
      controller: controller,
      hint: hint,
      obscureText: obscure,
      prefixIcon: Icons.lock_rounded,
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off : Icons.visibility,
          color: UBarberColors.primaryBlue,
        ),
        onPressed: onPressed,
      ),
    ),
  );
}
  Widget _buildField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
  return Padding(
  padding: const EdgeInsets.only(bottom: 14),
  child: AppTextField(
    controller: controller,
    hint: hint,
    keyboardType: keyboardType,
    prefixIcon: icon,
  ),
);
  }
}