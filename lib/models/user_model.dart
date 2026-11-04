class UserModel {
  String name;
  String phone;
  String type;
  double rating;
  int points;
  int createdAt;

  UserModel({
    required this.name,
    required this.phone,
    required this.type,
    this.rating = 0.0,
    this.points = 0,
    this.createdAt = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "phone": phone,
      "type": type,
      "rating": rating,
      "points": points,
      "createdAt": createdAt,
    };
  }
}