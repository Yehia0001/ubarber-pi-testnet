import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services_page.dart';
import 'app_translations.dart';

class SalonsPage extends StatefulWidget {
  const SalonsPage({super.key});

  @override
  State<SalonsPage> createState() => _SalonsPageState();
}

class _SalonsPageState extends State<SalonsPage> {
  final DatabaseReference rootRef = FirebaseDatabase.instance.ref();

  final Color bgColor = const Color(0xFF07111F);
  final Color cardColor = const Color(0xDD101B2D);
  final Color fieldColor = const Color(0xFF13233A);
  final Color borderColor = const Color(0xFF304763);
  final Color textColor = Colors.white;
  final Color subTextColor = const Color(0xFFC4D0E0);
  final Color greenColor = const Color(0xFF22C55E);
  final Color orangeColor = const Color(0xFFF59E0B);

  bool loading = true;
  String currentLang = 'ar';
  List<Map<String, dynamic>> salons = [];

  @override
  void initState() {
    super.initState();
    loadLang();
    loadSalons();
  }

  String t(String key) => tr(key, currentLang);

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

  Future<void> loadSalons() async {
    try {
      final snapshot = await rootRef.child('salons').get();

      if (!snapshot.exists || snapshot.value == null) {
        if (!mounted) return;
        setState(() {
          salons = [];
          loading = false;
        });
        return;
      }

      final raw = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final loaded = <Map<String, dynamic>>[];

      raw.forEach((key, value) {
        if (value is Map) {
          final salon = Map<dynamic, dynamic>.from(value);

          loaded.add({
            'id': key.toString(),
            'name': salon['name']?.toString() ?? t('salon'),
            'location': salon['location']?.toString() ??
                salon['address']?.toString() ??
                '',
            'phone': salon['phone']?.toString() ?? '',
            'rating': salon['rating'] is num
                ? (salon['rating'] as num).toDouble()
                : double.tryParse(salon['rating']?.toString() ?? '0') ?? 0.0,
            'profileImage': salon['profileImage']?.toString() ?? '',
          });
        }
      });

      loaded.sort(
        (a, b) => a['name'].toString().compareTo(b['name'].toString()),
      );

      if (!mounted) return;
      setState(() {
        salons = loaded;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        salons = [];
        loading = false;
      });
    }
  }

  Widget buildSalonCard(Map<String, dynamic> salon) {
    final String salonId = salon['id'].toString();
    final String salonName = salon['name'].toString();
    final String location = salon['location']?.toString() ?? '';
    final double rating = salon['rating'] is double
        ? salon['rating'] as double
        : double.tryParse(salon['rating'].toString()) ?? 0.0;

    final isArabic = currentLang == 'ar';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ServicesPage(salonId: salonId),
              ),
            );
          },
          child: Ink(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor.withOpacity(0.85)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: fieldColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Icon(
                      Icons.storefront_rounded,
                      color: greenColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          salonName,
                          textAlign: isArabic ? TextAlign.right : TextAlign.left,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          location.isEmpty ? t('no_address') : location,
                          textAlign: isArabic ? TextAlign.right : TextAlign.left,
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Row(
                          mainAxisAlignment:
                              isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.star_rounded,
                              color: orangeColor,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    isArabic
                        ? Icons.arrow_back_ios_new_rounded
                        : Icons.arrow_forward_ios_rounded,
                    color: subTextColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.store_mall_directory_outlined,
                color: subTextColor,
                size: 58,
              ),
              const SizedBox(height: 16),
              Text(
                t('no_salons_available_now'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t('try_again_later'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
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
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          foregroundColor: textColor,
          title: Text(
            t('choose_salon'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: toggleLang,
              icon: const Icon(Icons.translate_rounded),
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      bgColor,
                      const Color(0xFF0B1730),
                      bgColor,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            if (loading)
              Center(
                child: CircularProgressIndicator(color: greenColor),
              )
            else if (salons.isEmpty)
              buildEmptyState()
            else
              RefreshIndicator(
                onRefresh: loadSalons,
                color: greenColor,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      t('choose_salon_for_you'),
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t('each_salon_has_own_services'),
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...salons.map(buildSalonCard),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}