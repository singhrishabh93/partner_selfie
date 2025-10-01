import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'presentation/cubits/simple_upload_cubit.dart';
import 'presentation/screens/simple_upload_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlashootApp());
}

class FlashootApp extends StatelessWidget {
  const FlashootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SimpleUploadCubit(),
      child: MaterialApp(
        title: 'FLASHOOT',
        theme: ThemeData.dark(),
        home: const SimpleUploadScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
