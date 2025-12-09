import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_2/widgets/app_drawer.dart';

void main() {
  runApp(const MayorDashboardApp());
}

class MayorDashboardApp extends StatelessWidget {
  const MayorDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mayor Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const MayorDashboardPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MayorDashboardPage extends StatefulWidget {
  const MayorDashboardPage({super.key});

  @override
  State<MayorDashboardPage> createState() => _MayorDashboardPageState();
}

class _MayorDashboardPageState extends State<MayorDashboardPage> {
  bool _renewalIsOpen = false;
  bool _isLoading = true;
  int _totalNew = 0;
  int _approvedNew = 0;
  int _pendingNew = 0;
  int _rejectedNew = 0;
  int _totalRenewals = 0;
  int _approvedRenewals = 0;
  int _pendingRenewals = 0;
  int _rejectedRenewals = 0;

  @override
  void initState() {
    super.initState();
    _loadRenewalStatus();
    _loadStatistics();
  }

  Future<void> _loadRenewalStatus() async {
    try {
      final result = await Supabase.instance.client
          .from('renewal_settings')
          .select('is_open')
          .eq('id', 1)
          .maybeSingle();
      
      setState(() {
        _renewalIsOpen = result?['is_open'] ?? false;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final apps = await Supabase.instance.client
          .from('application')
          .select();
      
      final renewals = await Supabase.instance.client
          .from('renew')
          .select();
      
      setState(() {
        _totalNew = apps.length;
        _approvedNew = apps.where((a) => a['status'] == 'approved').length;
        _pendingNew = apps.where((a) => a['status'] == 'pending').length;
        _rejectedNew = apps.where((a) => a['status'] == 'rejected').length;
        
        _totalRenewals = renewals.length;
        _approvedRenewals = renewals.where((r) => r['status'] == 'approved').length;
        _pendingRenewals = renewals.where((r) => r['status'] == 'pending').length;
        _rejectedRenewals = renewals.where((r) => r['status'] == 'rejected').length;
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleRenewalStatus() async {
    try {
      final newStatus = !_renewalIsOpen;
      
      await Supabase.instance.client
          .from('renewal_settings')
          .upsert({'id': 1, 'is_open': newStatus, 'updated_at': DateTime.now().toIso8601String()});
      
      setState(() => _renewalIsOpen = newStatus);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Renewal is now ${newStatus ? "OPEN" : "CLOSED"}'),
            backgroundColor: newStatus ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
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
        title: const Row(
          children: [
            Icon(Icons.account_balance, color: Colors.grey),
            SizedBox(width: 12),
            Text(
              'Mayor Dashboard',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Container(
                    margin: const EdgeInsets.all(30),
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Welcome, Renee Rose Tuason!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.school, color: Colors.blue, size: 28),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Overview of scholarship applications and renewals',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // New Scholarship Applications
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      children: [
                        const Icon(Icons.fiber_new, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text(
                          'New Scholarship Applications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.bar_chart,
                            number: _totalNew.toString(),
                            label: 'TOTAL NEW',
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.check_circle,
                            number: _approvedNew.toString(),
                            label: 'APPROVED',
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.hourglass_empty,
                            number: _pendingNew.toString(),
                            label: 'PENDING',
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.cancel,
                            number: _rejectedNew.toString(),
                            label: 'REJECTED',
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Scholarship Renewals
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      children: [
                        const Icon(Icons.refresh, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Scholarship Renewals',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _renewalIsOpen ? Colors.green.shade100 : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _renewalIsOpen ? Colors.green : Colors.red,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _renewalIsOpen ? Icons.lock_open : Icons.lock,
                                size: 16,
                                color: _renewalIsOpen ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _renewalIsOpen ? 'OPEN' : 'CLOSED',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _renewalIsOpen ? Colors.green : Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _toggleRenewalStatus,
                          icon: Icon(_renewalIsOpen ? Icons.lock : Icons.lock_open, size: 18),
                          label: Text(_renewalIsOpen ? 'Close Renewal' : 'Open Renewal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _renewalIsOpen ? Colors.red : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.description,
                            number: _totalRenewals.toString(),
                            label: 'TOTAL RENEWALS',
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.check_circle,
                            number: _approvedRenewals.toString(),
                            label: 'APPROVED',
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.hourglass_empty,
                            number: _pendingRenewals.toString(),
                            label: 'PENDING',
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.cancel,
                            number: _rejectedRenewals.toString(),
                            label: 'REJECTED',
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Overall Summary
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade700,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Overall Summary',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  number: (_totalNew + _totalRenewals).toString(),
                                  label: 'TOTAL APPLICATIONS',
                                  color: Colors.blue.shade100,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSummaryCard(
                                  number: (_approvedNew + _approvedRenewals).toString(),
                                  label: 'TOTAL APPROVED',
                                  color: Colors.blue.shade100,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSummaryCard(
                                  number: (_pendingNew + _pendingRenewals).toString(),
                                  label: 'TOTAL PENDING',
                                  color: Colors.blue.shade100,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSummaryCard(
                                  number: (_rejectedNew + _rejectedRenewals).toString(),
                                  label: 'TOTAL REJECTED',
                                  color: Colors.blue.shade100,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String number,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 12),
          Text(
            number,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String number,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}