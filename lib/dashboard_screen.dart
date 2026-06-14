import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'ae.dart';
import 'job_detail_popup.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onJobChanged;

  const DashboardScreen({Key? key, this.onJobChanged}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<String> _statusList = ['Applied', 'Interviewed', 'Rejected', 'Accepted'];
  int _refreshKey = 0;

  int? get _userId => AuthService().userId;

  void _refresh() {
    setState(() {
      _refreshKey++;
    });
    widget.onJobChanged?.call();
  }

  void _navigateToAddJobScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditJobScreen(
          onSubmit: (_) {
            _refresh();
          },
        ),
      ),
    );
  }

  void _navigateToEditJobScreen(Map<String, dynamic> job, int jobId) {
    Navigator.pop(context);

    final formattedJob = {
      'id': jobId.toString(),
      'company': job['company'] ?? '',
      'position': job['position'] ?? '',
      'dateApplied': job['date_applied'] ?? '',
      'deadline': job['deadline'] ?? '',
      'notes': job['notes'] ?? '',
      'status': job['status'] ?? 'Applied',
      'salary': (job['salary'] ?? 0).toString(),
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditJobScreen(
          job: formattedJob,
          onSubmit: (_) {
            _refresh();
          },
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchJobs() async {
    if (_userId == null) return [];
    return await DatabaseService.getJobsByUserId(_userId!);
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
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
              TabBar(
                indicatorColor: Colors.blue,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.black,
                onTap: (index) {
                  setState(() {});
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

  Widget _buildJobsList(String status) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey(_refreshKey),
      future: _fetchJobs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allJobs = snapshot.data ?? [];
        final jobs = allJobs.where((job) => job['status'] == status).toList();

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
            final job = jobs[index];
            final jobId = job['id'] as int;

            return GestureDetector(
              onTap: () => _showJobDetails(job, jobId),
              child: JobCard(
                title: job['position'] ?? 'No Title',
                company: job['company'] ?? 'No Company',
                dateApplied: job['date_applied'] ?? 'No Date',
                deadline: job['deadline'] ?? 'No Deadline',
                status: job['status'] ?? 'No Status',
              ),
            );
          },
        );
      },
    );
  }

  void _showJobDetails(Map<String, dynamic> job, int jobId) {
    showDialog(
      context: context,
      builder: (context) => JobDetailPopup(
        job: job,
        jobId: jobId.toString(),
        onEdit: () => _navigateToEditJobScreen(job, jobId),
        onDelete: () => _confirmDelete(jobId),
      ),
    );
  }

  Future<void> _confirmDelete(int jobId) async {
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
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                _deleteJob(jobId);
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteJob(int jobId) async {
    try {
      await DatabaseService.deleteJob(jobId);
      _refresh();
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
