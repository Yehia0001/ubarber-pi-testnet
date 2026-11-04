import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'register_page.dart';
import 'services_page.dart';
import 'admin_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    startApp();
  }

  Future<void> startApp() async {
    await Future.delayed(const Duration(seconds: 5));

    final prefs = await SharedPreferences.getInstance();

    final role = prefs.getString('role');
    final salonId = prefs.getString('salonId');
    final isGuest = prefs.getBool('isGuest') ?? false;

    if (!mounted) return;

    if (role == null || role.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const RegisterPage(),
        ),
      );
      return;
    }

    if (role == 'salon') {
      if (salonId != null && salonId.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminPage(salonId: salonId),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const RegisterPage(),
          ),
        );
      }
      return;
    }

    if (role == 'customer' || role == 'guest' || isGuest) {
      if (salonId != null && salonId.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ServicesPage(salonId: salonId),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const RegisterPage(),
          ),
        );
      }
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_barber.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}