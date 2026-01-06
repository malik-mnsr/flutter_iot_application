import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_iot_application/constants.dart';
import 'package:flutter_iot_application/ui/auth/authentication_bloc.dart';
import 'package:flutter_iot_application/ui/auth/launcherScreen/launcher_screen.dart';
import 'package:flutter_iot_application/ui/loading_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => AuthenticationBloc(),
        // Optional: Add lazy initialization
        lazy: false,
      ),
      BlocProvider(create: (_) => LoadingCubit()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Screen App', // Add app title
      theme: ThemeData(
        snackBarTheme: const SnackBarThemeData(
          contentTextStyle: TextStyle(color: Colors.white),
          backgroundColor: Colors.black87,
        ),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue, // Or create from your COLOR_PRIMARY
        ).copyWith(secondary: const Color(COLOR_PRIMARY)),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
      ),
      debugShowCheckedModeBanner: false,
      color: const Color(COLOR_PRIMARY),
      home: const LauncherScreen(),
      builder: EasyLoading.init(
        builder: (context, child) {
          // You can wrap with additional providers here if needed
          return child!;
        },
      ),
    );
  }
}