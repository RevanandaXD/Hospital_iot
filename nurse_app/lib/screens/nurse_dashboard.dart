import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class NurseDashboard extends StatefulWidget {
  @override
  _NurseDashboardState createState() => _NurseDashboardState();
}

class _NurseDashboardState extends State<NurseDashboard> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  Set<String> processedRequests = {};
  StreamSubscription<DatabaseEvent>? _patientsSubscription;

  @override
  void initState() {
    super.initState();
    print('NurseDashboard: initState called');
    _listenToPatientRequests();
  }

  @override
  void dispose() {
    _patientsSubscription?.cancel();
    super.dispose();
  }

  void _listenToPatientRequests() {
    _patientsSubscription = _dbRef.child('patients').onValue.listen(
      (event) {
        try {
          final snapshot = event.snapshot;

          final data = snapshot.value;
          if (data is! Map) {
            print('Data bukan Map, tipe: ${data.runtimeType}');
            return;
          }

          // Iterate through patients
          final patients = data as Map<dynamic, dynamic>;
          
          patients.forEach((key, value) {
            try {
              if (value is! Map) {
                return;
              }

              final patientData = value as Map<dynamic, dynamic>;
              final status = patientData['status'];
              
              // Konversi status dengan aman
              bool isActive = false;
              if (status is bool) {
                isActive = status;
              } else if (status is int) {
                isActive = status == 1;
              } else if (status is String) {
                isActive = status.toLowerCase() == 'true' || status == '1';
              }

              if (isActive) {
                // Buat ID unik untuk request
                final timestamp = patientData['timestamp'] ?? 0;
                final requestId = '$key-$timestamp';

                if (!processedRequests.contains(requestId)) {
                  processedRequests.add(requestId);

                  // Ambil data dengan konversi tipe yang aman
                  final patientName =
                      patientData['name']?.toString() ?? 'Unknown Patient';
                  final message =
                      patientData['pesan']?.toString() ?? 
                      'Membutuhkan bantuan';
                  final roomNumber =
                      patientData['room']?.toString() ?? '-';

                  
                  // Tampilkan popup
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _showRequestPopup(
                        key.toString(),
                        patientName,
                        message,
                        roomNumber,
                      );
                    } else {
                    }
                  });
                } else {
                  print('Request already processed, skipping');
                }
              } else {
                print('Not active, cleaning up');
                // Jika status tidak aktif, bersihkan dari processed
                final timestamp = patientData['timestamp'] ?? 0;
                final requestId = '$key-$timestamp';
                processedRequests.remove(requestId);
              }
            } catch (e) {
              print('Error processing patient: $e');
            }
          });
        } catch (e) {
          print('Error in listener: $e');
        }
      },
      onError: (error) {
        print('Firebase listener error: $error');
      },
    );
  }

  void _showRequestPopup(
    String patientId,
    String patientName,
    String message,
    String roomNumber,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Container(
            padding: EdgeInsets.all(20),
            color: Color(0xFFE53935),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  color: Colors.white.withValues(alpha: 0.2),
                  child: Icon(
                    Icons.emergency,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'PERMINTAAN BANTUAN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          titlePadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Info
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    color: Color(0xFF1565C0),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patientName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'KAMAR $roomNumber',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // Message
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                color: Color(0xFFF5F5F5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PESAN:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Container(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        color: Color(0xFF666666),
                        child: Text(
                          'SEGERA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 2),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        _completeRequest(patientId, patientName);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        color: Color(0xFF4CAF50),
                        child: Text(
                          'SELESAI',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          actionsPadding: EdgeInsets.zero,
        );
      },
    );
  }

  Future<void> _completeRequest(String patientId, String patientName) async {
    try {
      await _dbRef.child('patients/$patientId').update({
        'status': 0,
        'pesan': '',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Penanganan $patientName selesai'),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

    } catch (e) {
      print('Error completing request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyelesaikan permintaan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              height: 130,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          color: Colors.white.withValues(alpha: 0.2),
                          child: Icon(
                            Icons.local_hospital,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'NURSE DASHBOARD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat datang,',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          Text(
                            'Perawat',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content - Waiting state
            Expanded(
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        color: Color(0xFF1565C0),
                        child: Icon(
                          Icons.notifications_none,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'MENUNGGU PERMINTAAN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1565C0),
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Pop-up akan muncul otomatis ketika\npasien membutuhkan bantuan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 32),
                      // Status indicator
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        color: Color(0xFF4CAF50),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'SISTEM AKTIF',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
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
}