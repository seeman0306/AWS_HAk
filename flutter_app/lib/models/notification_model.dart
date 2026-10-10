class CivicNotification {
  final String id;
  final String title;
  final String message;
  final String timestamp;
  final String type; // 'processing', 'ongoing', 'resolved', 'system'
  final String? complaintId;
  bool isRead;

  CivicNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.complaintId,
    this.isRead = false,
  });

  factory CivicNotification.fromJson(Map<String, dynamic> json) {
    return CivicNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] ?? '',
      type: json['type'] ?? 'system',
      complaintId: json['complaintId'],
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp,
      'type': type,
      'complaintId': complaintId,
      'isRead': isRead,
    };
  }
}
