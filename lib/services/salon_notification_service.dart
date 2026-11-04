import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalonNotificationService {
  static StreamSubscription<String>? tokenRefreshSubscription;

  static String safeTokenKey(String token) {
    return token.replaceAll(
      RegExp(r'[.#$/\[\]]'),
      '_',
    );
  }

  static Future<void> registerCurrentDeviceForSalon(
    String salonId,
  ) async {
    if (kIsWeb) return;

    try {
      await FirebaseMessaging.instance.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);
      final token = await FirebaseMessaging.instance.getToken();

      if (token != null && token.isNotEmpty) {
        await saveToken(
          salonId: salonId,
          token: token,
        );
      }

      await tokenRefreshSubscription?.cancel();

      tokenRefreshSubscription =
          FirebaseMessaging.instance.onTokenRefresh.listen(
        (newToken) async {
          final prefs = await SharedPreferences.getInstance();
          final currentSalonId = prefs.getString('salonId');

          if (currentSalonId == null || currentSalonId.isEmpty) {
            return;
          }

          await saveToken(
            salonId: currentSalonId,
            token: newToken,
          );
        },
      );
    } catch (_) {
      // عدم تعطيل تسجيل الدخول إذا تعذر حفظ رمز الإشعارات
    }
  }

  static Future<void> unregisterCurrentDevice() async {
    if (kIsWeb) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final salonId = prefs.getString('salonId');
      final token = await FirebaseMessaging.instance.getToken();

      if (salonId != null &&
          salonId.isNotEmpty &&
          token != null &&
          token.isNotEmpty) {
        await FirebaseDatabase.instance
            .ref()
            .child('salons')
            .child(salonId)
            .child('fcmTokens')
            .child(safeTokenKey(token))
            .remove();
      }

      await tokenRefreshSubscription?.cancel();
      tokenRefreshSubscription = null;
    } catch (_) {
      // عدم تعطيل تسجيل الخروج إذا تعذر حذف رمز الإشعارات
    }
  }

  static Future<void> saveToken({
    required String salonId,
    required String token,
  }) async {
    await FirebaseDatabase.instance
        .ref()
        .child('salons')
        .child(salonId)
        .child('fcmTokens')
        .child(safeTokenKey(token))
        .set({
      'token': token,
      'updatedAt': ServerValue.timestamp,
    });
  }
}