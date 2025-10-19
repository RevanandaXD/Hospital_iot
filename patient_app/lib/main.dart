import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/patient_selection_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
    // Continue running the app even if Firebase fails
  }
  
  print('Starting PatientApp...');
  runApp(PatientApp());
}

class PatientApp extends StatelessWidget {
  const PatientApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patient Care System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(),
        primaryColor: Color(0xFF1565C0),
        scaffoldBackgroundColor: Color(0xFFF5F5F5),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF1565C0),
          secondary: Color(0xFF42A5F5),
        ),
      ),
      home: PatientSelectionPage(),
    );
  }
}