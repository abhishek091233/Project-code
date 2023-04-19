import 'dart:async';

import 'package:api_client/api_client.dart';

enum UserAuthenticationStatus {
  initial,
  signedIn,
  signedOut,
}

class UserRepository {
  UserRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Stream<UserAuthenticationStatus> get userAuthenticationStatus {
    return _apiClient.authenticationStatus.map((status) {
      switch (status) {
        case AuthenticationStatus.authenticated:
          return UserAuthenticationStatus.signedIn;
        case AuthenticationStatus.unauthenticated:
          return UserAuthenticationStatus.signedOut;
        case AuthenticationStatus.initial:
        default:
          return UserAuthenticationStatus.initial;
      }
    });
  }

  Future<User?> getUser() async {
    try {
      return _apiClient.getUser();
    } catch (e) {
      return null;
    }
  }

  Future<void> resetPassword({
    required String email,
  }) async {
    await _apiClient.resetPassword(email: email);
  }
}
