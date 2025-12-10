import 'package:flutter/material.dart';
import 'package:flutter_application_2/widgets/app_drawer.dart';
import 'package:flutter_application_2/student/apply_scholarship_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

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

  Future<void> _editApplication(Map<String, dynamic> app) async {
    final studentIdController = TextEditingController(text: app['student_id']);
    final courseController = TextEditingController(text: app['course']);
    final yearLevelController = TextEditingController(text: app['year_level']);
    final gwaController = TextEditingController(text: app['gwa']);
    
    final images = <String, dynamic>{'school_id': null, 'id_picture': null, 'birth_cert': null, 'grades': null};
    final imageBytes = <String, Uint8List?>{'school_id': null, 'id_picture': null, 'birth_cert': null, 'grades': null};

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Application'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: studentIdController,
                  decoration: const InputDecoration(labelText: 'Student ID'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: courseController,
                  decoration: const InputDecoration(labelText: 'Course'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: yearLevelController,
                  decoration: const InputDecoration(labelText: 'Year Level'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: gwaController,
                  decoration: const InputDecoration(labelText: 'GWA'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Text('Update Documents (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...[('school_id', 'School ID'), ('id_picture', 'ID Picture'), ('birth_cert', 'Birth Certificate'), ('grades', 'Grades')].map((doc) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final file = await picker.pickImage(source: ImageSource.gallery);
                        if (file != null) {
                          setState(() {
                            if (kIsWeb) {
                              file.readAsBytes().then((bytes) => setState(() => imageBytes[doc.$1] = bytes));
                            } else {
                              images[doc.$1] = File(file.path);
                            }
                          });
                        }
                      },
                      icon: Icon(images[doc.$1] != null || imageBytes[doc.$1] != null ? Icons.check_circle : Icons.upload_file, size: 16),
                      label: Text(doc.$2),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: images[doc.$1] != null || imageBytes[doc.$1] != null ? Colors.green : const Color(0xFF667EEA),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667EEA)),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final updateData = {
          'student_id': studentIdController.text,
          'course': courseController.text,
          'year_level': yearLevelController.text,
          'gwa': double.tryParse(gwaController.text),
        };

        // Upload new documents if selected
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final studentId = studentIdController.text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
        
        for (var entry in images.entries) {
          if (entry.value != null || imageBytes[entry.key] != null) {
            final path = '$studentId/${entry.key}_$timestamp.jpg';
            if (kIsWeb && imageBytes[entry.key] != null) {
              await Supabase.instance.client.storage.from('scholarship_bucket').uploadBinary(path, imageBytes[entry.key]!);
            } else if (entry.value != null) {
              await Supabase.instance.client.storage.from('scholarship_bucket').upload(path, entry.value);
            }
            final url = Supabase.instance.client.storage.from('scholarship_bucket').getPublicUrl(path);
            updateData['${entry.key}_path'] = url;
          }
        }

        await Supabase.instance.client.from('application').update(updateData).eq('application_id', app['application_id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Application updated successfully'), backgroundColor: Colors.green),
          );
          _fetchApplications();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    studentIdController.dispose();
    courseController.dispose();
    yearLevelController.dispose();
    gwaController.dispose();
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

      // Fetch applications
      final apps = await Supabase.instance.client
          .from('application')
          .select()
          .eq('user_id', userId)
          .order('submission_date', ascending: false);

      // Fetch renewals
      final renewals = await Supabase.instance.client
          .from('renew')
          .select()
          .eq('user_id', userId)
          .order('submission_date', ascending: false);

      final allApplications = <Map<String, dynamic>>[];

      // Add applications
      allApplications.addAll(apps.map<Map<String, dynamic>>((app) => {
        'application_id': app['application_id'],
        'type': 'Application',
        'first_name': app['first_name'] ?? '',
        'middle_name': app['middle_name'] ?? '',
        'last_name': app['last_name'] ?? '',
        'student_id': app['student_id'] ?? 'N/A',
        'course': app['course'] ?? 'N/A',
        'year_level': app['year_level'] ?? 'N/A',
        'gwa': app['gwa']?.toString() ?? 'N/A',
        'status': (app['status'] ?? 'pending').toLowerCase(),
        'submission_date': app['submission_date']?.toString().split('T')[0] ?? 'N/A',
      }));

      // Add renewals
      allApplications.addAll(renewals.map<Map<String, dynamic>>((ren) => {
        'application_id': ren['renewal_id'],
        'type': 'Renewal',
        'first_name': ren['first_name'] ?? '',
        'middle_name': ren['middle_name'] ?? '',
        'last_name': ren['last_name'] ?? '',
        'student_id': ren['student_id'] ?? 'N/A',
        'course': ren['course'] ?? 'N/A',
        'year_level': ren['year_level'] ?? 'N/A',
        'gwa': ren['gwa']?.toString() ?? 'N/A',
        'status': (ren['status'] ?? 'pending').toLowerCase(),
        'submission_date': ren['submission_date']?.toString().split('T')[0] ?? 'N/A',
      }));

      // Sort by submission date
      allApplications.sort((a, b) => (b['submission_date'] ?? '').compareTo(a['submission_date'] ?? ''));

      setState(() {
        _applications = allApplications;
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: app['type'] == 'Renewal' ? const Color(0xFF7C3AED).withOpacity(0.1) : const Color(0xFF667EEA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            app['type'] ?? 'Application',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: app['type'] == 'Renewal' ? const Color(0xFF7C3AED) : const Color(0xFF667EEA),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ID: #${app['application_id']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ],
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
          if (status == 'pending') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _editApplication(app),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit Application'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
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