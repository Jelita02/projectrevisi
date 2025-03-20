import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ternak/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  runApp(MyApp());

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: 'https://ebihlwhphychpvauperi.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImViaWhsd2hwaHljaHB2YXVwZXJpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI0NzczNTYsImV4cCI6MjA1ODA1MzM1Nn0.wPxyrLVMhWJJ2PjLnLHinLh3uko2mTQRbikjTnXfJpc',
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final MobileScannerController cameraController = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
      ),
    );
    return MaterialApp(
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0.0,
        ),
      ),
      debugShowCheckedModeBanner: false,
      title: 'QR Scan',
      home: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage("assets/images/france.jpg"),
              repeat: ImageRepeat.repeat),
        ),
        child: const Login(),
      ),
    );
  }
}
