class ComplaintModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String issueType;
  final String issue;
  final String issueLabel;
  final double confidence;
  final String severity; // HIGH, MEDIUM, LOW
  final String departmentCode; // ROAD, STREET_LIGHT, TRAFFIC
  final String department;
  final double latitude;
  final double longitude;
  final String location;
  final String address;
  final String city;
  String status; // NEW, IN PROGRESS, RESOLVED
  final String? imageUrl;
  final int? vehicleCount;
  final String? trafficLevel;
  final String? lightStatus;
  String? notes;
  final String date;
  final String time;
  final int timestamp;
  final String officer;

  ComplaintModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userEmail = 'citizen@civiceye.ai',
    required this.issueType,
    required this.issue,
    required this.issueLabel,
    required this.confidence,
    required this.severity,
    required this.departmentCode,
    required this.department,
    required this.latitude,
    required this.longitude,
    required this.location,
    required this.address,
    this.city = 'Madurai',
    required this.status,
    this.imageUrl,
    this.vehicleCount,
    this.trafficLevel,
    this.lightStatus,
    this.notes,
    required this.date,
    required this.time,
    required this.timestamp,
    required this.officer,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      userName: json['userName'] ?? json['user_name'] ?? 'Citizen User',
      userEmail: json['userEmail'] ?? json['user_email'] ?? 'citizen@civiceye.ai',
      issueType: json['issueType'] ?? json['issue_type'] ?? 'pothole',
      issue: json['issue'] ?? json['issue_title'] ?? 'Pothole',
      issueLabel: json['issueLabel'] ?? json['issue_title'] ?? 'Pothole Detected',
      confidence: (json['confidence'] is num) ? (json['confidence'] as num).toDouble() : 0.92,
      severity: json['severity'] ?? 'HIGH',
      departmentCode: json['departmentCode'] ?? json['department_code'] ?? 'ROAD',
      department: json['department'] ?? json['department_name'] ?? 'Road Department',
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : 9.512345,
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : 77.633421,
      location: json['location'] ?? json['location_str'] ?? '9.512345, 77.633421',
      address: json['address'] ?? 'GPS Location Locked',
      city: json['city'] ?? 'Madurai',
      status: json['status'] ?? 'NEW',
      imageUrl: json['imageUrl'] ?? json['image_url'],
      vehicleCount: json['vehicleCount'] ?? json['vehicle_count'],
      trafficLevel: json['trafficLevel'] ?? json['traffic_level'],
      lightStatus: json['lightStatus'] ?? json['light_status'],
      notes: json['notes'] ?? json['officer_notes'],
      date: json['date'] ?? '18 Sep 2025',
      time: json['time'] ?? '10:00 AM',
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      officer: json['officer'] ?? 'Department Officer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'issueType': issueType,
      'issue': issue,
      'issueLabel': issueLabel,
      'confidence': confidence,
      'severity': severity,
      'departmentCode': departmentCode,
      'department': department,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'address': address,
      'city': city,
      'status': status,
      'imageUrl': imageUrl,
      'vehicleCount': vehicleCount,
      'trafficLevel': trafficLevel,
      'lightStatus': lightStatus,
      'notes': notes,
      'date': date,
      'time': time,
      'timestamp': timestamp,
      'officer': officer,
    };
  }
}
