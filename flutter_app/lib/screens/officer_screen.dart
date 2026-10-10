import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/map_view_widget.dart';
import 'complaint_detail_modal.dart';
import 'login_screen.dart';

class OfficerScreen extends StatefulWidget {
  final String deptTitle;
  final String departmentCode;

  const OfficerScreen({
    super.key,
    required this.deptTitle,
    required this.departmentCode,
  });

  @override
  State<OfficerScreen> createState() => _OfficerScreenState();
}

class _OfficerScreenState extends State<OfficerScreen> {
  UserModel? _currentUser;
  List<ComplaintModel> _complaints = [];
  bool _isLoading = true;
  String _selectedStatusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
  }

  Future<void> _loadUserAndData() async {
    final user = await ApiService.getCurrentUser();
    if (mounted) setState(() => _currentUser = user);
    await _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    if (mounted) setState(() => _isLoading = true);
    final list = await ApiService.getComplaints(
      department: widget.departmentCode,
      status: _selectedStatusFilter,
    );
    if (mounted) {
      setState(() {
        _complaints = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatusDialog(ComplaintModel complaint) async {
    // STOP UPDATE OPTION IF RESOLVED
    if (complaint.status == 'RESOLVED') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Complaint is RESOLVED and cannot be edited further.'),
          backgroundColor: CivicColors.accentEmerald,
        ),
      );
      return;
    }

    String newStatus = complaint.status;
    final notesController = TextEditingController(text: complaint.notes ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text('Update Incident ${complaint.id}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Incident Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: newStatus,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'NEW', child: Text('NEW')),
                  DropdownMenuItem(value: 'IN PROGRESS', child: Text('IN PROGRESS')),
                  DropdownMenuItem(value: 'RESOLVED', child: Text('RESOLVED')),
                ],
                onChanged: (val) {
                  if (val != null) setDlgState(() => newStatus = val);
                },
              ),
              const SizedBox(height: 16),
              const Text('Officer Field Notes & Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter action taken, crew deployed, maintenance completed...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: CivicColors.primary),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Save & Notify User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final String officerNotes = notesController.text.trim();
      await ApiService.updateStatus(
        complaint.id,
        newStatus,
        notes: officerNotes,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $newStatus. Email sent to ${complaint.userEmail}'),
            backgroundColor: CivicColors.accentEmerald,
          ),
        );
      }
      await _fetchComplaints();
    }
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
    int totalCount = _complaints.length;
    int newCount = _complaints.where((c) => c.status == 'NEW').length;
    int progressCount = _complaints.where((c) => c.status == 'IN PROGRESS').length;
    int resolvedCount = _complaints.where((c) => c.status == 'RESOLVED').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: CivicColors.darkBg,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.deptTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(_currentUser?.fullName ?? 'Department Officer', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchComplaints,
            tooltip: 'Refresh Queue',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: _logout,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchComplaints,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics Cards
              Row(
                children: [
                  _buildStatCard('Total', '$totalCount', Colors.blue.shade700, Colors.blue.shade50),
                  const SizedBox(width: 8),
                  _buildStatCard('New', '$newCount', Colors.amber.shade800, Colors.amber.shade50),
                  const SizedBox(width: 8),
                  _buildStatCard('In Progress', '$progressCount', Colors.purple.shade700, Colors.purple.shade50),
                  const SizedBox(width: 8),
                  _buildStatCard('Resolved', '$resolvedCount', Colors.green.shade700, Colors.green.shade50),
                ],
              ),
              const SizedBox(height: 20),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['ALL', 'NEW', 'IN PROGRESS', 'RESOLVED'].map((s) {
                    final isSelected = _selectedStatusFilter == s;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(s),
                        selected: isSelected,
                        selectedColor: CivicColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedStatusFilter = s);
                            _fetchComplaints();
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // List of Complaints
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_complaints.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                      SizedBox(height: 12),
                      Text('No incidents found for this filter.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _complaints.length,
                  itemBuilder: (context, index) {
                    final c = _complaints[index];
                    final bool isResolved = c.status == 'RESOLVED';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  c.id,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Monospace', color: CivicColors.primary),
                                ),
                                Row(
                                  children: [
                                    StatusBadge(status: c.status),
                                    const SizedBox(width: 6),
                                    SeverityBadge(severity: c.severity),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(c.issueLabel.isNotEmpty ? c.issueLabel : c.issue, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('User: ${c.userName} (${c.userEmail})', style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),

                            // Map View Location for Department Field Crew
                            LocationMapViewWidget(
                              latitude: c.latitude,
                              longitude: c.longitude,
                              address: c.address,
                              city: c.city,
                              complaintId: c.id,
                            ),
                            const SizedBox(height: 12),

                            if (c.notes != null && c.notes!.isNotEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade100),
                                ),
                                child: Text('Department Notes: ${c.notes}', style: TextStyle(fontSize: 12, color: Colors.blue.shade900)),
                              ),
                              const SizedBox(height: 12),
                            ],

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => ComplaintDetailModal.show(context, c),
                                  icon: const Icon(Icons.info_outline, size: 16),
                                  label: const Text('Details'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: isResolved ? null : () => _updateStatusDialog(c),
                                  icon: Icon(
                                    isResolved ? Icons.lock_rounded : Icons.edit_note,
                                    size: 18,
                                  ),
                                  label: Text(isResolved ? 'Resolved (Locked)' : 'Update Status'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isResolved ? Colors.grey.shade400 : CivicColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color textCol, Color bgCol) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bgCol,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textCol)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 10, color: textCol, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
