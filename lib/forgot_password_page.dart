import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_translations.dart';
import 'core/widgets/app_background.dart';
import 'core/widgets/app_text_field.dart';
import 'core/theme/ubarber_colors.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();

  bool loading = false;
  String errorText = '';
  String successText = '';

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

  @override
  Widget build(BuildContext context) {
    final isArabic = currentLang == 'ar';

    return Directionality(
      textDirection:
          isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: UBarberColors.background,
        body: AppBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: toggleLang,
                        icon: const Icon(
                          Icons.translate,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 50),

                  const Icon(
                    Icons.lock_reset_rounded,
                    color: UBarberColors.primaryBlue,
                    size: 64,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    t('forgot_password'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    t('forgot_password_subtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFC4D0E0),
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 30),

                  AppTextField(
                    controller: emailController,
                    hint: 'Gmail',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_rounded,
                  ),

                  if (errorText.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],

                  if (successText.isNotEmpty) ...[
  const SizedBox(height: 10),
  Text(
    successText,
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: UBarberColors.success,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
  ),
],

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                   onPressed: sendResetEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            UBarberColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        t('send_verification_code'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


Future<void> sendResetEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        errorText = 'اكتب البريد الإلكتروني أولاً';
      });
      return;
    }

    setState(() {
      loading = true;
      errorText = '';
      successText = '';
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      setState(() {
        successText =
            'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          errorText = 'لا يوجد حساب بهذا البريد الإلكتروني';
        } else if (e.code == 'invalid-email') {
          errorText = 'البريد الإلكتروني غير صحيح';
        } else {
          errorText = 'حدث خطأ، حاول مرة أخرى';
        }
      });
    } catch (e) {
      setState(() {
        errorText = 'حدث خطأ، حاول مرة أخرى';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }
}