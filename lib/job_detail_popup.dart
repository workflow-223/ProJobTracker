import 'package:flutter/material.dart';

class JobDetailPopup extends StatelessWidget {
  final Map<String, dynamic> job;
  final String jobId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const JobDetailPopup({
    Key? key,
    required this.job,
    required this.jobId,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  job['position'] ?? 'No Position',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStatusChip(job['status'] ?? 'Unknown'),
            ],
          ),
          SizedBox(height: 12),
          Text(
            job['company'] ?? 'No Company',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          _buildInfoRow(Icons.calendar_today, 'Date Applied:', job['dateApplied'] ?? 'Not specified'),
          SizedBox(height: 8),
          _buildInfoRow(Icons.timer, 'Deadline:', job['deadline'] ?? 'Not specified'),
          
          if (job['notes'] != null && job['notes'].toString().isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              'Notes:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                job['notes'],
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
          
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
              SizedBox(width: 8),
              TextButton(
                onPressed: onDelete,
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: onEdit,
                child: Text('Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 8),
        Text(value),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    
    switch (status) {
      case 'Applied':
        chipColor = Colors.blue;
        break;
      case 'Interviews':
        chipColor = Colors.orange;
        break;
      case 'Rejected':
        chipColor = Colors.red;
        break;
      case 'Accepted':
        chipColor = Colors.green;
        break;
      default:
        chipColor = Colors.grey;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}