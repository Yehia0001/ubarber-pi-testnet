import 'package:firebase_database/firebase_database.dart';
import '../models/queue_model.dart';

class QueueService {
  final DatabaseReference queueRef = FirebaseDatabase.instance.ref('queue');

  Future<String?> addToQueue({
    required String salonId,
    required String name,
    required String phone,
  }) async {
    final newRef = queueRef.push();

    await newRef.set({
      'id': newRef.key,
      'salonId': salonId,
      'name': name,
      'phone': phone,
      'status': 'waiting',
      'barber': '',
      'chair': '',
      'total': 0,
      'paid': 0,
      'createdAt': ServerValue.timestamp,
      'updatedAt': ServerValue.timestamp,
    });

    return newRef.key;
  }

  Future<void> finishCustomer(String firebaseKey) async {
    await queueRef.child(firebaseKey).update({
      'status': 'done',
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<void> savePaid(String firebaseKey, int paid) async {
    await queueRef.child(firebaseKey).update({
      'paid': paid,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<void> setBarber(String firebaseKey, String barber) async {
    await queueRef.child(firebaseKey).update({
      'barber': barber,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<void> setChair(String firebaseKey, String chair) async {
    await queueRef.child(firebaseKey).update({
      'chair': chair,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Stream<List<QueueModel>> getQueue(String salonId) {
    return queueRef.onValue.map((event) {
      final data = event.snapshot.value;

      if (data == null || data is! Map) {
        return <QueueModel>[];
      }

      final map = Map<dynamic, dynamic>.from(data);
      final List<QueueModel> queueList = [];

      for (final entry in map.entries) {
        final value = entry.value;
        if (value is! Map) continue;

        final item = Map<String, dynamic>.from(value);

        if ((item['salonId']?.toString() ?? '') != salonId) {
          continue;
        }

        item['id'] = item['id']?.toString().isNotEmpty == true
            ? item['id'].toString()
            : entry.key.toString();

        queueList.add(QueueModel.fromMap(item));
      }

      return queueList;
    });
  }
}