import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_2/widgets/app_drawer.dart';
import 'package:flutter_application_2/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RenewScholarshipScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const RenewScholarshipScreen({
    super.key,
    this.userName = 'Student',
    this.userEmail = 'student@example.com',
  });

  @override
  State<RenewScholarshipScreen> createState() => _RenewScholarshipScreenState();
}

class _RenewScholarshipScreenState extends State<RenewScholarshipScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Controllers
  final _controllers = {
    'firstName': TextEditingController(),
    'middleName': TextEditingController(),
    'surname': TextEditingController(),
    'studentId': TextEditingController(),
    'contact': TextEditingController(),
    'houseStreet': TextEditingController(),
    'course': TextEditingController(),
    'gwa': TextEditingController(),
    'reason': TextEditingController(),
  };

  String? _selectedSemester;
  String? _selectedYearLevel;
  String? _selectedSHSLevel;
  String? _selectedBarangay;
  
  final _images = <String, File?>{
    'grades': null,
    'id_picture': null,
  };

  bool _isSubmitting = false;
  bool _hasApprovedApplication = false;
  bool _isCheckingApplication = true;
  bool _hasExistingRenewal = false;

  final _semesters = ['First Semester', 'Second Semester', 'Summer'];
  final _shsLevels = ['11th Grade', '12th Grade', 'None'];
  final _yearLevels = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
  
  final _barangays = [
    'Amonoy', 'Bakia', 'Balanac', 'Balayong', 'Banilad', 'Banti', 'Bitaoy', 
    'Botocan', 'Bukal', 'Burgos', 'Burol', 'Coralao', 'Gagalot', 'Ibabang Banga', 
    'Ibabang Bayucain', 'Ilayang Banga', 'Ilayang Bayucain', 'Isabang', 'Malinao', 
    'May-it', 'Munting Kawayan', 'Olla', 'Oobi', 'Origuel (Poblacion)', 'Panalaban', 
    'Pangil', 'Panglan', 'Piit', 'Pook', 'Rizal', 'San Francisco (Poblacion)', 
    'San Isidro', 'San Miguel (Poblacion)', 'San Roque', 'Santa Catalina', 'Suba', 
    'Talortor', 'Tanawan', 'Taytay', 'Villa Nogales'
  ];

  @override
  void initState() {
    super.initState();
    _checkApprovedApplication();
  }

  Future<void> _checkApprovedApplication() async {
    try {
      final userEmail = Supabase.instance.client.auth.currentUser?.email;
      if (userEmail == null) return;

      final userResponse = await Supabase.instance.client
          .from('users')
          .select('user_id')
          .eq('email', userEmail)
          .single();
      
      final userId = userResponse['user_id'] as int;

      final apps = await Supabase.instance.client
          .from('application')
          .select('application_id, status')
          .eq('user_id', userId)
          .eq('status', 'approved');

      final renewals = await Supabase.instance.client
          .from('renew')
          .select('renewal_id')
          .eq('user_id', userId);

      setState(() {
        _hasApprovedApplication = apps.isNotEmpty;
        _hasExistingRenewal = renewals.isNotEmpty;
        _isCheckingApplication = false;
      });
    } catch (e) {
      setState(() => _isCheckingApplication = false);
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );
    if (image != null) setState(() => _images[type] = File(image.path));
  }

  Future<void> _submitRenewal() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate SHS Level
    if (_selectedSHSLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your Senior High School level or None for college!'), backgroundColor: Colors.red),
      );
      return;
    }

    // If college student (None), validate college year level and course
    if (_selectedSHSLevel == 'None') {
      if (_selectedYearLevel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your college year level!'), backgroundColor: Colors.red),
        );
        return;
      }
      if (_controllers['course']?.text.isEmpty ?? true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your course/program!'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    if (_images['grades'] == null || _images['id_picture'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final renewalData = {
        'student_id': 2,
        'student_name': '${_controllers['firstName']!.text} ${_controllers['surname']!.text}',
      };

      await ApiService.submitRenewal(renewalData);
      
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success! 🎉'),
          content: const Text('Your scholarship renewal has been submitted successfully! You will be notified of the decision.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9B59B6), foregroundColor: Colors.white),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting renewal: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingApplication) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F2FF),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasApprovedApplication || _hasExistingRenewal) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F2FF),
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
          title: const Text('🔄 Renew Scholarship', style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.w600)),
        ),
        drawer: AppDrawer(
          userType: 'student',
          userName: widget.userName,
          userEmail: widget.userEmail,
        ),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 4))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _hasExistingRenewal ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                  size: 80,
                  color: _hasExistingRenewal ? const Color(0xFF48BB78) : const Color(0xFFF56565),
                ),
                const SizedBox(height: 20),
                Text(
                  _hasExistingRenewal ? 'Already Renewed' : 'No Approved Application',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF2D3748)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _hasExistingRenewal
                      ? 'You have already submitted a renewal application. You can only renew once per scholarship period.'
                      : 'You need to have an approved scholarship application before you can renew. Please apply for a scholarship first.',
                  style: const TextStyle(color: Color(0xFF718096)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B59B6),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2FF),
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
        title: const Text('🔄 Renew Scholarship', style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.w600)),
      ),
      drawer: AppDrawer(
        userType: 'student',
        userName: widget.userName,
        userEmail: widget.userEmail,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF9B59B6), Color(0xFFBB8FCE)]),
              ),
              child: const Column(
                children: [
                  Text('Scholarship Renewal', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                  SizedBox(height: 8),
                  Text('Renew your scholarship for the upcoming semester', style: TextStyle(fontSize: 14, color: Colors.white70), textAlign: TextAlign.center),
                ],
              ),
            ),

            // Form
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoBox(),
                    const SizedBox(height: 24),

                    _buildSection('👤 Personal Information', [
                      _buildTextField('firstName', 'First Name', 'Juan', Icons.person),
                      _buildTextField('middleName', 'Middle Name', 'Santos', Icons.person_outline, required: false),
                      _buildTextField('surname', 'Surname', 'Dela Cruz', Icons.person),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('studentId', 'Student ID', '2024-12345', Icons.badge)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField('contact', 'Contact Number', '09171234567', Icons.phone, keyboardType: TextInputType.phone, maxLength: 11)),
                        ],
                      ),
                      _buildTextField('houseStreet', 'House No. & Street', 'e.g., 123 Rizal Street', Icons.home),
                      _buildDropdown('Barangay', _barangays, _selectedBarangay, Icons.location_city, (val) => setState(() => _selectedBarangay = val)),
                    ]),
                    const SizedBox(height: 24),

                    _buildSection('🎓 Academic Information', [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDropdown('Senior High School Level', _shsLevels, _selectedSHSLevel, Icons.school_outlined, (val) {
                            setState(() {
                              _selectedSHSLevel = val;
                              if (val != 'None') {
                                _selectedYearLevel = null;
                                _controllers['course']?.clear();
                              }
                            });
                          }),
                          Padding(
                            padding: const EdgeInsets.only(left: 48, top: 4),
                            child: Text('Note: For Senior High School only. College students select "None"', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                          ),
                        ],
                      ),
                      if (_selectedSHSLevel == 'None') ...[
                        _buildDropdown('College Year Level', _yearLevels, _selectedYearLevel, Icons.stairs, (val) => setState(() => _selectedYearLevel = val)),
                      ],
                      if (_selectedSHSLevel == 'None' && _selectedYearLevel != null) ...[
                        _buildTextField('course', 'Course/Program', 'BS Computer Science', Icons.school),
                      ],
                      _buildDropdown('Semester to Renew For', _semesters, _selectedSemester, Icons.calendar_today, (val) => setState(() => _selectedSemester = val)),
                      _buildTextField('gwa', 'Current GWA/GPA', '1.75', Icons.star, keyboardType: TextInputType.number),
                    ]),
                    const SizedBox(height: 24),

                    _buildSection('📎 Required Documents', [
                      _buildDocUpload('Latest Grades', 'Upload certificate of grades', 'grades', true),
                      _buildDocUpload('2x2 ID Picture', 'Recent photo with white background', 'id_picture', true),
                    ]),
                    const SizedBox(height: 24),

                    _buildSectionTitle('💭 Reason for Renewal'),
                    const SizedBox(height: 16),
                    _buildTextField('reason', 'Why do you want to continue as a scholar?', 'Share your reason...', Icons.edit, 
                      maxLines: 6, 
                      validator: (v) => v == null || v.isEmpty ? 'This field is required' : v.length < 50 ? 'Please provide at least 50 characters' : null
                    ),
                    const SizedBox(height: 24),

                    _buildWarningBox(),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitRenewal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9B59B6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [Icon(Icons.send, color: Colors.white), SizedBox(width: 8), Text('Submit Renewal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))],
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF9B59B6)));

  Widget _buildSection(String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle(title),
      const SizedBox(height: 16),
      ...children.map((w) => Padding(padding: const EdgeInsets.only(bottom: 16), child: w)),
    ],
  );

  Widget _buildTextField(String key, String label, String hint, IconData icon, {TextInputType? keyboardType, int maxLines = 1, int? maxLength, bool required = true, String? Function(String?)? validator}) {
    return TextFormField(
      controller: _controllers[key],
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF9B59B6)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF9B59B6), width: 2)),
        filled: true,
        fillColor: Colors.white,
        counterText: '',
      ),
      validator: validator ?? (required ? (v) => v == null || v.isEmpty ? 'This field is required' : null : null),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, IconData icon, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF9B59B6)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF9B59B6), width: 2)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Please select $label' : null,
    );
  }

  Widget _buildDocUpload(String title, String subtitle, String type, bool required) {
    final file = _images[type];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: file != null ? const Color(0xFF48BB78) : Colors.grey.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (required) const Text(' *', style: TextStyle(color: Colors.red, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          if (file != null)
            Stack(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(file, height: 120, width: double.infinity, fit: BoxFit.cover)),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => setState(() => _images[type] = null),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  ),
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: () => _pickImage(type),
              icon: const Icon(Icons.upload_file),
              label: const Text('Choose File'),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF9B59B6), side: const BorderSide(color: Color(0xFF9B59B6))),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF48BB78), width: 2)),
    child: const Row(
      children: [
        Icon(Icons.info_outline, color: Color(0xFF2E7D32)),
        SizedBox(width: 12),
        Expanded(child: Text('All fields marked with * are mandatory. Make sure all information is correct.', style: TextStyle(fontSize: 13, color: Color(0xFF2E7D32)))),
      ],
    ),
  );

  Widget _buildWarningBox() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFFFFF3CD), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFA500), width: 2)),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(Icons.warning_amber, color: Color(0xFF856404)), SizedBox(width: 8), Text('Important Reminders', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF856404)))]),
        SizedBox(height: 8),
        Text('• Double-check all information before submitting\n• Ensure your GWA is accurate\n• Your renewal will be reviewed by the admin\n• You will be notified of the decision', style: TextStyle(fontSize: 12, color: Color(0xFF856404))),
      ],
    ),
  );
}