import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_translations.dart';

class TrackQueuePage extends StatefulWidget {
  final String salonId;
  final String userId;

  const TrackQueuePage({
    super.key,
    required this.salonId,
    required this.userId,
  });

  @override
  State<TrackQueuePage> createState() => _TrackQueuePageState();
}

class _TrackQueuePageState extends State<TrackQueuePage> {
  bool wasInQueue = false;
  bool ratingDialogShown = false;
  Map<String, dynamic>? lastQueueItemForRating;
  String currentLang = 'ar';

  final DatabaseReference queueRef =
      FirebaseDatabase.instance.ref().child('queue');

  final Color bgColor = const Color(0xFF07111F);
  final Color cardColor = const Color(0xCC101C2E);
  final Color fieldColor = const Color(0xCC13233A);
  final Color borderColor = const Color(0x552B3D57);
  final Color greenColor = const Color(0xFF22C55E);
  final Color blueColor = const Color(0xFF4A86F7);
  final Color orangeColor = const Color(0xFFF59E0B);
  final Color textColor = Colors.white;
  final Color subTextColor = const Color(0xFFB8C4D6);

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

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  bool _isToday(int timestamp) {
    if (timestamp == 0) return false;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  int _getQueueOrder(Map<String, dynamic> item) {
    final queueOrder = _toInt(item['queueOrder']);
    if (queueOrder != 0) return queueOrder;
    return _toInt(item['createdAt']);
  }

  int _estimateMinutesForItem(Map<String, dynamic> item) {
    final totalDuration = _toInt(item['totalDuration']);
    if (totalDuration > 0) return totalDuration;

    final services = item['services'];
    if (services is List) {
      int sum = 0;
      for (final service in services) {
        if (service is Map) {
          sum += _toInt(service['duration']);
        }
      }
      if (sum > 0) return sum;
    }

    return 20;
  }

  List<Map<String, dynamic>> _extractActiveTodayQueue(DatabaseEvent event) {
    final activeItems = <Map<String, dynamic>>[];

    final raw = event.snapshot.value;
    if (raw == null || raw is! Map) return activeItems;

    final map = Map<dynamic, dynamic>.from(raw);

    for (final entry in map.entries) {
      if (entry.value is! Map) continue;

      final item = Map<String, dynamic>.from(entry.value);
      item['firebaseKey'] = entry.key.toString();

      if (item['salonId'] != widget.salonId) continue;

      final status = item['status'];
     if (status != 'waiting' && status != 'current' && status != 'done') continue;

      final stamp = _toInt(item['bookingDate']) != 0
          ? _toInt(item['bookingDate'])
          : _toInt(item['createdAt']);

      if (!_isToday(stamp)) continue;

      activeItems.add(item);
    }

    activeItems.sort((a, b) => _getQueueOrder(a).compareTo(_getQueueOrder(b)));
    return activeItems;
  }

  Widget _buildCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return _buildCard(
      Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign:
                  currentLang == 'ar' ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: subTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return _buildCard(
      Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: subTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralMode(List<Map<String, dynamic>> activeQueue) {
    final totalClients = activeQueue.length;
    final estimatedMinutes = activeQueue.fold<int>(
      0,
      (sum, item) => sum + _estimateMinutesForItem(item),
    );

    return Column(
      children: [
        _buildHeader(t('track_queue'), t('queue_status')),
        _buildInfoCard(
          title: t('clients_now'),
          value: '$totalClients',
          icon: Icons.people,
          color: blueColor,
        ),
        _buildInfoCard(
          title: t('estimated_time'),
          value: '$estimatedMinutes ${t('minutes')}',
          icon: Icons.timer,
          color: orangeColor,
        ),
      ],
    );
  }

  Widget _buildPersonalMode({
    required List<Map<String, dynamic>> activeQueue,
    required Map<String, dynamic> myItem,
  }) {
    final index = activeQueue.indexWhere(
      (e) => e['firebaseKey'] == myItem['firebaseKey'],
    );

    final clientsBefore = index <= 0 ? 0 : index;

    final minutes = activeQueue
        .take(index)
        .fold<int>(0, (sum, e) => sum + _estimateMinutesForItem(e));

    return Column(
      children: [
        _buildHeader(t('track_queue'), t('my_queue_status')),
        _buildInfoCard(
          title: t('clients_before_you'),
          value: '$clientsBefore',
          icon: Icons.format_list_numbered,
          color: blueColor,
        ),
        _buildInfoCard(
          title: t('estimated_time'),
          value: '$minutes ${t('minutes')}',
          icon: Icons.timer_outlined,
          color: orangeColor,
        ),
        _buildCard(
          Text(
            clientsBefore == 0 ? t('you_are_next') : t('queue_updates_live'),
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor),
          ),
        ),
      ],
    );
  }

  void showRatingDialog() {
    if (ratingDialogShown) return;
    ratingDialogShown = true;

    int selectedRating = 5;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(t('rate_your_experience')),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    onPressed: () => setState(() => selectedRating = i + 1),
                    icon: Icon(
                      Icons.star,
                      color: i < selectedRating ? Colors.amber : Colors.grey,
                    ),
                  );
                }),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseDatabase.instance
                    .ref()
                    .child('ratings')
                    .push()
                    .set({
                  'salonId': widget.salonId,
                  'userId': widget.userId,
                  'rating': selectedRating,
                  'createdAt': DateTime.now().millisecondsSinceEpoch,
                });

                Navigator.pop(context);
              },
              child: Text(t('done')),
            ),
          ],
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(t('track_queue')),
          actions: [
            IconButton(
              onPressed: toggleLang,
              icon: const Icon(Icons.translate),
            ),
          ],
        ),
        body: Stack(
          children: [
            Container(color: bgColor),
            StreamBuilder<DatabaseEvent>(
              stream: queueRef.onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: greenColor),
                  );
                }

                final activeQueue =
                    _extractActiveTodayQueue(snapshot.data!);

                final myItem = widget.userId.isEmpty
                    ? null
                    : activeQueue.firstWhere(
                        (e) => e['userId'] == widget.userId,
                        orElse: () => {},
                      );

               if (myItem != null) {
  wasInQueue = true;
  lastQueueItemForRating = myItem;
} else if (wasInQueue) {
  Future.microtask(showRatingDialog);
  wasInQueue = false;
}

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
             child: myItem != null
    ? _buildPersonalMode(
        activeQueue: activeQueue,
        myItem: myItem!,
      )
    : _buildGeneralMode(activeQueue),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}