class QueueModel {
  final String id;
  final String name;
  final String phone;
  final String status;
  final String barber;
  final String chair;
  final int total;
  final int paid;

  QueueModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    required this.barber,
    required this.chair,
    required this.total,
    required this.paid,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'status': status,
      'barber': barber,
      'chair': chair,
      'total': total,
      'paid': paid,
    };
  }

  factory QueueModel.fromMap(Map<String, dynamic> map) {
    return QueueModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      status: map['status'] ?? 'waiting',
      barber: map['barber'] ?? '',
      chair: map['chair'] ?? '',
      total: map['total'] ?? 0,
      paid: map['paid'] ?? 0,
    );
  }
}