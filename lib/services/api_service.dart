import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static final supabase = Supabase.instance.client;

  // Get student applications from Supabase
  static Future<List<Map<String, dynamic>>> getStudentApplications(int studentId) async {
    try {
      final response = await supabase
          .from('application')
          .select()
          .eq('user_id', studentId)
          .order('submission_date', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load applications: $e');
    }
  }

  // Submit scholarship application to Supabase
  static Future<Map<String, dynamic>> submitApplication(Map<String, dynamic> applicationData) async {
    try {
      final response = await supabase
          .from('application')
          .insert(applicationData)
          .select()
          .single();
      
      return response;
    } catch (e) {
      throw Exception('Failed to submit application: $e');
    }
  }

  // Submit renewal application to Supabase
  static Future<Map<String, dynamic>> submitRenewal(Map<String, dynamic> renewalData) async {
    try {
      final response = await supabase
          .from('application')
          .insert(renewalData)
          .select()
          .single();
      
      return response;
    } catch (e) {
      throw Exception('Failed to submit renewal: $e');
    }
  }
}