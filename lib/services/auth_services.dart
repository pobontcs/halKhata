import 'dart:io'; // Import this for File
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import Storage
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance; // Instance of Storage
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 1. GOOGLE SIGN IN
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return "User cancelled login";

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();

        if (!doc.exists) {
          await _db.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email ?? '',
            'name': user.displayName ?? 'Google User',
            'shop_name': 'My Shop',
            'phone': user.phoneNumber ?? '',
            'role': 'Manager',
            'photo_url': user.photoURL ?? '', // Save Google Photo URL
            'created_at': DateTime.now(),
          });
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An error occurred: $e";
    }
  }

  // 2. SIGN UP (Updated with Image Upload)
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String shopName,
    required String phone,
    required String role,
    File? imageFile, // <--- New Parameter
  }) async {
    try {
      // A. Check for duplicate Admin
      if (role == 'Admin') {
        final QuerySnapshot result = await _db
            .collection('users')
            .where('shop_name', isEqualTo: shopName)
            .where('role', isEqualTo: 'Admin')
            .get();
        if (result.docs.isNotEmpty) return "Validation Error: Admin already exists.";
      }

      // B. Create Auth User
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );

      String? photoUrl = "";

      // C. Upload Image if provided
      if (imageFile != null) {
        try {
          // 1. Create a reference: profile_images/USER_ID.jpg
          Reference ref = _storage.ref().child('profile_images/${result.user!.uid}.jpg');

          // 2. Upload the file
          await ref.putFile(imageFile);

          // 3. Get the URL
          photoUrl = await ref.getDownloadURL();
        } catch (e) {
          print("Image upload failed: $e");
          // We continue signing up even if image fails, just with empty URL
        }
      }

      // D. Save to Database
      await _db.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'name': name,
        'email': email,
        'shop_name': shopName,
        'phone': phone,
        'role': role,
        'photo_url': photoUrl, // <--- Saving the URL here
        'created_at': DateTime.now(),
      });

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Error: $e";
    }
  }

  // 3. LOG IN
  Future<String?> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // 4. LOG OUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}