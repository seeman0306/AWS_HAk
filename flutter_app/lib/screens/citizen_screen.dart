import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/complaint_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/r_logo.dart';
import 'complaint_detail_modal.dart';
import 'login_screen.dart';

class CitizenScreen extends StatefulWidget {
  const CitizenScreen({super.key});

  @override
  State<CitizenScreen> createState() => _CitizenScreenState();
}

class _CitizenScreenState extends State<CitizenScreen> {
  int _currentTabIndex = 0; // 0: Home, 1: Complaints, 2: Notifications

  UserModel? _currentUser;
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isDetecting = false;
  bool _isSubmitting = false;
  Map<String, dynamic>? _aiResult;
  bool _submissionSuccess = false;
  ComplaintModel? _submittedComplaint;

  double _latitude = 9.512345;
  double _longitude = 77.633421;
  String _addressStr = 'NH-44, Melur Road, Madurai';
  String _cityName = 'Madurai';
  bool _isLocating = false;

  List<ComplaintModel> _myComplaints = [];
  List<CivicNotification> _notifications = [];
  bool _isLoadingComplaints = true;

  // Filter & Search
  String _statusFilter = 'ALL'; // ALL, ONGOING, COMPLETED
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  int _userRating = 5;

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
    _fetchGpsLocation();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndData() async {
    final user = await ApiService.getCurrentUser();
    if (mounted) setState(() => _currentUser = user);
    await _loadComplaintsAndNotifications();
  }

  Future<void> _loadComplaintsAndNotifications() async {
    if (mounted) setState(() => _isLoadingComplaints = true);
    final user = _currentUser ?? await ApiService.getCurrentUser();
    final list = await ApiService.getComplaints(
      userEmail: user?.email,
      userId: user?.id,
    );
    final notifs = await ApiService.getNotifications();
    if (mounted) {
      setState(() {
        _myComplaints = list;
        _notifications = notifs;
        _isLoadingComplaints = false;
      });
    }
  }

  Future<void> _fetchGpsLocation() async {
    if (mounted) setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          Position pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 4),
          );
          if (mounted) {
            setState(() {
              _latitude = pos.latitude;
              _longitude = pos.longitude;
              _addressStr = '${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)} (GPS Locked)';
            });
          }
        }
      }
    } catch (e) {
      debugPrint('GPS fetch fallback: $e');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  // Pick image AND AUTOMATICALLY TRIGGER AI DETECTION IMMEDIATELY!
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      if (mounted) {
        setState(() {
          _selectedImage = picked;
          _imageBytes = bytes;
          _aiResult = null;
          _submissionSuccess = false;
        });
      }
      // AUTOMATICALLY RUN AI DETECTION (No "Detect" button needed!)
      await _runAutoAiDetection(bytes, picked.name);
    }
  }

  Future<void> _runAutoAiDetection(Uint8List bytes, String fileName) async {
    if (mounted) setState(() => _isDetecting = true);

    try {
      final res = await ApiService.detectIssue(
        imageBytes: bytes,
        fileName: fileName,
        lat: _latitude,
        lng: _longitude,
      );
      if (mounted) {
        setState(() {
          _aiResult = res;
        });

        // Enforce Threshold Checks
        final double conf = ((res['confidence'] is num) ? (res['confidence'] as num).toDouble() : 0.92);
        if (conf < 0.50) {
          _showBelow50WarningDialog(conf);
        } else if (conf < 0.90) {
          _showBelow90WarningDialog(conf);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Automatic AI Detection Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetecting = false);
    }
  }

  // WARNING DIALOG FOR CONFIDENCE < 90% and >= 50%
  void _showBelow90WarningDialog(double conf) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: CivicColors.accentAmber, size: 28),
            const SizedBox(width: 8),
            const Text('Moderate Confidence Warning', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Detection Confidence is ${(conf * 100).round()}%.',
              style: const TextStyle(fontWeight: FontWeight.bold, color: CivicColors.darkBg, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'The detected problem severity is moderate or low. Do you still want to raise this complaint or cancel?',
              style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _selectedImage = null;
                _imageBytes = null;
                _aiResult = null;
              });
            },
            child: const Text('Cancel & Re-take Photo', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CivicColors.primary),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Yes, Raise Complaint', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // WARNING DIALOG FOR CONFIDENCE < 50%
  void _showBelow50WarningDialog(double conf) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.report_problem_rounded, color: CivicColors.accentRed, size: 28),
            SizedBox(width: 8),
            Text('Low Confidence Detection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Detection Confidence is ${(conf * 100).round()}%.',
              style: const TextStyle(fontWeight: FontWeight.bold, color: CivicColors.accentRed, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'It is a very basic or minor problem. We recommend ignoring it and moving on to other civic reports.',
              style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _selectedImage = null;
                _imageBytes = null;
                _aiResult = null;
              });
            },
            child: const Text('Ignore & Re-take Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitComplaint() async {
    if (_aiResult == null) return;
    if (mounted) setState(() => _isSubmitting = true);

    final now = DateTime.now();
    final id = ApiService.generateId();
    final userEmail = _currentUser?.email ?? 'citizen@civiceye.ai';
    final userName = _currentUser?.fullName ?? 'Citizen User';

    final newComplaint = ComplaintModel(
      id: id,
      userId: _currentUser?.id ?? 'usr_citizen',
      userName: userName,
      userEmail: userEmail,
      issueType: _aiResult!['issueType'] ?? 'pothole',
      issue: _aiResult!['issueTitle'] ?? 'Pothole / Damaged Road',
      issueLabel: _aiResult!['issueTitle'] ?? 'Pothole Detected',
      confidence: (_aiResult!['confidence'] is num) ? (_aiResult!['confidence'] as num).toDouble() : 0.94,
      severity: _aiResult!['severity'] ?? 'HIGH',
      departmentCode: _aiResult!['department'] ?? 'ROAD',
      department: _aiResult!['departmentName'] ?? 'Road Department',
      latitude: _latitude,
      longitude: _longitude,
      location: '${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}',
      address: _addressStr,
      city: _cityName,
      status: 'NEW',
      imageUrl: _selectedImage != null ? _selectedImage!.path : 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=600',
      vehicleCount: _aiResult!['vehicleCount'],
      trafficLevel: _aiResult!['trafficLevel'],
      lightStatus: _aiResult!['lightStatus'],
      date: DateFormat('dd MMM yyyy').format(now),
      time: DateFormat('hh:mm a').format(now),
      timestamp: now.millisecondsSinceEpoch,
      officer: _aiResult!['department'] == 'STREET_LIGHT'
          ? 'Street Light Officer (V. Nathan)'
          : _aiResult!['department'] == 'TRAFFIC'
              ? 'Traffic Officer (K. Selvan)'
              : 'Road Officer (R. Sharma)',
    );

    try {
      final saved = await ApiService.submitComplaint(newComplaint);

      // Add Notification
      ApiService.addNotification(
        CivicNotification(
          id: 'notif_${now.millisecondsSinceEpoch}',
          title: 'Complaint Submitted Successfully',
          message: 'Incident $id registered & auto-routed to ${saved.department}. Confirmation email sent to $userEmail.',
          timestamp: 'Just now',
          type: 'processing',
          complaintId: id,
        ),
      );

      if (mounted) {
        setState(() {
          _submittedComplaint = saved;
          _submissionSuccess = true;
          _aiResult = null;
          _selectedImage = null;
          _imageBytes = null;
        });

        // Show Feedback Dialog
        _showThanksFeedbackDialog(saved);
      }
      await _loadComplaintsAndNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showThanksFeedbackDialog(ComplaintModel complaint) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: CivicColors.accentEmerald, size: 52),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Thank You for Your Feedback! 🙏',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CivicColors.darkBg),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your civic incident ${complaint.id} has been registered and auto-dispatched to the ${complaint.department}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.email_outlined, color: CivicColors.primary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Email sent to: ${complaint.userEmail}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: CivicColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Rate CivicEye AI Speed & Accuracy',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CivicColors.primary),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            iconSize: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            icon: Icon(
                              index < _userRating ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: const Color(0xFFF59E0B),
                            ),
                            onPressed: () => setDialogState(() => _userRating = index + 1),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CivicColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      setState(() => _currentTabIndex = 1); // Switch to My Complaints tab
                    },
                    child: const Text('View My Complaints', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadNotifs = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light grayish slate web background
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const RLogoWidget(size: 28, opacity: 1.0),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    children: [
                      TextSpan(text: 'CivicEye '),
                      TextSpan(text: 'AI', style: TextStyle(color: Color(0xFFD4AF37))),
                    ],
                  ),
                ),
                const Text('Citizen Reporting Portal', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Citizen',
                style: TextStyle(color: Color(0xFF1E40AF), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildHomeTabExactMatch(),
          _buildMyComplaintsTab(),
          _buildNotificationsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() => _currentTabIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: CivicColors.primary,
        unselectedItemColor: Colors.grey.shade500,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 10,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.assignment_rounded),
            label: 'My Complaints',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: unreadNotifs > 0,
              label: Text('$unreadNotifs'),
              child: const Icon(Icons.notifications_rounded),
            ),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }

  // EXACT WEB UI MATCH FOR HOME TAB
  Widget _buildHomeTabExactMatch() {
    double conf = _aiResult != null ? ((_aiResult!['confidence'] is num) ? (_aiResult!['confidence'] as num).toDouble() : 0.94) : 0.94;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP HERO BLUE BANNER (Matches Web UI Screenshot Exactly)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Text(
                    'AI-POWERED DETECTION ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Report a Civic Issue',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Capture a photo or upload from gallery. Our AI instantly classifies the issue and routes it to the correct municipal department — zero manual selection needed.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 18),

                // Category Pills Row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildHeroPill('Pothole & Road Damage'),
                    _buildHeroPill('Street Light Failure'),
                    _buildHeroPill('Traffic Congestion'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. REPORT A NEW ISSUE CARD (Matches Web UI Screenshot Exactly)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 2,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report a New Issue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 16),

                  // Open Camera & Upload Photo Buttons
                  Row(
                    children: [
                      // Open Camera Button (Solid Blue)
                      Expanded(
                        child: Material(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () => _pickImage(ImageSource.camera),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
                              child: Column(
                                children: const [
                                  Icon(Icons.camera_alt_outlined, color: Colors.white, size: 36),
                                  SizedBox(height: 10),
                                  Text(
                                    'Open Camera',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Capture live photo',
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Upload Photo Button (Dashed/Outlined)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF2563EB), width: 1.5, style: BorderStyle.solid),
                          ),
                          child: InkWell(
                            onTap: () => _pickImage(ImageSource.gallery),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
                              child: Column(
                                children: const [
                                  Icon(Icons.crop_original_rounded, color: Color(0xFF2563EB), size: 36),
                                  SizedBox(height: 10),
                                  Text(
                                    'Upload Photo',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Select from gallery',
                                    style: TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3. GPS LOCATION CARD (Matches Web UI Screenshot Exactly)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // Light Blue tint
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on_outlined, color: Color(0xFF2563EB), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GPS LOCATION & CITY',
                        style: TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_addressStr ($_cityName)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      const Text(
                        'Sub-meter accuracy location active',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  onPressed: _fetchGpsLocation,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF93C5FD)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLocating
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Refresh', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // 4. AUTOMATIC AI DETECTION STATE & RESULT
          if (_imageBytes != null) ...[
            const SizedBox(height: 18),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 220,
                            width: double.infinity,
                            color: Colors.black,
                            child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                          ),
                        ),
                        if (_isDetecting)
                          Container(
                            height: 220,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 3),
                                ),
                                SizedBox(height: 14),
                                Text(
                                  '🤖 AI Scanning & Auto-Classifying...',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Zero manual selection required',
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () => setState(() {
                            _selectedImage = null;
                            _imageBytes = null;
                            _aiResult = null;
                          }),
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          label: const Text('Clear Image', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                        if (_aiResult != null)
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                              SizedBox(width: 4),
                              Text('Auto-Detected', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Auto-Detected Result & Submit Card
          if (_aiResult != null) ...[
            const SizedBox(height: 18),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: conf >= 0.90
                      ? const Color(0xFF10B981)
                      : conf >= 0.50
                          ? CivicColors.accentAmber
                          : CivicColors.accentRed,
                  width: 1.5,
                ),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _aiResult!['issueTitle'] ?? 'Issue Detected',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        SeverityBadge(severity: _aiResult!['severity'] ?? 'HIGH'),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Confidence Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('AI Classification Confidence', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          '${(conf * 100).round()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: conf >= 0.90
                                ? const Color(0xFF10B981)
                                : conf >= 0.50
                                    ? CivicColors.accentAmber
                                    : CivicColors.accentRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: conf,
                        backgroundColor: Colors.grey.shade200,
                        color: conf >= 0.90
                            ? const Color(0xFF10B981)
                            : conf >= 0.50
                                ? CivicColors.accentAmber
                                : CivicColors.accentRed,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // THRESHOLD WARNING BANNER
                    if (conf >= 0.90) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.bolt_rounded, color: Color(0xFF16A34A), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'High Confidence (≥90%): Full Automation Enabled & Instant Priority Routing.',
                                style: TextStyle(color: Color(0xFF15803D), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (conf >= 0.50) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Moderate Confidence (<90%): Problem level is low/moderate. Please confirm if you want to raise.',
                                style: TextStyle(color: Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.report_problem_rounded, color: Color(0xFFDC2626), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Low Confidence (<50%): Basic problem or uncertain. Recommended to ignore and move on.',
                                style: TextStyle(color: Color(0xFFB91C1C), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // SIMULATION TESTING TOOLBAR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Simulate Threshold:', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            InkWell(
                              onTap: () => setState(() => _aiResult!['confidence'] = 0.95),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(6)),
                                child: const Text('95% High', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () {
                                setState(() => _aiResult!['confidence'] = 0.72);
                                _showBelow90WarningDialog(0.72);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                                child: const Text('72% Mod', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber)),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () {
                                setState(() => _aiResult!['confidence'] = 0.42);
                                _showBelow50WarningDialog(0.42);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(6)),
                                child: const Text('42% Low', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Auto-routed Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.alt_route_rounded, color: Color(0xFF2563EB)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('AUTO-ROUTED TO', style: TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                              Text(
                                _aiResult!['departmentName'] ?? 'Department',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitComplaint,
                        icon: _isSubmitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          conf >= 0.90
                              ? 'Automated Priority Submit & Send Email'
                              : 'Raise Complaint & Send Email',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // TAB 1: MY COMPLAINTS & DEPARTMENT RESPONSES PAGE
  Widget _buildMyComplaintsTab() {
    List<ComplaintModel> filtered = _myComplaints.where((c) {
      if (_statusFilter == 'ONGOING') {
        if (c.status == 'RESOLVED') return false;
      } else if (_statusFilter == 'COMPLETED') {
        if (c.status != 'RESOLVED') return false;
      }

      if (_searchQuery.isNotEmpty) {
        final title = (c.issueLabel.isNotEmpty ? c.issueLabel : c.issue).toLowerCase();
        final id = c.id.toLowerCase();
        final dept = c.department.toLowerCase();
        return title.contains(_searchQuery) || id.contains(_searchQuery) || dept.contains(_searchQuery);
      }

      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadComplaintsAndNotifications,
      child: Column(
        children: [
          // Filter & Search Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search complaints by ID, title or department...',
                    hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),

                // Status Filter Chips (Wrapped in horizontal scroll for narrow screens)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'All (${_myComplaints.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip('ONGOING', 'Ongoing / Processing'),
                      const SizedBox(width: 8),
                      _buildFilterChip('COMPLETED', 'Completed'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoadingComplaints
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.assignment_outlined, size: 52, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text('No complaints found matching "$_statusFilter"', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final c = filtered[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 1.5,
                            child: InkWell(
                              onTap: () => ComplaintDetailModal.show(context, c),
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            c.id,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Monospace', color: CivicColors.primary),
                                          ),
                                        ),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            StatusBadge(status: c.status),
                                            SeverityBadge(severity: c.severity),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      c.issueLabel.isNotEmpty ? c.issueLabel : c.issue,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('${c.department} • ${c.date} • City: ${c.city}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    const SizedBox(height: 12),

                                    // Timeline Track
                                    TimelineTracker(status: c.status),
                                    const SizedBox(height: 12),

                                    // DEPARTMENT RESPONSE SECTION
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.blue.shade100),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.quickreply_rounded, size: 16, color: CivicColors.primary),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Department Response (${c.officer})',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: CivicColors.primary),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            c.notes != null && c.notes!.isNotEmpty
                                                ? c.notes!
                                                : 'Complaint received and queued for field inspection by ${c.department}.',
                                            style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final bool isSelected = _statusFilter == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedColor: CivicColors.primary,
      backgroundColor: Colors.grey.shade100,
      onSelected: (val) {
        if (val) setState(() => _statusFilter = key);
      },
    );
  }

  // TAB 2: NOTIFICATIONS TAB
  Widget _buildNotificationsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notif = _notifications[index];
        IconData icon;
        Color color;

        switch (notif.type) {
          case 'resolved':
            icon = Icons.check_circle_rounded;
            color = CivicColors.accentEmerald;
            break;
          case 'processing':
            icon = Icons.autorenew_rounded;
            color = CivicColors.accentAmber;
            break;
          case 'ongoing':
            icon = Icons.engineering_rounded;
            color = CivicColors.primary;
            break;
          default:
            icon = Icons.notifications_active_rounded;
            color = CivicColors.primary;
            break;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 22),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(notif.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                Text(notif.timestamp, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(notif.message, style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
            ),
            onTap: () {
              setState(() => notif.isRead = true);
              if (notif.complaintId != null) {
                final match = _myComplaints.where((c) => c.id == notif.complaintId).firstOrNull;
                if (match != null) ComplaintDetailModal.show(context, match);
              }
            },
          ),
        );
      },
    );
  }
}
