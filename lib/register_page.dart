import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/widgets/app_background.dart';
import 'core/theme/ubarber_colors.dart';
import 'core/widgets/app_language_button.dart';

import 'new_registration_page.dart';
import 'login_page.dart';
import 'customer_page.dart';
import 'salon_page.dart';
import 'app_translations.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
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

  Future<void> _enterAsGuest(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('role', 'guest');
    await prefs.setBool('isGuest', true);
    await prefs.remove('userId');
    await prefs.remove('email');
    await prefs.remove('name');
    await prefs.remove('phone');

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const CustomerPage(),
      ),
      (route) => false,
    );
  }

  String t(String key) => tr(key, currentLang);

@override
Widget build(BuildContext context) {
  return Directionality(
    textDirection:
        currentLang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
    child: Scaffold(
      backgroundColor: UBarberColors.background,
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 36,
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: currentLang == 'ar'
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: AppLanguageButton(
                          currentLang: currentLang,
                          onPressed: toggleLang,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        t('premium_experience'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 300),

                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 430,
                          ),
                          child: Column(
                            children: [
                              _buildMenuItem(
                                title: t('new_registration'),
                                subtitle: t('register_and_benefit'),
                                icon: Icons.person_add_alt_1_rounded,
                                color: UBarberColors.success,
                                isArabic: currentLang == 'ar',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const NewRegistrationPage(),
                                    ),
                                  );
                                },
                              ),

                              _buildMenuItem(
                                title: t('login'),
                                subtitle: t('login_with_email'),
                                icon: Icons.login_rounded,
                                color: UBarberColors.warning,
                                isArabic: currentLang == 'ar',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginPage(),
                                    ),
                                  );
                                },
                              ),

                              _buildMenuItem(
                                title: t('guest'),
                                subtitle: t('guest_mode_desc'),
                                icon: Icons.person_outline_rounded,
                                color: UBarberColors.primaryBlue,
                                isArabic: currentLang == 'ar',
                                onTap: () => _enterAsGuest(context),
                              ),

                              _buildMenuItem(
                                title: t('salon_register_temp'),
                                subtitle: t('for_admin_only'),
                                icon: Icons.storefront_rounded,
                                color: UBarberColors.menuSalon,
                                isArabic: currentLang == 'ar',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const SalonRegisterPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}
 
  Widget _buildMenuItem({
  required String title,
  required String subtitle,
  required IconData icon,
  required Color color,
  required bool isArabic,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              if (!isArabic)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 18,
                ),

              if (!isArabic)
                const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: isArabic
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      textAlign:
                          isArabic ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      textAlign:
                          isArabic ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Icon(
                icon,
                color: color,
                size: 26,
              ),

              if (isArabic)
                const SizedBox(width: 10),

              if (isArabic)
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
            ],
          ),

          const SizedBox(height: 4),

          Container(
            height: 1,
           color: Colors.lightBlueAccent,
          ),
        ],
      ),
    ),
  );
}
}