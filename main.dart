import 'dart:async';
// import 'dart:js';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:cubegon/404/not_found_page.dart';
import 'package:cubegon/Utils/extensions.dart';
import 'package:cubegon/Utils/nav_observer.dart';
import 'package:cubegon/Router/router.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:user_repository/user_repository.dart';

import 'Auth/authentication.dart';
import 'Constants/constants.dart';
import 'Router/auth_guard.dart';
import 'Router/mobile_guard.dart';
import 'Utils/bloc_observer.dart';
import 'firebase_options.dart';

const apiBaseUrl = 'https://cubegon-api.applore.in/api/v1/';

final ApiClient apiClient = ApiClient(
  httpClient: Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
    ),
  ),
);

Future<Box> openHiveBox(String boxName) async {
  if (!kIsWeb && !Hive.isBoxOpen(boxName)) {
    Hive.init((await getApplicationDocumentsDirectory()).path);
  }

  return await Hive.openBox(boxName);
}

void main() async {
  debugRepaintRainbowEnabled = false;
  debugPaintSizeEnabled = false;
  setPathUrlStrategy();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    // If we're in debug mode, use the normal error widget which shows the error
    // message:
    if (kDebugMode) {
      return ErrorWidget(details.exception);
    }
    // In release builds, show a yellow-on-blue message instead:
    return const NotFoundPage();
  };

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await Future.wait([
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
        openHiveBox('prefs'),
      ]);

      final storage = await HydratedStorage.build(
        storageDirectory: kIsWeb
            ? HydratedStorage.webStorageDirectory
            : await getTemporaryDirectory(),
      );

      Bloc.observer = SimpleBlocObserver();
      await FirebaseAuth.instance.signInAnonymously();

      HydratedBlocOverrides.runZoned(
        () => runApp(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<Box>(create: (context) => Hive.box('prefs')),
              RepositoryProvider(
                create: (context) => AuthenticationRepository(
                  apiClient: apiClient,
                ),
              ),
              RepositoryProvider(
                create: (context) => UserRepository(
                  apiClient: apiClient,
                ),
              ),
            ],
            child: const MyApp(),
          ),
        ),
        storage: storage,
      );
    },
    (Object error, StackTrace stack) {
      // logger.e(error, stack);
      debugPrintStack(label: error.toString(), stackTrace: stack);
      if (kReleaseMode) {
        // FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final _appRouter = AppRouter(
    authGuard: AuthGuard(context),
    mobileGuard: MobileGuard(),
    // onboardedGuard: OnboardedGuard(),
    // firstTimeNotesGuard: FirstTimeNotesGuard(),
  );

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthenticationBloc>(
          lazy: false,
          create: (BuildContext context) => AuthenticationBloc(
            authenticationRepository: context.read<AuthenticationRepository>(),
            userRepository: context.read<UserRepository>(),
          ),
        )
      ],
      child: MaterialApp.router(
        title: 'NotesNET',
        routerDelegate: _appRouter.delegate(
          navigatorObservers: () => [MyObserver()],
        ),
        routeInformationParser: _appRouter.defaultRouteParser(),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: (kIsWeb && !context.isBigScreen) ? 0.7 : 1.0,
            ),
            child: ScrollConfiguration(
              behavior: const ScrollBehavior(),
              child: child!,
            ),
          );
        },
        theme: ThemeData(
          fontFamily: GoogleFonts.poppins().fontFamily,
          textTheme: GoogleFonts.poppinsTextTheme(),
          colorScheme: CGTheme.colorScheme,
          // primaryColor: ,
          scaffoldBackgroundColor: Colors.white,
          // useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
      ),
    );
  }
}
