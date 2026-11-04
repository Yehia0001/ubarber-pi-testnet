import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'admin_page.dart';
import 'app_translations.dart';

class QueuePage extends StatefulWidget {
  final String salonId;

  const QueuePage({
    super.key,
    required this.salonId,
  });

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  final DatabaseReference rootRef = FirebaseDatabase.instance.ref();

  Set<String> selectedServiceIds = {};

  late final DatabaseReference salonRef;
  late final DatabaseReference queueRef;
  late final DatabaseReference bookingsRef;
  late final DatabaseReference servicesRef;
  late final DatabaseReference barbersRef;
  late final DatabaseReference chairsRef;

  final TextEditingController manualNameController = TextEditingController();
  final TextEditingController manualPhoneController = TextEditingController();
  final TextEditingController paidAmountController = TextEditingController();

  final Color bgColor = const Color(0xFF07111F);
  final Color cardColor = const Color(0xDD101B2D);
  final Color fieldColor = const Color(0xDD13233A);
  final Color borderColor = const Color(0xFF304763);
  final Color greenColor = const Color(0xFF22C55E);
  final Color blueColor = const Color(0xFF4A86F7);
  final Color purpleColor = const Color(0xFF7C3AED);
  final Color orangeColor = const Color(0xFFF59E0B);
  final Color redColor = const Color(0xFFEF4444);
  final Color textColor = Colors.white;
  final Color subTextColor = const Color(0xFFC4D0E0);

  String currentLang = 'ar';
  String salonName = 'UBarber';
  String salonWhatsapp = '';
  String? currentPreviewClientId;

  List<Map<String, dynamic>> salonServices = [];
  List<Map<String, dynamic>> salonBarbers = [];
  List<Map<String, dynamic>> salonChairs = [];

  String selectedCurrentBarber = '';
  String selectedCurrentChair = '';

  @override
  void initState() {
    super.initState();

    salonRef = rootRef.child('salons').child(widget.salonId);
    queueRef = rootRef.child('queue');
    bookingsRef = salonRef.child('bookings');
    servicesRef = salonRef.child('services');
    barbersRef = salonRef.child('barbers');
    chairsRef = salonRef.child('chairs');

    _loadLang();
    _loadSalonInfo();
    _loadStaticData();
  }

  @override
  void dispose() {
    manualNameController.dispose();
    manualPhoneController.dispose();
    paidAmountController.dispose();
    super.dispose();
  }

  String t(String key) => tr(key, currentLang);

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

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _getQueueOrder(Map<String, dynamic> item) {
    final queueOrder = _toInt(item['queueOrder']);
    if (queueOrder != 0) return queueOrder;

    final createdAt = _toInt(item['createdAt']);
    if (createdAt != 0) return createdAt;

    return _toInt(item['updatedAt']);
  }

  bool _isToday(int timestamp) {
    if (timestamp == 0) return false;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _normalizeWhatsappPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('20')) return digits;
    if (digits.startsWith('0')) return '2$digits';
    return digits;
  }

  String _serviceName(Map<String, dynamic> service) {
    return currentLang == 'ar'
        ? service['nameAr']?.toString() ?? service['name']?.toString() ?? ''
        : service['nameEn']?.toString() ?? service['name']?.toString() ?? '';
  }

  String _barberName(Map<String, dynamic> barber) {
    return currentLang == 'ar'
        ? barber['nameAr']?.toString() ?? barber['name']?.toString() ?? ''
        : barber['nameEn']?.toString() ?? barber['name']?.toString() ?? '';
  }

  String _queueServiceName(Map<String, dynamic> service) {
    return currentLang == 'ar'
        ? service['nameAr']?.toString() ?? service['name']?.toString() ?? ''
        : service['nameEn']?.toString() ?? service['name']?.toString() ?? '';
  }

  String _clientBarberName(Map<String, dynamic> item) {
    return currentLang == 'ar'
        ? item['barberNameAr']?.toString() ??
            item['barberAr']?.toString() ??
            item['barberName']?.toString() ??
            item['barber']?.toString() ??
            ''
        : item['barberNameEn']?.toString() ??
            item['barberEn']?.toString() ??
            item['barberName']?.toString() ??
            item['barber']?.toString() ??
            '';
  }

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF101B2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
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
        borderSide: BorderSide(color: blueColor, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    );
  }

  Widget _premiumCard({
    required Widget child,
    EdgeInsets? padding,
  }) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor.withOpacity(0.85)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? color,
  }) {
    final isArabic = currentLang == 'ar';

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: (color ?? blueColor).withOpacity(0.14),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color ?? blueColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                title,
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
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

  Future<void> _loadSalonInfo() async {
    try {
      final snapshot = await salonRef.get();
      if (!snapshot.exists || snapshot.value == null) return;

      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);

      if (!mounted) return;
      setState(() {
        final rawName = data['name']?.toString().trim() ?? '';
        salonName = rawName.isNotEmpty ? rawName : 'UBarber';

        final bookingWhatsapp = data['bookingWhatsapp']?.toString() ?? '';
        final phone = data['phone']?.toString() ?? '';
        salonWhatsapp = bookingWhatsapp.isNotEmpty ? bookingWhatsapp : phone;
      });
    } catch (_) {
      showMessage(t('queue_load_salon_error'));
    }
  }

  Future<void> _loadStaticData() async {
    final servicesSnapshot = await servicesRef.get();
    final barbersSnapshot = await barbersRef.get();
    final chairsSnapshot = await chairsRef.get();

    final loadedServices = <Map<String, dynamic>>[];
    final loadedBarbers = <Map<String, dynamic>>[];
    final loadedChairs = <Map<String, dynamic>>[];

    if (servicesSnapshot.exists && servicesSnapshot.value != null) {
      final raw = Map<dynamic, dynamic>.from(servicesSnapshot.value as Map);

      raw.forEach((key, value) {
        if (value is Map) {
          final item = Map<dynamic, dynamic>.from(value);

          loadedServices.add({
            'id': key.toString(),
            'name': item['name']?.toString() ?? t('service'),
            'nameAr': item['nameAr']?.toString() ??
                item['name']?.toString() ??
                t('service'),
            'nameEn': item['nameEn']?.toString() ??
                item['name']?.toString() ??
                t('service'),
            'price': _toInt(item['price']),
            'duration': _toInt(item['duration']),
          });
        }
      });
    }

    if (barbersSnapshot.exists && barbersSnapshot.value != null) {
      final raw = Map<dynamic, dynamic>.from(barbersSnapshot.value as Map);

      raw.forEach((key, value) {
        if (value is Map) {
          final item = Map<dynamic, dynamic>.from(value);

          loadedBarbers.add({
            'id': key.toString(),
            'name': item['name']?.toString() ?? t('barber'),
            'nameAr': item['nameAr']?.toString() ??
                item['name']?.toString() ??
                t('barber'),
            'nameEn': item['nameEn']?.toString() ??
                item['name']?.toString() ??
                t('barber'),
          });
        } else {
          loadedBarbers.add({
            'id': key.toString(),
            'name': value.toString(),
            'nameAr': value.toString(),
            'nameEn': value.toString(),
          });
        }
      });
    }

    if (chairsSnapshot.exists && chairsSnapshot.value != null) {
      final raw = Map<dynamic, dynamic>.from(chairsSnapshot.value as Map);

      raw.forEach((key, value) {
        if (value is Map) {
          final item = Map<dynamic, dynamic>.from(value);

          loadedChairs.add({
            'id': key.toString(),
            'name': item['name']?.toString() ?? t('chair'),
          });
        } else {
          loadedChairs.add({
            'id': key.toString(),
            'name': value.toString(),
          });
        }
      });
    }

    if (!mounted) return;
    setState(() {
      salonServices = loadedServices;
      salonBarbers = loadedBarbers;
      salonChairs = loadedChairs;
    });
  }

  Future<void> _addManualClient() async {
    final name = manualNameController.text.trim();
    final phone = manualPhoneController.text.trim();

    if (name.isEmpty) {
      showMessage(t('please_enter_client_name'));
      return;
    }

    if (phone.isNotEmpty && (!phone.startsWith('01') || phone.length != 11)) {
      showMessage(t('phone_must_start_01'));
      return;
    }

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final newRef = queueRef.push();
      final id = newRef.key ?? '';

      await newRef.set({
        'id': id,
        'salonId': widget.salonId,
        'name': name,
        'phone': phone,
        'status': 'waiting',
        'services': [],
        'barber': '',
        'barberName': '',
        'barberNameAr': '',
        'barberNameEn': '',
        'chair': '',
        'subtotal': 0,
        'discount': 0,
        'finalTotal': 0,
        'paid': 0,
        'expectedPoints': 0,
        'isManual': true,
        'pointsEligible': false,
        'queueOrder': now,
        'createdAt': now,
        'updatedAt': now,
        'notificationStatus': 'pending',
      });

      manualNameController.clear();
      manualPhoneController.clear();

      if (!mounted) return;
      setState(() {});

      showMessage(t('client_added_to_queue'));
    } catch (_) {
      showMessage(t('client_add_error'));
    }
  }

  Future<void> _addScheduledBookingToQueue(Map<String, dynamic> booking) async {
    final bookingKey = booking['firebaseKey']?.toString() ?? '';
    if (bookingKey.isEmpty) return;

    final alreadyEntered = booking['enteredQueue'] == true;
    if (alreadyEntered) {
      showMessage(t('booking_already_added_to_queue'));
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final newQueueRef = queueRef.push();
    final queueId = newQueueRef.key ?? '';

    final bookingFinalTotal = _toInt(booking['finalTotal']);
  final bookingExpectedPoints = booking['isGuest'] == true
    ? 0
    : (bookingFinalTotal * 0.10).floor();

    await newQueueRef.set({
      'id': queueId,
      'bookingId': bookingKey,
      'userId': booking['userId'] ?? '',
      'role': booking['role'] ?? '',
      'isGuest': booking['isGuest'] == true,
      'userEmail': booking['userEmail'] ?? '',
      'name': booking['name'] ?? '',
      'phone': booking['phone'] ?? '',
      'salonId': widget.salonId,
      'barberId': booking['barberId'] ?? '',
      'barberName': booking['barberName'] ?? '',
      'barberNameAr': booking['barberNameAr'] ?? booking['barberName'] ?? '',
      'barberNameEn': booking['barberNameEn'] ?? booking['barberName'] ?? '',
      'barber': booking['barberName'] ?? '',
      'barberAr': booking['barberNameAr'] ?? booking['barberName'] ?? '',
      'barberEn': booking['barberNameEn'] ?? booking['barberName'] ?? '',
      'chair': '',
      'bookingType': booking['bookingType'] ?? 'later',
      'bookingDate': booking['bookingDate'],
      'bookingTime': booking['bookingTime'],
      'services': booking['services'] ?? [],
      'servicesCount': _toInt(booking['servicesCount']),
      'totalDuration': _toInt(booking['totalDuration']),
      'subtotal': _toInt(booking['subtotal']),
      'discount': _toInt(booking['discount']),
      'finalTotal': bookingFinalTotal,
      'paid': 0,
      'expectedPoints': bookingExpectedPoints,
      'usePoints': booking['usePoints'] == true,
      'pointsEligible': !(booking['isGuest'] == true),
      'isManual': false,
      'status': 'waiting',
      'queueOrder': now,
      'createdAt': now,
      'updatedAt': now,
      'notificationStatus': 'pending',
      'appliedDiscountType': booking['appliedDiscountType'] ?? '',
'pointsProcessed': false,
    });

    await bookingsRef.child(bookingKey).update({
      'enteredQueue': true,
      'status': 'pending',
      'queueEntryId': queueId,
      'updatedAt': now,
    });

    showMessage(t('booking_added_to_queue'));
  }

  Future<void> _makeCurrent(Map<String, dynamic> item) async {
    final key = item['firebaseKey']?.toString() ?? '';
    if (key.isEmpty) return;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final todaySnapshot = await queueRef.get();

      if (todaySnapshot.exists && todaySnapshot.value != null) {
        final raw = Map<dynamic, dynamic>.from(todaySnapshot.value as Map);

        for (final entry in raw.entries) {
          if (entry.value is Map) {
            final data = Map<dynamic, dynamic>.from(entry.value);

            if (data['salonId']?.toString() == widget.salonId &&
                data['status']?.toString() == 'current') {
              await queueRef.child(entry.key.toString()).update({
                'status': 'waiting',
                'updatedAt': now,
              });
            }
          }
        }
      }

      await queueRef.child(key).update({
        'status': 'current',
        'updatedAt': now,
        'notificationStatus': 'current',
      });

      if (!mounted) return;
      setState(() {
        currentPreviewClientId = key;
        selectedCurrentBarber = _clientBarberName(item);
        selectedCurrentChair = item['chair']?.toString() ?? '';
      });
    } catch (_) {
      showMessage(t('make_current_error'));
    }
  }

  Future<void> _activateNextClient({String? excludeKey}) async {
    final snapshot = await queueRef.get();

    if (!snapshot.exists || snapshot.value == null) {
      if (!mounted) return;
      setState(() {
        currentPreviewClientId = null;
        selectedCurrentBarber = '';
        selectedCurrentChair = '';
      });
      return;
    }

    final raw = Map<dynamic, dynamic>.from(snapshot.value as Map);
    final waitingClients = <Map<String, dynamic>>[];

    for (final entry in raw.entries) {
      if (entry.value is Map) {
        final item = Map<String, dynamic>.from(entry.value as Map);
        final key = entry.key.toString();

        if (item['salonId']?.toString() != widget.salonId) continue;
        if (excludeKey != null && key == excludeKey) continue;

        final createdAt = _toInt(item['createdAt']);
        final updatedAt = _toInt(item['updatedAt']);
        final bookingDate = _toInt(item['bookingDate']);
        final stamp =
            bookingDate != 0 ? bookingDate : (updatedAt != 0 ? updatedAt : createdAt);

        if (!_isToday(stamp)) continue;

        if (item['status']?.toString() == 'waiting') {
          item['firebaseKey'] = key;
          waitingClients.add(item);
        }
      }
    }

    if (waitingClients.isEmpty) {
      if (!mounted) return;
      setState(() {
        currentPreviewClientId = null;
        selectedCurrentBarber = '';
        selectedCurrentChair = '';
      });
      return;
    }

    waitingClients.sort(
      (a, b) => _getQueueOrder(a).compareTo(_getQueueOrder(b)),
    );

    final nextClient = waitingClients.first;
    final nextKey = nextClient['firebaseKey']?.toString() ?? '';
    if (nextKey.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    await queueRef.child(nextKey).update({
      'status': 'current',
      'updatedAt': now,
      'notificationStatus': 'current',
    });

    if (!mounted) return;
    setState(() {
      currentPreviewClientId = nextKey;
      selectedCurrentBarber = _clientBarberName(nextClient);
      selectedCurrentChair = nextClient['chair']?.toString() ?? '';
    });
  }

  Future<void> _saveBarberAndChair(
    Map<String, dynamic> item,
    String barber,
    String chair,
  ) async {
    final key = item['firebaseKey']?.toString() ?? '';
    if (key.isEmpty) return;

    final selectedBarberMap = salonBarbers.firstWhere(
      (b) => _barberName(b) == barber || b['name']?.toString() == barber,
      orElse: () => {},
    );

    final now = DateTime.now().millisecondsSinceEpoch;

    await queueRef.child(key).update({
      'barber': barber,
      'barberName': barber,
      'barberNameAr': selectedBarberMap['nameAr'] ?? barber,
      'barberNameEn': selectedBarberMap['nameEn'] ?? barber,
      'chair': chair,
      'updatedAt': now,
    });

    showMessage(t('barber_chair_saved'));
  }

  Future<void> _updatePaidAmount(Map<String, dynamic> item, int paid) async {
    final key = item['firebaseKey']?.toString() ?? '';
    if (key.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    await queueRef.child(key).update({
      'paid': paid,
      'updatedAt': now,
    });

    showMessage(t('paid_amount_saved'));
  }

  Future<void> _awardPointsForCompletedService(Map<String, dynamic> item) async {
    final userId = item['userId']?.toString() ?? '';
    final isGuest = item['isGuest'] == true;
    final pointsEligible = item['pointsEligible'] == true;

    if (userId.isEmpty || isGuest || !pointsEligible) return;

    await _cleanupExpiredPoints(userId);

    final paid = _toInt(item['paid']);
    final finalTotal = _toInt(item['finalTotal']);
    final amountBase = paid > 0 ? paid : finalTotal;

    if (amountBase <= 0) return;

    final earnedPoints = amountBase ~/ 20;
    if (earnedPoints <= 0) return;

    final userRef = rootRef.child('users').child(userId);
    final snapshot = await userRef.get();

    if (!snapshot.exists || snapshot.value == null) return;

    final userData = Map<dynamic, dynamic>.from(snapshot.value as Map);
    final currentPoints = _toInt(userData['points']);

    final now = DateTime.now();
    final expiresAt =
        DateTime(now.year, now.month + 3, now.day).millisecondsSinceEpoch;

    final currentHistoryRaw = userData['pointsHistory'];
    final List<dynamic> history =
        currentHistoryRaw is List ? List<dynamic>.from(currentHistoryRaw) : <dynamic>[];

    history.add({
      'earnedPoints': earnedPoints,
      'remainingPoints': earnedPoints,
      'earnedAt': now.millisecondsSinceEpoch,
      'expiresAt': expiresAt,
      'source': 'service_done',
      'bookingId': item['bookingId']?.toString() ?? '',
      'queueEntryId': item['firebaseKey']?.toString() ?? '',
    });

    await userRef.update({
      'points': currentPoints + earnedPoints,
      'pointsHistory': history,
      'updatedAt': ServerValue.timestamp,
    });

    final transactionRef = rootRef.child('pointsTransactions').push();

    await transactionRef.set({
      'type': 'earn',
      'userId': userId,
      'salonId': widget.salonId,
      'points': earnedPoints,
      'moneyValue': amountBase,
      'source': 'service_done',
      'bookingId': item['bookingId']?.toString() ?? '',
      'queueEntryId': item['firebaseKey']?.toString() ?? '',
      'createdAt': ServerValue.timestamp,
      'expiresAt': expiresAt,
    });
  }

  Future<void> _cleanupExpiredPoints(String userId) async {
    if (userId.isEmpty) return;

    final userRef = rootRef.child('users').child(userId);
    final snapshot = await userRef.get();

    if (!snapshot.exists || snapshot.value == null) return;

    final userData = Map<dynamic, dynamic>.from(snapshot.value as Map);
    final currentHistoryRaw = userData['pointsHistory'];

    final List<dynamic> history =
        currentHistoryRaw is List ? List<dynamic>.from(currentHistoryRaw) : <dynamic>[];

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final List<Map<String, dynamic>> validHistory = [];
    int totalRemainingPoints = 0;

    for (final entry in history) {
      if (entry is Map) {
        final item = Map<String, dynamic>.from(entry);
        final expiresAt = _toInt(item['expiresAt']);
        final remainingPoints = _toInt(item['remainingPoints']);

        if (remainingPoints <= 0) continue;
        if (expiresAt != 0 && expiresAt < nowMs) continue;

        validHistory.add(item);
        totalRemainingPoints += remainingPoints;
      }
    }

    await userRef.update({
      'pointsHistory': validHistory,
      'points': totalRemainingPoints,
      'updatedAt': ServerValue.timestamp,
    });
  }

Future<void> _changeStatus(Map<String, dynamic> item, String status) async {
  final key = item['firebaseKey']?.toString() ?? '';
  if (key.isEmpty) return;

  final now = DateTime.now().millisecondsSinceEpoch;

  if (status == 'postponed') {
    final snapshot = await queueRef.get();
    int minOrder = now;

    if (snapshot.exists && snapshot.value != null) {
      final raw = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final orders = <int>[];

      for (final entry in raw.entries) {
        if (entry.value is Map) {
          final data = Map<String, dynamic>.from(entry.value as Map);
          if (data['salonId']?.toString() != widget.salonId) continue;

          final itemStatus = data['status']?.toString() ?? '';
          if (itemStatus == 'waiting' || itemStatus == 'current') {
            orders.add(_getQueueOrder(data));
          }
        }
      }

      if (orders.isNotEmpty) {
        orders.sort();
        minOrder = orders.first - 1;
      }
    }

    await queueRef.child(key).update({
      'status': 'waiting',
      'queueOrder': minOrder,
      'updatedAt': now,
      'notificationStatus': 'postponed',
    });

    if (currentPreviewClientId == key && mounted) {
      setState(() {
        currentPreviewClientId = null;
        selectedCurrentBarber = '';
        selectedCurrentChair = '';
      });
    }

    await _activateNextClient(excludeKey: key);
    showMessage(t('client_postponed'));
    return;
  }

  await queueRef.child(key).update({
    'status': status,
    'updatedAt': now,
    'notificationStatus': status,
    if (status == 'done') 'finishedAt': now,
    'canRate': status == 'done',
  });

  final bookingId = item['bookingId']?.toString() ?? '';

  if (bookingId.isNotEmpty) {
    await bookingsRef.child(bookingId).update({
      'status': status,
      'updatedAt': now,
      if (status == 'done') 'finishedAt': now,
    });
  }

  if (status == 'done') {
    final freshSnapshot = await queueRef.child(key).get();
    ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('التقييم بقى متاح دلوقتي'),
  ),
);

    Map<String, dynamic> freshItem = Map<String, dynamic>.from(item);

    if (freshSnapshot.exists && freshSnapshot.value != null) {
      freshItem = Map<String, dynamic>.from(freshSnapshot.value as Map);
      freshItem['firebaseKey'] = key;     
    }
    await queueRef.child(key).update({
  'needsRating': true,
});
await rootRef.child('ratingRequests').child(key).set({
  'salonId': widget.salonId,
  'userId': freshItem['userId']?.toString() ?? '',
  'bookingId': freshItem['bookingId']?.toString() ?? '',
  'queueEntryId': key,
  'canRate': true,
  'createdAt': now,
});

    if (freshItem['pointsProcessed'] == true) {
      showMessage(t('client_done'));
      return;
    }

    final userId = freshItem['userId']?.toString() ?? '';
    final isGuest = freshItem['isGuest'] == true;

    final appliedDiscountType =
        freshItem['appliedDiscountType']?.toString() ?? '';

    final bool usedPointsDiscount =
        appliedDiscountType == 'points' || freshItem['usePoints'] == true;

   if (userId.isNotEmpty && !isGuest) {
  

      final userRef = rootRef.child('users').child(userId);
      final snapshot = await userRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        final currentPoints = _toInt(data['points']);

        final int discount = _toInt(freshItem['discount']);
        final int finalTotal = _toInt(freshItem['finalTotal']);

        final int usedPoints = usedPointsDiscount ? discount * 4 : 0;
        final int pointsEarned = (finalTotal * 0.10).floor();

        final int newPoints =
            (currentPoints - usedPoints + pointsEarned).clamp(0, 999999);

        await userRef.update({
          'points': newPoints,
          'updatedAt': ServerValue.timestamp,
        });

        final transactionRef = rootRef.child('pointsTransactions').push();

        await transactionRef.set({
          'type': 'complete_service',
          'userId': userId,
          'salonId': widget.salonId,
          'pointsUsed': usedPoints,
          'pointsEarned': pointsEarned,
          'discount': discount,
          'finalTotal': finalTotal,
          'bookingId': freshItem['bookingId']?.toString() ?? '',
          'queueEntryId': key,
          'createdAt': ServerValue.timestamp,
        });
      }
    }

    if (userId.isNotEmpty && appliedDiscountType == 'welcome') {
      await rootRef.child('users').child(userId).update({
        'welcomeDiscountUsed': true,
        'updatedAt': ServerValue.timestamp,
      });
    }

    await queueRef.child(key).update({
      'pointsProcessed': true,
      'pointsProcessedAt': now,
    });

    if (bookingId.isNotEmpty) {
      await bookingsRef.child(bookingId).update({
        'pointsProcessed': true,
        'pointsProcessedAt': now,
      });
    }
  }

  if (currentPreviewClientId == key && mounted) {
    setState(() {
      currentPreviewClientId = null;
      selectedCurrentBarber = '';
      selectedCurrentChair = '';
    });
  }

  await _activateNextClient(excludeKey: key);

  if (status == 'done') showMessage(t('client_done'));
  if (status == 'cancelled') showMessage(t('client_cancelled'));
}

  Future<void> _removeServiceFromClient(
    Map<String, dynamic> item,
    Map<String, dynamic> service,
  ) async {
    final key = item['firebaseKey']?.toString() ?? '';
    if (key.isEmpty) return;

    final currentServices = List<Map<String, dynamic>>.from(
      (item['services'] ?? []).map((e) => Map<String, dynamic>.from(e)),
    );

    currentServices.removeWhere(
      (s) => s['id']?.toString() == service['id']?.toString(),
    );

    final subtotal =
        currentServices.fold<int>(0, (sum, s) => sum + _toInt(s['price']));

    final discount = _toInt(item['discount']);
    final finalTotal = subtotal - discount < 0 ? 0 : subtotal - discount;
    final expectedPoints = item['pointsEligible'] == false
    ? 0
    : (finalTotal * 0.10).floor();
    final now = DateTime.now().millisecondsSinceEpoch;

    await queueRef.child(key).update({
      'services': currentServices,
      'servicesCount': currentServices.length,
      'totalDuration':
          currentServices.fold<int>(0, (sum, s) => sum + _toInt(s['duration'])),
      'subtotal': subtotal,
      'finalTotal': finalTotal,
      'expectedPoints': expectedPoints,
      'updatedAt': now,
    });

    showMessage(t('service_removed'));
  }

  Future<void> _sendWhatsapp(Map<String, dynamic> item) async {
    if (salonWhatsapp.trim().isEmpty) {
      showMessage(t('salon_whatsapp_not_available'));
      return;
    }

    try {
      final clientName = item['name']?.toString() ?? '';
      final clientPhone = item['phone']?.toString() ?? '';
      final number = _normalizeWhatsappPhone(salonWhatsapp);

      final message = Uri.encodeComponent(
        '${t('your_turn_has_arrived')}\n'
        '${t('name')}: $clientName\n'
        '${t('phone')}: $clientPhone\n'
        '${t('salon')}: $salonName',
      );

      final whatsappUri = Uri.parse('https://wa.me/$number?text=$message');

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        showMessage(t('cannot_open_whatsapp'));
      }
    } catch (_) {
      showMessage(t('cannot_open_whatsapp'));
    }
  }

  Future<void> _showAddServiceSheet(Map<String, dynamic> item) async {
    if (salonServices.isEmpty) {
      showMessage(t('no_services'));
      return;
    }

    final currentServices = List<Map<String, dynamic>>.from(
      (item['services'] ?? []).map((e) => Map<String, dynamic>.from(e)),
    );

    selectedServiceIds.clear();

    for (final service in currentServices) {
      final id = service['id']?.toString() ?? '';
      if (id.isNotEmpty) selectedServiceIds.add(id);
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Directionality(
              textDirection:
                  currentLang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.20),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t('add_service'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 420),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: salonServices.length,
                          separatorBuilder: (context, index) =>
                           const SizedBox(height: 10),                          
                          itemBuilder: (context, index) {
                            final service = salonServices[index];
                            final serviceId = service['id']?.toString() ?? '';
                            final isSelected =
                                selectedServiceIds.contains(serviceId);

                            return InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                setModalState(() {
                                  if (isSelected) {
                                    selectedServiceIds.remove(serviceId);
                                  } else {
                                    selectedServiceIds.add(serviceId);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: fieldColor,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected ? blueColor : borderColor,
                                    width: isSelected ? 1.4 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      activeColor: greenColor,
                                      onChanged: (value) {
                                        setModalState(() {
                                          if (value == true) {
                                            selectedServiceIds.add(serviceId);
                                          } else {
                                            selectedServiceIds.remove(serviceId);
                                          }
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: currentLang == 'ar'
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _serviceName(service),
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${_toInt(service['duration'])} ${t('minutes')} - ${_toInt(service['price'])} ${t('currency_egp')}',
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
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final selectedServices =
                                salonServices.where((service) {
                              final id = service['id']?.toString() ?? '';
                              return selectedServiceIds.contains(id);
                            }).toList();

                            if (selectedServices.isEmpty) {
                              showMessage(t('choose_at_least_one_service'));
                              return;
                            }

                            final updatedServices =
                                selectedServices.map((service) {
                              return {
                                'id': service['id'],
                                'name': _serviceName(service),
                                'nameAr':
                                    service['nameAr'] ?? service['name'] ?? '',
                                'nameEn':
                                    service['nameEn'] ?? service['name'] ?? '',
                                'price': _toInt(service['price']),
                                'duration': _toInt(service['duration']),
                              };
                            }).toList();

                            final subtotal = updatedServices.fold<int>(
                              0,
                              (sum, s) => sum + _toInt(s['price']),
                            );

                            final discount = _toInt(item['discount']);
                            final finalTotal =
                                subtotal - discount < 0 ? 0 : subtotal - discount;

                            final expectedPoints = item['pointsEligible'] == false
                              ? 0
                              : (finalTotal * 0.10).floor();

                            final totalDuration = updatedServices.fold<int>(
                              0,
                              (sum, s) => sum + _toInt(s['duration']),
                            );

                            final key = item['firebaseKey']?.toString() ?? '';
                            if (key.isEmpty) return;

                            final now = DateTime.now().millisecondsSinceEpoch;

                            await queueRef.child(key).update({
                              'services': updatedServices,
                              'servicesCount': updatedServices.length,
                              'totalDuration': totalDuration,
                              'subtotal': subtotal,
                              'finalTotal': finalTotal,
                              'expectedPoints': expectedPoints,
                              'updatedAt': now,
                            });

                            if (!mounted) return;
                            Navigator.pop(context);
                            showMessage(t('selected_services_saved'));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: purpleColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            t('save_selected_services'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _extractTodayQueue(DatabaseEvent event) {
    List<Map<String, dynamic>> all = [];

    if (event.snapshot.value != null) {
      final raw = event.snapshot.value;

      if (raw is Map) {
        final map = Map<dynamic, dynamic>.from(raw);

        all = map.entries.map((entry) {
          final dynamic value = entry.value;

          if (value is Map) {
            final item = Map<String, dynamic>.from(value);
            item['firebaseKey'] = entry.key.toString();
            return item;
          }

          return <String, dynamic>{};
        }).where((item) {
          if (item.isEmpty) return false;
          if (item['salonId']?.toString() != widget.salonId) return false;

          final createdAt = _toInt(item['createdAt']);
          final updatedAt = _toInt(item['updatedAt']);
          final bookingDate = _toInt(item['bookingDate']);
          final stamp = bookingDate != 0
              ? bookingDate
              : (updatedAt != 0 ? updatedAt : createdAt);

          return _isToday(stamp);
        }).toList();

        all.sort((a, b) => _getQueueOrder(a).compareTo(_getQueueOrder(b)));
      }
    }

    return all;
  }

  List<Map<String, dynamic>> _extractTodayScheduledBookings(
    DatabaseEvent event,
  ) {
    List<Map<String, dynamic>> all = [];

    if (event.snapshot.value != null) {
      final raw = event.snapshot.value;

      if (raw is Map) {
        final map = Map<dynamic, dynamic>.from(raw);

        all = map.entries.map((entry) {
          final dynamic value = entry.value;

          if (value is Map) {
            final item = Map<String, dynamic>.from(value);
            item['firebaseKey'] = entry.key.toString();
            return item;
          }

          return <String, dynamic>{};
        }).where((item) {
          if (item.isEmpty) return false;

          final bookingType = item['bookingType']?.toString() ?? '';
          final enteredQueue = item['enteredQueue'] == true;
          final status = item['status']?.toString() ?? '';
          final bookingDate = _toInt(item['bookingDate']);

          if (bookingType != 'later') return false;
          if (enteredQueue) return false;
          if (status == 'done' || status == 'cancelled') return false;
          if (!_isToday(bookingDate)) return false;

          return true;
        }).toList();

        all.sort((a, b) {
          final aDate = _toInt(a['bookingDate']);
          final bDate = _toInt(b['bookingDate']);
          return aDate.compareTo(bDate);
        });
      }
    }

    return all;
  }

  Map<String, dynamic> _getCurrentClient(List<Map<String, dynamic>> todayQueue) {
    if (currentPreviewClientId != null) {
      final found = todayQueue.where(
        (e) => e['firebaseKey'] == currentPreviewClientId,
      );

      if (found.isNotEmpty) return found.first;
    }

    final currentList =
        todayQueue.where((e) => e['status']?.toString() == 'current').toList();

    if (currentList.isNotEmpty) return currentList.last;

    final waitingList =
        todayQueue.where((e) => e['status']?.toString() == 'waiting').toList();

    if (waitingList.isNotEmpty) return waitingList.first;

    return {};
  }

  Widget _buildTopHeader() {
    return _premiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              salonName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 29,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            t('queue_system'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t('queue_system_subtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subTextColor,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleLang,
                  icon: const Icon(Icons.translate_rounded),
                  label: Text(currentLang == 'ar' ? 'EN' : 'AR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20365F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminPage(salonId: widget.salonId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(
                    t('back_to_admin'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blueColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddClientCard() {
    final isArabic = currentLang == 'ar';

    return _premiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(
            icon: Icons.person_add_alt_1_rounded,
            title: t('add_client_to_queue'),
            subtitle: t('add_client_to_queue_hint'),
            color: greenColor,
          ),
          const SizedBox(height: 20),
          Text(
            t('name'),
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: manualNameController,
            style: TextStyle(color: textColor),
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            decoration: _inputDecoration(t('client_name')),
          ),
          const SizedBox(height: 16),
          Text(
            t('phone'),
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: manualPhoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: textColor),
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            decoration: _inputDecoration('015xxxxxxxx'),
          ),
          const SizedBox(height: 10),
          Text(
            t('phone_must_start_01'),
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            style: TextStyle(color: subTextColor, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _addManualClient,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: Text(
              t('add_to_queue'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: greenColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    final isArabic = currentLang == 'ar';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value.isEmpty ? '--' : value,
              textAlign: isArabic ? TextAlign.left : TextAlign.right,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: subTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayBookingsCard(List<Map<String, dynamic>> todayBookings) {
    return _premiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(
            icon: Icons.event_available_rounded,
            title: t('today_bookings'),
            subtitle: t('today_bookings_hint'),
            color: blueColor,
          ),
          const SizedBox(height: 18),
          if (todayBookings.isEmpty)
            _emptyBox(t('no_scheduled_bookings_today'))
          else
            ...todayBookings.map((booking) {
              final bookingTime = booking['bookingTime'];
              String timeText = '';

              if (bookingTime is Map) {
                final timeMap = Map<dynamic, dynamic>.from(bookingTime);
                final hour = _toInt(timeMap['hour']);
                final minute = _toInt(timeMap['minute']);
                timeText =
                    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: fieldColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _statusBadge(
                          text: timeText.isEmpty ? '--:--' : timeText,
                          color: blueColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: currentLang == 'ar'
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking['name']?.toString() ?? '',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                booking['phone']?.toString() ?? '',
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _addScheduledBookingToQueue(booking),
                        icon: const Icon(
                          Icons.playlist_add_check_circle_outlined,
                        ),
                        label: Text(
                          t('add_to_queue'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blueColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCurrentClientCard(Map<String, dynamic> currentClient) {
    final isArabic = currentLang == 'ar';

    if (currentClient.isEmpty) {
      return _premiumCard(
        child: Column(
          children: [
            _sectionTitle(
              icon: Icons.person_pin_circle_rounded,
              title: t('current_client'),
              subtitle: t('current_client_hint'),
              color: blueColor,
            ),
            const SizedBox(height: 20),
            _emptyBox(t('no_current_client_now')),
          ],
        ),
      );
    }

    final clientServices = List<Map<String, dynamic>>.from(
      (currentClient['services'] ?? []).map((e) => Map<String, dynamic>.from(e)),
    );

    if (selectedCurrentBarber.isEmpty) {
      selectedCurrentBarber = _clientBarberName(currentClient);
    }

    if (selectedCurrentChair.isEmpty) {
      selectedCurrentChair = currentClient['chair']?.toString() ?? '';
    }

    final currentPaid = _toInt(currentClient['paid']);
    if (paidAmountController.text.isEmpty && currentPaid > 0) {
      paidAmountController.text = currentPaid.toString();
    }

    return _premiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(
            icon: Icons.person_pin_circle_rounded,
            title: t('current_client'),
            subtitle: t('current_client_hint'),
            color: blueColor,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: fieldColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: blueColor.withOpacity(0.28)),
            ),
            child: Column(
              children: [
                Text(
                  currentClient['name']?.toString() ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentClient['phone']?.toString() ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: subTextColor, fontSize: 16),
                ),
                const SizedBox(height: 14),
                _statusBadge(text: t('current'), color: blueColor),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _dropdownBox(
                  title: t('chair'),
                  hint: t('choose_chair'),
                  value: selectedCurrentChair.isNotEmpty
                      ? selectedCurrentChair
                      : null,
                  items: salonChairs
                      .map((chair) => chair['name']?.toString() ?? '')
                      .where((name) => name.isNotEmpty)
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCurrentChair = value ?? '';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dropdownBox(
                  title: t('barber'),
                  hint: t('choose_barber'),
                  value: selectedCurrentBarber.isNotEmpty
                      ? selectedCurrentBarber
                      : null,
                  items: salonBarbers.map(_barberName).where((name) {
                    return name.isNotEmpty;
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCurrentBarber = value ?? '';
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await _saveBarberAndChair(
                currentClient,
                selectedCurrentBarber,
                selectedCurrentChair,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: blueColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              t('save_barber_chair'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => _showAddServiceSheet(currentClient),
            style: ElevatedButton.styleFrom(
              backgroundColor: purpleColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              t('add_service'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: paidAmountController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: textColor),
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            decoration: _inputDecoration(t('paid_amount_actual')),
            onSubmitted: (value) async {
              await _updatePaidAmount(currentClient, _toInt(value));
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  text: t('done'),
                  color: greenColor,
                  onTap: () async {
                    final paid = paidAmountController.text.trim().isEmpty
                        ? 0
                        : _toInt(paidAmountController.text);

                    await _updatePaidAmount(currentClient, paid);
                    await _changeStatus(currentClient, 'done');
                    paidAmountController.clear();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  text: t('postponed'),
                  color: orangeColor,
                  onTap: () => _changeStatus(currentClient, 'postponed'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  text: t('cancelled'),
                  color: redColor,
                  onTap: () => _changeStatus(currentClient, 'cancelled'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => _sendWhatsapp(currentClient),
            icon: const Icon(Icons.message_rounded, size: 18),
            label: Text(
              t('send_whatsapp_turn'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: greenColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildClientSummary(currentClient, clientServices),
        ],
      ),
    );
  }

  Widget _buildClientSummary(
    Map<String, dynamic> currentClient,
    List<Map<String, dynamic>> clientServices,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t('client_summary'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _summaryRow(t('name'), currentClient['name']?.toString() ?? ''),
          _summaryRow(t('phone'), currentClient['phone']?.toString() ?? ''),
          _summaryRow(t('barber'), selectedCurrentBarber),
          _summaryRow(t('chair'), selectedCurrentChair),
          _summaryRow(
            t('price_before_discount'),
            '${_toInt(currentClient['subtotal'])} ${t('currency_egp')}',
          ),
          _summaryRow(
            t('discount'),
            '${_toInt(currentClient['discount'])} ${t('currency_egp')}',
          ),
          _summaryRow(
            t('total_after_discount'),
            '${_toInt(currentClient['finalTotal'])} ${t('currency_egp')}',
          ),
          _summaryRow(
            t('paid_amount_actual'),
            '${_toInt(currentClient['paid'])} ${t('currency_egp')}',
          ),
          _summaryRow(
            t('expected_points'),
            '${_toInt(currentClient['expectedPoints'])} ${t('points')}',
          ),
          const SizedBox(height: 16),
          Text(
            t('services'),
            textAlign: currentLang == 'ar' ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 10),
          if (clientServices.isEmpty)
            Text(
              t('no_services'),
              textAlign: currentLang == 'ar' ? TextAlign.right : TextAlign.left,
              style: TextStyle(color: subTextColor, fontSize: 15),
            )
          else
            ...clientServices.map((service) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          _removeServiceFromClient(currentClient, service),
                      icon: Icon(
                        Icons.delete_outline,
                        color: redColor,
                        size: 22,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${_queueServiceName(service)} - ${_toInt(service['price'])} ${t('currency_egp')}',
                        textAlign: currentLang == 'ar'
                            ? TextAlign.right
                            : TextAlign.left,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _queueItemCard(Map<String, dynamic> item, int index) {
    final status = item['status']?.toString() ?? 'waiting';
    final isCurrent = status == 'current';

    String statusText = t('waiting');
    if (status == 'current') statusText = t('current');
    if (status == 'cancelled') statusText = t('cancelled');

    Color statusColor = subTextColor;
    if (status == 'current') statusColor = blueColor;
    if (status == 'cancelled') statusColor = redColor;

    String timeText = '';
    final bookingTime = item['bookingTime'];

    if (bookingTime is Map) {
      final timeMap = Map<dynamic, dynamic>.from(bookingTime);
      final hour = _toInt(timeMap['hour']);
      final minute = _toInt(timeMap['minute']);
      timeText =
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }

    return GestureDetector(
      onTap: () => _makeCurrent(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: fieldColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCurrent ? blueColor : borderColor,
            width: isCurrent ? 1.5 : 1,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: blueColor.withOpacity(0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? blueColor.withOpacity(0.16)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isCurrent ? blueColor : textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: currentLang == 'ar'
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name']?.toString() ?? '',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['phone']?.toString() ?? '',
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 14,
                        ),
                      ),
                      if (timeText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '⏰ $timeText',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: currentLang == 'ar'
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: _statusBadge(text: statusText, color: statusColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueList(List<Map<String, dynamic>> waitingClients) {
    return _premiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(
            icon: Icons.format_list_numbered_rounded,
            title: t('queue_list'),
            subtitle: t('queue_list_hint'),
            color: orangeColor,
          ),
          const SizedBox(height: 18),
          if (waitingClients.isEmpty)
            _emptyBox(t('no_clients_in_queue_today'))
          else
            ...waitingClients.asMap().entries.map(
                  (entry) => _queueItemCard(entry.value, entry.key),
                ),
        ],
      ),
    );
  }

  Widget _buildFinishedClients(List<Map<String, dynamic>> finishedClients) {
    return _premiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(
            icon: Icons.done_all_rounded,
            title: t('finished_clients_today'),
            subtitle: t('finished_clients_hint'),
            color: greenColor,
          ),
          const SizedBox(height: 18),
          if (finishedClients.isEmpty)
            _emptyBox(t('no_finished_clients_today'))
          else
            ...finishedClients.take(10).map((item) {
              final paid = _toInt(item['paid']) == 0
                  ? _toInt(item['finalTotal'])
                  : _toInt(item['paid']);

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: fieldColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: currentLang == 'ar'
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _statusBadge(text: t('done'), color: greenColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item['name']?.toString() ?? '',
                            textAlign: currentLang == 'ar'
                                ? TextAlign.right
                                : TextAlign.left,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${t('barber')}: ${_clientBarberName(item)}',
                      style: TextStyle(color: subTextColor, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${t('price_before_discount')}: ${_toInt(item['subtotal'])} ${t('currency_egp')}',
                      style: TextStyle(color: subTextColor, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${t('total_after_discount')}: ${_toInt(item['finalTotal'])} ${t('currency_egp')}',
                      style: TextStyle(color: subTextColor, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${t('paid_amount_actual')}: $paid ${t('currency_egp')}',
                      style: TextStyle(
                        color: greenColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: subTextColor,
          fontWeight: FontWeight.w600,
          fontSize: 16,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _statusBadge({
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }

  Widget _dropdownBox({
    required String title,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: currentLang == 'ar'
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: fieldColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor.withOpacity(0.7)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value != null && items.contains(value) ? value : null,
              dropdownColor: const Color(0xFF13233A),
              isExpanded: true,
              hint: Text(
                hint,
                style: TextStyle(color: subTextColor),
              ),
              style: TextStyle(color: textColor),
              items: items.map((name) {
                return DropdownMenuItem<String>(
                  value: name,
                  child: Text(name),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = currentLang == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: StreamBuilder<DatabaseEvent>(
            stream: queueRef.onValue,
            builder: (context, queueSnapshot) {
              return StreamBuilder<DatabaseEvent>(
                stream: bookingsRef.onValue,
                builder: (context, bookingsSnapshot) {
                  final todayQueue = queueSnapshot.hasData
                      ? _extractTodayQueue(queueSnapshot.data!)
                      : <Map<String, dynamic>>[];

                  final todayBookings = bookingsSnapshot.hasData
                      ? _extractTodayScheduledBookings(bookingsSnapshot.data!)
                      : <Map<String, dynamic>>[];

                  final currentClient = _getCurrentClient(todayQueue);

                  final waitingClients = todayQueue.where((e) {
                    final status = e['status']?.toString() ?? '';
                    return status == 'waiting' || status == 'current';
                  }).toList();

                  final finishedClients = todayQueue
                      .where((e) => e['status']?.toString() == 'done')
                      .toList()
                      .reversed
                      .toList();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _buildTopHeader(),
                        const SizedBox(height: 22),
                        _buildAddClientCard(),
                        const SizedBox(height: 22),
                        _buildTodayBookingsCard(todayBookings),
                        const SizedBox(height: 22),
                        _buildCurrentClientCard(currentClient),
                        const SizedBox(height: 22),
                        _buildQueueList(waitingClients),
                        const SizedBox(height: 22),
                        _buildFinishedClients(finishedClients),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}