import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_2/student/my_applications_screen.dart';
import 'package:flutter_application_2/student/student_dashboard.dart';
import 'package:flutter_application_2/student/apply_scholarship_screen.dart';
import 'package:flutter_application_2/student/renewal_scholarship_screen.dart';
import 'package:flutter_application_2/admin/add_admin.dart';
import 'package:flutter_application_2/admin/admin_dashboard.dart';
import 'package:flutter_application_2/mayor/mayor_dashboard.dart';
import 'package:flutter_application_2/mayor/view_scholars(mayor).dart';
import 'package:flutter_application_2/mayor/view_scholar_records(mayor).dart';


class AppDrawer extends StatelessWidget {
  final String userType;
  final String userName;
  final String userEmail;

  const AppDrawer({
    super.key,
    required this.userType,
    required this.userName,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/majayjay.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 15),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ).createShader(bounds),
              child: const Text(
                'MajayjayScholars',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: _buildMenuItems(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildLogoutButton(context),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    if (userType == 'student') {
      return [
        _buildMenuItem(context, '🏠 Dashboard'),
        _buildMenuItem(context, '📄 My Applications'),
        _buildMenuItem(context, '🔄 Renew Scholarship'),
        _buildMenuItem(context, '📝 Apply Scholarship'),
      ];
    } else if (userType == 'mayor') {
      return [
        _buildMenuItem(context, '🏛 Mayor Dashboard'),
        _buildMenuItem(context, '👥 View Scholars'),
        _buildMenuItem(context, '📁 Scholar Records'),
      ];
    } else if (userType == 'admin') {
      return [
        _buildMenuItem(context, '🏛 Admin Dashboard'),
        _buildMenuItem(context, '👥 Add Admin Account'),
      ];
    }
    return [];
  }

  Widget _buildMenuItem(BuildContext context, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            if (title == '🏠 Dashboard') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentDashboard(name: userName),
                ),
              );
            } else if (title == '📄 My Applications') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MyApplicationsScreen(
                    userName: userName,
                    userEmail: userEmail,
                  ),
                ),
              );
            } else if (title == '📝 Apply Scholarship') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ApplyScholarshipScreen(
                    userName: userName,
                    userEmail: userEmail,
                  ),
                ),
              );
            } else if (title == '🔄 Renew Scholarship') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RenewScholarshipScreen(
                    userName: userName,
                    userEmail: userEmail,
                  ),
                ),
              );
            } else if (title == '🏛 Admin Dashboard') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminDashboard(),
                ),
              );
            } else if (title == '👥 Add Admin Account') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddAdminScreen(),
                ),
              );
            } else if (title == '🏛 Mayor Dashboard') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MayorDashboardPage(),
                ),
              );
            } else if (title == '👥 View Scholars') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ViewScholarsScreen(),
                ),
              );
            } else if (title == '📁 Scholar Records') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScholarRecordsScreen(),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title - Coming Soon')),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          hoverColor: const Color(0xFF667EEA).withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await Supabase.instance.client.auth.signOut();
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/');
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
