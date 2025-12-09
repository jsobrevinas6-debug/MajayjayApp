import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_2/widgets/app_drawer.dart';
import 'package:url_launcher/url_launcher.dart';

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
  List<Map<String, dynamic>> _renewals = [];
  bool _isLoading = true;
  int _currentPage = 1;
  final int _rowsPerPage = 10;
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _fetchApplications();
    _fetchRenewals();
  }

  Future<void> _fetchApplications() async {
    try {
      var query = Supabase.instance.client
          .from('application')
          .select();
      
      // Filter based on selected tab
      if (_selectedTab == 'Active Applications') {
        query = query.eq('archived', false);
      } else if (_selectedTab == 'Archived Applications') {
        query = query.eq('archived', true);
      } else if (_selectedTab == 'Renewal Applications') {
        setState(() {
          _applications = [];
          _isLoading = false;
        });
        return;
      }
      
      final apps = await query.order('submission_date', ascending: false);

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
          'type': 'Application',
          'status': (app['status'] ?? 'pending').toString().capitalize(),
          'dateApplied': app['submission_date']?.toString().split('T')[0] ?? 'N/A',
          'application_id': app['application_id'],
          'renewal_id': null,
          'address': app['address'] ?? 'N/A',
          'reason': app['reason'] ?? 'N/A',
          'schoolId': app['school_id_path'] ?? '',
          'idPicture': app['id_picture_path'] ?? '',
          'birthCert': app['birth_certificate_path'] ?? '',
          'grades': app['grades_path'] ?? '',
          'cor': app['cor_path'] ?? '',
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

  Future<void> _fetchRenewals() async {
    try {
      var query = Supabase.instance.client
          .from('renew')
          .select();
      
      // Filter based on selected tab
      if (_selectedTab == 'Renewal Applications') {
        query = query.eq('archived', false);
      } else if (_selectedTab == 'Archived Applications') {
        query = query.eq('archived', true);
      } else if (_selectedTab == 'Active Applications') {
        setState(() {
          _renewals = [];
        });
        return;
      }
      
      final renewals = await query.order('submission_date', ascending: false);

      setState(() {
        _renewals = renewals.map<Map<String, dynamic>>((ren) => {
          'id': '#R${ren['renewal_id']}',
          'firstName': ren['first_name'] ?? '',
          'middleName': ren['middle_name'] ?? '',
          'lastName': ren['last_name'] ?? '',
          'studentId': ren['student_id'] ?? 'N/A',
          'course': ren['course'] ?? 'N/A',
          'year': ren['year_level'] ?? 'N/A',
          'gwa': ren['gwa']?.toString() ?? 'N/A',
          'type': 'Renewal',
          'status': (ren['status'] ?? 'pending').toString().capitalize(),
          'dateApplied': ren['submission_date']?.toString().split('T')[0] ?? 'N/A',
          'application_id': null,
          'renewal_id': ren['renewal_id'],
          'address': ren['address'] ?? 'N/A',
          'reason': ren['reason'] ?? 'N/A',
          'schoolId': ren['school_id'] ?? '',
          'idPicture': ren['id_picture'] ?? '',
          'birthCert': ren['birth_certificate'] ?? '',
          'grades': ren['grades'] ?? '',
          'cor': ren['cor'] ?? '',
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading renewals: $e')),
        );
      }
    }
  }

  void _sortApplications(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      
      _applications.sort((a, b) {
        dynamic aValue, bValue;
        switch (columnIndex) {
          case 0: aValue = a['id']; bValue = b['id']; break;
          case 1: aValue = a['firstName']; bValue = b['firstName']; break;
          case 2: aValue = a['middleName']; bValue = b['middleName']; break;
          case 3: aValue = a['lastName']; bValue = b['lastName']; break;
          case 4: aValue = a['studentId']; bValue = b['studentId']; break;
          case 5: aValue = a['course']; bValue = b['course']; break;
          case 6: aValue = a['year']; bValue = b['year']; break;
          case 7: aValue = a['gwa']; bValue = b['gwa']; break;
          case 8: aValue = a['status']; bValue = b['status']; break;
          case 9: aValue = a['dateApplied']; bValue = b['dateApplied']; break;
          default: return 0;
        }
        return ascending ? Comparable.compare(aValue, bValue) : Comparable.compare(bValue, aValue);
      });
    });
  }

  List<Map<String, dynamic>> get _filteredApplications {
    List<Map<String, dynamic>> filtered = [];
    
    // Select data based on tab
    if (_selectedTab == 'Active Applications') {
      filtered = _applications;
    } else if (_selectedTab == 'Renewal Applications') {
      filtered = _renewals;
    } else if (_selectedTab == 'Archived Applications') {
      filtered = [..._applications, ..._renewals];
    }

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

  List<Map<String, dynamic>> get _paginatedApplications {
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    return _filteredApplications.sublist(
      startIndex,
      endIndex > _filteredApplications.length ? _filteredApplications.length : endIndex,
    );
  }

  int get _totalPages => (_filteredApplications.length / _rowsPerPage).ceil();

  Future<int> get _totalCount async {
    final appsResponse = await Supabase.instance.client.from('application').select().eq('archived', false);
    final renewalsResponse = await Supabase.instance.client.from('renew').select().eq('archived', false);
    return appsResponse.length + renewalsResponse.length;
  }
  
  Future<int> get _activeApplicationsCount async {
    final response = await Supabase.instance.client.from('application').select().eq('archived', false);
    return response.length;
  }
  
  Future<int> get _renewalApplicationsCount async {
    final response = await Supabase.instance.client.from('renew').select().eq('archived', false);
    return response.length;
  }
  
  Future<int> get _archivedCount async {
    final appsResponse = await Supabase.instance.client.from('application').select().eq('archived', true);
    final renewalsResponse = await Supabase.instance.client.from('renew').select().eq('archived', true);
    return appsResponse.length + renewalsResponse.length;
  }

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.grey),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.folder, color: Colors.grey),
            const SizedBox(width: 12),
            const Text(
              'Scholar Records',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),

      ),
      drawer: const AppDrawer(
        userType: 'mayor',
        userName: '',
        userEmail: '',
      ),
      body: SingleChildScrollView(
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
        Expanded(child: _buildStatCardAsync(_totalCount, 'Total', Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCardAsync(_activeApplicationsCount, 'Active Applications', Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCardAsync(_renewalApplicationsCount, 'Renewal Applications', const Color(0xFF7C3AED))),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCardAsync(_archivedCount, 'Archived Applications', Colors.red)),
      ],
    );
  }

  Widget _buildStatCardAsync(Future<int> countFuture, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: FutureBuilder<int>(
        future: countFuture,
        builder: (context, snapshot) {
          return Column(
            children: [
              Text(
                snapshot.hasData ? snapshot.data.toString() : '0',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
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
      onPressed: () {
        setState(() => _selectedTab = label);
        _fetchApplications();
        _fetchRenewals();
      },
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
            onChanged: (value) => setState(() {
              _searchQuery = value;
              _currentPage = 1;
            }),
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
        onSelected: (selected) => setState(() {
          _selectedFilter = label;
          _currentPage = 1;
        }),
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
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              columns: [
                DataColumn(label: const Text('ID', style: TextStyle(fontWeight: FontWeight.bold)), onSort: (columnIndex, ascending) => _sortApplications(columnIndex, ascending)),
                DataColumn(label: const Text('First Name', style: TextStyle(fontWeight: FontWeight.bold)), onSort: (columnIndex, ascending) => _sortApplications(columnIndex, ascending)),
                DataColumn(label: const Text('Middle Name', style: TextStyle(fontWeight: FontWeight.bold)), onSort: (columnIndex, ascending) => _sortApplications(columnIndex, ascending)),
                DataColumn(label: const Text('Last Name', style: TextStyle(fontWeight: FontWeight.bold)), onSort: (columnIndex, ascending) => _sortApplications(columnIndex, ascending)),
                DataColumn(label: const Text('Student ID', style: TextStyle(fontWeight: FontWeight.bold)), onSort: (columnIndex, ascending) => _sortApplications(columnIndex, ascending)),
                DataColumn(label: const Text('Course', style: TextStyle(fontWeight: FontWeight.bold)), onSort: (columnIndex, ascending) => _sortApplications(columnIndex, ascending)),
                DataColumn(label: const Text('Year', style: TextStyle(fontWeight: FontWeight.bold)), onSort: (columnIndex, ascending) => _sortApplications(columnIndex, ascending)),
                DataColumn(label: const Text('GWA', style: TextStyle(fontWeight: FontWeight.bold)), onSort: (columnIndex, ascending) => _sortApplications(columnIndex, ascending)),
                DataColumn(label: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)), onSort: (columnIndex, ascending) => _sortApplications(columnIndex, ascending)),
                DataColumn(label: const Text('Date Applied', style: TextStyle(fontWeight: FontWeight.bold)), onSort: (columnIndex, ascending) => _sortApplications(columnIndex, ascending)),
                const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _paginatedApplications.map((app) {
                return DataRow(cells: [
                  DataCell(Text(app['id'])),
                  DataCell(Text(app['firstName'])),
                  DataCell(Text(app['middleName'])),
                  DataCell(Text(app['lastName'])),
                  DataCell(Text(app['studentId'])),
                  DataCell(Text(app['course'])),
                  DataCell(Text(app['year'])),
                  DataCell(Text(app['gwa'], style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                  DataCell(_buildStatusBadge(app['status'])),
                  DataCell(Text(app['dateApplied'])),
                  DataCell(_buildActionButtons(app)),
                ]);
              }).toList(),
            ),
          ),
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${(_currentPage - 1) * _rowsPerPage + 1} to ${(_currentPage * _rowsPerPage) > _filteredApplications.length ? _filteredApplications.length : (_currentPage * _rowsPerPage)} of ${_filteredApplications.length} entries',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      ...List.generate(
                        _totalPages > 5 ? 5 : _totalPages,
                        (index) {
                          final pageNum = _currentPage <= 3
                              ? index + 1
                              : (_currentPage >= _totalPages - 2
                                  ? _totalPages - 4 + index
                                  : _currentPage - 2 + index);
                          if (pageNum < 1 || pageNum > _totalPages) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              onPressed: () => setState(() => _currentPage = pageNum),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _currentPage == pageNum ? const Color(0xFF6366F1) : Colors.white,
                                foregroundColor: _currentPage == pageNum ? Colors.white : Colors.black,
                                minimumSize: const Size(40, 40),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(pageNum.toString()),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        onPressed: _currentPage < _totalPages ? () => setState(() => _currentPage++) : null,
                        icon: const Icon(Icons.chevron_right),
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
                _buildDetailRow('Address', app['address']),
                _buildDetailRow('Reason', app['reason']),
                _buildDetailRow('Status', app['status']),
                _buildDetailRow('Date Applied', app['dateApplied']),
                const SizedBox(height: 16),
                const Text(
                  '📎 Documents:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                _buildDocumentRow('🆔 School ID', app['schoolId']),
                _buildDocumentRow('📷 2x2 ID Picture', app['idPicture']),
                _buildDocumentRow('📋 Birth Certificate', app['birthCert']),
                _buildDocumentRow('📊 Copy of Grades', app['grades']),
                _buildDocumentRow('📄 COR', app['cor']),
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

  Widget _buildDocumentRow(String label, String path) {
    final hasFile = path.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (hasFile)
            TextButton.icon(
              onPressed: () async {
                // Open URL in browser
                final uri = Uri.parse(path);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('View', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            )
          else
            Row(
              children: [
                Icon(
                  Icons.cancel,
                  size: 16,
                  color: Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  'Missing',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _archiveApplication(Map<String, dynamic> app) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Application'),
        content: Text('Are you sure you want to archive ${app['type']} ${app['id']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (app['type'] == 'Application') {
                  await Supabase.instance.client
                      .from('application')
                      .update({'archived': true})
                      .eq('application_id', app['application_id']);
                } else {
                  await Supabase.instance.client
                      .from('renew')
                      .update({'archived': true})
                      .eq('renewal_id', app['renewal_id']);
                }
                
                await _fetchApplications();
                await _fetchRenewals();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${app['type']} ${app['id']} archived')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error archiving: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }
}