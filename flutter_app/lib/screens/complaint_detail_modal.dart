import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/map_view_widget.dart';

class ComplaintDetailModal extends StatelessWidget {
  final ComplaintModel complaint;

  const ComplaintDetailModal({super.key, required this.complaint});

  static void show(BuildContext context, ComplaintModel complaint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ComplaintDetailModal(complaint: complaint),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle & top bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.id,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Monospace',
                        color: CivicColors.primary,
                      ),
                    ),
                    Text(
                      '${complaint.date} • ${complaint.time}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    StatusBadge(status: complaint.status),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Preview
                  if (complaint.imageUrl != null && complaint.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey.shade100,
                        child: Image.network(
                          complaint.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Issue Title & Severity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          complaint.issueLabel.isNotEmpty ? complaint.issueLabel : complaint.issue,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CivicColors.darkBg),
                        ),
                      ),
                      SeverityBadge(severity: complaint.severity),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Timeline Track
                  const Text('Resolution Progress Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: CivicColors.darkBg)),
                  const SizedBox(height: 8),
                  TimelineTracker(status: complaint.status),
                  const SizedBox(height: 20),

                  // Interactive Map View showing Location, Lat, Lng, City & Marker!
                  LocationMapViewWidget(
                    latitude: complaint.latitude,
                    longitude: complaint.longitude,
                    address: complaint.address,
                    city: complaint.city,
                    complaintId: complaint.id,
                  ),
                  const SizedBox(height: 20),

                  // Metadata Grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildMetaRow('Assigned Department', complaint.department),
                        const Divider(),
                        _buildMetaRow('Assigned Field Officer', complaint.officer),
                        const Divider(),
                        _buildMetaRow('Registered User Email', complaint.userEmail),
                        const Divider(),
                        _buildMetaRow('City / District', complaint.city),
                        const Divider(),
                        _buildMetaRow('Latitude, Longitude', '${complaint.latitude.toStringAsFixed(6)}, ${complaint.longitude.toStringAsFixed(6)}'),
                        const Divider(),
                        _buildMetaRow('Address', complaint.address),
                        const Divider(),
                        _buildMetaRow('AI Confidence Score', '${(complaint.confidence * 100).round()}%'),
                        if (complaint.vehicleCount != null) ...[
                          const Divider(),
                          _buildMetaRow('Traffic Telemetry', '${complaint.vehicleCount} Vehicles (${complaint.trafficLevel})'),
                        ],
                        if (complaint.lightStatus != null) ...[
                          const Divider(),
                          _buildMetaRow('Luminaire Circuit', 'Status: ${complaint.lightStatus}'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Officer / Department Notes
                  if (complaint.notes != null && complaint.notes!.isNotEmpty) ...[
                    const Text('Department Response & Field Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: CivicColors.darkBg)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        complaint.notes!,
                        style: TextStyle(color: Colors.blue.shade900, fontSize: 13, height: 1.3),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: CivicColors.darkBg),
            ),
          ),
        ],
      ),
    );
  }
}
