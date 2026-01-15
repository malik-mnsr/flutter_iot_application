// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_iot_application/constants.dart';
import 'package:flutter_iot_application/ui/auth/authentication/authentication_bloc.dart';
import 'package:flutter_iot_application/ui/auth/launcherScreen/launcher_screen.dart';
import 'package:flutter_iot_application/ui/loading_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  runApp(MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => AuthenticationBloc(),
        lazy: false,
      ),
      BlocProvider(create: (_) => LoadingCubit()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key?  key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 Controller',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme. fromSeed(
          seedColor: const Color(COLOR_PRIMARY),
          brightness:  Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(COLOR_PRIMARY),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(COLOR_PRIMARY),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius:  BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const LauncherScreen(),
      builder: EasyLoading.init(),
    );
  }
}