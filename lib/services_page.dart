import 'services/salon_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_translations.dart';
import 'booking_page.dart';
import 'register_page.dart';
import 'track_queue_page.dart';
import 'offers_page.dart';

class ServicesPage extends StatefulWidget {
  final String salonId;
  final bool fromAdminPreview;

  const ServicesPage({
    super.key,
    required this.salonId,
    this.fromAdminPreview = false,
  });

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final DatabaseReference rootRef = FirebaseDatabase.instance.ref();

  static const String backgroundImagePath = 'assets/images/home_bg.jpg';

  final Color bgColor = const Color(0xFF07111F);
  final Color cardColor = const Color(0xDD101B2D);
  final Color fieldColor = const Color(0xDD13233A);
  final Color borderColor = const Color(0xFF304763);
  final Color greenColor = const Color(0xFF22C55E);
  final Color orangeColor = const Color(0xFFF59E0B);
  final Color blueColor = const Color(0xFF4A86F7);
  final Color textColor = Colors.white;
  final Color subTextColor = const Color(0xFFC4D0E0);
  final Color redColor = const Color(0xFFEF4444);

  bool loading = true;
  String errorText = '';

  Map<String, dynamic> salonData = {};
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> barbers = [];

  String myName = '';
  String myPhone = '';
  int myPoints = 0;
  String myRating = '0.0';
  String myRole = '';
  String myUserId = '';
  bool isGuest = false;
  String currentLang = 'ar';

  @override
  void initState() {
    super.initState();
    loadPageData();
    loadMyProfile();
  }

  String get salonWord => currentLang == 'en' ? 'Salon' : 'صالون';

String getSalonPrefix(String salonName) {
  final name = salonName.trim();

  if (name.isEmpty) return 'Salon';

  final onlyLetters = name.replaceAll(
    RegExp(r'[^A-Za-z\u0600-\u06FF]'),
    '',
  );

  if (onlyLetters.isNotEmpty &&
      RegExp(r'^[\u0600-\u06FF]+$').hasMatch(onlyLetters)) {
    return 'صالون';
  }

  return 'Salon';
}
  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  String getServiceName(Map<String, dynamic> service) {
    return currentLang == 'ar'
        ? service['nameAr']?.toString() ?? service['name']?.toString() ?? ''
        : service['nameEn']?.toString() ?? service['name']?.toString() ?? '';
  }

  String getBarberName(Map<String, dynamic> barber) {
    return currentLang == 'ar'
        ? barber['nameAr']?.toString() ?? barber['name']?.toString() ?? ''
        : barber['nameEn']?.toString() ?? barber['name']?.toString() ?? '';
  }

  Future<void> _saveLang(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', lang);

    if (!mounted) return;
    setState(() {
      currentLang = lang;
    });
  }

  Future<void> _toggleLanguage() async {
    final newLang = currentLang == 'ar' ? 'en' : 'ar';
    await _saveLang(newLang);
  }

  Future<void> loadMyProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final savedName = prefs.getString('name') ?? '';
    final savedPhone = prefs.getString('phone') ?? '';
    final savedRole = prefs.getString('role') ?? '';
    final savedUserId = prefs.getString('userId') ?? '';
    final savedGuest = prefs.getBool('isGuest') ?? false;
    final savedLang = prefs.getString('lang') ?? 'ar';

    int points = 0;
    String rating = '0.0';

    if (!savedGuest && savedRole == 'customer' && savedUserId.isNotEmpty) {
      final userSnapshot = await rootRef.child('users').child(savedUserId).get();

      if (userSnapshot.exists && userSnapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(userSnapshot.value as Map);
        points = _toInt(data['points']);
        rating = data['rating']?.toString() ?? '0.0';
      }
    }

    if (!mounted) return;
    setState(() {
      myName = savedName;
      myPhone = savedPhone;
      myRole = savedRole;
      myUserId = savedUserId;
      isGuest = savedGuest || savedRole == 'guest';
      myPoints = points;
      myRating = rating;
      currentLang = savedLang;
    });
  }

Future<void> loadPageData() async {
  setState(() {
    loading = true;
    errorText = '';
  });

  try {
    final salonSnapshot =
        await rootRef.child('salons').child(widget.salonId).get();

    if (!salonSnapshot.exists || salonSnapshot.value == null) {
      setState(() {
        loading = false;
        errorText = tr('salon_not_found', currentLang);
      });
      return;
    }

    final salonMap =
        Map<dynamic, dynamic>.from(salonSnapshot.value as Map);

    final loadedCategories = <Map<String, dynamic>>[];
    final loadedServices = <Map<String, dynamic>>[];
    final loadedBarbers = <Map<String, dynamic>>[];

    // =========================================================
    // تحميل الأقسام
    // =========================================================

    if (salonMap['categories'] != null) {
      final rawCategories =
          Map<dynamic, dynamic>.from(salonMap['categories'] as Map);

      rawCategories.forEach((key, value) {
        if (value is Map) {
          final item = Map<dynamic, dynamic>.from(value);

          loadedCategories.add({
            'id': key.toString(),
            'name': item['name']?.toString() ??
                tr('category', currentLang),
            'nameAr': item['nameAr']?.toString() ??
                item['name']?.toString() ??
                '',
            'nameEn': item['nameEn']?.toString() ??
                item['name']?.toString() ??
                '',
          });
        } else {
          loadedCategories.add({
            'id': key.toString(),
            'name': value.toString(),
            'nameAr': value.toString(),
            'nameEn': value.toString(),
          });
        }
      });
    }

    // =========================================================
    // تحميل الخدمات من salon/services
    // =========================================================

    if (salonMap['services'] != null) {
      final rawServices =
          Map<dynamic, dynamic>.from(salonMap['services'] as Map);

      rawServices.forEach((key, value) {
        if (value is Map) {
          final item = Map<dynamic, dynamic>.from(value);

          loadedServices.add({
            'id': key.toString(),
            'name': item['name']?.toString() ??
                tr('service', currentLang),
            'nameAr': item['nameAr']?.toString() ??
                item['name']?.toString() ??
                '',
            'nameEn': item['nameEn']?.toString() ??
                item['name']?.toString() ??
                '',
            'price': item['price']?.toString() ?? '',
            'duration': item['duration']?.toString() ?? '',
            'categoryId': item['categoryId']?.toString() ?? '',
          });
        }
      });
    }

    // =========================================================
    // مهم جدًا:
    // ربط الخدمات بالأقسام من:
    //
    // salons/{salonId}/categories/{categoryId}/services
    //
    // لأن AdminPage يحفظ الربط هنا.
    // =========================================================

    if (salonMap['categories'] != null) {
      final rawCategories =
          Map<dynamic, dynamic>.from(salonMap['categories'] as Map);

      for (final categoryEntry in rawCategories.entries) {
        final categoryId = categoryEntry.key.toString();
        final categoryValue = categoryEntry.value;

        if (categoryValue is! Map) continue;

        final categoryMap =
            Map<dynamic, dynamic>.from(categoryValue);

        final categoryServices = categoryMap['services'];

        if (categoryServices is! Map) continue;

        final linkedServices =
            Map<dynamic, dynamic>.from(categoryServices);

        for (final serviceEntry in linkedServices.entries) {
          final serviceId = serviceEntry.key.toString();

          final serviceIndex = loadedServices.indexWhere(
            (service) => service['id'].toString() == serviceId,
          );

          if (serviceIndex != -1) {
            loadedServices[serviceIndex]['categoryId'] = categoryId;
          }
        }
      }
    }

    // =========================================================
    // تحميل الحلاقين
    // =========================================================

    if (salonMap['barbers'] != null) {
      final rawBarbers =
          Map<dynamic, dynamic>.from(salonMap['barbers'] as Map);

      rawBarbers.forEach((key, value) {
        if (value is Map) {
          final item = Map<dynamic, dynamic>.from(value);

          loadedBarbers.add({
            'id': key.toString(),
            'name': item['name']?.toString() ??
                tr('barber', currentLang),
            'nameAr': item['nameAr']?.toString() ??
                item['name']?.toString() ??
                '',
            'nameEn': item['nameEn']?.toString() ??
                item['name']?.toString() ??
                '',
            'role': item['role']?.toString() ?? '',
            'available': item['available'] is bool
                ? item['available'] as bool
                : true,
            'active': item['active'] is bool
                ? item['active'] as bool
                : true,
            'rating': item['rating']?.toString() ?? '',
          });
        } else {
          loadedBarbers.add({
            'id': key.toString(),
            'name': value.toString(),
            'nameAr': value.toString(),
            'nameEn': value.toString(),
            'role': '',
            'available': true,
            'active': true,
            'rating': '',
          });
        }
      });
    }

    // =========================================================
    // تحديث الشاشة
    // =========================================================

    if (!mounted) return;

    setState(() {
      salonData = {
        'name': salonMap['name']?.toString() ?? '',
        'address': salonMap['location']?.toString() ??
            salonMap['address']?.toString() ??
            '',
        'phone': salonMap['phone']?.toString() ?? '',
        'description': salonMap['description']?.toString() ?? '',
        'rating': salonMap['ratingAverage']?.toString() ?? '0.0',
        'bookingWhatsapp':
            salonMap['bookingWhatsapp']?.toString() ?? '',
      };

      categories = loadedCategories;
      services = loadedServices;
      barbers = loadedBarbers;
      loading = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      errorText = '${tr('error', currentLang)}: $e';
      loading = false;
    });
  }
}

  Future<void> logout() async {
    await SalonNotificationService.unregisterCurrentDevice();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterPage(),
      ),
      (route) => false,
    );
  }

  List<Map<String, dynamic>> _servicesForCategory(String categoryId) {
    return services
        .where((service) => service['categoryId']?.toString() == categoryId)
        .toList();
  }

  List<Map<String, dynamic>> _uncategorizedServices() {
    final categoryIds = categories.map((e) => e['id'].toString()).toSet();
    return services.where((service) {
      final categoryId = service['categoryId']?.toString() ?? '';
      return categoryId.isEmpty || !categoryIds.contains(categoryId);
    }).toList();
  }

  String getCategoryName(Map<String, dynamic> category) {
    return currentLang == 'ar'
        ? category['nameAr']?.toString() ?? category['name']?.toString() ?? ''
        : category['nameEn']?.toString() ?? category['name']?.toString() ?? '';
  }

  void showSalonInfo() {
    final displayName = salonData['name']?.toString().trim().isNotEmpty == true
        ? salonData['name'].toString().trim()
        : tr('not_available_text', currentLang);

    final displayPhone =
        salonData['phone']?.toString().trim().isNotEmpty == true
            ? salonData['phone'].toString().trim()
            : tr('not_available_text', currentLang);

    final displayAddress =
        salonData['address']?.toString().trim().isNotEmpty == true
            ? salonData['address'].toString().trim()
            : tr('not_specified', currentLang);

    final displayDescription =
        salonData['description']?.toString().trim().isNotEmpty == true
            ? salonData['description'].toString().trim()
            : tr('no_description', currentLang);

    final displayRating =
        salonData['rating']?.toString().trim().isNotEmpty == true
            ? salonData['rating'].toString().trim()
            : '0.0';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1728),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return Directionality(
          textDirection:
              currentLang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Wrap(
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF1A2B45),
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName.characters.first
                            : 'S',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$salonWord $displayName',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr('salon_official_page', currentLang),
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _premiumInfoRow(
                  Icons.storefront,
                  tr('name', currentLang),
                  displayName,
                ),
                _premiumInfoRow(
                  Icons.location_on_outlined,
                  tr('address', currentLang),
                  displayAddress,
                ),
                _premiumInfoRow(
                  Icons.phone_outlined,
                  tr('phone', currentLang),
                  displayPhone,
                ),
                _premiumInfoRow(
                  Icons.star_outline,
                  tr('rating', currentLang),
                  displayRating,
                ),
                _premiumInfoRow(
                  Icons.description_outlined,
                  tr('description', currentLang),
                  displayDescription,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showMyAccount() {
    final displayName =
        myName.trim().isNotEmpty ? myName.trim() : tr('guest', currentLang);
    final displayPhone = myPhone.trim().isNotEmpty
        ? myPhone.trim()
        : tr('not_available_text', currentLang);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1728),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return Directionality(
          textDirection:
              currentLang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Wrap(
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor: const Color(0xFF1A2B45),
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName.characters.first
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayPhone,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 22),
                _profileStatCard(
                  icon: Icons.stars_rounded,
                  title: tr('points', currentLang),
                  value: '$myPoints',
                ),
                const SizedBox(height: 12),
                _profileStatCard(
                  icon: Icons.star_rate_rounded,
                  title: tr('rating', currentLang),
                  value: myRating,
                ),
                const SizedBox(height: 12),
                _profileStatCard(
                  icon: Icons.badge_outlined,
                  title: tr('account', currentLang),
                  value: isGuest
                      ? tr('guest', currentLang)
                      : tr('customer', currentLang),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: logout,
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(
                      tr('logout', currentLang),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: redColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _premiumInfoRow(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: orangeColor),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              textDirection:
                  currentLang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: orangeColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: currentLang == 'ar' ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: subTextColor,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment:
          currentLang == 'ar' ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: currentLang == 'ar' ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            color: textColor,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: currentLang == 'ar' ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              color: subTextColor,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget buildServiceCard(Map<String, dynamic> service) {
    final price = service['price']?.toString() ?? '';
    final duration = service['duration']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withOpacity(0.85)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: orangeColor.withOpacity(0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.content_cut_rounded,
              color: orangeColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: currentLang == 'ar'
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  getServiceName(service),
                  textAlign:
                      currentLang == 'ar' ? TextAlign.right : TextAlign.left,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  mainAxisAlignment: currentLang == 'ar'
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    if (duration.isNotEmpty) ...[
                      Text(
                        '$duration ${tr('minutes', currentLang)}',
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (price.isNotEmpty)
                      Text(
                        '$price ${tr('currency_egp', currentLang)}',
                        style: TextStyle(
                          color: greenColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBarberCard(Map<String, dynamic> barber) {
    final available = barber['available'] == true || barber['active'] == true;
    final ratingText = barber['rating']?.toString().trim() ?? '';
    final hasRating =
        ratingText.isNotEmpty && ratingText != '0' && ratingText != '0.0';

    return Container(
      width: 170,
      margin: EdgeInsets.only(
        left: currentLang == 'ar' ? 12 : 0,
        right: currentLang == 'ar' ? 0 : 12,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor.withOpacity(0.85)),
      ),
      child: Column(
        crossAxisAlignment:
            currentLang == 'ar' ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF1A2B45),
            child: Icon(Icons.content_cut_rounded, color: orangeColor),
          ),
          const SizedBox(height: 12),
          Text(
            getBarberName(barber),
            textAlign: currentLang == 'ar' ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            barber['role']?.toString().isNotEmpty == true
                ? barber['role'].toString()
                : tr('barber', currentLang),
            textAlign: currentLang == 'ar' ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              color: subTextColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          if (hasRating)
            Row(
              mainAxisAlignment: currentLang == 'ar'
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                Text(
                  ratingText,
                  style: TextStyle(
                    color: orangeColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.star_rounded, color: orangeColor, size: 16),
              ],
            )
          else
            Text(
              tr('no_rating', currentLang),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: available
                  ? greenColor.withOpacity(0.15)
                  : redColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              available
                  ? tr('available', currentLang)
                  : tr('not_available', currentLang),
              style: TextStyle(
                color: available ? greenColor : Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget buildHeaderCard() {
  final displayName =
      salonData['name']?.toString().trim().isNotEmpty == true
          ? salonData['name'].toString().trim()
          : tr('salon_name', currentLang);

  final rating =
      salonData['rating']?.toString().trim().isNotEmpty == true
          ? salonData['rating'].toString().trim()
          : '0.0';

  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 0,
      vertical: 0,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${getSalonPrefix(displayName)} $displayName',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 33,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tr('premium_experience', currentLang),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: subTextColor,
            fontSize: 17,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.24),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rating,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.star_rounded,
                    color: orangeColor,
                    size: 16,
                  ),
                ],
              ),
            ),

            if (!widget.fromAdminPreview &&
                !isGuest &&
                myRole == 'customer') ...[
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'التقييم هيتفتح بعد ما الصالون يضغط تم',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.star_rounded),
                label: const Text('قيّم'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 16),

        if (!widget.fromAdminPreview)
          SizedBox(
            width: 300,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingPage(
                      salonId: widget.salonId,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.event_available_rounded,
              ),
              label: Text(
                tr('book_now', currentLang),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: greenColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

        
          const SizedBox(height: 10),
          SizedBox(
            width: 300,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OffersPage(
                      salonId: widget.salonId,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.local_offer_rounded,
              ),
              label: Text(
                tr('offers', currentLang),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: orangeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

        if (isGuest && !widget.fromAdminPreview) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: orangeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: orangeColor.withOpacity(0.35),
              ),
            ),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    tr('register_now', currentLang),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr(
                      'register_and_get_discount_points',
                      currentLang,
                    ),
                    textAlign: currentLang == 'ar'
                        ? TextAlign.right
                        : TextAlign.left,
                    style: TextStyle(
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

Widget buildCategoryExpansion(
  String title,
  List<Map<String, dynamic>> categoryServices, {
  String? subtitle,
}) {
  return Align(
    alignment: currentLang == 'ar'
        ? Alignment.centerRight
        : Alignment.centerLeft,
    child: SizedBox(
      width: 240,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: fieldColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: 1.3,
            ),
          ),
          child: ExpansionTile(
            iconColor: orangeColor,
            collapsedIconColor: Colors.white70,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              10,
              0,
              10,
              10,
            ),
            title: Text(
              title,
              textAlign:
                  currentLang == 'ar'
                      ? TextAlign.right
                      : TextAlign.left,
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              subtitle ??
                  (categoryServices.isEmpty
                      ? tr('no_services', currentLang)
                      : '${categoryServices.length} ${tr('service', currentLang)}'),
              textAlign:
                  currentLang == 'ar'
                      ? TextAlign.right
                      : TextAlign.left,
              style: TextStyle(
                color: subTextColor,
                fontSize: 12,
              ),
            ),
            children: categoryServices.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        tr('no_services_in_category', currentLang),
                        textAlign: currentLang == 'ar'
                            ? TextAlign.right
                            : TextAlign.left,
                        style: TextStyle(
                          color: subTextColor,
                        ),
                      ),
                    ),
                  ]
                : categoryServices.map(buildServiceCard).toList(),
          ),
        ),
      ),
    ),
  );
}

Widget buildServicesSection() {
  if (services.isEmpty) {
    return Text(
      tr('no_services', currentLang),
      textAlign:
          currentLang == 'ar' ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        color: subTextColor,
      ),
    );
  }

  return Container(
    decoration: const BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: Colors.blue,
          width: 1,
        ),
      ),
    ),
    child: Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        iconColor: orangeColor,
        collapsedIconColor: Colors.white70,
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,

        title: Text(
          tr('services', currentLang),
          textAlign:
              currentLang == 'ar' ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            color: textColor,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Text(
          '${services.length} ${tr('service', currentLang)}',
          textAlign:
              currentLang == 'ar' ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            color: subTextColor,
            fontSize: 13,
          ),
        ),

        children: services.map(buildServiceCard).toList(),
      ),
    ),
  );
}

  Widget buildTrackQueueButton() {
    final bool isSalonView = widget.fromAdminPreview || myRole == 'salon';

    final String label = isSalonView
        ? tr('track_queue_system', currentLang)
        : (myUserId.isNotEmpty && !isGuest)
            ? tr('track_queue_now', currentLang)
            : tr('track_queue', currentLang);

    final bool compact = isSalonView;

    return Align(
      alignment: Alignment.center,
      child: SizedBox(
     width: 260,
        child: ElevatedButton.icon(
          onPressed: () {
            if (isSalonView) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrackQueuePage(
                    salonId: widget.salonId,
                    userId: '',
                  ),
                ),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TrackQueuePage(
                  salonId: widget.salonId,
                  userId: (myUserId.isEmpty || isGuest) ? '' : myUserId,
                ),
              ),
            );
          },
          icon: const Icon(Icons.access_time_rounded),
          label: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: compact ? 13 : 15,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: blueColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
  vertical: 10,
  horizontal: 16,
),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBody() {
    return RefreshIndicator(
      onRefresh: () async {
        await loadPageData();
        await loadMyProfile();
      },
      color: greenColor,
      child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [

buildHeaderCard(),
const SizedBox(height: 18),


const SizedBox(height: 18),

buildTrackQueueButton(),

const SizedBox(height: 22),
          buildServicesSection(),
          const SizedBox(height: 22),
          buildSectionTitle(
            tr('barbers', currentLang),
            subtitle: tr('team_available', currentLang),
          ),
          const SizedBox(height: 12),
          if (barbers.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.78),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Text(
                tr('no_barbers', currentLang),
                textAlign: TextAlign.center,
                style: TextStyle(color: subTextColor),
              ),
            )
          else
            SizedBox(
              height: 198,
              child: ListView(
                scrollDirection: Axis.horizontal,
                reverse: currentLang == 'ar',
                children: barbers.map(buildBarberCard).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildBackgroundLayer() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            backgroundImagePath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.38),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.18),
                  Colors.black.withOpacity(0.10),
                  const Color(0xFF07111F).withOpacity(0.86),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopProfileButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                ),
              ),
              child: Icon(
                icon,
                color: textColor,
                size: 17,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showCustomerProfile = !widget.fromAdminPreview && !isGuest;

    return Directionality(
      textDirection:
          currentLang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leading: widget.fromAdminPreview
              ? IconButton(
                  icon: Icon(Icons.arrow_back, color: textColor),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )
              : null,
          leadingWidth: widget.fromAdminPreview ? 56 : 0,
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const SizedBox.shrink(),
          actions: widget.fromAdminPreview
              ? [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _buildTopProfileButton(
                      icon: Icons.translate_rounded,
                      label: currentLang == 'ar' ? 'EN' : 'AR',
                      onTap: _toggleLanguage,
                    ),
                  ),
                ]
              : [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildTopProfileButton(
                      icon: Icons.storefront_rounded,
                      label: tr('salon', currentLang),
                      onTap: showSalonInfo,
                    ),
                  ),
                  if (showCustomerProfile)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildTopProfileButton(
                        icon: Icons.person_rounded,
                        label: tr('profile', currentLang),
                        onTap: showMyAccount,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildTopProfileButton(
                      icon: Icons.logout_rounded,
                      label: tr('logout', currentLang),
                      onTap: logout,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _buildTopProfileButton(
                      icon: Icons.translate_rounded,
                      label: currentLang == 'ar' ? 'EN' : 'AR',
                      onTap: _toggleLanguage,
                    ),
                  ),
                ],
        ),
        body: Stack(
          children: [
            buildBackgroundLayer(),
            if (loading)
              Center(
                child: CircularProgressIndicator(color: greenColor),
              )
            else if (errorText.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      errorText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
            else
              SafeArea(
                child: buildBody(),
              ),
          ],
        ),
      ),
    );
  }
}