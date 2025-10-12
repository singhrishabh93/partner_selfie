import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'presentation/cubits/simple_upload_cubit.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  runApp(const FlashootApp());
}

class FlashootApp extends StatelessWidget {
  const FlashootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SimpleUploadCubit(),
      child: MaterialApp(
        title: 'Image Maker',
        theme: ThemeData.dark(),
        home: const SplashScreenWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({super.key});

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  bool _showSplash = true;

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _showSplash
        ? SplashScreen(onAnimationComplete: _onSplashComplete)
        : const HomeScreen();
  }
}
