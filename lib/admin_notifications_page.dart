import 'package:shared_preferences/shared_preferences.dart';
import 'app_translations.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:audioplayers/audioplayers.dart';

class AdminNotificationsPage extends StatefulWidget {
  final String salonId;

  const AdminNotificationsPage({
    super.key,
    required this.salonId,
  });

  @override
  State<AdminNotificationsPage> createState() =>
      _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  List<Map<dynamic, dynamic>> bookings = [];
  List<String> readNotifications = [];
  bool showUnreadOnly = false;
  final AudioPlayer notificationPlayer = AudioPlayer();

  String currentLang = 'ar';

@override
void initState() {
  super.initState();
  _loadLanguage();
}

Future<void> _loadLanguage() async {
  final prefs = await SharedPreferences.getInstance();

  if (!mounted) return;

  setState(() {
    currentLang = prefs.getString('lang') ?? 'ar';
  });
}

Future<void> _toggleLanguage() async {
  final prefs = await SharedPreferences.getInstance();
  final newLang = currentLang == 'ar' ? 'en' : 'ar';

  await prefs.setString('lang', newLang);

  if (!mounted) return;

  setState(() {
    currentLang = newLang;
  });
}

  @override
  void dispose() {
    notificationPlayer.dispose();
    super.dispose();
  }

String formatBookingDate(dynamic value) {
  if (value == null) return 'غير معروف';

  int? millis;

  if (value is int) {
    millis = value;
  } else if (value is double) {
    millis = value.toInt();
  } else if (value is String) {
    millis = int.tryParse(value);
    if (millis == null) return value;
  }

  if (millis == null) return 'غير معروف';

  final date = DateTime.fromMillisecondsSinceEpoch(millis);

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();

  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '$day/$month/$year - $hour:$minute';
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
       title: Text(tr('notifications', currentLang)),
        actions: [
          TextButton.icon(
  onPressed: _toggleLanguage,
  icon: const Icon(Icons.translate),
  label: Text(currentLang == 'ar' ? 'EN' : 'AR'),
),
          IconButton(
            icon: const Icon(Icons.delete),
          tooltip: tr('delete_all_notifications', currentLang),
            onPressed: () async {
              final ref = FirebaseDatabase.instance
                  .ref()
                  .child('salons')
                  .child(widget.salonId)
                  .child('bookings');
              await ref.remove();
            },
          ),
          IconButton(
            icon: Icon(
                showUnreadOnly ? Icons.mark_email_unread : Icons.mark_email_read),
            tooltip: showUnreadOnly ? 'عرض كل الإشعارات' : 'عرض الغير مقروءة',
            onPressed: () {
              setState(() {
                showUnreadOnly = !showUnreadOnly;
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance
            .ref()
            .child('salons')
            .child(widget.salonId)
            .child('bookings')
            .onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final value = snapshot.data?.snapshot.value;

          if (value == null) {
            return const Center(
              child: Text('لا توجد إشعارات حتى الآن'),
            );
          }

          final rawBookings = Map<dynamic, dynamic>.from(value as Map);
          final currentBookings = rawBookings.entries
              .where((entry) => entry.value is Map)
              .map((entry) => Map<dynamic, dynamic>.from(entry.value as Map))
              .toList();

          bookings = currentBookings;

          bookings.sort((a, b) {
            final aTime = int.tryParse(a['createdAt']?.toString() ?? '') ?? 0;
            final bTime = int.tryParse(b['createdAt']?.toString() ?? '') ?? 0;
            return bTime.compareTo(aTime);
          });

          List<Map<dynamic, dynamic>> displayedBookings = showUnreadOnly
              ? bookings.where((b) => !readNotifications.contains(b['id'])).toList()
              : bookings;

          if (displayedBookings.isEmpty) {
            return const Center(
              child: Text('لا توجد إشعارات حتى الآن'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: displayedBookings.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final booking = displayedBookings[index];
              final name = booking['name']?.toString().trim();
              final isUnread = !readNotifications.contains(booking['id']);

              return ListTile(
                leading: Icon(
                  Icons.notifications,
                  color: isUnread ? Colors.amber : null,
                ),
               title: Text(
  name == null || name.isEmpty
      ? tr('new_booking', currentLang)
      : "${tr('new_booking_from', currentLang)} $name",
                  style: TextStyle(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal),
                ),
subtitle: Text(
  '${tr('check_queue_booking_details', currentLang)}\n${tr('booking_date', currentLang)}: ${formatBookingDate(booking['createdAtDate'] ?? booking['createdAt'])}',
),
                onTap: () {
                  setState(() {
                    readNotifications.add(booking['id']);
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}