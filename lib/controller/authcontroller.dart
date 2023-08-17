import 'package:firebase_auth/firebase_auth.dart';

import '../models/user.dart';

Future<void> createUserInFirebase(UserModel user) async {
  try {
    FirebaseAuth auth = FirebaseAuth.instance;
    await auth.createUserWithEmailAndPassword(
      email: user.email!,
      password: 'password', // You can set a default password here
    );

    // Update display name and photo URL
    User? firebaseUser = auth.currentUser;
    if (firebaseUser != null) {
      await firebaseUser.updateProfile(
          displayName: user.displayName, photoURL: user.photoURL);
    }

    // Send email verification if needed
    if (!user.isEmailVerified) {
      await firebaseUser!.sendEmailVerification();
    }
  } catch (e) {
    print('Error creating user: $e');
  }
}
