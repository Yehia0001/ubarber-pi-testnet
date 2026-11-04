import 'services/salon_notification_service.dart';
import 'dart:ui';

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';

import 'app_translations.dart';
import 'register_page.dart';

class BookingPage extends StatefulWidget {
  final String salonId;

  const BookingPage({super.key, required this.salonId});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {

  final AudioPlayer _audioPlayer = AudioPlayer();

void _playNotificationSound() async {
  await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
}

Future<void> _sendBookingNotificationToSalon({
  required String salonId,
  required String customerName,
  required String customerPhone,
}) async {
  try {
    await http.post(
      Uri.parse(
        'https://ubarber-notification-server.vercel.app/api/send-booking-notification',
      ),
      headers: {
        'Content-Type': 'application/json',
        'x-notification-secret': 'ubarber_secret_2026',
      },
      body: jsonEncode({
        'salonId': salonId,
        'title': 'حجز جديد',
        'body': 'لديك حجز جديد من $customerName',
        'customerName': customerName,
        'customerPhone': customerPhone,
      }),
    );
  } catch (e) {
    debugPrint('Notification error: $e');
  }
}

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final Color bgColor = const Color(0xFF08111F);
  final Color cardColor = const Color(0xDD101C2E);
  final Color fieldColor = const Color(0xEE13233A);
  final Color borderColor = const Color(0x552B3D57);
  final Color greenColor = const Color(0xFF22C55E);
  final Color goldColor = const Color(0xFFFBBF24);
  final Color textColor = Colors.white;
  final Color subTextColor = const Color(0xFFB8C4D6);

  late DatabaseReference servicesRef;
  late DatabaseReference barbersRef;
  late DatabaseReference bookingsRef;
  late DatabaseReference salonRef;
  late DatabaseReference settingsRef;

  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> barbers = [];
  List<Map<String, dynamic>> selectedServices = [];

  bool loadingServices = true;
  bool loadingBarbers = true;
  bool savingBooking = false;
  bool usePoints = false;
  bool isGuest = false;
  bool pointsEnabled = false;
  bool showBarbersSection = false;

  String role = '';
  String userId = '';
  String userEmail = '';
  String salonName = 'الصالون';
  String salonPhone = '';
  String bookingWhatsapp = '';
  String currentLang = 'ar';

  String bookingType = "now";
  String? selectedBarberId;
  String? selectedBarberName;
  String? selectedBarberNameAr;
  String? selectedBarberNameEn;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  int pointsBalance = 0;
  int subtotal = 0;
  int totalDuration = 0;
  int discount = 0;
  int finalTotal = 0;
  int welcomeDiscountPercent = 0;

  String appliedDiscountType = '';

  bool welcomeDiscountEnabled = false;
  bool hasUsedWelcomeDiscount = false;

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

  @override
  void initState() {
    super.initState();

    servicesRef = FirebaseDatabase.instance
        .ref()
        .child("salons")
        .child(widget.salonId)
        .child("services");

    barbersRef = FirebaseDatabase.instance
        .ref()
        .child("salons")
        .child(widget.salonId)
        .child("barbers");

    bookingsRef = FirebaseDatabase.instance
        .ref()
        .child("salons")
        .child(widget.salonId)
        .child("bookings");

    salonRef = FirebaseDatabase.instance
        .ref()
        .child("salons")
        .child(widget.salonId);

    settingsRef = FirebaseDatabase.instance
        .ref()
        .child("salons")
        .child(widget.salonId)
        .child("settings");

    loadLang();
    loadSession();
    loadSalonInfo();
    loadSettings();
    loadServices();
    loadBarbers();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
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

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    final savedRole = prefs.getString('role') ?? '';
    final savedUserId = prefs.getString('userId') ?? '';
    final savedName = prefs.getString('name') ?? '';
    final savedEmail = prefs.getString('email') ?? '';
    final savedGuest = prefs.getBool('isGuest') ?? false;
    final savedLang = prefs.getString('lang') ?? 'ar';

    if (!mounted) return;

    setState(() {
      role = savedRole;
      userId = savedUserId;
      userEmail = savedEmail;
      isGuest = savedGuest || savedRole == 'guest';
      currentLang = savedLang;

      if (!isGuest && savedName.isNotEmpty) {
        nameController.text = savedName;
      }
    });

    if (!isGuest && savedUserId.isNotEmpty) {
      final userSnapshot = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(savedUserId)
          .get();

      if (userSnapshot.exists && userSnapshot.value != null) {
        final data = Map<String, dynamic>.from(userSnapshot.value as Map);

        if (!mounted) return;

        setState(() {
          pointsBalance = _toInt(data['points']);
          hasUsedWelcomeDiscount = data['usedWelcomeDiscount'] == true;

          if ((data['name']?.toString() ?? '').isNotEmpty) {
            nameController.text = data['name'].toString();
          }

          if ((data['phone']?.toString() ?? '').isNotEmpty) {
            phoneController.text = data['phone'].toString();
          }
        });
      }
    }

    calculateSummary();
  }

  String formatDate(DateTime? date) {
  if (date == null) return "--";
  return "${date.day}/${date.month}/${date.year}";
}

String formatTime(TimeOfDay? time) {
  if (time == null) return "--";
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return "$hour:$minute";
}

InputDecoration inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: subTextColor),
    filled: true,
    fillColor: fieldColor,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: greenColor, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          : t('salon');

      salonPhone = data['phone']?.toString() ?? '';
      bookingWhatsapp = data['bookingWhatsapp']?.toString() ?? '';
    });
  }

  Future<void> loadSettings() async {
    final snapshot = await settingsRef.get();

    if (!snapshot.exists || snapshot.value == null) {
      if (!mounted) return;

      setState(() {
        welcomeDiscountEnabled = false;
        welcomeDiscountPercent = 0;
        pointsEnabled = false;
        calculateSummary();
      });
      return;
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    if (!mounted) return;

    setState(() {
      welcomeDiscountEnabled = data['enabled'] == true;
      welcomeDiscountPercent = _toInt(data['discount']);
      pointsEnabled = data['pointsEnabled'] == true;
      calculateSummary();
    });
  }

  void loadServices() {
    servicesRef.onValue.listen((event) {
      final data = event.snapshot.value;

      if (data == null || data is! Map) {
        if (mounted) {
          setState(() {
            services = [];
            selectedServices = [];
            loadingServices = false;
            calculateSummary();
          });
        }
        return;
      }

      final rawMap = Map<dynamic, dynamic>.from(data);
      final List<Map<String, dynamic>> loadedServices = [];

      rawMap.forEach((key, value) {
        if (value is Map) {
          final serviceMap = Map<dynamic, dynamic>.from(value);

          loadedServices.add({
            "id": key.toString(),
            "name": serviceMap["name"]?.toString() ?? "",
            "nameAr": serviceMap["nameAr"]?.toString() ??
                serviceMap["name"]?.toString() ??
                "",
            "nameEn": serviceMap["nameEn"]?.toString() ??
                serviceMap["name"]?.toString() ??
                "",
            "price": _toInt(serviceMap["price"]),
            "duration": _toInt(serviceMap["duration"]),
            "image": serviceMap["image"]?.toString() ?? "",
          });
        }
      });

      if (mounted) {
        setState(() {
          services = loadedServices;
          selectedServices.removeWhere(
            (selected) => !services.any((s) => s["id"] == selected["id"]),
          );
          loadingServices = false;
          calculateSummary();
        });
      }
    });
  }

  void loadBarbers() {
    barbersRef.onValue.listen((event) {
      final data = event.snapshot.value;

      if (data == null || data is! Map) {
        if (mounted) {
          setState(() {
            barbers = [];
            loadingBarbers = false;
            selectedBarberId = null;
            selectedBarberName = null;
            selectedBarberNameAr = null;
            selectedBarberNameEn = null;
          });
        }
        return;
      }

      final rawMap = Map<dynamic, dynamic>.from(data);
      final List<Map<String, dynamic>> loadedBarbers = [];

      rawMap.forEach((key, value) {
        if (value is Map) {
          final barberMap = Map<dynamic, dynamic>.from(value);

          loadedBarbers.add({
            "id": key.toString(),
            "name": barberMap["name"]?.toString() ?? "",
            "nameAr": barberMap["nameAr"]?.toString() ??
                barberMap["name"]?.toString() ??
                "",
            "nameEn": barberMap["nameEn"]?.toString() ??
                barberMap["name"]?.toString() ??
                "",
            "active": barberMap["active"] == true,
            "rating": barberMap["rating"]?.toString() ?? "0",
            "reviewsCount": _toInt(barberMap["reviewsCount"]),
          });
        }
      });

      if (mounted) {
        setState(() {
          barbers = loadedBarbers;
          loadingBarbers = false;

          if (selectedBarberId != null &&
              !barbers.any((b) => b["id"] == selectedBarberId)) {
            selectedBarberId = null;
            selectedBarberName = null;
            selectedBarberNameAr = null;
            selectedBarberNameEn = null;
          }
        });
      }
    });
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? "0") ?? 0;
  }

  String getServiceName(Map<String, dynamic> service) {
    return currentLang == 'ar'
        ? service["nameAr"]?.toString() ?? service["name"]?.toString() ?? ""
        : service["nameEn"]?.toString() ?? service["name"]?.toString() ?? "";
  }

  String getBarberName(Map<String, dynamic> barber) {
    return currentLang == 'ar'
        ? barber["nameAr"]?.toString() ?? barber["name"]?.toString() ?? ""
        : barber["nameEn"]?.toString() ?? barber["name"]?.toString() ?? "";
  }

  String getSelectedBarberName() {
    if (selectedBarberId == null) return t("let_management_choose");

    return currentLang == 'ar'
        ? selectedBarberNameAr ?? selectedBarberName ?? ""
        : selectedBarberNameEn ?? selectedBarberName ?? "";
  }
void calculateSummary() {
  int totalPrice = 0;
  int totalMinutes = 0;

  for (final service in selectedServices) {
    totalPrice += _toInt(service["price"]);
    totalMinutes += _toInt(service["duration"]);
  }

  subtotal = totalPrice;
  totalDuration = totalMinutes;

  final bool canUseWelcomeDiscount = !isGuest &&
      role == 'customer' &&
      welcomeDiscountEnabled &&
      welcomeDiscountPercent > 0 &&
      !hasUsedWelcomeDiscount;

  int welcomeDiscount = 0;
  if (canUseWelcomeDiscount) {
    welcomeDiscount = ((subtotal * welcomeDiscountPercent) / 100).round();
  }

  int pointsDiscount = 0;

  if (usePoints && !isGuest && role == 'customer') {
    if (pointsBalance >= 20 && subtotal > 0) {
      final int maxDiscountByPercent = (subtotal * 0.25).floor();
      final int maxDiscountByPointsCap = 100 ~/ 4;
      final int availableDiscountFromPoints = pointsBalance ~/ 4;

      pointsDiscount = availableDiscountFromPoints;

      if (pointsDiscount > maxDiscountByPercent) {
        pointsDiscount = maxDiscountByPercent;
      }

      if (pointsDiscount > maxDiscountByPointsCap) {
        pointsDiscount = maxDiscountByPointsCap;
      }

      final int usedPoints = pointsDiscount * 4;

      if (usedPoints < 20) {
        pointsDiscount = 0;
      }
    }
  }
  print("pointsDiscount: $pointsDiscount");
print("usePoints: $usePoints");
print("pointsBalance: $pointsBalance");
print("subtotal: $subtotal");
print("final discount before set: $discount");

  if (usePoints && pointsDiscount > 0) {
    discount = pointsDiscount;
    appliedDiscountType = 'points';
  } else if (!usePoints && welcomeDiscount > 0) {
    discount = welcomeDiscount;
    appliedDiscountType = 'welcome';
  } else {
    discount = 0;
    appliedDiscountType = '';
  }

  if (discount > subtotal) {
    discount = subtotal;
  }

  finalTotal = subtotal - discount;

  if (finalTotal < 0) {
    finalTotal = 0;
  }
}
 

  Widget buildSectionCard({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withOpacity(0.09)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget buildSmallBadge({
    required IconData icon,
    required String text,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: (color ?? greenColor).withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: (color ?? greenColor).withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color ?? greenColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSummaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              textAlign: currentLang == 'ar' ? TextAlign.left : TextAlign.right,
              style: TextStyle(
                color: valueColor ?? textColor,
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                fontSize: bold ? 17 : 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: subTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDivider() {
    return Divider(
      color: Colors.white.withOpacity(0.10),
      thickness: 1,
      height: 24,
    );
  }

  bool isServiceSelected(Map<String, dynamic> service) {
    return selectedServices.any((item) => item["id"] == service["id"]);
  }

  void toggleService(Map<String, dynamic> service) {
    setState(() {
      if (isServiceSelected(service)) {
        selectedServices.removeWhere((item) => item["id"] == service["id"]);
      } else {
        selectedServices.add(service);
      }
      calculateSummary();
    });
  }

  Future<void> pickDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (pickedDate == null || !mounted) return;

    final settingsSnapshot = await FirebaseDatabase.instance
        .ref()
        .child("salons")
        .child(widget.salonId)
        .child("settings")
        .get();

    int openHour = 10;
    int closeHour = 22;

    if (settingsSnapshot.exists && settingsSnapshot.value != null) {
      final data = Map<String, dynamic>.from(settingsSnapshot.value as Map);

      openHour = _toInt(data['openHour']);
      closeHour = _toInt(data['closeHour']);

      if (openHour == 0) openHour = 10;
      if (closeHour == 0) closeHour = 22;
    }

    final selectedDateMillis = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
    ).millisecondsSinceEpoch;

    final bookingsSnapshot = await bookingsRef.get();

    final activeBarbers = barbers.where((b) => b["active"] == true).toList();
    final int activeBarbersCount = activeBarbers.length;

    final Map<int, int> bookingsCountPerHour = {};
    final Set<int> bookedHoursForSelectedBarber = {};

    if (bookingsSnapshot.exists && bookingsSnapshot.value != null) {
      final rawBookings = Map<dynamic, dynamic>.from(
        bookingsSnapshot.value as Map,
      );

      rawBookings.forEach((key, value) {
        if (value is! Map) return;

        final booking = Map<dynamic, dynamic>.from(value);

        final bookingDate = _toInt(booking['bookingDate']);
        final status = booking['status']?.toString() ?? '';
        final bookingTypeValue = booking['bookingType']?.toString() ?? '';
        final barberId = booking['barberId']?.toString() ?? '';

        if (bookingDate != selectedDateMillis) return;
        if (status == 'cancelled' || status == 'completed') return;
        if (bookingTypeValue != 'later') return;

        final bookingTime = booking['bookingTime'];
        if (bookingTime is! Map) return;

        final timeMap = Map<dynamic, dynamic>.from(bookingTime);
        final hour = _toInt(timeMap['hour']);

        bookingsCountPerHour[hour] = (bookingsCountPerHour[hour] ?? 0) + 1;

        if (selectedBarberId != null &&
            selectedBarberId!.isNotEmpty &&
            barberId == selectedBarberId) {
          bookedHoursForSelectedBarber.add(hour);
        }
      });
    }

    final List<int> availableHours = [];

    for (int hour = openHour; hour < closeHour; hour++) {
      final isToday = pickedDate.year == now.year &&
          pickedDate.month == now.month &&
          pickedDate.day == now.day;

      if (isToday && hour <= now.hour) continue;

      if (selectedBarberId != null && selectedBarberId!.isNotEmpty) {
        if (bookedHoursForSelectedBarber.contains(hour)) continue;
      } else {
        if (activeBarbersCount == 0) continue;

        final bookedCount = bookingsCountPerHour[hour] ?? 0;
        if (bookedCount >= activeBarbersCount) continue;
      }

      availableHours.add(hour);
    }

    if (!mounted) return;

    if (availableHours.isEmpty) {
      showMessage(t("no_available_times_today"));
      return;
    }

    final selectedHour = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xF2101C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Directionality(
          textDirection:
              currentLang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.62,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 52,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      t("choose_available_time"),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        itemCount: availableHours.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.9,
                        ),
                        itemBuilder: (context, index) {
                          final hour = availableHours[index];
                          final formattedHour =
                              "${hour.toString().padLeft(2, '0')}:00";

                          return ElevatedButton(
                            onPressed: () => Navigator.pop(context, hour),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: fieldColor,
                              foregroundColor: textColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: borderColor),
                              ),
                            ),
                            child: Text(
                              formattedHour,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
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

    if (selectedHour == null) return;

    setState(() {
      selectedDate = pickedDate;
      selectedTime = TimeOfDay(hour: selectedHour, minute: 0);
    });
  }

  Future<void> openServicesBottomSheet() async {
    if (loadingServices) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xF2101C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Directionality(
          textDirection:
              currentLang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              void modalToggle(Map<String, dynamic> service) {
                setState(() {
                  if (isServiceSelected(service)) {
                    selectedServices.removeWhere(
                      (item) => item["id"] == service["id"],
                    );
                  } else {
                    selectedServices.add(service);
                  }
                  calculateSummary();
                });
                setModalState(() {});
              }

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.76,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 52,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          t("choose_services"),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t("choose_services_hint"),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: services.isEmpty
                              ? Center(
                                  child: Text(
                                    t("no_services"),
                                    style: TextStyle(color: subTextColor),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: services.length,
                                  itemBuilder: (context, index) {
                                    final service = services[index];
                                    final selected = isServiceSelected(service);

                                    return GestureDetector(
                                      onTap: () => modalToggle(service),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? greenColor.withOpacity(0.13)
                                              : fieldColor,
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          border: Border.all(
                                            color: selected
                                                ? greenColor
                                                : borderColor,
                                            width: selected ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 42,
                                              height: 42,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: selected
                                                    ? greenColor
                                                    : Colors.white
                                                        .withOpacity(0.08),
                                              ),
                                              child: Icon(
                                                selected
                                                    ? Icons.check_rounded
                                                    : Icons.content_cut,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    getServiceName(service),
                                                    style: TextStyle(
                                                      color: textColor,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 7),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children: [
                                                      buildSmallBadge(
                                                        icon: Icons.timer,
                                                        text:
                                                            "${_toInt(service["duration"])} ${t('minutes')}",
                                                      ),
                                                      buildSmallBadge(
                                                        icon:
                                                            Icons.payments_rounded,
                                                        text:
                                                            "${_toInt(service["price"])}",
                                                        color: goldColor,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: greenColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            t("done"),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

Future<void> submitBooking() async {
  final name = nameController.text.trim();
  final phone = phoneController.text.trim();

  if (name.isEmpty || phone.isEmpty) {
    showMessage(t("please_enter_name_phone"));
    throw Exception("missing_name_or_phone");
  }

  if (selectedServices.isEmpty) {
    showMessage(t("please_choose_service"));
    throw Exception("missing_services");
  }

  if (bookingType == "later" &&
      (selectedDate == null || selectedTime == null)) {
    showMessage(t("please_choose_date_time"));
    throw Exception("missing_date_or_time");
  }

  setState(() {
    savingBooking = true;
  });

  try {
    final now = DateTime.now().millisecondsSinceEpoch;
    final newBookingRef = bookingsRef.push();

    final servicesData = selectedServices.map((service) => {
          "id": service["id"],
          "name": getServiceName(service),
          "nameAr": service["nameAr"] ?? service["name"] ?? "",
          "nameEn": service["nameEn"] ?? service["name"] ?? "",
          "price": _toInt(service["price"]),
          "duration": _toInt(service["duration"]),
        }).toList();

    final bookingData = {
      "id": newBookingRef.key,
      "userId": userId,
      "role": role,
      "isGuest": isGuest,
      "userEmail": userEmail,
      "name": name,
      "phone": phone,
      "salonId": widget.salonId,

      "barberId": selectedBarberId ?? "",
      "barberName": selectedBarberName ?? "",
      "barberNameAr": selectedBarberNameAr ?? "",
      "barberNameEn": selectedBarberNameEn ?? "",

      "bookingType": bookingType,
      "bookingDate": selectedDate?.millisecondsSinceEpoch,
      "bookingTime": selectedTime == null
          ? null
          : {
              "hour": selectedTime!.hour,
              "minute": selectedTime!.minute,
            },

      "services": servicesData,
      "servicesCount": selectedServices.length,
      "totalDuration": totalDuration,
      "subtotal": subtotal,
      "discount": discount,
      "finalTotal": finalTotal,

      "usePoints": usePoints,
      "pointsUsed": appliedDiscountType == "points" ? discount * 4 : 0,
      "pointsDiscountPending": appliedDiscountType == "points",
      "welcomeDiscountPending": appliedDiscountType == "welcome",
      "appliedDiscountType": appliedDiscountType,

      "enteredQueue": bookingType == "now",
      "status": "pending",
      "createdAt": ServerValue.timestamp,
    };

    await newBookingRef.set(bookingData);

await _sendBookingNotificationToSalon(
  salonId: widget.salonId,
  customerName: name,
  customerPhone: phone,
);

    if (bookingType == "now") {
      final newQueueRef =
          FirebaseDatabase.instance.ref().child("queue").push();

      await newQueueRef.set({
        "id": newQueueRef.key,
        "bookingId": newBookingRef.key,
        "userId": userId,
        "role": role,
        "isGuest": isGuest,
        "userEmail": userEmail,
        "name": name,
        "phone": phone,
        "salonId": widget.salonId,

        "barberId": selectedBarberId ?? "",
        "barberName": selectedBarberName ?? "",
        "barberNameAr": selectedBarberNameAr ?? "",
        "barberNameEn": selectedBarberNameEn ?? "",
        "barber": selectedBarberName ?? "",
        "barberAr": selectedBarberNameAr ?? "",
        "barberEn": selectedBarberNameEn ?? "",

        "chair": "",
        "bookingType": bookingType,
        "bookingDate": selectedDate?.millisecondsSinceEpoch,
        "bookingTime": selectedTime == null
            ? null
            : {
                "hour": selectedTime!.hour,
                "minute": selectedTime!.minute,
              },

        "services": servicesData,
        "servicesCount": selectedServices.length,
        "totalDuration": totalDuration,
        "subtotal": subtotal,
        "discount": discount,
        "finalTotal": finalTotal,
        "paid": 0,
        "expectedPoints": isGuest ? 0 : (finalTotal ~/ 10),

        "usePoints": usePoints,
        "pointsUsed": appliedDiscountType == "points" ? discount * 4 : 0,
        "pointsDiscountPending": appliedDiscountType == "points",
        "welcomeDiscountPending": appliedDiscountType == "welcome",
        "appliedDiscountType": appliedDiscountType,

        "pointsEligible": !isGuest,
        "isManual": false,
        "status": "waiting",
        "queueOrder": now,
        "createdAt": now,
        "updatedAt": now,
      });
    }
  } catch (e) {
    showMessage(t("booking_error"));
    rethrow;
  } finally {
    if (mounted) {
      setState(() {
        savingBooking = false;
      });
    }
  }
}

String buildWhatsappMessage() {
  final name = nameController.text.trim().isEmpty
      ? t("not_specified")
      : nameController.text.trim();

  final phone = phoneController.text.trim().isEmpty
      ? t("not_specified")
      : phoneController.text.trim();

  final barber = getSelectedBarberName();

  final servicesText = selectedServices.isEmpty
      ? t("no_services_text")
      : selectedServices.map((service) {
          final serviceName = getServiceName(service);
          final duration = _toInt(service["duration"]);
          final price = _toInt(service["price"]);

          return "- $serviceName ($duration ${t('minutes')} / $price)";
        }).join("\n");

  final bookingText = bookingType == "now"
      ? t("booking_now_text")
      : "${t('appointment_day_time')} ${formatDate(selectedDate)} ${t('time')} ${formatTime(selectedTime)}";

  return """
${t('new_booking_request')}
${t('salon_name_label')}: $salonName
${t('name')}: $name
${t('phone')}: $phone
${t('booking_type')}: $bookingText
${t('barber_label')}: $barber

${t('services_label')}:
$servicesText

${t('total_time')}: $totalDuration ${t('minutes')}
${t('price_before_discount')}: $subtotal
${t('discount')}: $discount
${t('total_after_discount')}: $finalTotal
""";
}

String normalizePhone(String phone) {
  String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

  if (digits.startsWith('20')) return digits;
  if (digits.startsWith('0')) return '2$digits';

  return digits;
}

void clearBookingForm() {
  nameController.clear();
  phoneController.clear();

  setState(() {
    selectedServices = [];
    selectedBarberId = null;
    selectedBarberName = null;
    selectedBarberNameAr = null;
    selectedBarberNameEn = null;
    selectedDate = null;
    selectedTime = null;
    bookingType = "now";
    usePoints = false;
    showBarbersSection = false;
    calculateSummary();
  });
}

Future<void> openWhatsapp() async {
  final now = DateTime.now().hour;

  final snapshot = await FirebaseDatabase.instance
      .ref()
      .child("salons")
      .child(widget.salonId)
      .child("settings")
      .get();

  if (snapshot.exists && snapshot.value != null) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);

    final openHour = _toInt(data['openHour']);
    final closeHour = _toInt(data['closeHour']);

    final safeOpenHour = openHour == 0 ? 10 : openHour;
    final safeCloseHour = closeHour == 0 ? 22 : closeHour;

    if (now < safeOpenHour || now >= safeCloseHour) {
      showMessage(
        "${t('booking_available_from')} $safeOpenHour ${t('to')} $safeCloseHour",
      );
      return;
    }
  }

  final name = nameController.text.trim();
  final phone = phoneController.text.trim();

  if (name.isEmpty || phone.isEmpty) {
    showMessage(t("please_enter_name_phone_first"));
    return;
  }

  if (selectedServices.isEmpty) {
    showMessage(t("please_choose_service"));
    return;
  }

  /// 🔥 أهم إضافة (حالة الحجز بموعد)
  if (bookingType == "later") {
    if (selectedDate == null || selectedTime == null) {
      showMessage(t("please_choose_date_time"));
      return;
    }
  }

  try {
    await submitBooking();
  } catch (_) {
    return;
  }

  final rawSalonPhone =
      (bookingWhatsapp.isNotEmpty ? bookingWhatsapp : salonPhone).trim();

  if (rawSalonPhone.isEmpty) {
    showMessage(t("whatsapp_not_available"));
    return;
  }

  final phoneNumber = normalizePhone(rawSalonPhone);
  final message = buildWhatsappMessage();

  final Uri webUri = Uri.parse(
    "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}",
  );

  final Uri appUri = Uri.parse(
    "whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}",
  );

 try {
      final launched = await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        clearBookingForm();
        return;
      }

      final appLaunched = await launchUrl(
        appUri,
        mode: LaunchMode.externalApplication,
      );

      if (appLaunched) {
        clearBookingForm();
        return;
      }

      showMessage(t("cannot_open_whatsapp"));
    } catch (e) {
      debugPrint('WhatsApp launch error: $e');
      showMessage(t("cannot_open_whatsapp"));
    }
}

void goToRegister() {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const RegisterPage(),
    ),
  );
}

void showMessage(String text) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF101C2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
  );
}

Widget buildBackgroundLayer() {
  return Stack(
    children: [
      Positioned.fill(
        child: Image.asset(
          'assets/images/booking_bg.jpg',
          fit: BoxFit.cover,
        ),
      ),
      Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.55),
        ),
      ),
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.25),
                Colors.transparent,
                bgColor.withOpacity(0.88),
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

Widget buildGuestBanner() {
  if (!isGuest) return const SizedBox.shrink();

  return buildSectionCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: goldColor.withOpacity(0.16),
          ),
          child: Icon(
            Icons.card_giftcard_rounded,
            color: goldColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            t("guest_discount_banner"),
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: goToRegister,
          style: ElevatedButton.styleFrom(
            backgroundColor: greenColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            t("register"),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

Widget buildHeaderBanner() {
  return buildSectionCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        buildSmallBadge(
          icon: Icons.verified_rounded,
          text: t("premium_booking"),
          color: goldColor,
        ),
        const SizedBox(height: 14),
        Text(
          salonName,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t("professional_booking_fast"),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: subTextColor,
            fontSize: 15.5,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            buildSmallBadge(
              icon: Icons.flash_on_rounded,
              text: t("fast_booking"),
            ),
            buildSmallBadge(
              icon: Icons.schedule_rounded,
              text: t("queue_or_appointment"),
            ),
            if (!isGuest)
              buildSmallBadge(
                icon: Icons.stars_rounded,
                text: "$pointsBalance ${t('points')}",
                color: goldColor,
              ),
          ],
        ),
      ],
    ),
  );
}

Widget buildSectionTitle({
  required IconData icon,
  required String title,
  String? subtitle,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: greenColor.withOpacity(0.14),
          border: Border.all(color: greenColor.withOpacity(0.30)),
        ),
        child: Icon(icon, color: greenColor, size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

@override
Widget build(BuildContext context) {
  final activeBarbers = barbers.where((b) => b["active"] == true).toList();

  return Directionality(
    textDirection: currentLang == 'ar'
        ? TextDirection.rtl
        : TextDirection.ltr,
    child: Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
        title: Text(
          t("booking_page"),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton.icon(
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
                  horizontal: 10,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.14),
                  ),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: logout,
            child: Text(
              t("logout"),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          buildBackgroundLayer(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  buildHeaderBanner(),
                  const SizedBox(height: 12),
                  buildGuestBanner(),
                  const SizedBox(height: 18),

                  /// ================== MAIN CARD ==================
                  buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        /// ===== CUSTOMER =====
                        buildSectionTitle(
                          icon: Icons.person,
                          title: t("customer_details"),
                          subtitle: t("customer_details_hint"),
                        ),
                        const SizedBox(height: 16),

                        Text(t("name"),
                            style: TextStyle(color: subTextColor)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameController,
                          style: TextStyle(color: textColor),
                          decoration: inputDecoration(t("enter_name")),
                        ),

                        const SizedBox(height: 14),

                        Text(t("phone"),
                            style: TextStyle(color: subTextColor)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: textColor),
                          decoration: inputDecoration(t("enter_phone")),
                        ),

                        const SizedBox(height: 22),

                        /// ===== BOOKING TYPE =====
                        buildSectionTitle(
                          icon: Icons.calendar_month,
                          title: t("choose_booking_type"),
                          subtitle: t("choose_booking_type_hint"),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    bookingType = "later";
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: bookingType == "later"
                                      ? greenColor
                                      : Colors.white,
                                  foregroundColor: bookingType == "later"
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                child: Text(t("choose_appointment")),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    bookingType = "now";
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: bookingType == "now"
                                      ? greenColor
                                      : Colors.white,
                                  foregroundColor: bookingType == "now"
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                child: Text(t("book_now_queue")),
                              ),
                            ),
                          ],
                        ),

                        /// ===== DATE TIME =====
                        if (bookingType == "later") ...[
                          const SizedBox(height: 16),

                          GestureDetector(
                            onTap: pickDate,
                            child: AbsorbPointer(
                              child: TextField(
                                decoration: inputDecoration(
                                  selectedDate == null
                                      ? t("choose_date")
                                      : formatDate(selectedDate),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          GestureDetector(
                            onTap: pickDate,
                            child: AbsorbPointer(
                              child: TextField(
                                decoration: inputDecoration(
                                  selectedTime == null
                                      ? t("choose_time")
                                      : formatTime(selectedTime),
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 22),

                        /// ===== BARBERS =====
                        buildSectionTitle(
                          icon: Icons.content_cut,
                          title: t("barber_optional"),
                          subtitle: t("barber_optional_hint"),
                        ),

                        const SizedBox(height: 10),

                        GestureDetector(
                          onTap: () {
                            setState(() {
                              showBarbersSection = !showBarbersSection;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: fieldColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    getSelectedBarberName(),
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (showBarbersSection)
                          Column(
                            children: activeBarbers.map((barber) {
                              final barberId = barber["id"];

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedBarberId = barberId;

                                    selectedBarberName =
                                        getBarberName(barber);

                                    selectedBarberNameAr =
                                        barber["nameAr"];

                                    selectedBarberNameEn =
                                        barber["nameEn"];

                                    showBarbersSection = false;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: fieldColor,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          getBarberName(barber),
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 22),

                        /// ===== SERVICES =====
                        buildSectionTitle(
                          icon: Icons.spa,
                          title: t("services"),
                          subtitle: t("services_hint"),
                        ),

                        const SizedBox(height: 10),

                        ElevatedButton(
                          onPressed: openServicesBottomSheet,
                          child: Text(t("choose_services")),
                        ),

                        const SizedBox(height: 12),

                        ...selectedServices.map((s) => ListTile(
                              title: Text(
                                getServiceName(s),
                                style: TextStyle(color: textColor),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => toggleService(s),
                              ),
                            )),

                        const SizedBox(height: 18),

                        
                       /// ===== POINTS TOGGLE =====
GestureDetector(
onTap: () {
  setState(() {
    usePoints = !usePoints;
    calculateSummary(); // 👈 دي أهم سطر ناقص
  });
},
  child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: fieldColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor),
    ),
    child: Row(
      children: [
        Icon(
          usePoints ? Icons.check_circle : Icons.circle_outlined,
          color: usePoints ? greenColor : Colors.white54,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            currentLang == 'ar'
                ? "استخدم نقاطك — كل 4 نقاط = 1 جنيه"
                : "Use your points — every 4 points = 1 EGP",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  ),
),

const SizedBox(height: 16),
                     /// ===== SUMMARY =====
                        buildSectionTitle(
                          icon: Icons.receipt,
                          title: t("booking_summary"),
                          subtitle: t("booking_summary_hint"),
                        ),

                        const SizedBox(height: 12),

                        buildSummaryRow(
                            t("total_time"), "$totalDuration"),
                        buildSummaryRow(
                            t("price_before_discount"), "$subtotal"),
                        buildSummaryRow(t("discount"), "$discount"),
                        buildSummaryRow(
                          t("total_after_discount"),
                          "$finalTotal",
                          valueColor: greenColor,
                          bold: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// ===== BUTTON =====
                  ElevatedButton(
                    onPressed: savingBooking ? null : openWhatsapp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      savingBooking
                          ? t("saving_booking")
                          : t("confirm_booking_whatsapp"),
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
}