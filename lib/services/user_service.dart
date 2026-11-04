import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class UserService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

Future<String> createUser(UserModel user) async {
  final newUser = _db.child("users").push();

  await newUser.set(user.toMap());

  return newUser.key!;
}
}