import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String? displayName;
  final String? email;
  final bool isEmailVerified;
  final bool isAnonymous;
  final String? phoneNumber;
  final String? photoURL;
  final String? refreshToken;
  final String uid;

  UserModel({
    this.displayName = "Anonyme",
    this.email = 'Anonyme@mail.com',
    this.isEmailVerified = false,
    this.isAnonymous = true,
    this.phoneNumber = '034834893485',
    this.photoURL =
        "https://geekflare.com/wp-content/plugins/wp-user-avatars/wp-user-avatars/assets/images/mystery.jpg",
    this.refreshToken = null,
    required this.uid,
  });

  // Convert UserModel to a JSON map
  static Map<String, dynamic> toJson(UserModel user) {
    return {
      'displayName': user.displayName,
      'email': user.email,
      'isEmailVerified': user.isEmailVerified,
      'isAnonymous': user.isAnonymous,
      'phoneNumber': user.phoneNumber,
      'photoURL': user.photoURL,
      'refreshToken': user.refreshToken,
      'uid': user.uid,
    };
  }
}

// Add user information to Firebase Firestore
Future<void> addUserToFirebase({required UserModel data}) async {
  try {
    await Firebase.initializeApp();

    CollectionReference usersCollection =
        FirebaseFirestore.instance.collection('users');

    // Convert UserModel to JSON
    Map<String, dynamic> userData = UserModel.toJson(data);

    // Add the JSON data to the Firestore collection
    await usersCollection.doc(data.uid).set(userData);
    print("add user complet");
    print('User data added to Firebase successfully');
    userDataall = data;
  } catch (e) {
    print('Error adding user data to Firebase: $e');
  }
}

late final UserModel userDataall;
