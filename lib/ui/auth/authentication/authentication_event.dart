part of 'authentication_bloc.dart';

abstract class AuthenticationEvent {}

class CheckFirstRunEvent extends AuthenticationEvent {}

class FinishedOnBoardingEvent extends AuthenticationEvent {}

class LoginWithEmailAndPasswordEvent extends AuthenticationEvent {
  final String email;
  final String password;

  LoginWithEmailAndPasswordEvent({
    required this.email,
    required this.password,
  });
}

// REMOVED: class LoginWithFacebookEvent extends AuthenticationEvent {}

class LoginWithAppleEvent extends AuthenticationEvent {}

class LoginWithPhoneNumberEvent extends AuthenticationEvent {
  final auth.PhoneAuthCredential credential;
  final String phoneNumber;
  final String? firstName;
  final String? lastName;
  final File? image;

  LoginWithPhoneNumberEvent({
    required this.credential,
    required this.phoneNumber,
    this.firstName,
    this.lastName,
    this.image,
  });
}

class SignupWithEmailAndPasswordEvent extends AuthenticationEvent {
  final String emailAddress;
  final String password;
  final File? image;
  final String firstName;
  final String lastName;

  SignupWithEmailAndPasswordEvent({
    required this.emailAddress,
    required this.password,
    this.image,
    this.firstName = 'Anonymous',
    this.lastName = 'User',
  });
}

class LogoutEvent extends AuthenticationEvent {}