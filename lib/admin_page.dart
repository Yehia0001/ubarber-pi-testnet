import 'register_page.dart';
import 'services/salon_notification_service.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'manage_offers_page.dart';

import 'booking_page.dart';
import 'queue_page.dart';
import 'services_page.dart';
import 'app_translations.dart';
import 'admin_notifications_page.dart';

class AdminPage extends StatefulWidget {
  final String salonId;

  const AdminPage({super.key, required this.salonId});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {

bool showQrSection = false;
bool hasUnreadNotifications = false;
StreamSubscription<DatabaseEvent>? bookingsSubscription;
final AudioPlayer notificationPlayer = AudioPlayer();

String getSalonLink() {
  return 'https://yehia0001.github.io/qr-ubarber-site/?salonId=${widget.salonId}';
}

String getSalonQr() {
  final link = getSalonLink();
  return 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${Uri.encodeComponent(link)}';
}

  final DatabaseReference rootRef = FirebaseDatabase.instance.ref();

  late final DatabaseReference salonRef;
  late final DatabaseReference settingsRef;
  late final DatabaseReference servicesRef;
  late final DatabaseReference barbersRef;
  late final DatabaseReference chairsRef;
  late final DatabaseReference categoriesRef;
  late final DatabaseReference queueRef;
  late final DatabaseReference bookingsRef;

  final TextEditingController discountController = TextEditingController();

  final TextEditingController serviceNameController = TextEditingController();
  final TextEditingController serviceNameEnController = TextEditingController();
  final TextEditingController servicePriceController = TextEditingController();
  final TextEditingController serviceDurationController = TextEditingController();

  final TextEditingController barberNameController = TextEditingController();
  final TextEditingController barberNameEnController = TextEditingController();
  final TextEditingController chairNameController = TextEditingController();
  final chairNameEnController = TextEditingController();
  final TextEditingController categoryNameController = TextEditingController();
  final TextEditingController categoryNameEnController = TextEditingController();
  

  bool discountEnabled = false;
  bool pointsEnabled = false;

  int openHour = 10;
  int closeHour = 22;

  String salonName = 'ubarber';
  String currentLang = 'ar';

  String barberType = 'professional';
  bool barberActive = true;
  bool chairActive = true;
  bool categoryActive = true;

  String? editingServiceId;
  String? editingBarberId;
  String? editingChairId;
  String? editingCategoryId;

  final Color bgColor = const Color(0xFF07111F);
  final Color cardColor = const Color(0xFF101B2D);
  final Color fieldColor = const Color(0xFF13233A);
  final Color borderColor = const Color(0xFF304763);
  final Color greenColor = const Color(0xFF22C55E);
  final Color redColor = const Color(0xFFEF4444);
  final Color blueColor = const Color(0xFF3B82F6);
  final Color orangeColor = const Color(0xFFF59E0B);
  final Color purpleColor = const Color(0xFF8B5CF6);
  final Color textColor = Colors.white;
  final Color subTextColor = const Color(0xFFC4D0E0);

  String t(String key) => tr(key, currentLang);

  @override
  void initState() {
    super.initState();

    salonRef = rootRef.child('salons').child(widget.salonId);
    settingsRef = salonRef.child('settings');
    servicesRef = salonRef.child('services');
    barbersRef = salonRef.child('barbers');
    chairsRef = salonRef.child('chairs');
    categoriesRef = salonRef.child('categories');
    queueRef = rootRef.child('queue');
    bookingsRef = salonRef.child('bookings');
    final listenFrom = DateTime.now().millisecondsSinceEpoch;

bookingsSubscription = bookingsRef
    .orderByChild('createdAt')
    .startAt(listenFrom + 1)
    .onChildAdded
    .listen((_) {
  if (!mounted) return;

  setState(() {
    hasUnreadNotifications = true;
  });

unawaited(
  notificationPlayer.play(
    AssetSource('sounds/notification.mp3'),
  ),
);
});

    _loadLang();
    loadSalonInfo();
    loadSettings();
  }

  @override
  void dispose() {
    discountController.dispose();
    serviceNameController.dispose();
    servicePriceController.dispose();
    serviceDurationController.dispose();
    barberNameController.dispose();
    chairNameController.dispose();
    categoryNameController.dispose();
    bookingsSubscription?.cancel();
    unawaited(notificationPlayer.dispose());
    super.dispose();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      currentLang = prefs.getString('lang') ?? 'ar';
    });
  }

Future<void> _toggleLang() async {
  final prefs = await SharedPreferences.getInstance();
  final newLang = currentLang == 'ar' ? 'en' : 'ar';

  await prefs.setString('lang', newLang);

  if (!mounted) return;

  setState(() {
    currentLang = newLang;
  });
}

Future<void> _logout() async {
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
  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  void showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> loadSalonInfo() async {
    final snapshot = await salonRef.get();
    if (!snapshot.exists || snapshot.value == null) return;

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    if (!mounted) return;
    setState(() {
      salonName = data['name']?.toString().trim().isNotEmpty == true
          ? data['name'].toString()
          : 'ubarber';
    });
  }

  Future<void> loadSettings() async {
    final snapshot = await settingsRef.get();

    if (!snapshot.exists || snapshot.value == null) {
      await settingsRef.set({
        'enabled': false,
        'discount': 0,
        'pointsEnabled': false,
        'openHour': 10,
        'closeHour': 22,
      });

      if (!mounted) return;
      setState(() {
        discountEnabled = false;
        pointsEnabled = false;
        discountController.text = '0';
        openHour = 10;
        closeHour = 22;
      });
      return;
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    if (!mounted) return;
    setState(() {
      discountEnabled = data['enabled'] == true;
      pointsEnabled = data['pointsEnabled'] == true;
      discountController.text = _toInt(data['discount']).toString();
      openHour = _toInt(data['openHour']);
      closeHour = _toInt(data['closeHour']);

  if (openHour == 0 && data['openHour'] == null) openHour = 10;
if (closeHour == 0 && data['closeHour'] == null) closeHour = 22;
    });
  }

  Future<void> saveDiscountSettings() async {
    final enteredDiscount = _toInt(discountController.text);

    await settingsRef.update({
      'enabled': discountEnabled,
      'discount': discountEnabled ? enteredDiscount : 0,
      'pointsEnabled': pointsEnabled,
      'openHour': openHour,
      'closeHour': closeHour,
    });

    if (!mounted) return;

    setState(() {
      if (!discountEnabled) {
        discountController.text = '0';
      }
    });

    showMessage(t('settings_saved'));
  }

  Future<void> saveService() async {
   final nameAr = serviceNameController.text.trim();
   final nameEn = serviceNameEnController.text.trim();
    final price = _toInt(servicePriceController.text);
    final duration = _toInt(serviceDurationController.text);

   if (nameAr.isEmpty) {
      showMessage(t('enter_service_name'));
      return;
    }

    if (price <= 0) {
      showMessage(t('enter_valid_price'));
      return;
    }

    if (duration <= 0) {
      showMessage(t('enter_valid_duration'));
    
    }
    final data = {
     'name': nameAr,
     'nameAr': nameAr,
     'nameEn': nameEn,
      'price': price,
     'duration': duration,
      'updatedAt': ServerValue.timestamp,
    };

    if (editingServiceId == null) {
      final newRef = servicesRef.push();
      await newRef.set({
        ...data,
        'id': newRef.key,
        'createdAt': ServerValue.timestamp,
      });
      showMessage(t('service_added'));
    } else {
      await servicesRef.child(editingServiceId!).update(data);
      showMessage(t('service_updated'));
    }

    clearServiceForm();
  }

  void clearServiceForm() {
    serviceNameController.clear();
    serviceNameEnController.clear();
    servicePriceController.clear();
    serviceDurationController.clear();

    setState(() {
      editingServiceId = null;
    });
  }

  void editService(String id, Map<String, dynamic> service) {
  serviceNameController.text =
    (service['nameAr'] ?? service['name'] ?? '').toString();

serviceNameEnController.text =
    (service['nameEn'] ?? '').toString();
    servicePriceController.text = _toInt(service['price']).toString();
    serviceDurationController.text = _toInt(service['duration']).toString();

    setState(() {
      editingServiceId = id;
    });
  }

  Future<void> deleteService(String id) async {
    await servicesRef.child(id).remove();

    final categoriesSnapshot = await categoriesRef.get();
    if (categoriesSnapshot.exists && categoriesSnapshot.value != null) {
      final rawCategories =
          Map<dynamic, dynamic>.from(categoriesSnapshot.value as Map);

      for (final entry in rawCategories.entries) {
        if (entry.value is Map) {
          final categoryMap = Map<dynamic, dynamic>.from(entry.value);
          if (categoryMap['services'] is Map) {
            final servicesMap =
                Map<dynamic, dynamic>.from(categoryMap['services'] as Map);
            if (servicesMap.containsKey(id)) {
              await categoriesRef
                  .child(entry.key.toString())
                  .child('services')
                  .child(id)
                  .remove();
            }
          }
        }
      }
    }

    if (editingServiceId == id) clearServiceForm();
    showMessage(t('service_deleted'));
  }

  Future<void> saveBarber() async {
   final nameAr = barberNameController.text.trim();
final nameEn = barberNameEnController.text.trim();

   if (nameAr.isEmpty) {
 showMessage(t('enter_barber_name_ar'));
  return;
}

  final data = {
  'name': nameAr, // مهم عشان القديم
  'nameAr': nameAr,
  'nameEn': nameEn,
  'type': barberType,
  'active': barberActive,
  'updatedAt': ServerValue.timestamp,
};

    if (editingBarberId == null) {
      final newRef = barbersRef.push();
      await newRef.set({
        ...data,
        'id': newRef.key,
        'createdAt': ServerValue.timestamp,
      });
      showMessage(t('barber_added'));
    } else {
      await barbersRef.child(editingBarberId!).update(data);
      showMessage(t('barber_updated'));
    }

    clearBarberForm();
  }

  void clearBarberForm() {
    barberNameController.clear();
    barberNameEnController.clear();

    setState(() {
      barberType = 'professional';
      barberActive = true;
      editingBarberId = null;
    });
  }

  void editBarber(String id, Map<String, dynamic> barber) {
  barberNameController.text =
    barber['nameAr']?.toString() ?? barber['name']?.toString() ?? '';
   barberNameEnController.text = barber['nameEn']?.toString() ?? '';

    setState(() {
      editingBarberId = id;
      barberType = barber['type']?.toString() ?? 'professional';
      barberActive = barber['active'] == true;
    });
  }

  Future<void> deleteBarber(String id) async {
    await barbersRef.child(id).remove();
    if (editingBarberId == id) clearBarberForm();
    showMessage(t('barber_deleted'));
  }

  Future<void> saveChair() async {
   final nameAr = chairNameController.text.trim();
final nameEn = chairNameEnController.text.trim();

if (nameAr.isEmpty) {
  showMessage(t('enter_chair_name'));
  return;
}

final data = {
  'nameAr': nameAr,
  'nameEn': nameEn,
  'name': nameAr,
  'active': chairActive,
  'updatedAt': ServerValue.timestamp,
};

    if (editingChairId == null) {
      final newRef = chairsRef.push();
      await newRef.set({
        ...data,
        'id': newRef.key,
        'createdAt': ServerValue.timestamp,
      });
      showMessage(t('chair_added'));
    } else {
      await chairsRef.child(editingChairId!).update(data);
      showMessage(t('chair_updated'));
    }

    clearChairForm();
  }

  void clearChairForm() {
    chairNameController.clear();
    chairNameEnController.clear();

    setState(() {
      chairActive = true;
      editingChairId = null;
    });
  }

  void editChair(String id, Map<String, dynamic> chair) {
   chairNameController.text =
    (chair['nameAr'] ?? chair['nameEn'] ??
     chair['name'] ?? '').toString();

chairNameEnController.text =
    (chair['nameEn'] ?? '').toString();

    setState(() {
      editingChairId = id;
      chairActive = chair['active'] != false;
    });
  }

  Future<void> deleteChair(String id) async {
    await chairsRef.child(id).remove();
    if (editingChairId == id) clearChairForm();
    showMessage(t('chair_deleted'));
  }

  Future<void> saveCategory() async {
   final nameAr = categoryNameController.text.trim();
final nameEn = categoryNameEnController.text.trim();

 if (nameAr.isEmpty) {
  showMessage(t('enter_category_name'));
  return;
}

  final data = {
  'nameAr': nameAr,
  'nameEn': nameEn,
  'name': nameAr,
  'active': categoryActive,
  'updatedAt': ServerValue.timestamp,
};

    if (editingCategoryId == null) {
      final newRef = categoriesRef.push();
      await newRef.set({
        ...data,
        'id': newRef.key,
        'services': {},
        'createdAt': ServerValue.timestamp,
      });
      showMessage(t('category_added'));
    } else {
      await categoriesRef.child(editingCategoryId!).update(data);
      showMessage(t('category_updated'));
    }

    clearCategoryForm();
  }

  void clearCategoryForm() {
    categoryNameController.clear();
    categoryNameEnController.clear();

    setState(() {
      categoryActive = true;
      editingCategoryId = null;
    });
  }

  void editCategory(String id, Map<String, dynamic> category) {
  categoryNameController.text =
    (category['nameAr'] ?? category['name'] ?? '').toString();

categoryNameEnController.text =
    (category['nameEn'] ?? '').toString();

    setState(() {
      editingCategoryId = id;
      categoryActive = category['active'] != false;
    });
  }

  Future<void> deleteCategory(String id) async {
    await categoriesRef.child(id).remove();
    if (editingCategoryId == id) clearCategoryForm();
    showMessage(t('category_deleted'));
  }

  Future<List<Map<String, dynamic>>> getAllServicesList() async {
    final snapshot = await servicesRef.get();

    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final raw = Map<dynamic, dynamic>.from(snapshot.value as Map);
    final items = raw.entries.map((e) {
      final map = Map<String, dynamic>.from(e.value);
      return {
        'id': e.key.toString(),
        ...map,
      };
    }).toList();

    items.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
    return items;
  }



Future<void> openAddServicesToCategorySheet(
  String categoryId,
  String categoryName,
) async {
  final TextEditingController nameArController =
      TextEditingController();
  final TextEditingController nameEnController =
      TextEditingController();
  final TextEditingController priceController =
      TextEditingController();
  final TextEditingController durationController =
      TextEditingController();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),
    builder: (context) {
      return Directionality(
        textDirection:
            currentLang == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 20,
              bottom:
                  MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${t('add_service')} - $categoryName',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    t('category_service_hint'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: nameArController,
                    style: TextStyle(color: textColor),
                    decoration:
                        fieldDecoration(t('service_name_ar')),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: nameEnController,
                    style: TextStyle(color: textColor),
                    decoration:
                        fieldDecoration(t('service_name_en')),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textColor),
                          decoration:
                              fieldDecoration(t('price_egp')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: durationController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textColor),
                          decoration:
                              fieldDecoration(
                            t('duration_minute'),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () async {
                      final nameAr =
                          nameArController.text.trim();
                      final nameEn =
                          nameEnController.text.trim();

                      final price =
                          _toInt(priceController.text);

                      final duration =
                          _toInt(durationController.text);

                      if (nameAr.isEmpty) {
                        showMessage(
                          t('enter_service_name'),
                        );
                        return;
                      }

                      if (price <= 0) {
                        showMessage(
                          t('enter_valid_price'),
                        );
                        return;
                      }

                      if (duration <= 0) {
                        showMessage(
                          t('enter_valid_duration'),
                        );
                        return;
                      }

                      try {
                        // إنشاء الخدمة في قائمة الخدمات الرئيسية
                        final serviceRef = servicesRef.push();

                        final serviceId = serviceRef.key;

                        if (serviceId == null) {
                          showMessage(
                            t('error'),
                          );
                          return;
                        }

                        // حفظ الخدمة كاملة في services
                        await serviceRef.set({
                          'id': serviceId,
                          'name': nameAr,
                          'nameAr': nameAr,
                          'nameEn': nameEn,
                          'price': price,
                          'duration': duration,
                          'categoryId': categoryId,
                          'active': true,
                          'createdAt': ServerValue.timestamp,
                          'updatedAt': ServerValue.timestamp,
                        });

                        // ربط الخدمة بالقسم
                        await categoriesRef
                            .child(categoryId)
                            .child('services')
                            .child(serviceId)
                            .set(true);

                        if (!mounted) return;

                        Navigator.pop(context);

                        showMessage(
                          t('service_added'),
                        );
                      } catch (e) {
                        showMessage(
                          '${t('error')}: $e',
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greenColor,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      t('add_service'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  nameArController.dispose();
  nameEnController.dispose();
  priceController.dispose();
  durationController.dispose();
}
 Future<void> removeServiceFromCategory(
    String categoryId,
    String serviceId,
  ) async {
    await categoriesRef
        .child(categoryId)
        .child('services')
        .child(serviceId)
        .remove();

    showMessage(t('service_removed_from_category'));
  }

  InputDecoration fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: subTextColor.withOpacity(0.8)),
      filled: true,
      fillColor: fieldColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: greenColor, width: 1.3),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor.withOpacity(0.9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget sectionTitle(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: textColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget statCard(String title, String value, {Color? color}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color ?? textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: subTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget smallActionButton({
    required String text,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget pageHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF12233D),
            const Color(0xFF0F1D33),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor.withOpacity(0.9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            salonName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            t('admin_dashboard'),
            style: TextStyle(
              color: textColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t('admin_dashboard_subtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subTextColor,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget entityItemCard({
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: content,
    );
  }

  Widget formActionRow({
    required String saveText,
    required VoidCallback onSave,
    required VoidCallback onClear,
    Color? saveColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: saveColor ?? greenColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              saveText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: onClear,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4B5563),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              t('clear'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildCategoryServicesList(
    String categoryId,
    Map<dynamic, dynamic> category,
  ) {
    final servicesMap = category['services'] is Map
        ? Map<dynamic, dynamic>.from(category['services'] as Map)
        : <dynamic, dynamic>{};

    return FutureBuilder<DataSnapshot>(
      future: servicesRef.get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            !snapshot.data!.exists ||
            snapshot.data!.value == null) {
          return Text(
            t('no_linked_services'),
            style: TextStyle(color: subTextColor),
          );
        }

        final allServices =
            Map<dynamic, dynamic>.from(snapshot.data!.value as Map);
        final attachedServices = <Map<String, dynamic>>[];

        for (final serviceId in servicesMap.keys) {
          if (allServices.containsKey(serviceId)) {
            final serviceMap =
                Map<String, dynamic>.from(allServices[serviceId] as Map);
            attachedServices.add({
              'id': serviceId.toString(),
              ...serviceMap,
            });
          }
        }

        if (attachedServices.isEmpty) {
          return Text(
            t('no_linked_services'),
            style: TextStyle(color: subTextColor),
          );
        }

        attachedServices.sort(
          (a, b) => a['name'].toString().compareTo(b['name'].toString()),
        );

        return Column(
          children: attachedServices.map((service) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF18263B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  smallActionButton(
                    text: t('delete'),
                    onPressed: () => removeServiceFromCategory(
                      categoryId,
                      service['id'].toString(),
                    ),
                    color: redColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          service['name']?.toString() ?? '',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_toInt(service['price'])} ${t('egp')} - ${_toInt(service['duration'])} ${t('minute')}',
                          style: TextStyle(color: subTextColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
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
        elevation: 0,
        centerTitle: true,
        title: StreamBuilder<DatabaseEvent>(
          stream: salonRef.onValue,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              final data = Map<dynamic, dynamic>.from(
                snapshot.data!.snapshot.value as Map,
              );
              final name = data['name'] ?? t('unnamed');
              return Text(name.toString());
            }
            return const Text('...');
          },
        ),

        actions: [
          // 👇 زرار تغيير اللغة
       TextButton.icon(
  onPressed: _toggleLang,
  icon: const Icon(Icons.translate, color: Colors.white),
  label: Text(
    currentLang == 'ar' ? 'EN' : 'AR',
    style: const TextStyle(color: Colors.white),
  ),
),

TextButton.icon(
  onPressed: _logout,
  icon: const Icon(Icons.logout, color: Colors.white),
  label: Text(
    t('logout'),
    style: const TextStyle(color: Colors.white),
  ),
),

          // 👇 زرار الصفحة الرئيسية (بتاعك)
          IconButton(
            tooltip: t('view_main_page'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServicesPage(
                    salonId: widget.salonId,
                    fromAdminPreview: true,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.visibility_outlined),
          ),
          IconButton(
  tooltip: 'الإشعارات',
onPressed: () {
  setState(() {
    hasUnreadNotifications = false;
  });
  
  Navigator.push(
    context,
    MaterialPageRoute(
    builder: (_) => AdminNotificationsPage(
  salonId: widget.salonId,
),
    ),
  );
},
icon: Icon(
  hasUnreadNotifications
      ? Icons.notifications
      : Icons.notifications_none,
  color: hasUnreadNotifications ? Colors.amber : null,
),
),
        ],
      ),
        body: SafeArea(
          child: StreamBuilder<DatabaseEvent>(
            stream: queueRef.onValue,
            builder: (context, queueSnapshot) {
              List<Map<String, dynamic>> todayQueue = [];

              if (queueSnapshot.hasData &&
                  queueSnapshot.data!.snapshot.value != null) {
                final raw = queueSnapshot.data!.snapshot.value;
                if (raw is Map) {
                  final map = Map<dynamic, dynamic>.from(raw);

                  final now = DateTime.now();

                  todayQueue = map.entries.map((e) {
                    final item = Map<String, dynamic>.from(e.value);
                    item['firebaseKey'] = e.key.toString();
                    return item;
                  }).where((item) {
                    if (item['salonId']?.toString() != widget.salonId) {
                      return false;
                    }

                    final updatedAt = _toInt(item['updatedAt']);
                    final createdAt = _toInt(item['createdAt']);
                    final stamp = updatedAt != 0 ? updatedAt : createdAt;
                    if (stamp == 0) return false;

                    final date = DateTime.fromMillisecondsSinceEpoch(stamp);
                    return date.year == now.year &&
                        date.month == now.month &&
                        date.day == now.day;
                  }).toList();
                }
              }

              final doneToday = todayQueue
                  .where((item) => item['status']?.toString() == 'done')
                  .toList();
              final cancelledToday = todayQueue
                  .where((item) => item['status']?.toString() == 'cancelled')
                  .toList();
              final delayedToday = todayQueue
                  .where((item) => item['queueState']?.toString() == 'delayed')
                  .toList();

              final int totalBeforeDiscount = doneToday.fold(
                0,
                (sum, item) =>
                    sum +
                    _toInt(
                      item['subtotal'] == null
                          ? item['totalBeforeDiscount']
                          : item['subtotal'],
                    ),
              );

              final int totalDiscount = doneToday.fold(
                0,
                (sum, item) =>
                    sum +
                    _toInt(
                      item['discount'] == null
                          ? item['discountAmount']
                          : item['discount'],
                    ),
              );

              final int totalPaid = doneToday.fold(
                0,
                (sum, item) {
                  final paid = _toInt(item['paid']);
                  final finalTotal = _toInt(item['finalTotal']);
                  return sum + (paid > 0 ? paid : finalTotal);
                },
              );

              final Map<String, int> servicesCount = {};
              final Map<String, int> barbersCount = {};

              for (final item in doneToday) {
                final barberName = item['barber']?.toString() ?? '';
                if (barberName.isNotEmpty) {
                  barbersCount[barberName] =
                      (barbersCount[barberName] ?? 0) + 1;
                }

                final services = item['services'];
                if (services is List) {
                  for (final service in services) {
                    if (service is Map) {
                      final map = Map<String, dynamic>.from(service);
                      final serviceName = map['name']?.toString() ?? '';
                      if (serviceName.isNotEmpty) {
                        servicesCount[serviceName] =
                            (servicesCount[serviceName] ?? 0) + 1;
                      }
                    }
                  }
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    pageHeader(),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BookingPage(salonId: widget.salonId),
                                ),
                              );
                            },
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: Text(
                              t('back_to_booking'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: blueColor,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      QueuePage(salonId: widget.salonId),
                                ),
                              );
                            },
                            icon: const Icon(Icons.people_alt_outlined),
                            label: Text(
                              t('open_queue_system'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orangeColor,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                   const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ManageOffersPage(
                                salonId: widget.salonId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.local_offer_outlined),
                        label: Text(
                          currentLang == 'ar'
                              ? 'إدارة العروض'
                              : 'Manage Offers',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: greenColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    sectionCard(
                      child: Column(
                        children: [
                          sectionTitle(t('settings')),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Checkbox(
                                value: discountEnabled,
                                activeColor: greenColor,
                                onChanged: (value) {
                                  setState(() {
                                    discountEnabled = value ?? false;
                                  });
                                },
                              ),
                              Text(
                                t('enable_discount'),
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Expanded(
                                child: TextField(
                                  controller: discountController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: textColor),
                                  decoration:
                                      fieldDecoration(t('registered_discount_percent')),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Checkbox(
                                value: pointsEnabled,
                                activeColor: greenColor,
                                onChanged: (value) {
                                  setState(() {
                                    pointsEnabled = value ?? false;
                                  });
                                },
                              ),
                              Text(
                                t('enable_points'),
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            t('working_hours'),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: openHour,
                                  dropdownColor: fieldColor,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    labelText: t('opening_hour'),
                                    labelStyle:
                                        TextStyle(color: subTextColor),
                                    filled: true,
                                    fillColor: fieldColor,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide:
                                          BorderSide(color: borderColor),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: greenColor,
                                        width: 1.3,
                                      ),
                                    ),
                                  ),
                                  items: List.generate(
                                    24,
                                    (i) => DropdownMenuItem(
                                      value: i,
                                      child: Text(
                                        '$i:00',
                                        style: TextStyle(color: textColor),
                                      ),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      openHour = val!;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: closeHour,
                                  dropdownColor: fieldColor,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    labelText: t('closing_hour'),
                                    labelStyle:
                                        TextStyle(color: subTextColor),
                                    filled: true,
                                    fillColor: fieldColor,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide:
                                          BorderSide(color: borderColor),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: greenColor,
                                        width: 1.3,
                                      ),
                                    ),
                                  ),
                                  items: List.generate(
                                    24,
                                    (i) => DropdownMenuItem(
                                      value: i,
                                      child: Text(
                                        '$i:00',
                                        style: TextStyle(color: textColor),
                                      ),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      closeHour = val!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: saveDiscountSettings,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: greenColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                t('save_settings'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    sectionCard(
                      child: Column(
                        children: [
                          sectionTitle(t('categories')),
                          const SizedBox(height: 18),
                          TextField(
                            controller: categoryNameController,
                            style: TextStyle(color: textColor),
                            decoration: fieldDecoration(t('category_name')),
                          ),
                          TextField(
  controller: categoryNameEnController,
  style: TextStyle(color: textColor),
  decoration: fieldDecoration(t('category_name_en')),
),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Checkbox(
                                value: categoryActive,
                                activeColor: greenColor,
                                onChanged: (value) {
                                  setState(() {
                                    categoryActive = value ?? true;
                                  });
                                },
                              ),
                              Text(
                                t('active'),
                                style: TextStyle(color: textColor),
                              ),
                            ],
                          ),
                          formActionRow(
                            saveText: editingCategoryId == null
                                ? t('add_category')
                                : t('save_edit'),
                            onSave: saveCategory,
                            onClear: clearCategoryForm,
                            saveColor: purpleColor,
                          ),
                          const SizedBox(height: 16),
                          StreamBuilder<DatabaseEvent>(
                            stream: categoriesRef.onValue,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData ||
                                  snapshot.data!.snapshot.value == null) {
                                return Text(
                                  t('no_categories_yet'),
                                  style: TextStyle(color: subTextColor),
                                );
                              }

                              final raw = Map<dynamic, dynamic>.from(
                                snapshot.data!.snapshot.value as Map,
                              );

                              final items = raw.entries.map((e) {
                                return {
                                  'id': e.key.toString(),
                                  ...Map<String, dynamic>.from(e.value),
                                };
                              }).toList();

                              items.sort(
                                (a, b) => a['name']
                                    .toString()
                                    .compareTo(b['name'].toString()),
                              );

                              return Column(
                                children: items.map((category) {
                                  return entityItemCard(
                                    content: Column(
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            smallActionButton(
                                              text: t('edit'),
                                              onPressed: () => editCategory(
                                                category['id'].toString(),
                                                category,
                                              ),
                                              color: blueColor,
                                            ),
                                            const SizedBox(width: 8),
                                            smallActionButton(
                                              text: t('delete'),
                                              onPressed: () =>
                                                  deleteCategory(
                                                category['id'].toString(),
                                              ),
                                              color: redColor,
                                            ),
                                            const SizedBox(width: 8),
                                            smallActionButton(
                                              text: t('add_services'),
                                              onPressed: () =>
                                                  openAddServicesToCategorySheet(
                                                category['id'].toString(),
                                                category['name']
                                                        ?.toString() ??
                                                    '',
                                              ),
                                              color: purpleColor,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    category['name']
                                                            ?.toString() ??
                                                        '',
                                                    style: TextStyle(
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    category['active'] == true
                                                        ? t('active')
                                                        : t('inactive'),
                                                    style: TextStyle(
                                                      color: subTextColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            t('category_services'),
                                            style: TextStyle(
                                              color: textColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        buildCategoryServicesList(
                                          category['id'].toString(),
                                          category,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

sectionCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      sectionTitle('QR Code'),
      const SizedBox(height: 18),

      Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Image.network(
            getSalonQr(),
            height: 200,
            width: 200,
            fit: BoxFit.contain,
          ),
        ),
      ),

      const SizedBox(height: 16),

      SelectableText(
        getSalonLink(),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),

      const SizedBox(height: 16),

      ElevatedButton(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: getSalonLink()));
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('salon_link_copied'))),
          );
        },
        child: Text(t('copy_salon_link')),
      ),
    ],
  ),
),

StreamBuilder<DatabaseEvent>(
  stream: categoriesRef.onValue,
  builder: (context, categoriesSnapshot) {
    final hasCategories =
        categoriesSnapshot.hasData &&
        categoriesSnapshot.data!.snapshot.exists &&
        categoriesSnapshot.data!.snapshot.value != null;

    if (hasCategories) {
      return const SizedBox.shrink();
    }

    return sectionCard(
      child: Column(
        children: [
          sectionTitle(t('services')),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: serviceNameController,
                  style: TextStyle(color: textColor),
                  decoration: fieldDecoration(t('service_name_ar')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: serviceNameEnController,
                  style: TextStyle(color: textColor),
                  decoration: fieldDecoration(t('service_name_en')),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: servicePriceController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textColor),
                  decoration: fieldDecoration(t('price_egp')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: serviceDurationController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textColor),
                  decoration: fieldDecoration(t('duration_minute')),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          formActionRow(
            saveText: editingServiceId == null
                ? t('add_service')
                : t('save_edit'),
            onSave: saveService,
            onClear: clearServiceForm,
          ),

          const SizedBox(height: 16),

          StreamBuilder<DatabaseEvent>(
            stream: servicesRef.onValue,
            builder: (context, snapshot) {
              if (!snapshot.hasData ||
                  snapshot.data!.snapshot.value == null) {
                return Text(
                  t('no_services_yet'),
                  style: TextStyle(color: subTextColor),
                );
              }

              final raw = Map<dynamic, dynamic>.from(
                snapshot.data!.snapshot.value as Map,
              );

              final items = raw.entries.map((e) {
                return {
                  'id': e.key.toString(),
                  ...Map<String, dynamic>.from(e.value),
                };
              }).toList();

              items.sort(
                (a, b) => a['name']
                    .toString()
                    .compareTo(b['name'].toString()),
              );

              return Column(
                children: items.map((service) {
                  return entityItemCard(
                    content: Row(
                      children: [
                        smallActionButton(
                          text: t('edit'),
                          onPressed: () => editService(
                            service['id'].toString(),
                            service,
                          ),
                          color: blueColor,
                        ),
                        const SizedBox(width: 8),
                        smallActionButton(
                          text: t('delete'),
                          onPressed: () => deleteService(
                            service['id'].toString(),
                          ),
                          color: redColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Text(
                                currentLang == 'ar'
                                    ? (service['nameAr']?.toString() ??
                                        service['name']?.toString() ??
                                        '')
                                    : (service['nameEn']
                                                ?.toString()
                                                .isNotEmpty ==
                                            true
                                        ? service['nameEn'].toString()
                                        : service['nameAr']?.toString() ??
                                            service['name']?.toString() ??
                                            ''),
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${_toInt(service['price'])} ${t('egp')} - ${_toInt(service['duration'])} ${t('minute')}',
                                style: TextStyle(
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  },
),

                    sectionCard(
                      child: Column(
                        children: [
                          sectionTitle(t('barbers')),
                          const SizedBox(height: 18),
                        Row(
  children: [
    Expanded(
      child: TextField(
        controller: barberNameController, // عربي
        style: TextStyle(color: textColor),
   decoration: fieldDecoration(t('barber_name_ar')),
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: TextField(
        controller: barberNameEnController, // إنجليزي
        style: TextStyle(color: textColor),
       decoration: fieldDecoration(t('barber_name_en')),
      ),
    ),
  ],
),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: fieldColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                dropdownColor: fieldColor,
                                isExpanded: true,
                                value: barberType,
                                style: TextStyle(color: textColor),
                                items: [
                                  DropdownMenuItem(
                                    value: 'professional',
                                    child: Text(t('professional')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'assistant',
                                    child: Text(t('assistant')),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    barberType =
                                        value ?? 'professional';
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Checkbox(
                                value: barberActive,
                                activeColor: greenColor,
                                onChanged: (value) {
                                  setState(() {
                                    barberActive = value ?? true;
                                  });
                                },
                              ),
                              Text(
                                t('active'),
                                style: TextStyle(color: textColor),
                              ),
                            ],
                          ),
                          formActionRow(
                            saveText: editingBarberId == null
                                ? t('add_barber')
                                : t('save_edit'),
                            onSave: saveBarber,
                            onClear: clearBarberForm,
                          ),
                          const SizedBox(height: 16),
                          StreamBuilder<DatabaseEvent>(
                            stream: barbersRef.onValue,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData ||
                                  snapshot.data!.snapshot.value == null) {
                                return Text(
                                  t('no_barbers_yet'),
                                  style: TextStyle(color: subTextColor),
                                );
                              }

                              final raw = Map<dynamic, dynamic>.from(
                                snapshot.data!.snapshot.value as Map,
                              );

                              final items = raw.entries.map((e) {
                                return {
                                  'id': e.key.toString(),
                                  ...Map<String, dynamic>.from(e.value),
                                };
                              }).toList();

                              items.sort((a, b) => a['name']
                                  .toString()
                                  .compareTo(b['name'].toString()));

                              return Column(
                                children: items.map((barber) {
                                  return entityItemCard(
                                    content: Row(
                                      children: [
                                        smallActionButton(
                                          text: t('edit'),
                                          onPressed: () => editBarber(
                                            barber['id'].toString(),
                                            barber,
                                          ),
                                          color: blueColor,
                                        ),
                                        const SizedBox(width: 8),
                                        smallActionButton(
                                          text: t('delete'),
                                          onPressed: () => deleteBarber(
                                            barber['id'].toString(),
                                          ),
                                          color: redColor,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                          Text(
  currentLang == 'ar'
      ? (barber['nameAr']?.toString() ??
          barber['name']?.toString() ??
          '')
      : (barber['nameEn']?.toString().isNotEmpty == true
          ? barber['nameEn'].toString()
          : barber['nameAr']?.toString() ??
              barber['name']?.toString() ??
              ''),
  style: TextStyle(
    color: textColor,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  ),
),
                                              const SizedBox(height: 6),
                                              Text(
                                                '${barber['type'] == 'assistant' ? t('assistant') : t('professional')} - ${barber['active'] == true ? t('active') : t('inactive')}',
                                                style: TextStyle(
                                                  color: subTextColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    sectionCard(
                      child: Column(
                        children: [
                          sectionTitle(t('chairs')),
                          const SizedBox(height: 18),
                       TextField(
  controller: chairNameController,
  style: TextStyle(color: textColor),
  decoration: fieldDecoration(t('chair_name')),
),

const SizedBox(height: 12),

TextField(
  controller: chairNameEnController,
  style: TextStyle(color: textColor),
  decoration: fieldDecoration(t('chair_name_en')),
),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Checkbox(
                                value: chairActive,
                                activeColor: greenColor,
                                onChanged: (value) {
                                  setState(() {
                                    chairActive = value ?? true;
                                  });
                                },
                              ),
                              Text(
                                t('active'),
                                style: TextStyle(color: textColor),
                              ),
                            ],
                          ),
                          formActionRow(
                            saveText: editingChairId == null
                                ? t('add_chair')
                                : t('save_edit'),
                            onSave: saveChair,
                            onClear: clearChairForm,
                          ),
                          const SizedBox(height: 16),
                          StreamBuilder<DatabaseEvent>(
                            stream: chairsRef.onValue,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData ||
                                  snapshot.data!.snapshot.value == null) {
                                return Text(
                                  t('no_chairs_yet'),
                                  style: TextStyle(color: subTextColor),
                                );
                              }

                              final raw = Map<dynamic, dynamic>.from(
                                snapshot.data!.snapshot.value as Map,
                              );

                              final items = raw.entries.map((e) {
                                return {
                                  'id': e.key.toString(),
                                  ...Map<String, dynamic>.from(e.value),
                                };
                              }).toList();

                           final isArabic = currentLang == 'ar';

items.sort((a, b) {
  final nameA = isArabic
      ? (a['nameAr'] ?? a['name'] ?? '')
      : (a['nameEn'] ?? a['name'] ?? '');

  final nameB = isArabic
      ? (b['nameAr'] ?? b['name'] ?? '')
      : (b['nameEn'] ?? b['name'] ?? '');

  return nameA.toString().compareTo(nameB.toString());
});

                              return Column(
                                children: items.map((chair) {
                                  return entityItemCard(
                                    content: Row(
                                      children: [
                                        smallActionButton(
                                          text: t('edit'),
                                          onPressed: () => editChair(
                                            chair['id'].toString(),
                                            chair,
                                          ),
                                          color: blueColor,
                                        ),
                                        const SizedBox(width: 8),
                                        smallActionButton(
                                          text: t('delete'),
                                          onPressed: () => deleteChair(
                                            chair['id'].toString(),
                                          ),
                                          color: redColor,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                               isArabic
                                               ? chair['nameAr'] ??
                                                               chair['name'] ?? ''
                                               : chair['nameEn'] ??
                                                               chair['name'] ?? ''
                                                    '',
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                chair['active'] == true
                                                    ? t('active')
                                                    : t('inactive'),
                                                style: TextStyle(
                                                  color: subTextColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    sectionCard(
                      child: Column(
                        children: [
                          sectionTitle(t('daily_summary')),
                          const SizedBox(height: 16),
                          statCard(
                            t('finished_clients_count'),
                            '${doneToday.length}',
                            color: greenColor,
                          ),
                          statCard(
                            t('cancelled_clients_count'),
                            '${cancelledToday.length}',
                            color: redColor,
                          ),
                          statCard(
                            t('postponed_clients_count'),
                            '${delayedToday.length}',
                            color: orangeColor,
                          ),
                          statCard(
                            t('total_before_discount'),
                            '$totalBeforeDiscount ${t('egp')}',
                          ),
                          statCard(
                            t('total_discounts'),
                            '$totalDiscount ${t('egp')}',
                            color: orangeColor,
                          ),
                          statCard(
                            t('total_paid_amount'),
                            '$totalPaid ${t('egp')}',
                            color: greenColor,
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              t('most_used_services_today'),
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (servicesCount.isEmpty)
                            Text(
                              t('no_services_recorded_today'),
                              style: TextStyle(color: subTextColor),
                            )
                          else
                            ...servicesCount.entries.map((entry) {
                              return statCard(
                                entry.key,
                                '${entry.value} ${t('times')}',
                              );
                            }),
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              t('clients_distribution_barbers'),
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (barbersCount.isEmpty)
                            Text(
                              t('no_distribution_recorded_today'),
                              style: TextStyle(color: subTextColor),
                            )
                          else
                            ...barbersCount.entries.map((entry) {
                              return statCard(
                                entry.key,
                                '${entry.value} ${t('client')}',
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}