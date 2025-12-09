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
  String _adminName = 'Admin';
  String _adminEmail = 'admin@example.com';
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;

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
    });
  }

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
                      columns: const [
                        DataColumn(
                          label: Text(
                            'User ID',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'First Name',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Middle Name',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Last Name',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Email',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Role',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                      ],
                      rows: _filteredUsers.map((user) {
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
                          'Showing 1 to ${_filteredUsers.length} of ${_filteredUsers.length} entries',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: null,
                              child: Text(
                                'Previous',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7A5AF5), Color(0xFF5B4AC7)],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '1',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: null,
                              child: Text(
                                'Next',
                                style: TextStyle(color: Colors.grey[400]),
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