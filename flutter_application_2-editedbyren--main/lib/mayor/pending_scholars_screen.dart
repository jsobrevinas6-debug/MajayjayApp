import 'package:flutter/material.dart';

class PendingScholarsScreen extends StatefulWidget {
  const PendingScholarsScreen({super.key});

  @override
  State<PendingScholarsScreen> createState() => _PendingScholarsScreenState();
}

class _PendingScholarsScreenState extends State<PendingScholarsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _searchQuery = '';

  // Sample data - replace with actual API call
  final List<Map<String, dynamic>> _pendingApplications = [
    {
      'id': 'APP-2024-089',
      'studentId': '2023-00123',
      'name': 'Sofia Martinez',
      'course': 'BS Information Technology',
      'yearLevel': '1st Year',
      'type': 'New Application',
      'gpa': '1.65',
      'dateSubmitted': 'November 10, 2024',
      'email': 'sofia.martinez@email.com',
      'phone': '0922-345-6789',
      'address': 'Los Baños, Laguna',
      'reason': 'I am passionate about technology and want to pursue a career in software development. This scholarship would help me focus on my studies without financial burden.',
      'documents': ['ID', 'Grades', 'Certificate of Indigency'],
      'priority': 'High',
    },
    {
      'id': 'APP-2024-090',
      'studentId': '2022-00456',
      'name': 'Miguel Torres',
      'course': 'BS Civil Engineering',
      'yearLevel': '2nd Year',
      'type': 'Renewal',
      'gpa': '1.80',
      'dateSubmitted': 'November 12, 2024',
      'email': 'miguel.torres@email.com',
      'phone': '0923-456-7890',
      'address': 'Bay, Laguna',
      'reason': 'I maintained my grades and would like to continue as a scholar to complete my engineering degree.',
      'documents': ['ID', 'Grades', 'Renewal Form'],
      'priority': 'Normal',
    },
    {
      'id': 'APP-2024-091',
      'studentId': '2021-00789',
      'name': 'Isabella Cruz',
      'course': 'BS Psychology',
      'yearLevel': '3rd Year',
      'type': 'New Application',
      'gpa': '1.55',
      'dateSubmitted': 'November 13, 2024',
      'email': 'isabella.cruz@email.com',
      'phone': '0924-567-8901',
      'address': 'Calauan, Laguna',
      'reason': 'My family is struggling financially and I need support to continue my education. I am committed to giving back to the community.',
      'documents': ['ID', 'Grades', 'Certificate of Indigency', 'Recommendation Letter'],
      'priority': 'High',
    },
    {
      'id': 'APP-2024-092',
      'studentId': '2023-00234',
      'name': 'Gabriel Santos',
      'course': 'BS Business Administration',
      'yearLevel': '1st Year',
      'type': 'New Application',
      'gpa': '2.00',
      'dateSubmitted': 'November 14, 2024',
      'email': 'gabriel.santos@email.com',
      'phone': '0925-678-9012',
      'address': 'Victoria, Laguna',
      'reason': 'I want to help my family business grow and need education to achieve this goal.',
      'documents': ['ID', 'Grades'],
      'priority': 'Normal',
    },
    {
      'id': 'APP-2024-093',
      'studentId': '2022-00567',
      'name': 'Camila Reyes',
      'course': 'BS Nursing',
      'yearLevel': '2nd Year',
      'type': 'Renewal',
      'gpa': '1.70',
      'dateSubmitted': 'November 15, 2024',
      'email': 'camila.reyes@email.com',
      'phone': '0926-789-0123',
      'address': 'Pila, Laguna',
      'reason': 'I am dedicated to becoming a nurse and serving the community. This scholarship helps me continue my studies.',
      'documents': ['ID', 'Grades', 'Renewal Form', 'Certificate of Good Moral'],
      'priority': 'Normal',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredApplications {
    var applications = _pendingApplications;

    // Apply type filter
    if (_selectedFilter != 'All') {
      applications = applications.where((app) => app['type'] == _selectedFilter).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      applications = applications.where((app) {
        final name = app['name'].toString().toLowerCase();
        final studentId = app['studentId'].toString().toLowerCase();
        final course = app['course'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        
        return name.contains(query) || 
               studentId.contains(query) || 
               course.contains(query);
      }).toList();
    }

    return applications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5B4AC7)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pending Applications',
          style: TextStyle(
            color: Color(0xFF5B4AC7),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF5B4AC7)),
            tooltip: 'Sort by Priority',
            onPressed: () {
              setState(() {
                _pendingApplications.sort((a, b) {
                  final priorityOrder = {'High': 0, 'Normal': 1, 'Low': 2};
                  return priorityOrder[a['priority']]!.compareTo(priorityOrder[b['priority']]!);
                });
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sorted by priority'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Card with Stats
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFA500), Color(0xFFFFB84D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.hourglass_empty, color: Colors.white, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Pending Review',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Applications awaiting your review',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickStat('Total', _pendingApplications.length.toString()),
                    _buildQuickStat(
                      'New',
                      _pendingApplications.where((a) => a['type'] == 'New Application').length.toString(),
                    ),
                    _buildQuickStat(
                      'Renewal',
                      _pendingApplications.where((a) => a['type'] == 'Renewal').length.toString(),
                    ),
                    _buildQuickStat(
                      'High Priority',
                      _pendingApplications.where((a) => a['priority'] == 'High').length.toString(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by name, ID, or course...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFFFA500)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFFA500), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('New Application'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Renewal'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Applications List
          Expanded(
            child: filteredApplications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No pending applications',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All applications have been reviewed',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filteredApplications.length,
                    itemBuilder: (context, index) {
                      final application = filteredApplications[index];
                      return _buildApplicationCard(application);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFFFA500),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: Colors.white,
      elevation: isSelected ? 3 : 1,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    final priority = application['priority'] as String;
    final type = application['type'] as String;
    
    Color priorityColor;
    IconData priorityIcon;

    switch (priority) {
      case 'High':
        priorityColor = Colors.red;
        priorityIcon = Icons.priority_high;
        break;
      case 'Normal':
        priorityColor = Colors.blue;
        priorityIcon = Icons.info_outline;
        break;
      default:
        priorityColor = Colors.grey;
        priorityIcon = Icons.arrow_downward;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: priority == 'High' 
            ? Border.all(color: Colors.red.shade200, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA500).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFFFA500),
                  radius: 24,
                  child: Text(
                    application['name'].toString().substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              application['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5B4AC7),
                              ),
                            ),
                          ),
                          if (priority == 'High')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: priorityColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(priorityIcon, color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'HIGH',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        application['studentId'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: type == 'New Application' 
                        ? Colors.green 
                        : Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    type == 'New Application' ? 'NEW' : 'RENEWAL',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoColumn(
                        Icons.school,
                        'Course',
                        application['course'],
                      ),
                    ),
                    Expanded(
                      child: _buildInfoColumn(
                        Icons.grade,
                        'Year Level',
                        application['yearLevel'],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoColumn(
                        Icons.analytics,
                        'GPA',
                        application['gpa'],
                      ),
                    ),
                    Expanded(
                      child: _buildInfoColumn(
                        Icons.calendar_today,
                        'Submitted',
                        application['dateSubmitted'],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoColumn(
                  Icons.location_on,
                  'Address',
                  application['address'],
                ),
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showApplicationDetails(application),
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('Review'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7A5AF5),
                          side: const BorderSide(color: Color(0xFF7A5AF5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showApprovalDialog(application),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF48BB78),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _showRejectionDialog(application),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showApplicationDetails(Map<String, dynamic> application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            const Icon(Icons.person, color: Color(0xFFFFA500)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                application['name'],
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Application ID', application['id']),
              _buildDetailRow('Student ID', application['studentId']),
              _buildDetailRow('Type', application['type']),
              _buildDetailRow('Course', application['course']),
              _buildDetailRow('Year Level', application['yearLevel']),
              _buildDetailRow('GPA', application['gpa']),
              _buildDetailRow('Priority', application['priority']),
              _buildDetailRow('Date Submitted', application['dateSubmitted']),
              _buildDetailRow('Email', application['email']),
              _buildDetailRow('Phone', application['phone']),
              _buildDetailRow('Address', application['address']),
              const Divider(height: 24),
              Text(
                'Reason for Application',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                application['reason'],
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Documents Submitted',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (application['documents'] as List<String>).map((doc) {
                  return Chip(
                    label: Text(doc),
                    backgroundColor: const Color(0xFF7A5AF5).withValues(alpha: 0.1),
                    labelStyle: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7A5AF5),
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF7A5AF5)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showApprovalDialog(application);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF48BB78),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Approve',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showApprovalDialog(Map<String, dynamic> application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF48BB78)),
            SizedBox(width: 10),
            Text('Approve Application'),
          ],
        ),
        content: Text(
          'Are you sure you want to approve the scholarship application for ${application['name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _approveApplication(application);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF48BB78),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Approve',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog(Map<String, dynamic> application) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 10),
            Text('Reject Application'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject the application for ${application['name']}?',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason for Rejection',
                hintText: 'Please provide a reason...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              reasonController.dispose();
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for rejection'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              reasonController.dispose();
              Navigator.pop(context);
              _rejectApplication(application, reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Reject',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _approveApplication(Map<String, dynamic> application) {
    setState(() {
      _pendingApplications.removeWhere((app) => app['id'] == application['id']);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${application['name']} has been approved!'),
        backgroundColor: const Color(0xFF48BB78),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _pendingApplications.add(application);
            });
          },
        ),
      ),
    );
  }

  void _rejectApplication(Map<String, dynamic> application, String reason) {
    setState(() {
      _pendingApplications.removeWhere((app) => app['id'] == application['id']);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${application['name']} has been rejected'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _pendingApplications.add(application);
            });
          },
        ),
      ),
    );
  }
}