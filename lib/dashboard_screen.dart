import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ae.dart'; // Using the original ae.dart
import 'job_detail_popup.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Status list for the tabs
  final List<String> _statusList = ['Applied', 'Interviewed', 'Rejected', 'Accepted'];

  // Current selected tab
  int _selectedIndex = 0;

  // Get current user's email
  String? get _currentUserEmail => FirebaseAuth.instance.currentUser?.email;

  void _navigateToAddJobScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditJobScreen(
          onSubmit: (_) {
            // Refresh the dashboard after a job is added.
            setState(() {});
          },
        ),
      ),
    );
  }

  // Navigate to edit job screen.
  // We now pass the jobId as part of the job map (using the key 'id') so that AddEditJobScreen
  // can detect an update scenario.
  void _navigateToEditJobScreen(Map<String, dynamic> job, String jobId) {
    Navigator.pop(context); // Close the detail popup

    final formattedJob = {
      'id': jobId, // include the job id for updating
      'company': job['company'] ?? '',
      'position': job['position'] ?? '',
      'dateApplied': job['dateApplied'] ?? '',
      'deadline': job['deadline'] ?? '',
      'notes': job['notes'] ?? '',
      'status': job['status'] ?? 'Applied',
      'salary': job['salary'] ?.toString() ?? '',
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditJobScreen(
          job: formattedJob,
          onSubmit: (_) {
            // Refresh the dashboard after a job is updated.
            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserEmail == null) {
      return Center(child: Text('Please log in to view your jobs'));
    }

    return DefaultTabController(
      length: _statusList.length,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // TabBar without AppBar
              TabBar(
                indicatorColor: Colors.blue,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.black,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                tabs: _statusList.map((status) {
                  return Tab(text: status);
                }).toList(),
              ),
              Expanded(
                child: TabBarView(
                  children: _statusList.map((status) {
                    return _buildJobsList(status);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _navigateToAddJobScreen,
          child: Icon(Icons.add),
          backgroundColor: Colors.blue,
        ),
      ),
    );
  }

  // Build the list of jobs from Firestore - filter by user email and status
  Widget _buildJobsList(String status) {
    return StreamBuilder<QuerySnapshot>(
      // Query Firestore for jobs with the current user's email
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('email', isEqualTo: _currentUserEmail)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allJobs = snapshot.data?.docs ?? [];
        
        // Filter by status in memory
        final jobs = allJobs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == status;
        }).toList();
        
        // Sort by updatedAt in descending order in memory
        jobs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          
          final aTimestamp = aData['updatedAt'] as Timestamp?;
          final bTimestamp = bData['updatedAt'] as Timestamp?;
          
          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1; // nulls last
          if (bTimestamp == null) return -1;
          
          return bTimestamp.compareTo(aTimestamp);
        });

        if (jobs.isEmpty) {
          return Center(
            child: Text(
              'No jobs with status "$status"',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index].data() as Map<String, dynamic>;
            final jobId = jobs[index].id;

            return GestureDetector(
              onTap: () => _showJobDetails(job, jobId),
              child: JobCard(
                title: job['position'] ?? 'No Title',
                company: job['company'] ?? 'No Company',
                dateApplied: job['dateApplied'] ?? 'No Date',
                deadline: job['deadline'] ?? 'No Deadline',
                status: job['status'] ?? 'No Status',
              ),
            );
          },
        );
      },
    );
  }

  // Show job details in a popup
  void _showJobDetails(Map<String, dynamic> job, String jobId) {
    showDialog(
      context: context,
      builder: (context) => JobDetailPopup(
        job: job,
        jobId: jobId,
        onEdit: () => _navigateToEditJobScreen(job, jobId),
        onDelete: () => _confirmDelete(jobId),
      ),
    );
  }

  // Confirm delete dialog
  Future<void> _confirmDelete(String jobId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete this job?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close confirmation dialog
                Navigator.of(context).pop(); // Close detail popup
                _deleteJob(jobId);
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Delete a job from Firestore
  Future<void> _deleteJob(String jobId) async {
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Job deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting job: $e')),
      );
    }
  }
}

class JobCard extends StatelessWidget {
  final String title;
  final String company;
  final String dateApplied;
  final String deadline;
  final String status;

  const JobCard({
    Key? key,
    required this.title,
    required this.company,
    required this.dateApplied,
    required this.deadline,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Company: $company',
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 4),
            Text(
              'Date Applied: $dateApplied',
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 4),
            Text(
              'Deadline: $deadline',
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get color for the status
  Color _getStatusColor() {
    switch (status) {
      case 'Applied':
        return Colors.blue;
      case 'Interviews':
        return Colors.orange;
      case 'Rejected':
        return Colors.red;
      case 'Accepted':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
