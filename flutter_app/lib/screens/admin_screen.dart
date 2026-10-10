import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../services/api_service.dart';
import '../widgets/custom_widgets.dart';
import 'complaint_detail_modal.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<ComplaintModel> _allComplaints = [];
  bool _isLoading = true;
  String _selectedDept = 'ALL';
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    if (mounted) setState(() => _isLoading = true);
    final list = await ApiService.getComplaints(
      department: _selectedDept,
      status: _selectedStatus,
    );
    if (mounted) {
      setState(() {
        _allComplaints = list;
        _isLoading = false;
      });
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
    int total = _allComplaints.length;
    int pending = _allComplaints.where((c) => c.status != 'RESOLVED').length;
    int resolved = _allComplaints.where((c) => c.status == 'RESOLVED').length;
    int roadCount = _allComplaints.where((c) => c.departmentCode == 'ROAD').length;
    int streetCount = _allComplaints.where((c) => c.departmentCode == 'STREET_LIGHT').length;
    int trafficCount = _allComplaints.where((c) => c.departmentCode == 'TRAFFIC').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: CivicColors.darkBg,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Municipal Admin Portal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('CivicEye AI System Management', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchComplaints,
            tooltip: 'Refresh System Stats',
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
              // Executive Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [CivicColors.darkBg, CivicColors.cardBg],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CivicColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Executive Operations Center', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildMetricCol('Total Issues', '$total', Colors.blue.shade400),
                        _buildMetricCol('Pending', '$pending', Colors.amber.shade400),
                        _buildMetricCol('Resolved', '$resolved', Colors.green.shade400),
                        _buildMetricCol('AI Accuracy', '98.4%', CivicColors.accentEmerald),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Department Counters
              const Text('Department Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildDeptCard('Road', '$roadCount', Icons.add_road, Colors.orange),
                  const SizedBox(width: 8),
                  _buildDeptCard('Street Light', '$streetCount', Icons.lightbulb, Colors.amber),
                  const SizedBox(width: 8),
                  _buildDeptCard('Traffic', '$trafficCount', Icons.traffic, Colors.red),
                ],
              ),
              const SizedBox(height: 24),

              // Filters & Search
              const Text('All City Complaints', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedDept,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ALL', child: Text('All Departments')),
                        DropdownMenuItem(value: 'ROAD', child: Text('Road Dept')),
                        DropdownMenuItem(value: 'STREET_LIGHT', child: Text('Street Light Dept')),
                        DropdownMenuItem(value: 'TRAFFIC', child: Text('Traffic Dept')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _selectedDept = v);
                          _fetchComplaints();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ALL', child: Text('All Statuses')),
                        DropdownMenuItem(value: 'NEW', child: Text('New')),
                        DropdownMenuItem(value: 'IN PROGRESS', child: Text('In Progress')),
                        DropdownMenuItem(value: 'RESOLVED', child: Text('Resolved')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _selectedStatus = v);
                          _fetchComplaints();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Complaints Table/List
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_allComplaints.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(
                    child: Text('No complaints matching filter.', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _allComplaints.length,
                  itemBuilder: (context, index) {
                    final c = _allComplaints[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1.5,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        onTap: () => ComplaintDetailModal.show(context, c),
                        title: Row(
                          children: [
                            Text(c.id, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Monospace', fontSize: 13, color: CivicColors.primary)),
                            const SizedBox(width: 8),
                            DepartmentBadge(department: c.department),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.issueLabel.isNotEmpty ? c.issueLabel : c.issue, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 2),
                              Text('${c.address} • ${c.date}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                            ],
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            StatusBadge(status: c.status),
                            const SizedBox(height: 4),
                            SeverityBadge(severity: c.severity),
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

  Widget _buildMetricCol(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildDeptCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
