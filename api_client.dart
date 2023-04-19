import 'dart:convert' as convert;
import 'dart:convert';
import 'dart:developer';

import 'dart:math' hide log;

import 'package:api_client/models/bank_details/bank_details_model.dart';
import 'package:api_client/models/create_note_result.dart/create_note_result.dart';
import 'package:api_client/models/goal/goal.dart';
import 'package:api_client/models/models.dart';
import 'package:api_client/models/note/note.dart';
import 'package:api_client/responses/responses.dart';
import 'package:api_client/src/api_client_storage.dart';
import 'package:cross_file/cross_file.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:fresh_dio/fresh_dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http_parser/http_parser.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

part 'apple_sign_in_utils.dart';

class ApiClient {
  ApiClient({
    Dio? httpClient,
  }) : _httpClient = (httpClient ?? Dio())
          ..interceptors.add(_fresh)
          ..interceptors.add(
            LogInterceptor(
              requestHeader: false,
              responseHeader: false,
              requestBody: true,
              responseBody: true,
            ),
          ) {
    // _fresh.clearToken();
    _fresh.authenticationStatus.listen((status) {
      log('Fresh Authentication Status ::: $status');
    });
  }

  static final _fresh = Fresh<Authentication>(
    refreshToken: (token, client) async {
      try {
        final response = await ApiClient(
          httpClient: Dio(
            BaseOptions(
              baseUrl: 'https://cubegon-api.applore.in/api/v1/',
            ),
          ),
        ).refreshToken(token!.refreshtoken) as Response<Map<String, dynamic>>;

        // await FirebaseAuth.instance.signInWithCustomToken(
        //   'Bearer ${response.data!['accesToken'] as String}',
        // );
        await FirebaseAuth.instance.signInAnonymously();

        return Authentication(
          accesstoken: response.data!['accesToken'] as String,
          refreshtoken: token.refreshtoken,
        );
      } catch (e) {
        throw RevokeTokenException();
      }
    },
    tokenStorage: ApiClientStorage(
        // kIsWeb: kIsWeb,
        ),
    tokenHeader: (token) {
      return {
        'Authorization': 'Bearer ${token.accesstoken}',
      };
    },
    shouldRefresh: (response) {
      return response?.statusCode == 401 &&
          response?.requestOptions.path != '/user/retire';
    },
  );

  final Dio _httpClient;

  final _modelDioClient = Dio(
    BaseOptions(
      baseUrl: 'https://cubegon-api.applore.in/api/',
    ),
  )
    ..interceptors.add(_fresh)
    ..interceptors.add(
      LogInterceptor(
        requestHeader: false,
        responseHeader: false,
        requestBody: true,
        responseBody: true,
      ),
    );

  Stream<AuthenticationStatus> get authenticationStatus =>
      _fresh.authenticationStatus;

  /// Google Sign In
  Future<ApiResult> googleLogin() async {
    try {
      UserCredential userCred;
      log('Google Login');

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider()
          ..addScope('https://www.googleapis.com/auth/userinfo.email')
          ..addScope('https://www.googleapis.com/auth/userinfo.profile')
          ..setCustomParameters(
            <String, dynamic>{'login_hint': 'user@example.com'},
          );

        // Once signed in, return the UserCredential
        userCred = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        // Trigger the authentication flow
        final googleUser = await GoogleSignIn().signIn();

        log('Google User ::: $googleUser');

        // Obtain the auth details from the request
        final googleAuth = await googleUser?.authentication;

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth?.accessToken,
          idToken: googleAuth?.idToken,
        );

        // Once signed in, return the UserCredential
        userCred = await FirebaseAuth.instance.signInWithCredential(credential);
        log('User Credential ::: $userCred');
      }

      final user = userCred.user;

      if (user == null) {
        return const ApiResult.error(
          errors: [
            ApiErrorModel(
              location: 'googleLogin',
              msg: 'Unable to login with google',
              param: 'user',
              value: 'null',
            ),
          ],
        );
      }

      if (user.email == null) {
        return const ApiResult.error(
          errors: [
            ApiErrorModel(
              location: 'googleLogin',
              msg: 'Unable to get email',
              param: 'user.email',
              value: 'null',
            ),
          ],
        );
      }
      final userExists = await checkUserExists(user.email!);

      if (userExists) {
        final res = logIn(email: user.email!, password: user.uid);
        return res;
      } else {
        final res = await register(
          email: user.email!,
          fullname: user.displayName ?? '',
          password: user.uid,
          mobile: user.phoneNumber ?? '1234567890',
          authProvider: 'Google',
        );
        return res;
      }
    } catch (e) {
      debugPrint('Google Login Error ::: $e');
      log('Google Login Error ::: $e');
      // rethrow;
      return const ApiResult.error(
        errors: [
          ApiErrorModel(
            location: 'googleLogin',
            msg: 'Unable to login with google',
            param: 'user',
            value: 'null',
          ),
        ],
      );
    }
  }

  /// Facebook Sign In
  Future<ApiResult> facebookLogin() async {
    log('facebookLogin');
    UserCredential userCred;
    if (kIsWeb) {
      final facebookProvider = FacebookAuthProvider()
        ..addScope('email')
        ..addScope('public_profile');

      // Once signed in, return the UserCredential
      userCred = await FirebaseAuth.instance.signInWithPopup(facebookProvider);
    } else {
      // Trigger the sign-in flow
      final result = await FacebookAuth.instance.login();

      // Create a credential from the access token
      final facebookAuthCredential =
          FacebookAuthProvider.credential(result.accessToken!.token);

      // Once signed in, return the UserCredential
      userCred = await FirebaseAuth.instance
          .signInWithCredential(facebookAuthCredential);
    }

    final user = userCred.user;

    log('facebookLogin user ${user.toString()}');

    if (user == null) {
      return const ApiResult.error(
        errors: [
          ApiErrorModel(
            location: 'facebookLogin',
            msg: 'Unable to login with facebook',
            param: 'user',
            value: 'null',
          ),
        ],
      );
    }

    if (user.email == null) {
      return const ApiResult.error(
        errors: [
          ApiErrorModel(
            location: 'facebookLogin',
            msg: 'Unable to get email',
            param: 'user.email',
            value: 'null',
          ),
        ],
      );
    }
    final userExists = await checkUserExists(user.email!);

    if (userExists) {
      final res = logIn(email: user.email!, password: user.uid);
      return res;
    } else {
      final res = await register(
        email: user.email!,
        fullname: user.displayName ?? '',
        password: user.uid,
        mobile: user.phoneNumber ?? '1234567890',
        authProvider: 'Facebook',
      );
      return res;
    }
  }

  /// Apple Log In
  Future<ApiResult> appleLogin() async {
    UserCredential userCred;
    if (kIsWeb) {
      final appleProvider = OAuthProvider('apple.com')
        ..addScope('email')
        ..addScope('name');

      // Once signed in, return the UserCredential
      userCred = await FirebaseAuth.instance.signInWithPopup(appleProvider);
    } else {
      // Trigger the sign-in flow
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      // Request credential for the currently signed in Apple account.
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Create an `OAuthCredential` from the credential returned by Apple.
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // Once signed in, return the UserCredential
      userCred =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    }

    try {
      final user = userCred.user;
      log('appleLogin user ${userCred.toString()}');

      if (user == null) {
        return const ApiResult.error(
          errors: [
            ApiErrorModel(
              location: 'appleLogin',
              msg: 'Unable to login with apple',
              param: 'user',
              value: 'null',
            ),
          ],
        );
      }

      /// TODO: Implement UID based login for apple
      ///
      final userExists = await checkUUIDExists(user.uid);

      if (userExists) {
        final res = logIn(email: user.uid, password: user.uid, uuid: user.uid);
        return res;
      } else {
        final res = await register(
          email: user.email ?? user.uid,
          fullname: user.displayName ?? '',
          password: user.uid,
          mobile: user.phoneNumber ?? '1234567890',
          uuid: user.uid,
          authProvider: 'Apple',
        );
        return res;
      }
    } catch (e, s) {
      log(e.toString(), stackTrace: s);
      rethrow;
    }

    // if (user.email == null) {
    //   // return const ApiResult.error(
    //   //   errors: [
    //   //     ApiErrorModel(
    //   //       location: 'appleLogin',
    //   //       msg: 'Unable to get email',
    //   //       param: 'user.email',
    //   //       value: 'null',
    //   //     ),
    //   //   ],
    //   // );

    //   final userExists = await checkUserExists(user.phoneNumber!);

    //   if (userExists) {
    //     final res = logIn(email: user.phoneNumber!, password: user.uid);
    //     return res;
    //   } else {
    //     final res = await register(
    //       email: user.phoneNumber!,
    //       fullname: user.displayName ?? '',
    //       password: user.uid,
    //       mobile: user.phoneNumber ?? '1234567890',
    //     );
    //     return res;
    //   }
    // } else {
    //   final userExists = await checkUserExists(user.email!);

    //   if (userExists) {
    //     final res = logIn(email: user.email!, password: user.uid);
    //     return res;
    //   } else {
    //     final res = await register(
    //       email: user.email!,
    //       fullname: user.displayName ?? '',
    //       password: user.uid,
    //       mobile: user.phoneNumber ?? '1234567890',
    //     );
    //     return res;
    //   }
    // }
  }

  Future<ApiResult> logIn({
    String? uuid,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _httpClient.post<Map<String, dynamic>>(
        '/user/login',
        data: convert.jsonEncode(
          {
            if (uuid != null) 'uuid': uuid,
            'email': email,
            'password': password,
          },
        ),
      );

      final body = Authentication.fromJson(response.data!);

      // await FirebaseAuth.instance
      //     .signInWithCustomToken('Bearer ${body.accesstoken}');
      await FirebaseAuth.instance.signInAnonymously();

      await _fresh.setToken(
        body,
      );

      return const ApiResult.success(
        message: 'User logged-in successfully',
      );
    } on DioError catch (e) {
      log(e.toString());
      if (e.response?.statusCode == 409 || e.response?.statusCode == 401) {
        final error = ApiResult.error(
          errors: [
            ApiErrorModel(
              // ignore: avoid_dynamic_calls
              msg: (e.response!.data as Map)['message'] as String,

              param: 'email',
              location: 'edgeCase',
            )
          ],
        );

        return error;
      }
      final error = ApiError.fromJson(
        e.response!.data as Map<String, dynamic>,
      );
      return error;
    }
  }

  Future<ApiResult> register({
    String? uuid,
    required String email,
    required String password,
    required String fullname,
    required String mobile,
    String authProvider = 'Normal',
  }) async {
    log('registering');
    try {
      final response = await _httpClient.post<Map<String, dynamic>>(
        '/user/signup',
        data: convert.jsonEncode(
          {
            if (uuid != null) 'uuid': uuid,
            'email': email,
            'password': password,
            'fullname': fullname.isEmpty ? ' ' : fullname,
            'mobile': mobile,
            'authProvider': authProvider,
          },
        ),
      );

      log(response.data.toString());

      final body = Authentication.fromJson(response.data!);

      // await FirebaseAuth.instance
      //     .signInWithCustomToken('Bearer ${body.accesstoken}');
      await FirebaseAuth.instance.signInAnonymously();

      await _fresh.setToken(body);

      return const ApiResult.success(
        message: 'User registered successfully',
      );
    } on DioError catch (e) {
      log(e.toString());
      if (e.response?.statusCode == 409) {
        final error = ApiResult.error(
          errors: [
            ApiErrorModel(
              // ignore: avoid_dynamic_calls
              msg: e.response!.data.runtimeType is String
                  ? e.response!.data.toString()
                  : (e.response!.data as Map)['message'] as String,
              param: 'email',
              location: 'edgeCase',
            )
          ],
        );

        return error;
      }
      final error = ApiError.fromJson(
        e.response!.data as Map<String, dynamic>,
      );
      return error;
    }
  }

  Future refreshToken(String refreshToken) async {
    return _httpClient.post<Map<String, dynamic>>(
      '/user/retire',
      data: convert.jsonEncode({'refreshToken': refreshToken}),
    );
  }

  Future logOut() async {
    return _fresh.clearToken();
  }

  /// Check if user exists
  Future<bool> checkUserExists(String email) async {
    try {
      final response = await _modelDioClient.post<Map<String, dynamic>>(
        'checkEmail',
        data: convert.jsonEncode(
          {
            'email': email,
          },
        ),
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } on DioError catch (e) {
      log(e.toString());
      return false;
    }
  }

  /// Check if UUID exists in database
  Future<bool> checkUUIDExists(String uuid) async {
    try {
      final response = await _modelDioClient.post<Map<String, dynamic>>(
        'v1/user/checkUUID',
        data: convert.jsonEncode(
          {
            'uuid': uuid,
          },
        ),
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } on DioError catch (e) {
      log(e.toString());
      return false;
    }
  }

  /// Forgot password - Send OTP
  Future<ApiResult> forgotPasswordSendOTP({
    required String email,
  }) async {
    try {
      final response = await _modelDioClient.post<String>(
        'sendOtp',
        data: convert.jsonEncode(
          {
            'email': email,
          },
        ),
      );

      log(response.data.toString());

      return const ApiResult.success(
        message: 'OTP sent successfully',
      );
    } on DioError catch (e) {
      // rethrow;s
      // log(e.toString(),);
      if (e.response?.statusCode == 409) {
        final error = ApiResult.error(
          errors: [
            ApiErrorModel(
              // ignore: avoid_dynamic_calls
              msg: e.response!.data.runtimeType is Map
                  ? (e.response!.data as Map)['message'] as String
                  : e.response!.data.toString(),
              param: 'email',
              location: 'edgeCase',
            )
          ],
        );

        return error;
      }
      // ignore: avoid_dynamic_calls
      if (e.response?.data == null) {
        return const ApiResult.error(
          errors: [
            ApiErrorModel(
              msg: 'Something went wrong',
              param: 'email',
              location: 'edgeCase',
            )
          ],
        );
      }
      final error = ApiError.fromJson(
        e.response?.data as Map<String, dynamic>,
      );
      return error;
    }
  }

  /// Forgot password - Verify OTP
  Future<ApiResult> forgotPasswordVerifyOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _modelDioClient.post<Map<String, dynamic>>(
        'check',
        data: convert.jsonEncode(
          {
            'email': email,
            'otp': otp,
          },
        ),
      );

      log(response.data.toString());

      return const ApiResult.success(
        message: 'OTP verified successfully',
      );
    } on DioError catch (e) {
      log(e.toString());
      // if (e.response?.statusCode == 409) {
      final error = ApiResult.error(
        errors: [
          ApiErrorModel(
            // ignore: avoid_dynamic_calls
            msg: (e.response!.data as Map)['message'] as String,

            param: 'email',
            location: 'edgeCase',
          )
        ],
      );

      return error;
      // }
      // final error = ApiError.fromJson(
      //   e.response!.data as Map<String, dynamic>,
      // );
      // return error;
    }
  }

  /// Forgot password - Reset password
  Future<ApiResult> forgotPasswordResetPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _modelDioClient.post<Map<String, dynamic>>(
        'reset',
        data: convert.jsonEncode(
          {
            'email': email,
            'password': password,
          },
        ),
      );

      log(response.data.toString());

      return const ApiResult.success(
        message: 'Password reset successfully',
      );
    } on DioError catch (e) {
      log(e.toString());
      if (e.response?.statusCode == 409) {
        final error = ApiResult.error(
          errors: [
            ApiErrorModel(
              // ignore: avoid_dynamic_calls
              msg: e.response!.data.runtimeType is Map
                  ? (e.response!.data as Map)['message'] as String
                  : e.response!.data.toString(),
              param: 'email',
              location: 'edgeCase',
            )
          ],
        );

        return error;
      }
      final error = ApiError.fromJson(
        e.response!.data as Map<String, dynamic>,
      );
      return error;
    }
  }

  /// Get user details
  Future<User> getUser() async {
    try {
      final response = await _httpClient.get<Map<String, dynamic>>(
        'user/',
      );
      return User.fromJson(response.data!['result'] as Map<String, dynamic>);
    } on DioError catch (e) {
      if (e.response?.statusCode == 204) {
        throw RevokeTokenException();
      } else {
        rethrow;
      }
    }
  }

  /// Update user details
  Future<ApiResult> updateUser({
    required String id,
    required String name,
    required String gender,
    required String experience,
    required String phone,
    required String degree,
    required String college,
    required String year,
    required String designation,
    required String company,
    required String location,
  }) async {
    try {
      final body = {
        'fullname': name,
        'phone': phone,
        'gender': gender,
        'experience': experience,
        'education': {'degree': degree, 'college': college, 'year': year},
        'currentlyWorking': {
          'designation': designation,
          'company': company,
          'location': location
        },
      };
      log(body.toString());
      final response = await _modelDioClient.patch<Map<String, dynamic>>(
        'model/user/$id',
        data: convert.jsonEncode(
          body,
        ),
      );

      log(response.data.toString());

      return const ApiResult.success(
        message: 'User updated successfully',
      );
    } on DioError catch (e) {
      log(e.toString());
      final error = ApiError.fromJson(
        e.response!.data as Map<String, dynamic>,
      );
      return error;
    }
  }

  /// Deactivate user
  Future<ApiResult> deactivateUser() async {
    final id = (await _fresh.token)?.user?.id;
    try {
      final response = await _modelDioClient.patch<Map<String, dynamic>>(
        'model/user/$id',
        data: convert.jsonEncode(
          {
            'deactivated': true,
          },
        ),
      );

      log(response.data.toString());

      return const ApiResult.success(
        message: 'User deactivated successfully',
      );
    } on DioError catch (e) {
      log(e.toString());
      final error = ApiError.fromJson(
        e.response!.data as Map<String, dynamic>,
      );
      return error;
    }
  }

  /// Update User Profile Picture
  Future<ApiResult> updateUserProfilePicture({
    required String email,
    required XFile image,
  }) async {
    try {
      final response = await _httpClient.put<Map<String, dynamic>>(
        'user/update',
        data: FormData.fromMap(
          <String, dynamic>{
            'email': email,
            'picture': MultipartFile.fromBytes(
              await image.readAsBytes(),
              filename: image.name,
              contentType: MediaType(
                image.mimeType?.split('/').first ?? 'application',
                image.mimeType?.split('/').last ?? 'octet-stream',
              ),
            ),
          },
        ),
      );

      log(response.data.toString());

      return const ApiResult.success(
        message: 'Profile picture updated successfully',
      );
    } on DioError catch (e) {
      log(e.toString());
      final error = ApiError.fromJson(
        e.response!.data as Map<String, dynamic>,
      );
      return error;
    }
  }

  /// Reset password
  Future<void> resetPassword({
    required String email,
  }) async {
    await _httpClient.put<Map<String, dynamic>>(
      '/users/reset-password',
      data: convert.jsonEncode({'email': email}),
    );
  }

  /// Get Notes uploaded by the user
  Future<List<Note>> getNotes({
    List<String>? status,
    List<int>? grade,
    String? searchTerm,
  }) async {
    final response = await _httpClient.post<List>(
      '/user/notes',
      data: <String, dynamic>{
        if (status != null) 'status': status,
        if (grade != null) 'grade': grade,
      },
      queryParameters: <String, dynamic>{
        if (searchTerm != null) 'searchTerm': searchTerm,
      },
    );

    final notes = (response.data!)
        .map((dynamic e) => Note.fromJson(e as Map<String, dynamic>))
        .toList();

    return notes;
  }

  /// Get Publice Notes
  Future<List<Note>> getPublicNotes({
    List<String>? status,
    List<String>? subject,
    List<int>? grade,
    String? searchTerm,
  }) async {
    final response = await _httpClient.post<List>(
      '/public/getPublicNotes',
      data: <String, dynamic>{
        if (status != null) 'status': status,
        if (grade != null) 'grade': grade,
        if (subject != null) 'subject': subject,
      },
      queryParameters: <String, dynamic>{
        if (searchTerm != null) 'searchTerm': searchTerm,
      },
    );

    final notes = (response.data!)
        .map((dynamic e) => Note.fromJson(e as Map<String, dynamic>))
        .toList();

    return notes;
  }

  /// Get Note by id
  Future<Note> getNoteById(String id) async {
    final response = await _httpClient.customGet<Map<String, dynamic>>(
      path: 'https://cubegon-api.applore.in/api/model/notes/$id',
    );

    return Note.fromJson(response.data!);
  }

  /// Create a new note
  Future<CreateNoteResult> createNote({
    required XFile file,
    required String title,
    required String institute,
    required String subject,
    required int grade,
    required String stream,
    required String bank,
    required String teachers,
    required String description,
    required String board,
    String status = 'review',
    required String tags,
    // String? courseGrade,
    String? yearAuthored,
  }) async {
    final client = _modelDioClient;
    // {}

    try {
      log('Uploading file Grade :: $grade');
      final response = await client.post<Map<String, dynamic>>(
        'model/notes',
        options: Options(
          headers: <String, dynamic>{
            'Content-Type': 'multipart/form-data',
          },
        ),
        data: FormData.fromMap(
          <String, dynamic>{
            'title': title,
            'institution': institute,
            'subject': subject,
            'grade': grade,
            'stream': stream,
            'board': board,
            'bank': bank,
            // if (courseGrade != null) 'courseGrade': courseGrade,
            if (yearAuthored != null) 'yearAuthored': yearAuthored,
            'description':
                description.isEmpty ? 'No description provided' : description,
            'authoredDate': DateTime.now().toIso8601String().split('T').first,
            'teachers': teachers,
            'status': status,
            'file': MultipartFile.fromBytes(
              await file.readAsBytes(),
              filename: file.name,
              contentType: MediaType(
                file.mimeType?.split('/').first ?? 'application',
                file.mimeType?.split('/').last ?? 'octet-stream',
              ),
            ),
            'tags':
                '''$tags, ${title.toLowerCase()}, ${institute.toLowerCase()}, ${subject.toLowerCase()}, ${grade.toString()}, ${stream.toLowerCase()}, ${teachers.toLowerCase()}, ${description.toLowerCase()}}''',
          },
        ),
      );

      if (response.statusCode.toString().startsWith('2')) {
        return CreateNoteResult.success(
          note: Note.fromJson(response.data!['result'] as Map<String, dynamic>),
        );
      } else {
        return CreateNoteResult.error(
          errors: [
            ApiErrorModel(
              msg: response.data!['error'] as String,
              param: 'file',
              location: 'edgeCase',
            )
          ],
        );
      }
    } catch (e, s) {
      log('', error: e, stackTrace: s, time: DateTime.now());

      return CreateNoteResult.error(
        errors: [
          ApiErrorModel(
            msg: e.toString(),
            param: 'file',
            location: 'edgeCase',
          )
        ],
      );
    }

    // return Note.fromJson(response.data!['result'] as Map<String, dynamic>);
  }

  /// Get Bank Details
  Future<List<BankDetails>> getBankDetails() async {
    final response = await _httpClient.get<List>(
      '/user/getBank',
    );

    final bankDetails = (response.data!)
        .map((dynamic e) => BankDetails.fromJson(e as Map<String, dynamic>))
        .toList();

    return bankDetails;
  }

  /// Add Bank Details
  Future<Map> addBankDetails({
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
    required String upiId,
  }) async {
    final response = await _httpClient.post<Json>(
      '/user/createBank',
      data: <String, dynamic>{
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'accountHolderName': accountHolderName,
        'upiId': upiId,
      },
    );

    if (response.statusCode.toString().startsWith('2')) {
      return response.data!['result'] as Map;
    } else {
      throw Exception(response.data!['error'] as String);
    }
  }

  /// Get Goals
  Future<List<Goal>> getGoals() async {
    try {
      final response = await _modelDioClient.get<Map>(
        '/model/goal',
      );

      final goals = (response.data!['result'] as List)
          .map((dynamic e) => Goal.fromJson(e as Map<String, dynamic>))
          .toList();

      return goals;
    } catch (e, s) {
      log('Error in getGoals', error: e, stackTrace: s);
      return [];
    }
  }

  /// Create Goal
  Future<Goal> createGoal({
    required String title,
    required XFile document,
    required int amount,
  }) async {
    final response = await _modelDioClient.post<Map<String, dynamic>>(
      '/model/goal',
      options: Options(
        headers: <String, dynamic>{
          'Content-Type': 'multipart/form-data',
        },
      ),
      data: FormData.fromMap(<String, dynamic>{
        'title': title,
        'document': MultipartFile.fromBytes(
          await document.readAsBytes(),
          filename: document.name,
          contentType: document.mimeType != null
              ? MediaType(
                  document.mimeType?.split('/').first ?? 'application',
                  document.mimeType?.split('/').last ?? 'octet-stream',
                )
              : MediaType('application', 'octet-stream'),
        ),
        'amount': amount,
      }),
    );

    return Goal.fromJson(response.data!['goal'] as Map<String, dynamic>);
  }

  /// Delete Goal
  Future<void> deleteGoal(String id) async {
    final response = await _modelDioClient.delete<Map<String, dynamic>>(
      '/model/goal/$id',
    );

    if (response.statusCode.toString().startsWith('2')) {
      return;
    } else {
      throw Exception(response.data!['error'] as String);
    }
  }

  /// Join Us Form
  Future<void> joinUs({
    required String email,
    required String phone,
    required String description,
  }) async {
    final response = await _modelDioClient.customPost<Map<String, dynamic>>(
      path: 'https://cubegon-api.applore.in/api/v1/user/joinUs',
      data: <String, dynamic>{
        'email': email,
        'Phone_No': phone,
        'description': description,
      },
    );

    log('Join Us Response: ${response.data}');

    if (response.statusCode.toString().startsWith('2')) {
      return;
    } else {
      throw Exception(response.data!['error'] as String);
    }
  }

  /// Contact Us Form
  /// [firstname] is the first name of the user
  /// [lastname] is the last name of the user
  /// [email] is the email of the user
  /// [phone] is the phone number of the user
  /// [message] is the message of the user
  Future<void> contactUs({
    required String firstname,
    required String lastname,
    required String email,
    required String phone,
    required String message,
  }) async {
    final response = await _modelDioClient.customPost<Map<String, dynamic>>(
      path: 'https://cubegon-api.applore.in/api/v1/user/contactUs',
      data: <String, dynamic>{
        'firstName': firstname,
        'lastName': lastname,
        'email': email,
        'PhoneNumber': phone,
        'message': message,
      },
    );

    log('Contact Us Response: ${response.data}');

    if (response.statusCode.toString().startsWith('2')) {
      return;
    } else {
      throw Exception(response.data!['error'] as String);
    }
  }

  /// Get All counts for landing page
  Future<Json> getLandingPageCounts() async {
    final response = await _httpClient.get<Map<String, dynamic>>(
      '/public/getAllAPI',
    );

    return response.data!;
  }

  /// Increase Note View Count
  /// /public/incrementViews
  Future<void> increaseNoteViewCount(String id) async {
    final response = await _httpClient.post<Map<String, dynamic>>(
      '/public/incrementViews/$id',
      // data: <String, dynamic>{
      //   'id': id,
      // },
    );

    if (response.statusCode.toString().startsWith('2')) {
      return;
    } else {
      throw Exception(response.data!['error'] as String);
    }
  }
}

typedef Json = Map<String, dynamic>;

extension on Dio {
  Future<Response<T>> customGet<T>({
    required String path,
  }) {
    return get<T>(path);
  }

  Future<Response<T>> customPost<T>({
    required String path,
    required Map<String, dynamic> data,
  }) {
    return post<T>(path, data: data);
  }
}
