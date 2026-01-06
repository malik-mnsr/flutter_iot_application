import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_iot_application/constants.dart';
import 'package:flutter_iot_application/model/user.dart';
import 'package:flutter_iot_application/services/helper.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart' as apple;

class FireStoreUtils {
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static Reference storage = FirebaseStorage.instance.ref();

  static Future<User?> getCurrentUser(String uid) async {
    DocumentSnapshot<Map<String, dynamic>> userDocument =
    await firestore.collection(USERS).doc(uid).get();
    if (userDocument.data() != null && userDocument.exists) {
      return User.fromJson(userDocument.data()!);
    } else {
      return null;
    }
  }

  static Future<User> updateCurrentUser(User user) async {
    return await firestore
        .collection(USERS)
        .doc(user.userID)
        .set(user.toJson())
        .then((document) {
      return user;
    });
  }

  static Future<String> uploadUserImageToServer(
      File image, String userID) async {
    Reference upload = storage.child("images/$userID.png");
    UploadTask uploadTask = upload.putFile(image);
    var downloadUrl =
    await (await uploadTask.whenComplete(() {})).ref.getDownloadURL();
    return downloadUrl.toString();
  }

  static Future<dynamic> loginWithEmailAndPassword(
      String email, String password) async {
    print('=== LOGIN ATTEMPT ===');
    print('Email: $email');
    print('Password length: ${password.length}');

    try {
      print('Calling FirebaseAuth.instance.signInWithEmailAndPassword...');
      auth.UserCredential result = await auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      print('Firebase login successful!');
      print('User UID: ${result.user?.uid}');
      print('User email: ${result.user?.email}');

      print('Fetching user document from Firestore...');
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
      await firestore.collection(USERS).doc(result.user?.uid ?? '').get();

      User? user;
      if (documentSnapshot.exists) {
        print('User document found in Firestore');
        user = User.fromJson(documentSnapshot.data() ?? {});
        print('User created: ${user.email}');
      } else {
        print('WARNING: User document NOT found in Firestore!');
        print('Creating new user document...');

        // Create a new user document
        user = User(
          email: result.user?.email ?? email,
          firstName: 'New',
          lastName: 'User',
          userID: result.user?.uid ?? '',
          profilePictureURL: '',
        );

        await createNewUser(user);
        print('New user document created');
      }

      print('=== LOGIN SUCCESSFUL ===');
      return user;

    } on auth.FirebaseAuthException catch (exception, s) {
      print('=== FIREBASE AUTH ERROR ===');
      print('Error code: ${exception.code}');
      print('Error message: ${exception.message}');
      print('Stack trace: $s');

      String errorMessage = 'Unexpected firebase error, Please try again.';
      switch ((exception).code) {
        case 'invalid-email':
          errorMessage = 'Email address is malformed.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password.';
          break;
        case 'user-not-found':
          errorMessage = 'No user corresponding to the given email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This user has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts to sign in as this user.';
          break;
        case 'invalid-credential':
          errorMessage = 'The supplied auth credential is incorrect, malformed or has expired.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled. Please enable them in Firebase Console.';
          break;
      }

      print('Returning error: $errorMessage');
      return errorMessage;

    } catch (e, s) {
      print('=== GENERAL LOGIN ERROR ===');
      print('Error: $e');
      print('Stack trace: $s');

      // Check if user is authenticated despite the parsing error
      auth.User? currentUser = auth.FirebaseAuth.instance.currentUser;
      print('Current Firebase user: ${currentUser?.uid}');

      if (currentUser != null) {
        print('User is authenticated, fetching from Firestore...');
        User? user = await getCurrentUser(currentUser.uid);
        if (user != null) {
          print('User found despite error, returning user');
          return user;
        }
      }

      return 'Login failed, Please try again.';
    }
  }

  static Future<String?> createNewUser(User user) async => await firestore
      .collection(USERS)
      .doc(user.userID)
      .set(user.toJson())
      .then((value) => null, onError: (e) => e);

  static Future<dynamic> signUpWithEmailAndPassword(
      {required String emailAddress,
        required String password,
        File? image,
        required String firstName,
        required String lastName}) async {
    try {
      auth.UserCredential result = await auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(
          email: emailAddress, password: password);
      String profilePicUrl = '';
      if (image != null) {
        updateProgress('Uploading image, Please wait...');
        profilePicUrl =
        await uploadUserImageToServer(image, result.user?.uid ?? '');
      }
      User user = User(
          email: emailAddress,
          firstName: firstName,
          userID: result.user?.uid ?? '',
          lastName: lastName,
          profilePictureURL: profilePicUrl);
      String? errorMessage = await createNewUser(user);
      if (errorMessage == null) {
        return user;
      } else {
        return 'Couldn\'t sign up for firebase, Please try again.';
      }
    } on auth.FirebaseAuthException catch (error) {
      debugPrint(error.toString() + '${error.stackTrace}');
      String message = 'Couldn\'t sign up';
      switch (error.code) {
        case 'email-already-in-use':
          message = 'Email already in use, Please pick another email!';
          break;
        case 'invalid-email':
          message = 'Enter valid e-mail';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled';
          break;
        case 'weak-password':
          message = 'Password must be more than 5 characters';
          break;
        case 'too-many-requests':
          message = 'Too many requests, Please try again later.';
          break;
      }
      return message;
    } catch (e) {
      return 'Couldn\'t sign up';
    }
  }

  static logout() async {
    await auth.FirebaseAuth.instance.signOut();
  }

  static Future<User?> getAuthUser() async {
    auth.User? firebaseUser = auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      User? user = await getCurrentUser(firebaseUser.uid);
      return user;
    } else {
      return null;
    }
  }

  static Future<dynamic> loginOrCreateUserWithPhoneNumberCredential({
    required auth.PhoneAuthCredential credential,
    required String phoneNumber,
    String? firstName = 'Anonymous',
    String? lastName = 'User',
    File? image,
  }) async {
    auth.UserCredential userCredential =
    await auth.FirebaseAuth.instance.signInWithCredential(credential);
    User? user = await getCurrentUser(userCredential.user?.uid ?? '');
    if (user != null) {
      return user;
    } else {
      String profileImageUrl = '';
      if (image != null) {
        profileImageUrl = await uploadUserImageToServer(
            image, userCredential.user?.uid ?? '');
      }
      User user = User(
          firstName:
          firstName!.trim().isNotEmpty ? firstName.trim() : 'Anonymous',
          lastName: lastName!.trim().isNotEmpty ? lastName.trim() : 'User',
          email: '',
          profilePictureURL: profileImageUrl,
          userID: userCredential.user?.uid ?? '');
      String? errorMessage = await createNewUser(user);
      if (errorMessage == null) {
        return user;
      } else {
        return 'Couldn\'t create new user with phone number.';
      }
    }
  }

  static Future<dynamic> loginWithApple() async {
    try {
      final appleCredential = await apple.TheAppleSignIn.performRequests([
        const apple.AppleIdRequest(
            requestedScopes: [apple.Scope.email, apple.Scope.fullName])
      ]);
      if (appleCredential.error != null) {
        return 'Couldn\'t login with apple.';
      }

      if (appleCredential.status == apple.AuthorizationStatus.authorized) {
        final auth.AuthCredential credential =
        auth.OAuthProvider('apple.com').credential(
          accessToken: String.fromCharCodes(
              appleCredential.credential?.authorizationCode ?? []),
          idToken: String.fromCharCodes(
              appleCredential.credential?.identityToken ?? []),
        );
        return await _handleAppleLogin(credential, appleCredential.credential!);
      } else {
        return 'Couldn\'t login with apple.';
      }
    } catch (e) {
      debugPrint('Apple login error: $e');
      return 'Apple login failed.';
    }
  }

  static Future<dynamic> _handleAppleLogin(
      auth.AuthCredential credential,
      apple.AppleIdCredential appleIdCredential,
      ) async {
    try {
      auth.UserCredential authResult =
      await auth.FirebaseAuth.instance.signInWithCredential(credential);
      User? user = await getCurrentUser(authResult.user?.uid ?? '');
      if (user != null) {
        return user;
      } else {
        user = User(
          email: appleIdCredential.email ?? '',
          firstName: appleIdCredential.fullName?.givenName ?? '',
          profilePictureURL: '',
          userID: authResult.user?.uid ?? '',
          lastName: appleIdCredential.fullName?.familyName ?? '',
        );
        String? errorMessage = await createNewUser(user);
        if (errorMessage == null) {
          return user;
        } else {
          return errorMessage;
        }
      }
    } catch (e) {
      debugPrint('Handle Apple login error: $e');
      return 'Couldn\'t complete apple login.';
    }
  }

  static resetPassword(String emailAddress) async =>
      await auth.FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailAddress);
}