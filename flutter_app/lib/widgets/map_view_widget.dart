import 'package:flutter/material.dart';
import 'custom_widgets.dart';

class LocationMapViewWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String complaintId;

  const LocationMapViewWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city = 'Madurai',
    this.complaintId = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: CivicColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.map_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'GIS Incident Map Location',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    city,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Visual Vector Map Container
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0), // Map grid background color
            ),
            child: Stack(
              children: [
                // Custom Map Grid Lines Painter
                Positioned.fill(
                  child: CustomPaint(
                    painter: GridMapPainter(),
                  ),
                ),

                // Map Pin Marker
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: CivicColors.darkBg,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: Text(
                          complaintId.isNotEmpty ? complaintId : 'GPS Incident Locked',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Monospace'),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Icon(
                        Icons.location_on,
                        color: CivicColors.accentRed,
                        size: 38,
                      ),
                      Container(
                        width: 12,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),

                // Map Scale / Controls overlay
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Scale: 1:500m • GPS High Accuracy', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ),
                ),
              ],
            ),
          ),

          // Coordinates & Address Footer
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.my_location_rounded, color: CivicColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'LAT: ${latitude.toStringAsFixed(6)}  |  LNG: ${longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: CivicColors.darkBg, fontFamily: 'Monospace'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.home_work_outlined, color: Colors.grey, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$address ($city)',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GridMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0;

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14.0;

    final roadBorderPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 16.0;

    // Draw grid
    for (double i = 0; i < size.width; i += 24) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 24) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw main arterial roads
    final mainRoad = Path()
      ..moveTo(0, size.height * 0.5)
      ..lineTo(size.width, size.height * 0.5);

    final crossRoad = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.5, size.height);

    canvas.drawPath(mainRoad, roadBorderPaint);
    canvas.drawPath(mainRoad, roadPaint);

    canvas.drawPath(crossRoad, roadBorderPaint);
    canvas.drawPath(crossRoad, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
