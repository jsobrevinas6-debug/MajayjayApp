import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_2/widgets/app_drawer.dart';
import 'package:flutter_application_2/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApplyScholarshipScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const ApplyScholarshipScreen({
    super.key,
    this.userName = 'Student',
    this.userEmail = 'student@example.com',
  });

  @override
  State<ApplyScholarshipScreen> createState() => _ApplyScholarshipScreenState();
}

class _ApplyScholarshipScreenState extends State<ApplyScholarshipScreen> {
  final _formKey = GlobalKey<FormState>();

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

  String? _selectedGradeLevel;
  String? _selectedBarangay;
  final _images = <String, File?>{
    'school_id': null,
    'id_picture': null,
    'birth_cert': null,
    'grades': null,
  };
  final _imageBytes = <String, Uint8List?>{
    'school_id': null,
    'id_picture': null,
    'birth_cert': null,
    'grades': null,
  };
  final _imageNames = <String, String?>{
    'school_id': null,
    'id_picture': null,
    'birth_cert': null,
    'grades': null,
  };

  bool _isSubmitting = false;
  bool _hasExistingApplication = false;
  bool _isCheckingApplication = true;

  final _gradeLevels = ['Grade 11', 'Grade 12', '1st Year', '2nd Year', '3rd Year', '4th Year'];
  
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
    _checkExistingApplication();
  }

  Future<void> _checkExistingApplication() async {
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
          .select('application_id')
          .eq('user_id', userId);

      setState(() {
        _hasExistingApplication = apps.isNotEmpty;
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
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        setState(() {
          if (kIsWeb) {
            pickedFile.readAsBytes().then((bytes) {
              setState(() {
                _imageBytes[type] = bytes;
                _imageNames[type] = pickedFile.name;
              });
            });
          } else {
            _images[type] = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate Grade Level is selected
    if (_selectedGradeLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your grade level!'), backgroundColor: Colors.red),
      );
      return;
    }

    // Validate Barangay is selected
    if (_selectedBarangay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your barangay!'), backgroundColor: Colors.red),
      );
      return;
    }

    // Validate Course/Program/Strand
    if (_controllers['course']?.text.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your course/program/strand!'), backgroundColor: Colors.red),
      );
      return;
    }

    final hasSchoolId = kIsWeb ? _imageBytes['school_id'] != null : _images['school_id'] != null;
    final hasIdPicture = kIsWeb ? _imageBytes['id_picture'] != null : _images['id_picture'] != null;
    final hasBirthCert = kIsWeb ? _imageBytes['birth_cert'] != null : _images['birth_cert'] != null;
    final hasGrades = kIsWeb ? _imageBytes['grades'] != null : _images['grades'] != null;
    
    if (!hasSchoolId || !hasIdPicture || !hasBirthCert || !hasGrades) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get current user's email
      final userEmail = Supabase.instance.client.auth.currentUser?.email;
      
      if (userEmail == null) {
        throw Exception('User not authenticated');
      }

      // Get the user_id from users table using email
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('user_id')
          .eq('email', userEmail)
          .single();
      
      final userId = userResponse['user_id'] as int;

      // Get current year
      final currentYear = DateTime.now().year;

      // Upload files to Supabase Storage and get URLs
      String? schoolIdUrl, idPictureUrl, birthCertUrl, gradesUrl;
      
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final studentId = _controllers['studentId']!.text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
        
        // Upload school_id
        if (kIsWeb && _imageBytes['school_id'] != null) {
          final path = '$studentId/school_id_$timestamp.jpg';
          await Supabase.instance.client.storage.from('scholarship-documents').uploadBinary(path, _imageBytes['school_id']!);
          schoolIdUrl = Supabase.instance.client.storage.from('scholarship-documents').getPublicUrl(path);
          print('Uploaded School ID to: $schoolIdUrl');
        } else if (_images['school_id'] != null) {
          final path = '$studentId/school_id_$timestamp.jpg';
          await Supabase.instance.client.storage.from('scholarship-documents').upload(path, _images['school_id']!);
          schoolIdUrl = Supabase.instance.client.storage.from('scholarship-documents').getPublicUrl(path);
          print('Uploaded School ID to: $schoolIdUrl');
        }
        
        // Upload id_picture
        if (kIsWeb && _imageBytes['id_picture'] != null) {
          final path = '$studentId/id_picture_$timestamp.jpg';
          await Supabase.instance.client.storage.from('scholarship-documents').uploadBinary(path, _imageBytes['id_picture']!);
          idPictureUrl = Supabase.instance.client.storage.from('scholarship-documents').getPublicUrl(path);
          print('Uploaded ID Picture to: $idPictureUrl');
        } else if (_images['id_picture'] != null) {
          final path = '$studentId/id_picture_$timestamp.jpg';
          await Supabase.instance.client.storage.from('scholarship-documents').upload(path, _images['id_picture']!);
          idPictureUrl = Supabase.instance.client.storage.from('scholarship-documents').getPublicUrl(path);
          print('Uploaded ID Picture to: $idPictureUrl');
        }
        
        // Upload birth_cert
        if (kIsWeb && _imageBytes['birth_cert'] != null) {
          final path = '$studentId/birth_cert_$timestamp.jpg';
          await Supabase.instance.client.storage.from('scholarship-documents').uploadBinary(path, _imageBytes['birth_cert']!);
          birthCertUrl = Supabase.instance.client.storage.from('scholarship-documents').getPublicUrl(path);
          print('Uploaded Birth Cert to: $birthCertUrl');
        } else if (_images['birth_cert'] != null) {
          final path = '$studentId/birth_cert_$timestamp.jpg';
          await Supabase.instance.client.storage.from('scholarship-documents').upload(path, _images['birth_cert']!);
          birthCertUrl = Supabase.instance.client.storage.from('scholarship-documents').getPublicUrl(path);
          print('Uploaded Birth Cert to: $birthCertUrl');
        }
        
        // Upload grades
        if (kIsWeb && _imageBytes['grades'] != null) {
          final path = '$studentId/grades_$timestamp.jpg';
          await Supabase.instance.client.storage.from('scholarship-documents').uploadBinary(path, _imageBytes['grades']!);
          gradesUrl = Supabase.instance.client.storage.from('scholarship-documents').getPublicUrl(path);
          print('Uploaded Grades to: $gradesUrl');
        } else if (_images['grades'] != null) {
          final path = '$studentId/grades_$timestamp.jpg';
          await Supabase.instance.client.storage.from('scholarship-documents').upload(path, _images['grades']!);
          gradesUrl = Supabase.instance.client.storage.from('scholarship-documents').getPublicUrl(path);
          print('Uploaded Grades to: $gradesUrl');
        }
      } catch (e) {
        throw Exception('Failed to upload files: $e');
      }

      // Debug: Print URLs to verify they were generated
      print('School ID URL: $schoolIdUrl');
      print('ID Picture URL: $idPictureUrl');
      print('Birth Cert URL: $birthCertUrl');
      print('Grades URL: $gradesUrl');

      // Prepare application data matching your table structure
      final applicationData = {
        'user_id': userId,
        'student_id': _controllers['studentId']!.text,
        'first_name': _controllers['firstName']!.text,
        'middle_name': _controllers['middleName']!.text.isNotEmpty ? _controllers['middleName']!.text : null,
        'last_name': _controllers['surname']!.text,
        'contact_number': _controllers['contact']!.text,
        'address': _controllers['houseStreet']!.text,
        'municipality': 'Majayjay',
        'baranggay': _selectedBarangay,
        'school_name': null,
        'course': _controllers['course']!.text,
        'year_level': _selectedGradeLevel,
        'gwa': double.tryParse(_controllers['gwa']!.text),
        'year_applied': currentYear,
        'reason': _controllers['reason']!.text,
        'scholarship_type': 'New Application',
        'status': 'pending',
        'archived': false,
        'school_id_path': schoolIdUrl ?? '',
        'id_picture_path': idPictureUrl ?? '',
        'birth_certificate_path': birthCertUrl ?? '',
        'grades_path': gradesUrl ?? '',
      };

      await ApiService.submitApplication(applicationData);
      
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success! 🎉'),
          content: const Text('Your scholarship application has been submitted successfully! You will be notified of the decision.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7A5AF5), foregroundColor: Colors.white),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting application: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingApplication) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7FAFC),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasExistingApplication) {
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
          title: const Text('📝 Apply for Scholarship', style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.w600)),
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
                const Icon(Icons.info_outline, size: 80, color: Color(0xFFFFA500)),
                const SizedBox(height: 20),
                const Text(
                  'Application Already Submitted',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF2D3748)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'You have already submitted a scholarship application. You can only submit one application.',
                  style: TextStyle(color: Color(0xFF718096)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
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
        title: const Text('📝 Apply for Scholarship', style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.w600)),
      ),
      drawer: AppDrawer(
        userType: 'student',
        userName: widget.userName,
        userEmail: widget.userEmail,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 4)),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoBox(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('👤 Personal Information'),
                    const SizedBox(height: 12),
                    _buildTextField('firstName', 'First Name *', 'Juan'),
                    _buildTextField('middleName', 'Middle Name', 'Santos', required: false),
                    _buildTextField('surname', 'Last Name *', 'Dela Cruz'),
                    _buildTextField('studentId', 'Student ID *', '2024-12345'),
                    _buildTextField('contact', 'Contact Number *', '09171234567', keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _buildSectionTitle('📍 Address'),
                    const SizedBox(height: 12),
                    _buildTextField('houseStreet', 'House No. / Street *', 'Blk 2 Lot 10, Rizal St.'),
                    _buildDropdown('Barangay *', _barangays, _selectedBarangay, (val) => setState(() => _selectedBarangay = val)),
                    const SizedBox(height: 16),
                    _buildSectionTitle('🎓 Academic Information'),
                    const SizedBox(height: 12),
                    _buildTextField('course', 'Course *', 'BS Computer Science'),
                    _buildDropdown('Year Level *', _gradeLevels, _selectedGradeLevel, (val) => setState(() => _selectedGradeLevel = val)),
                    _buildTextField('gwa', 'GWA *', '1.75', keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildSectionTitle('💭 Application Information'),
                    const SizedBox(height: 12),
                    _buildTextField('reason', 'Why do you deserve this scholarship? *', 'Explain why...', maxLines: 3),
                    const SizedBox(height: 16),
                    _buildSectionTitle('📎 Upload Requirements'),
                    const SizedBox(height: 12),
                    _buildDocUpload('School ID *', 'school_id'),
                    _buildDocUpload('2x2 ID Picture *', 'id_picture'),
                    _buildDocUpload('Birth Certificate *', 'birth_cert'),
                    _buildDocUpload('Copy of Grades *', 'grades'),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitApplication,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF667EEA),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('📝 Submit Application', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 4))],
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ).createShader(bounds),
          child: const Text(
            'Scholarship Application Form',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Complete the form honestly. Fields marked with * are required.',
          style: TextStyle(color: Color(0xFF718096)),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildSectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2D3748)));

  Widget _buildTextField(String key, String label, String hint, {TextInputType? keyboardType, int maxLines = 1, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _controllers[key],
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2)),
          filled: true,
          fillColor: const Color(0xFFF7FAFC),
        ),
        validator: required ? (v) => v == null || v.isEmpty ? 'This field is required' : null : null,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2)),
          filled: true,
          fillColor: const Color(0xFFF7FAFC),
        ),
        items: [DropdownMenuItem(value: null, child: Text('Select $label')), ...items.map((item) => DropdownMenuItem(value: item, child: Text(item)))],
        onChanged: onChanged,
        validator: (v) => v == null ? 'Please select $label' : null,
      ),
    );
  }

  Widget _buildDocUpload(String title, String type) {
    final hasFile = kIsWeb ? _imageBytes[type] != null : _images[type] != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          if (hasFile)
            Stack(
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: kIsWeb
                      ? (_imageBytes[type] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(_imageBytes[type]!, fit: BoxFit.cover),
                            )
                          : Center(child: Text(_imageNames[type] ?? 'File selected')))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_images[type]!, height: 100, width: double.infinity, fit: BoxFit.cover),
                        ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    onPressed: () => setState(() {
                      _images[type] = null;
                      _imageBytes[type] = null;
                      _imageNames[type] = null;
                    }),
                    icon: const Icon(Icons.close, size: 18),
                    style: IconButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.all(4)),
                  ),
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: () => _pickImage(type),
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Choose File'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF667EEA),
                side: const BorderSide(color: Color(0xFF667EEA)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5E9),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF48BB78)),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline, color: Color(0xFF2E7D32), size: 20),
        SizedBox(width: 10),
        Expanded(child: Text('📋 Before you start\nMake sure your documents are ready. Max file size 5MB. Supported: JPG, PNG, PDF.', style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600))),
      ],
    ),
  );
}