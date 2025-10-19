import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'patient_selection_page.dart';

class PatientHomePage extends StatefulWidget {
  final String patientId;

  PatientHomePage({required this.patientId});

  @override
  _PatientHomePageState createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage>
    with TickerProviderStateMixin {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _statusSub; // simpan subscription
  bool isRequesting = false;
  String patientName = '';
  String roomNumber = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    print('PatientHomePage: initState called for patient ${widget.patientId}');
    _loadPatientInfo();
    _listenToStatus();

    // Animasi untuk tombol
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    print('PatientHomePage: initialization complete');
  }

  @override
  void dispose() {
    // batalkan listener supaya gak panggil setState setelah dispose
    _statusSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // Helper: aman convert ke String
  String _toSafeString(dynamic v, {String fallback = '-'}) {
    if (v == null) return fallback;
    return v.toString();
  }

  // Load data pasien dari Firebase (dengan parsing aman)
  void _loadPatientInfo() async {
    try {
      print('Loading patient info for: ${widget.patientId}');
      final snapshot = await _dbRef.child('patients/${widget.patientId}').get();

      if (!mounted) {
        print('Widget disposed before patient info loaded, aborting setState.');
        return;
      }

      if (snapshot.exists) {
        final data = snapshot.value;
        // data bisa Map<dynamic, dynamic> atau tipe lain — amanin dulu
        if (data is Map) {
          final nameRaw = data['name'];
          final roomRaw = data['room'];

          // convert ke string (jika di DB int maka toString() akan merubahnya)
          final loadedName = _toSafeString(nameRaw, fallback: 'Unknown');
          final loadedRoom = _toSafeString(roomRaw, fallback: '-');

          if (!mounted) return;
          setState(() {
            patientName = loadedName;
            roomNumber = loadedRoom;
          });
          print('Patient info loaded: $patientName, Room $roomNumber');
        } else {
          print('Unexpected data type for patient: ${data.runtimeType}');
        }
      } else {
        print('No patient data found, creating default data for: ${widget.patientId}');
        // Create default patient data if not exists
        String defaultName = widget.patientId == 'pasien01' ? 'Pasien 01' : 'Pasien 02';
        String defaultRoom = widget.patientId == 'pasien01' ? '101' : '102';
        
        await _dbRef.child('patients/${widget.patientId}').set({
          'name': defaultName,
          'room': defaultRoom,
          'status': 0,
          'pesan': '',
        });
        
        if (!mounted) return;
        setState(() {
          patientName = defaultName;
          roomNumber = defaultRoom;
        });
        print('Default patient data created: $patientName, Room $roomNumber');
      }
    } catch (e, st) {
      print('Error loading patient info: $e\n$st');
    }
  }

  // Listen perubahan status real-time (simpan subscription)
  void _listenToStatus() {
    try {
      print('👂 Setting up status listener for: ${widget.patientId}');
      _statusSub = _dbRef
          .child('patients/${widget.patientId}/status')
          .onValue
          .listen((event) {
        final raw = event.snapshot.value;
        // status bisa berupa int (1/0) atau bool (true/false) tergantung sumber
        bool newStatus;
        if (raw is int) {
          newStatus = raw == 1;
        } else if (raw is String) {
          final lower = raw.toLowerCase();
          newStatus = raw == '1' || lower == 'true';
        } else if (raw is bool) {
          newStatus = raw;
        } else {
          newStatus = false;
        }

        print('Status update received (raw=$raw) -> newStatus: $newStatus');

        if (!mounted) {
          print('Widget disposed; ignoring status update.');
          return;
        }

        setState(() {
          isRequesting = newStatus;
        });
      }, onError: (err) {
        print('Status listener error: $err');
      });
    } catch (e) {
      print('Error setting up status listener: $e');
    }
  }

  // Kirim request bantuan ke Firebase (cek mounted sebelum akses context)
  Future<void> _requestHelp() async {
    try {
      await _dbRef.child('patients/${widget.patientId}').update({
        'status': 1,
        'pesan': '$patientName Membutuhkan Bantuan',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Permintaan bantuan telah dikirim'),
            ],
          ),
          backgroundColor: Color(0xFF1976D2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Batalkan request bantuan
  Future<void> _cancelRequest() async {
    try {
      await _dbRef.child('patients/${widget.patientId}').update({
        'status': 0,
        'pesan': '',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Permintaan dibatalkan'),
            ],
          ),
          backgroundColor: Color(0xFF42A5F5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error: $e');
    }
  }

  // Ganti pasien (sama seperti sebelumnya)
  Future<void> _changePatient() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PatientSelectionPage()),
      );
    } catch (e) {
      print('Change patient error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('PatientHomePage: build called (isRequesting: $isRequesting)');
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header dengan gradient
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
                    // Top bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              color: Colors.white.withOpacity(0.2),
                              child: Icon(
                                Icons.local_hospital,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'PATIENT CARE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: _changePatient,
                          child: Icon(Icons.exit_to_app, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Welcome text
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat datang,',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          Text(
                            patientName.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
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

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Status Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isRequesting ? Color(0xFFFFEBEE) : Color(0xFFE3F2FD),
                        border: Border.all(
                          color: isRequesting ? Color(0xFFE57373) : Color(0xFF64B5F6),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            color: isRequesting ? Color(0xFFE57373) : Color(0xFF64B5F6),
                            child: Icon(
                              isRequesting ? Icons.notifications_active : Icons.check_circle,
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
                                  isRequesting ? 'STATUS AKTIF' : 'STATUS NORMAL',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isRequesting ? Color(0xFFD32F2F) : Color(0xFF1976D2),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  isRequesting
                                      ? 'Permintaan bantuan sedang diproses'
                                      : 'Tidak ada permintaan bantuan aktif',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF666666),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Patient Info Cards
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(20),
                            color: Colors.white,
                            child: Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  color: Color(0xFF42A5F5),
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'PASIEN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF999999),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  patientName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF1565C0),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 2),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(20),
                            color: Colors.white,
                            child: Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  color: Color(0xFF66BB6A),
                                  child: Icon(
                                    Icons.room,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'KAMAR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF999999),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  roomNumber,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF1565C0),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 40),

                    // Main Action Button
                    ScaleTransition(
                      scale: isRequesting ? _pulseAnimation : AlwaysStoppedAnimation(1.0),
                      child: InkWell(
                        onTap: isRequesting ? _cancelRequest : _requestHelp,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: isRequesting ? Color(0xFFE53935) : Color(0xFF1976D2),
                            boxShadow: [
                              BoxShadow(
                                color: (isRequesting ? Color(0xFFE53935) : Color(0xFF1976D2))
                                    .withOpacity(0.3),
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                color: Colors.white.withOpacity(0.2),
                                child: Icon(
                                  isRequesting ? Icons.cancel_outlined : Icons.add_alert,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                isRequesting ? 'BATALKAN' : 'PANGGIL',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                isRequesting ? 'BANTUAN' : 'PERAWAT',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 32),

                    // Quick Actions
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                color: Color(0xFF42A5F5),
                                child: Icon(
                                  Icons.info_outline,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'INFORMASI',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1565C0),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Text(
                            isRequesting
                                ? '• Perawat akan segera datang ke kamar Anda\n• Harap tetap tenang dan tunggu bantuan\n• Tekan tombol merah untuk membatalkan permintaan'
                                : '• Tekan tombol biru untuk memanggil perawat\n• Gunakan hanya dalam keadaan darurat\n• Perawat akan segera merespons panggilan Anda',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF666666),
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
