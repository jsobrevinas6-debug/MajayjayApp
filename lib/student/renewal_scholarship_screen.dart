import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_2/widgets/app_drawer.dart';
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
    'municipality': TextEditingController(text: 'Majayjay'),
    'course': TextEditingController(),
    'gwa': TextEditingController(),
    'reason': TextEditingController(),
  };

  String? _selectedYearLevel;
  String? _selectedBarangay;
  
  final _images = <String, File?>{
    'school_id': null,
    'id_picture': null,
    'birth_cert': null,
    'grades': null,
    'cor': null,
  };
  
  final _imageBytes = <String, Uint8List?>{
    'school_id': null,
    'id_picture': null,
    'birth_cert': null,
    'grades': null,
    'cor': null,
  };

  bool _isSubmitting = false;
  bool _hasApprovedApplication = false;
  bool _isCheckingApplication = true;
  bool _hasExistingRenewal = false;

  @override
  void initState() {
    super.initState();
    _checkApprovedApplication();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userEmail = Supabase.instance.client.auth.currentUser?.email;
      if (userEmail == null) return;

      final userResponse = await Supabase.instance.client
          .from('users')
          .select('user_id')
          .eq('email', userEmail)
          .single();
      
      final userId = userResponse['user_id'] as int;

      final appResponse = await Supabase.instance.client
          .from('application')
          .select()
          .eq('user_id', userId)
          .eq('status', 'approved')
          .maybeSingle();

      if (appResponse != null) {
        setState(() {
          _controllers['firstName']?.text = appResponse['first_name'] ?? '';
          _controllers['middleName']?.text = appResponse['middle_name'] ?? '';
          _controllers['surname']?.text = appResponse['last_name'] ?? '';
          _controllers['houseStreet']?.text = appResponse['address'] ?? '';
          _selectedBarangay = appResponse['baranggay'];
        });
      }
    } catch (e) {
      // Silently fail if user data not found
    }
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
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() => _imageBytes[type] = bytes);
        } else {
          setState(() => _images[type] = File(image.path));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitRenewal() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedYearLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your year level!'), backgroundColor: Colors.red),
      );
      return;
    }

    final hasSchoolId = kIsWeb ? _imageBytes['school_id'] != null : _images['school_id'] != null;
    final hasIdPicture = kIsWeb ? _imageBytes['id_picture'] != null : _images['id_picture'] != null;
    final hasBirthCert = kIsWeb ? _imageBytes['birth_cert'] != null : _images['birth_cert'] != null;
    final hasGrades = kIsWeb ? _imageBytes['grades'] != null : _images['grades'] != null;
    final hasCor = kIsWeb ? _imageBytes['cor'] != null : _images['cor'] != null;
    
    if (!hasSchoolId || !hasIdPicture || !hasBirthCert || !hasGrades || !hasCor) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userEmail = Supabase.instance.client.auth.currentUser?.email;
      if (userEmail == null) throw Exception('User not authenticated');

      final userResponse = await Supabase.instance.client
          .from('users')
          .select('user_id')
          .eq('email', userEmail)
          .single();
      
      final userId = userResponse['user_id'] as int;

      final appResponse = await Supabase.instance.client
          .from('application')
          .select('application_id')
          .eq('user_id', userId)
          .eq('status', 'approved')
          .single();
      
      final applicationId = appResponse['application_id'] as int;

      // Upload documents to Supabase Storage
      String? schoolIdUrl, idPictureUrl, birthCertUrl, gradesUrl, corUrl;
      
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final studentId = _controllers['studentId']!.text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
        
        // Upload school_id
        if (kIsWeb && _imageBytes['school_id'] != null) {
          final path = '$studentId/school_id_$timestamp.jpg';
          await Supabase.instance.client.storage.from('scholarship_bucket').uploadBinary(path, _imageBytes['school_id']!);
          schoolIdUrl = Supabase.instance.client.storage.from('scholarship_bucket').getPublicUrl(path);
        } else if (_images['school_id'] != null) {
          final path = '$studentId/school_id_$timestamp.jpg';
          await Supabase.instance.client.storage.from('scholarship_bucket').upload(path, _images['school_id']!);
          schoolIdUrl = Supabase.instance.client.storage.from('scholarship_bucket').getPublicUrl(path);
        }
        
        // Upload id_picture
        if (kIsWeb && _imageBytes['id_picture'] != null) {
          final path = '$studentId/id_picture_$timestamp.jpg';
          await Supabase.instance.client.storage.from('scholarship_bucket').uploadBinary(path, _imageBytes['id_picture']!);
          idPictureUrl = Supabase.instance.client.storage.from('scholarship_bucket').getPublicUrl(path);
        } else if (_images['id_picture'] != null) {
          final path = '$studentId/id_picture_$timestamp.jpg';
          await Supabase.instance.client.storage.from('scholarship_bucket').upload(path, _images['id_picture']!);
          idPictureUrl = Supabase.instance.client.storage.from('scholarship_bucket').getPublicUrl(path);
        }
        
        // Upload birth_cert
        if (kIsWeb && _imageBytes['birth_cert'] != null) {
          final path = '$studentId/birth_cert_$timestamp.jpg';
          await Supabase.instance.client.storage.from('scholarship_bucket').uploadBinary(path, _imageBytes['birth_cert']!);
          birthCertUrl = Supabase.instance.client.storage.from('scholarship_bucket').getPublicUrl(path);
        } else if (_images['birth_cert'] != null) {
          final path = '$studentId/birth_cert_$timestamp.jpg';
          await Supabase.instance.client.storage.from('scholarship_bucket').upload(path, _images['birth_cert']!);
          birthCertUrl = Supabase.instance.client.storage.from('scholarship_bucket').getPublicUrl(path);
        }
        
        // Upload grades
        if (kIsWeb && _imageBytes['grades'] != null) {
          final path = '$studentId/grades_$timestamp.jpg';
          await Supabase.instance.client.storage.from('scholarship_bucket').uploadBinary(path, _imageBytes['grades']!);
          gradesUrl = Supabase.instance.client.storage.from('scholarship_bucket').getPublicUrl(path);
        } else if (_images['grades'] != null) {
          final path = '$studentId/grades_$timestamp.jpg';
          await Supabase.instance.client.storage.from('scholarship_bucket').upload(path, _images['grades']!);
          gradesUrl = Supabase.instance.client.storage.from('scholarship_bucket').getPublicUrl(path);
        }
        
        // Upload cor
        if (kIsWeb && _imageBytes['cor'] != null) {
          final path = '$studentId/cor_$timestamp.jpg';
          await Supabase.instance.client.storage.from('scholarship_bucket').uploadBinary(path, _imageBytes['cor']!);
          corUrl = Supabase.instance.client.storage.from('scholarship_bucket').getPublicUrl(path);
        } else if (_images['cor'] != null) {
          final path = '$studentId/cor_$timestamp.jpg';
          await Supabase.instance.client.storage.from('scholarship_bucket').upload(path, _images['cor']!);
          corUrl = Supabase.instance.client.storage.from('scholarship_bucket').getPublicUrl(path);
        }
      } catch (e) {
        throw Exception('Failed to upload files: $e');
      }

      // Debug: Print URLs
      print('School ID URL: $schoolIdUrl');
      print('ID Picture URL: $idPictureUrl');
      print('Birth Cert URL: $birthCertUrl');
      print('Grades URL: $gradesUrl');
      print('COR URL: $corUrl');

      await Supabase.instance.client.from('renew').insert({
        'application_id': applicationId,
        'user_id': userId,
        'first_name': _controllers['firstName']!.text,
        'middle_name': _controllers['middleName']!.text.isNotEmpty ? _controllers['middleName']!.text : null,
        'last_name': _controllers['surname']!.text,
        'student_id': _controllers['studentId']!.text,
        'contact_number': _controllers['contact']!.text,
        'course': _controllers['course']!.text,
        'year_level': _selectedYearLevel,
        'gwa': double.tryParse(_controllers['gwa']!.text),
        'reason': _controllers['reason']!.text,
        'status': 'pending',
        'school_id_path': schoolIdUrl ?? '',
        'id_picture_path': idPictureUrl ?? '',
        'birth_certificate_path': birthCertUrl ?? '',
        'grades_path': gradesUrl ?? '',
        'cor_path': corUrl ?? '',
      });
      
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
                      _buildTextField('firstName', 'First Name', 'Juan', Icons.person, enabled: false),
                      _buildTextField('middleName', 'Middle Name', 'Santos', Icons.person_outline, required: false, enabled: false),
                      _buildTextField('surname', 'Surname', 'Dela Cruz', Icons.person, enabled: false),
                      _buildTextField('studentId', 'Student ID *', '2024-12345', Icons.badge),
                      _buildTextField('contact', 'Contact Number *', '09171234567', Icons.phone, keyboardType: TextInputType.phone, maxLength: 11),
                      _buildTextField('houseStreet', 'House No. & Street', 'e.g., 123 Rizal Street', Icons.home, enabled: false),
                      _buildTextField('municipality', 'Municipality', 'Majayjay', Icons.location_on, enabled: false),
                      TextFormField(
                        initialValue: _selectedBarangay ?? '',
                        enabled: false,
                        style: const TextStyle(color: Color(0xFF9CA3AF)),
                        decoration: InputDecoration(
                          labelText: 'Barangay',
                          prefixIcon: const Icon(Icons.location_city, color: Color(0xFF9B59B6)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    _buildSection('🎓 Academic Information', [
                      _buildTextField('course', 'Course/Program/Academic *', 'BS Computer Science', Icons.school),
                      _buildDropdown('Year Level *', ['Grade 11', 'Grade 12', '1st Year', '2nd Year', '3rd Year', '4th Year'], _selectedYearLevel, Icons.stairs, (val) => setState(() => _selectedYearLevel = val)),
                      _buildTextField('gwa', 'GWA (General Weighted Average) *', '1.75', Icons.star, keyboardType: TextInputType.number),
                    ]),
                    const SizedBox(height: 24),

                    _buildSection('📎 Required Documents', [
                      _buildDocUpload('School ID', 'Upload school ID', 'school_id', true),
                      _buildDocUpload('2x2 ID Picture', 'Recent photo with white background', 'id_picture', true),
                      _buildDocUpload('Birth Certificate', 'Upload birth certificate', 'birth_cert', true),
                      _buildDocUpload('Copy of Grades', 'Upload certificate of grades', 'grades', true),
                      _buildDocUpload('COR (Certificate of Registration)', 'Upload COR', 'cor', true),
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

  Widget _buildTextField(String key, String label, String hint, IconData icon, {TextInputType? keyboardType, int maxLines = 1, int? maxLength, bool required = true, bool enabled = true, String? Function(String?)? validator}) {
    return TextFormField(
      controller: _controllers[key],
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: enabled,
      style: enabled ? null : const TextStyle(color: Color(0xFF9CA3AF)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF9B59B6)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF9B59B6), width: 2)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
    final hasFile = kIsWeb ? _imageBytes[type] != null : _images[type] != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasFile ? const Color(0xFF48BB78) : Colors.grey.shade300, width: 2),
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
          if (hasFile)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: kIsWeb
                      ? Image.memory(_imageBytes[type]!, height: 120, width: double.infinity, fit: BoxFit.cover)
                      : Image.file(_images[type]!, height: 120, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => setState(() {
                      _images[type] = null;
                      _imageBytes[type] = null;
                    }),
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