import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

class ScholarRecordsScreen extends StatefulWidget {
  const ScholarRecordsScreen({super.key});

  @override
  State<ScholarRecordsScreen> createState() => _ScholarRecordsScreenState();
}

class _ScholarRecordsScreenState extends State<ScholarRecordsScreen> {
  String _selectedTab = 'Active Applications';
  String _selectedFilter = 'All';
  String _searchQuery = '';
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    try {
      final apps = await Supabase.instance.client
          .from('application')
          .select()
          .order('submission_date', ascending: false);

      setState(() {
        _applications = apps.map<Map<String, dynamic>>((app) => {
          'id': '#${app['application_id']}',
          'firstName': app['first_name'] ?? '',
          'middleName': app['middle_name'] ?? '',
          'lastName': app['last_name'] ?? '',
          'studentId': app['student_id'] ?? 'N/A',
          'course': app['course'] ?? 'N/A',
          'year': app['year_level'] ?? 'N/A',
          'gwa': app['gwa']?.toString() ?? 'N/A',
          'type': app['scholarship_type'] ?? 'New Application',
          'status': (app['status'] ?? 'pending').toString().capitalize(),
          'dateApplied': app['submission_date']?.toString().split('T')[0] ?? 'N/A',
          'application_id': app['application_id'],
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading applications: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredApplications {
    List<Map<String, dynamic>> filtered = _applications;

    // Apply status filter
    if (_selectedFilter != 'All') {
      filtered = filtered
          .where((app) => app['status'] == _selectedFilter)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((app) {
        final searchLower = _searchQuery.toLowerCase();
        return app['firstName'].toString().toLowerCase().contains(searchLower) ||
            app['lastName'].toString().toLowerCase().contains(searchLower) ||
            app['studentId'].toString().toLowerCase().contains(searchLower) ||
            app['course'].toString().toLowerCase().contains(searchLower);
      }).toList();
    }

    return filtered;
  }

  int get _totalCount => _applications.length;
  int get _approvedCount => _applications.where((app) => app['status'] == 'Approved').length;
  int get _pendingCount => _applications.where((app) => app['status'] == 'Pending').length;
  int get _rejectedCount => _applications.where((app) => app['status'] == 'Rejected').length;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),
          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoSection(),
                          const SizedBox(height: 30),
                          _buildStatsCards(),
                          const SizedBox(height: 30),
                          _buildTabButtons(),
                          const SizedBox(height: 20),
                          _buildFilterButtons(),
                          const SizedBox(height: 30),
                          _buildApplicationsTable(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 30),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: const Icon(Icons.location_city, size: 40, color: Colors.blue),
          ),
          const SizedBox(height: 20),
          const Text(
            'MajayjayScholars',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 30),
          _buildSidebarItem(Icons.dashboard, 'Mayor Dashboard', false),
          const SizedBox(height: 8),
          _buildSidebarItem(Icons.people, 'View Scholars', false),
          const SizedBox(height: 8),
          _buildSidebarItem(Icons.folder, 'Scholar Records', true),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(12),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF6366F1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.white : Colors.grey),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        dense: true,
        onTap: () {
          if (!isActive) Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(30),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
              const SizedBox(width: 12),
              const Icon(Icons.folder, color: Colors.grey),
              const SizedBox(width: 12),
              const Text(
                'Scholar Records',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back to Dashboard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complete Scholarship Records',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View and manage all scholarship applications',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(child: _buildStatCard(_totalCount.toString(), 'Total', Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard(_approvedCount.toString(), 'Approved', Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard(_pendingCount.toString(), 'Pending', Colors.orange)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard(_rejectedCount.toString(), 'Rejected', Colors.red)),
      ],
    );
  }

  Widget _buildStatCard(String number, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Text(
            number,
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButtons() {
    return Row(
      children: [
        _buildTabButton('Active Applications', Icons.description),
        const SizedBox(width: 12),
        _buildTabButton('Renewal Applications', Icons.refresh),
        const SizedBox(width: 12),
        _buildTabButton('Archived Applications', Icons.archive),
      ],
    );
  }

  Widget _buildTabButton(String label, IconData icon) {
    final isSelected = _selectedTab == label;
    return ElevatedButton.icon(
      onPressed: () => setState(() => _selectedTab = label),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF6366F1) : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Row(
      children: [
        _buildFilterChip('All'),
        _buildFilterChip('Approved'),
        _buildFilterChip('Pending'),
        _buildFilterChip('Rejected'),
        const Spacer(),
        SizedBox(
          width: 300,
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search by name, ID, course, status...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => setState(() => _selectedFilter = label),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF6366F1),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        checkmarkColor: Colors.white,
        side: BorderSide(color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade300),
      ),
    );
  }

  Widget _buildApplicationsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Application Records',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
              columns: const [
                DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('First Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Middle Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Last Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Student ID', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Course', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Year', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('GWA', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Date Applied', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _filteredApplications.map((app) {
                return DataRow(cells: [
                  DataCell(Text(app['id'])),
                  DataCell(Text(app['firstName'])),
                  DataCell(Text(app['middleName'])),
                  DataCell(Text(app['lastName'])),
                  DataCell(Text(app['studentId'])),
                  DataCell(Text(app['course'])),
                  DataCell(Text(app['year'])),
                  DataCell(Text(app['gwa'], style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                  DataCell(_buildTypeBadge(app['type'])),
                  DataCell(_buildStatusBadge(app['status'])),
                  DataCell(Text(app['dateApplied'])),
                  DataCell(_buildActionButtons(app)),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type,
        style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Approved':
        color = Colors.green;
        break;
      case 'Pending':
        color = Colors.orange;
        break;
      case 'Rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> app) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () => _viewApplicationDetails(app),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(60, 32),
          ),
          child: const Text('View', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _archiveApplication(app),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(60, 32),
          ),
          child: const Text('Archive', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  void _viewApplicationDetails(Map<String, dynamic> app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.description, color: Color(0xFF6366F1)),
            const SizedBox(width: 12),
            Text('Application ${app['id']}'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Name', '${app['firstName']} ${app['middleName']} ${app['lastName']}'),
                _buildDetailRow('Student ID', app['studentId']),
                _buildDetailRow('Course', app['course']),
                _buildDetailRow('Year Level', app['year']),
                _buildDetailRow('GWA', app['gwa']),
                _buildDetailRow('Type', app['type']),
                _buildDetailRow('Status', app['status']),
                _buildDetailRow('Date Applied', app['dateApplied']),
              ],
            ),
          ),
        ),
        actions: [
          if (app['status'] == 'Pending') ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _updateApplicationStatus(app, 'Approved');
              },
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _updateApplicationStatus(app, 'Rejected');
              },
              icon: const Icon(Icons.cancel, size: 18),
              label: const Text('Reject'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateApplicationStatus(Map<String, dynamic> app, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('application')
          .update({'status': newStatus.toLowerCase()})
          .eq('application_id', app['application_id']);
      
      await _fetchApplications();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application ${app['id']} has been $newStatus'),
            backgroundColor: newStatus == 'Approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _archiveApplication(Map<String, dynamic> app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Application'),
        content: Text('Are you sure you want to archive application ${app['id']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Application ${app['id']} archived')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }
}