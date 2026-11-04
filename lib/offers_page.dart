import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'app_translations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OffersPage extends StatefulWidget {
  final String salonId;

  const OffersPage({
    super.key,
    required this.salonId,
  });

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  final DatabaseReference rootRef = FirebaseDatabase.instance.ref();

  String currentLang = 'ar';
  bool loading = true;
  String errorText = '';

  Map<String, dynamic> services = {};
  List<Map<String, dynamic>> offers = [];

  final Color bgColor = const Color(0xFF07111F);
  final Color cardColor = const Color(0xFF101B2D);
  final Color borderColor = const Color(0xFF304763);
  final Color greenColor = const Color(0xFF22C55E);
  final Color orangeColor = const Color(0xFFF59E0B);
  final Color textColor = Colors.white;
  final Color subTextColor = const Color(0xFFC4D0E0);

  String tr(String key) => appTexts[currentLang]?[key] ??
      appTexts['ar']?[key] ??
      key;

  @override
  void initState() {
    super.initState();
    loadOffers();
  }

  int toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> loadOffers() async {
    if (mounted) {
      setState(() {
        loading = true;
        errorText = '';
      });
    }

    try {
      final prefs = await SharedPreferencesHelper.getLanguage();
      final salonSnapshot =
          await rootRef.child('salons').child(widget.salonId).get();

      if (!salonSnapshot.exists || salonSnapshot.value == null) {
        throw Exception(tr('salon_not_found'));
      }

      final salon = Map<dynamic, dynamic>.from(
        salonSnapshot.value as Map,
      );

      final loadedServices = <String, dynamic>{};
      final rawServices = salon['services'];

      if (rawServices is Map) {
        rawServices.forEach((key, value) {
          if (value is Map) {
            loadedServices[key.toString()] =
                Map<String, dynamic>.from(value);
          }
        });
      }

      final loadedOffers = <Map<String, dynamic>>[];
      final rawOffers = salon['offers'];

      if (rawOffers is Map) {
        rawOffers.forEach((key, value) {
          if (value is Map) {
            loadedOffers.add({
              'id': key.toString(),
              ...Map<String, dynamic>.from(value),
            });
          }
        });
      }

      if (!mounted) return;

      setState(() {
        currentLang = prefs;
        services = loadedServices;
        offers = loadedOffers;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorText = tr('error');
        loading = false;
      });
    }
  }

  bool isOfferAvailable(Map<String, dynamic> offer) {
    if (offer['active'] != true) return false;

    final now = DateTime.now();
    final days = offer['days'];

    if (days is! List || days.isEmpty) return false;

    final validToday = days.any(
      (day) => toInt(day) == now.weekday,
    );

    if (!validToday) return false;

    final startHour = toInt(offer['startHour']);
    final startMinute = toInt(offer['startMinute']);
    final endHour = toInt(offer['endHour']);
    final endMinute = toInt(offer['endMinute']);

    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    return currentMinutes >= startMinutes &&
        currentMinutes < endMinutes;
  }

  String serviceName(String id) {
    final service = services[id];

    if (service is! Map) return '';

    if (currentLang == 'ar') {
      return (service['nameAr'] ?? service['name'] ?? '').toString();
    }

    return (service['nameEn'] ?? service['name'] ?? '').toString();
  }

  List<String> getOfferServiceNames(Map<String, dynamic> offer) {
    final result = <String>[];
    final ids = offer['serviceIds'];

    if (ids is List) {
      for (final id in ids) {
        final name = serviceName(id.toString());
        if (name.isNotEmpty) result.add(name);
      }
    }

    return result;
  }

  String offerTitle(Map<String, dynamic> offer) {
    final value = currentLang == 'ar'
        ? offer['titleAr']
        : offer['titleEn'];

    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }

    return currentLang == 'ar' ? 'عرض خاص' : 'Special Offer';
  }

  String formatTime(dynamic hour, dynamic minute) {
    final h = toInt(hour).toString().padLeft(2, '0');
    final m = toInt(minute).toString().padLeft(2, '0');
    return '$h:$m';
  }

  String daysText(Map<String, dynamic> offer) {
    final days = offer['days'];

    if (days is! List) return '';

    const arDays = [
      '',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];

    const enDays = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final names = days
        .map((day) => toInt(day))
        .where((day) => day >= 1 && day <= 7)
        .map((day) =>
            currentLang == 'ar' ? arDays[day] : enDays[day])
        .toList();

    return names.join('، ');
  }

  Widget buildOfferCard(Map<String, dynamic> offer) {
    final names = getOfferServiceNames(offer);
    final price = toInt(offer['price']);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_offer_rounded,
                color: Color(0xFFF59E0B),
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  offerTitle(offer),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            currentLang == 'ar' ? 'الخدمات داخل العرض' : 'Included services',
            style: TextStyle(
              color: subTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (names.isEmpty)
            Text(
              currentLang == 'ar'
                  ? 'تفاصيل الخدمات غير متاحة'
                  : 'Service details are unavailable',
              style: TextStyle(color: subTextColor),
            )
          else
            ...names.map(
              (name) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 17,
                      color: greenColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            '${currentLang == 'ar' ? 'سعر العرض' : 'Offer price'}: $price ${currentLang == 'ar' ? 'جنيه' : 'EGP'}',
            style: TextStyle(
              color: greenColor,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${currentLang == 'ar' ? 'الأيام' : 'Days'}: ${daysText(offer)}',
            style: TextStyle(color: subTextColor),
          ),
          const SizedBox(height: 5),
          Text(
            '${currentLang == 'ar' ? 'الوقت' : 'Time'}: ${formatTime(offer['startHour'], offer['startMinute'])} - ${formatTime(offer['endHour'], offer['endMinute'])}',
            style: TextStyle(color: subTextColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          currentLang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          centerTitle: true,
          title: Text(
            currentLang == 'ar' ? 'عروض الصالون' : 'Salon Offers',
          ),
        ),
        body: RefreshIndicator(
          onRefresh: loadOffers,
          color: greenColor,
          child: loading
              ? ListView(
                  children: const [
                    SizedBox(height: 180),
                    Center(child: CircularProgressIndicator()),
                  ],
                )
              : errorText.isNotEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 100),
                        Text(
                          errorText,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textColor),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: ElevatedButton(
                            onPressed: loadOffers,
                            child: Text(
                              currentLang == 'ar'
                                  ? 'إعادة المحاولة'
                                  : 'Try again',
                            ),
                          ),
                        ),
                      ],
                    )
                  : Builder(
                      builder: (context) {
                        final availableOffers = offers
                            .where(isOfferAvailable)
                            .toList();

                        if (availableOffers.isEmpty) {
                          return ListView(
                            padding: const EdgeInsets.all(24),
                            children: [
                              const SizedBox(height: 120),
                              Icon(
                                Icons.local_offer_outlined,
                                size: 64,
                                color: orangeColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                currentLang == 'ar'
                                    ? 'لا توجد عروض متاحة في الوقت الحالي'
                                    : 'No offers available at the moment',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        }

                        return ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            ...availableOffers.map(buildOfferCard),
                          ],
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

class SharedPreferencesHelper {
  static Future<String> getLanguage() async {
    final snapshot = await SharedPreferencesHelperStorage.getLanguage();
    return snapshot;
  }
}

class SharedPreferencesHelperStorage {
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lang') ?? 'ar';
  }
}