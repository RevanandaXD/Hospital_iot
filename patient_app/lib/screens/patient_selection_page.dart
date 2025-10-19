import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'patient_home_page.dart';

class PatientSelectionPage extends StatefulWidget {
  @override
  _PatientSelectionPageState createState() => _PatientSelectionPageState();
}

class _PatientSelectionPageState extends State<PatientSelectionPage> {
  @override
  void initState() {
    super.initState();
    _checkSavedPatient();
  }

  // Cek apakah user sudah pernah pilih pasien
  void _checkSavedPatient() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedPatientId = prefs.getString('selected_patient_id');
      
      if (savedPatientId != null) {
        // Langsung ke home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PatientHomePage(patientId: savedPatientId),
          ),
        );
      } else {
        print('ℹNo saved patient found, showing selection page');
      }
    } catch (e) {
      print('Error checking saved patient: $e');
    }
  }

  // Simpan pilihan pasien dan masuk ke home
  void _selectPatient(String patientId, String name, String room) async {
    try {
      print('Patient selected: $patientId ($name, Room $room)');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_patient_id', patientId);
      print('Patient ID saved to preferences');
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PatientHomePage(patientId: patientId),
        ),
      );
      print('Navigating to PatientHomePage');
    } catch (e) {
      print('Error selecting patient: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('PatientSelectionPage: build called');
    return Scaffold(
      backgroundColor: Color(0xFF1565C0), // Deep blue background
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 60, horizontal: 32),
              color: Color(0xFF1565C0),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    color: Color(0xFF42A5F5).withOpacity(0.4), // Light blue
                    child: Icon(
                      Icons.local_hospital,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 32),
                  Text(
                    'PATIENT CARE SYSTEM',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: 60,
                    height: 2,
                    color: Color(0xFF42A5F5),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Pilih nomor pasien anda untuk melanjutkan',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFBBDEFB),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            
            // Patient Cards
            Expanded(
              child: Container(
                width: double.infinity,
                color: Color(0xFFF5F5F5), // Light gray background
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Pasien 01
                      _buildPatientCard(
                        patientId: 'pasien01',
                        patientName: 'PASIEN 01',
                        roomNumber: '101',
                        isFirst: true,
                      ),
                      SizedBox(height: 10), // Minimal gap
                      
                      // Pasien 02
                      _buildPatientCard(
                        patientId: 'pasien02',
                        patientName: 'PASIEN 02',
                        roomNumber: '102',
                        isFirst: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard({
    required String patientId,
    required String patientName,
    required String roomNumber,
    required bool isFirst,
  }) {
    return InkWell(
      onTap: () => _selectPatient(patientId, patientName, roomNumber),
      child: Container(
        width: double.infinity,
        height: 80,
        color: isFirst ? Color(0xFF1976D2) : Color(0xFF42A5F5), // Different blue shades
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                color: Colors.white.withValues(alpha: 0.2),
                child: Icon(
                  Icons.person,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 27),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      patientName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'KAMAR $roomNumber',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                color: Colors.white.withValues(alpha: 0.2),
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}