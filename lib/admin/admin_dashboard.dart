import 'package:flutter/material.dart';
import 'package:flutter_application_2/widgets/app_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final TextEditingController _searchController = TextEditingController();
  String _adminName = '';
  String _adminEmail = '';
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  int _currentPage = 1;
  final int _rowsPerPage = 10;
  String _sortColumn = 'id';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await Supabase.instance.client
          .from('users')
          .select()
          .order('user_id', ascending: true);
      
      setState(() {
        _users = users.map<Map<String, dynamic>>((user) => {
          'id': user['user_id'],
          'firstName': user['first_name'] ?? '',
          'middleName': user['middle_name'] ?? '',
          'lastName': user['last_name'] ?? '',
          'email': user['email'] ?? '',
          'role': user['user_type'] ?? 'student',
        }).toList();
        _filteredUsers = _users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAdminProfile() async {
    try {
      final email = Supabase.instance.client.auth.currentUser?.email;
      if (email != null) {
        final profile = await Supabase.instance.client
            .from('users')
            .select()
            .eq('email', email)
            .single();
        
        String capitalize(String? text) {
          if (text == null || text.isEmpty) return '';
          return text[0].toUpperCase() + text.substring(1).toLowerCase();
        }
        
        setState(() {
          _adminName = '${capitalize(profile['first_name'])} ${capitalize(profile['middle_name'])} ${capitalize(profile['last_name'])}'.trim();
          _adminEmail = email;
        });
      }
    } catch (e) {
      // Keep default values
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) {
          return user['id'].toString().contains(query.toLowerCase()) ||
              user['firstName'].toLowerCase().contains(query.toLowerCase()) ||
              user['middleName'].toLowerCase().contains(query.toLowerCase()) ||
              user['lastName'].toLowerCase().contains(query.toLowerCase()) ||
              user['email'].toLowerCase().contains(query.toLowerCase()) ||
              user['role'].toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
      _currentPage = 1;
      _sortUsers();
    });
  }

  void _sortUsers() {
    _filteredUsers.sort((a, b) {
      dynamic aValue = a[_sortColumn];
      dynamic bValue = b[_sortColumn];
      
      if (aValue == null) return 1;
      if (bValue == null) return -1;
      
      int comparison = aValue.toString().toLowerCase().compareTo(bValue.toString().toLowerCase());
      return _sortAscending ? comparison : -comparison;
    });
  }

  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
      _sortUsers();
    });
  }

  List<Map<String, dynamic>> get _paginatedUsers {
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    return _filteredUsers.sublist(
      startIndex,
      endIndex > _filteredUsers.length ? _filteredUsers.length : endIndex,
    );
  }

  int get _totalPages => (_filteredUsers.length / _rowsPerPage).ceil();

  int get totalUsers => _users.length;
  int get mayorCount => _users.where((u) => u['role'] == 'mayor').length;
  int get studentCount => _users.where((u) => u['role'] == 'student').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF5B6ADB)),
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Row(
              children: [
                Text(
                  'Welcome, $_adminName',
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7A5AF5), Color(0xFF5B4AC7)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ADMIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: AppDrawer(
        userType: 'admin',
        userName: _adminName,
        userEmail: _adminEmail,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Users',
                    value: totalUsers.toString(),
                    color: const Color(0xFF5B6ADB),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'Mayors',
                    value: mayorCount.toString(),
                    color: const Color(0xFF5B6ADB),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'Students',
                    value: studentCount.toString(),
                    color: const Color(0xFF5B6ADB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Registered Users Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Registered Users',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: _filterUsers,
                                decoration: InputDecoration(
                                  hintText: 'Search by User ID, Name, Email, or Role...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey[400],
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF5B6ADB),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                _filterUsers('');
                              },
                              child: const Text(
                                'Clear',
                                style: TextStyle(
                                  color: Color(0xFF5B6ADB),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Table
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        Colors.grey[50],
                      ),
                      sortColumnIndex: ['id', 'firstName', 'middleName', 'lastName', 'email', 'role'].indexOf(_sortColumn),
                      sortAscending: _sortAscending,
                      columns: [
                        DataColumn(
                          label: const Text(
                            'User ID',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                          ),
                          onSort: (columnIndex, ascending) => _onSort('id'),
                        ),
                        DataColumn(
                          label: const Text(
                            'First Name',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                          ),
                          onSort: (columnIndex, ascending) => _onSort('firstName'),
                        ),
                        DataColumn(
                          label: const Text(
                            'Middle Name',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                          ),
                          onSort: (columnIndex, ascending) => _onSort('middleName'),
                        ),
                        DataColumn(
                          label: const Text(
                            'Last Name',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                          ),
                          onSort: (columnIndex, ascending) => _onSort('lastName'),
                        ),
                        DataColumn(
                          label: const Text(
                            'Email',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                          ),
                          onSort: (columnIndex, ascending) => _onSort('email'),
                        ),
                        DataColumn(
                          label: const Text(
                            'Role',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                          ),
                          onSort: (columnIndex, ascending) => _onSort('role'),
                        ),
                      ],
                      rows: _paginatedUsers.map((user) {
                        return DataRow(
                          cells: [
                            DataCell(Text(user['id'].toString())),
                            DataCell(Text(user['firstName'])),
                            DataCell(Text(user['middleName'])),
                            DataCell(Text(user['lastName'])),
                            DataCell(Text(user['email'])),
                            DataCell(Text(user['role'])),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  
                  // Footer
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${(_currentPage - 1) * _rowsPerPage + 1} to ${(_currentPage * _rowsPerPage) > _filteredUsers.length ? _filteredUsers.length : (_currentPage * _rowsPerPage)} of ${_filteredUsers.length} entries',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                              child: Text(
                                'Previous',
                                style: TextStyle(color: _currentPage > 1 ? const Color(0xFF5B6ADB) : Colors.grey[400]),
                              ),
                            ),
                            ...List.generate(
                              _totalPages > 5 ? 5 : _totalPages,
                              (index) {
                                int pageNum = _currentPage <= 3 ? index + 1 : _currentPage - 2 + index;
                                if (pageNum > _totalPages) return const SizedBox.shrink();
                                return GestureDetector(
                                  onTap: () => setState(() => _currentPage = pageNum),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: _currentPage == pageNum
                                          ? const LinearGradient(colors: [Color(0xFF7A5AF5), Color(0xFF5B4AC7)])
                                          : null,
                                      color: _currentPage == pageNum ? null : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      pageNum.toString(),
                                      style: TextStyle(
                                        color: _currentPage == pageNum ? Colors.white : Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            TextButton(
                              onPressed: _currentPage < _totalPages ? () => setState(() => _currentPage++) : null,
                              child: Text(
                                'Next',
                                style: TextStyle(color: _currentPage < _totalPages ? const Color(0xFF5B6ADB) : Colors.grey[400]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}