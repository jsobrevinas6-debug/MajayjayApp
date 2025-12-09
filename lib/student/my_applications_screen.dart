import 'package:flutter/material.dart';
import 'package:flutter_application_2/widgets/app_drawer.dart';
import 'package:flutter_application_2/student/apply_scholarship_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyApplicationsScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const MyApplicationsScreen({
    super.key,
    this.userName = 'Student',
    this.userEmail = 'student@example.com',
  });

  //asdasdasd

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    setState(() => _isLoading = true);
    try {
      final userEmail = Supabase.instance.client.auth.currentUser?.email;
      if (userEmail == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userResponse = await Supabase.instance.client
          .from('users')
          .select('user_id')
          .eq('email', userEmail)
          .single();
      
      final userId = userResponse['user_id'] as int;

      final apps = await Supabase.instance.client
          .from('application')
          .select()
          .eq('user_id', userId)
          .order('submission_date', ascending: false);

      setState(() {
        _applications = apps.map<Map<String, dynamic>>((app) => {
          'application_id': app['application_id'],
          'first_name': app['first_name'] ?? '',
          'middle_name': app['middle_name'] ?? '',
          'last_name': app['last_name'] ?? '',
          'student_id': app['student_id'] ?? 'N/A',
          'course': app['course'] ?? 'N/A',
          'year_level': app['year_level'] ?? 'N/A',
          'gwa': app['gwa']?.toString() ?? 'N/A',
          'status': (app['status'] ?? 'pending').toLowerCase(),
          'submission_date': app['submission_date']?.toString().split('T')[0] ?? 'N/A',
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF667EEA)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          '📋 My Applications',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF667EEA)),
                  onPressed: _fetchApplications,
                ),
        ],
      ),
      drawer: AppDrawer(
        userType: 'student',
        userName: widget.userName,
        userEmail: widget.userEmail,
      ),
      body: _applications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _fetchApplications,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 20),
                    _buildStatsGrid(),
                    const SizedBox(height: 20),
                    ..._applications.map((app) => _buildApplicationCard(app)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ).createShader(bounds),
            child: const Text(
              'Your Scholarship Applications',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Track the status of your scholarship applications and view complete details.',
            style: TextStyle(color: Color(0xFF718096)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final total = _applications.length;
    final approved = _applications.where((a) => a['status'] == 'approved').length;
    final pending = _applications.where((a) => a['status'] == 'pending').length;
    final rejected = _applications.where((a) => a['status'] == 'rejected').length;

    return Row(
      children: [
        Expanded(child: _buildStatCard(total.toString(), 'Total', const Color(0xFF667EEA))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(approved.toString(), 'Approved', const Color(0xFF48BB78))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(pending.toString(), 'Pending', const Color(0xFFFFA500))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(rejected.toString(), 'Rejected', const Color(0xFFF56565))),
      ],
    );
  }

  Widget _buildStatCard(String number, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            number,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF718096),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(60),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '📭',
              style: TextStyle(fontSize: 60),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Applications Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You haven't submitted any scholarship applications.",
              style: TextStyle(color: Color(0xFF718096)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ApplyScholarshipScreen(
                      userName: widget.userName,
                      userEmail: widget.userEmail,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                backgroundColor: const Color(0xFF667EEA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Apply for Scholarship',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> app) {
    final status = app['status'] ?? 'pending';
    Color borderColor;
    Color badgeColor;
    String badgeText;

    switch (status) {
      case 'approved':
        borderColor = const Color(0xFF48BB78);
        badgeColor = const Color(0xFFD4EDDA);
        badgeText = '✓ Approved';
        break;
      case 'rejected':
        borderColor = const Color(0xFFF56565);
        badgeColor = const Color(0xFFF8D7DA);
        badgeText = '✗ Rejected';
        break;
      default:
        borderColor = const Color(0xFFFFA500);
        badgeColor = const Color(0xFFFFF3CD);
        badgeText = '⏳ Pending Review';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${app['first_name']} ${app['middle_name']} ${app['last_name']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Application ID: #${app['application_id']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📅 Submitted: ${app['submission_date']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildDetailRow('Student ID', app['student_id'] ?? 'N/A'),
                _buildDetailRow('Course', app['course'] ?? 'N/A'),
                _buildDetailRow('Year Level', app['year_level'] ?? 'N/A'),
                _buildDetailRow('GWA', app['gwa'] ?? 'N/A'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }
}