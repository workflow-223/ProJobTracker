import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddEditJobScreen extends StatefulWidget {
  final Map<String, dynamic>? job;
  final Function(Map<String, dynamic>) onSubmit;

  const AddEditJobScreen({
    Key? key,
    this.job,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _AddEditJobScreenState createState() => _AddEditJobScreenState();
}

class _AddEditJobScreenState extends State<AddEditJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _positionController = TextEditingController();
  final _dateAppliedController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _notesController = TextEditingController();
  final _statusController = TextEditingController();
  final _salaryController = TextEditingController();

  // // For new file selections
  // PlatformFile? _resumeFile;
  // PlatformFile? _coverLetterFile;

  // // For existing attachments (when editing)
  // String? _existingResumeUrl;
  // String? _existingCoverLetterUrl;

  bool _isSubmitting = false;
  bool _isButtonDisabled = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    if (widget.job != null) {
      _companyController.text = widget.job!['company'] ?? '';
      _positionController.text = widget.job!['position'] ?? '';
      _dateAppliedController.text = widget.job!['dateApplied'] ?? '';
      _deadlineController.text = widget.job!['deadline'] ?? '';
      _notesController.text = widget.job!['notes'] ?? '';
      _statusController.text = widget.job!['status'] ?? 'Applied';
      _salaryController.text = widget.job!['salary']?.toString() ?? '';
      
      // // Retrieve existing file URLs if available
      // _existingResumeUrl = widget.job!['resumeUrl'];
      // _existingCoverLetterUrl = widget.job!['coverLetterUrl'];
    } else {
      _statusController.text = 'Applied'; // Set default for new jobs
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _positionController.dispose();
    _dateAppliedController.dispose();
    _deadlineController.dispose();
    _notesController.dispose();
    _statusController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  // // Helper method to upload a file and return its download URL.
  // Future<String?> _uploadFile(PlatformFile file, String folder) async {
  //   try {
  //     final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
  //     final storageRef = _storage.ref().child('$folder/$fileName');

  //     if (file.bytes != null) {
  //       await storageRef.putData(file.bytes!);
  //     } else if (file.path != null) {
  //       await storageRef.putFile(File(file.path!));
  //     } else {
  //       throw Exception('No file data available');
  //     }

  //     final downloadUrl = await storageRef.getDownloadURL();
  //     return downloadUrl;
  //   } catch (e) {
  //     debugPrint('File upload error: $e');
  //     return null;
  //   }
  // }

  Future<void> _submitForm() async {
    // Prevent multiple submissions
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);

    try {
      final dateApplied = DateTime.parse(_dateAppliedController.text);
      final deadline = DateTime.parse(_deadlineController.text);

      if (deadline.isBefore(dateApplied)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deadline cannot be before the applied date')),
        );
        return;
      }

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final newJob = {
        'company': _companyController.text,
        'position': _positionController.text,
        'dateApplied': _dateAppliedController.text,
        'deadline': _deadlineController.text,
        'notes': _notesController.text,
        'status': _statusController.text, // Ensure status is included
        'email': user.email,
        'salary': _salaryController.text.isNotEmpty 
            ? double.tryParse(_salaryController.text) ?? 0 
            : 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userID': user.uid,
      };


      // For debugging
      debugPrint('Submitting job with status: ${newJob['status']}');

      if (widget.job != null && widget.job!.containsKey('id')) {
        await _firestore.collection('jobs').doc(widget.job!['id']).update(newJob);
      } else {
        // Check for existing identical job
        final query = await _firestore.collection('jobs')
            .where('company', isEqualTo: newJob['company'])
            .where('position', isEqualTo: newJob['position'])
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          await _firestore.collection('jobs').add(newJob);
        } else {
          throw Exception('This job already exists in your applications');
        }
      }

      widget.onSubmit(newJob);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Submission error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // Future<void> _pickFile(bool isResume) async {
  //   try {
  //     FilePickerResult? result = await FilePicker.platform.pickFiles(
  //       withData: true, // Ensure file bytes are loaded
  //       type: FileType.custom,
  //       allowedExtensions: ['pdf', 'doc', 'docx'],
  //     );
  //     if (result != null) {
  //       setState(() {
  //         if (isResume) {
  //           _resumeFile = result.files.first;
  //         } else {
  //           _coverLetterFile = result.files.first;
  //         }
  //       });
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error picking file: ${e.toString()}')),
  //     );
  //   }
  // }

  Future<void> _selectDate(BuildContext context, String field) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (field == 'dateApplied') {
          _dateAppliedController.text = picked.toLocal().toString().split(' ')[0];
        } else if (field == 'deadline') {
          _deadlineController.text = picked.toLocal().toString().split(' ')[0];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // // Determine text to display for attachments.
    // final resumeAttachmentText = _resumeFile?.name ??
    //     (_existingResumeUrl != null ? 'Resume Uploaded' : 'No file selected');
    // final coverLetterAttachmentText = _coverLetterFile?.name ??
    //     (_existingCoverLetterUrl != null ? 'Cover Letter Uploaded' : 'No file selected');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.job == null ? 'Add Job' : 'Edit Job'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _companyController,
                decoration: InputDecoration(labelText: 'Company'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a company name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _positionController,
                decoration: InputDecoration(labelText: 'Position'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a position';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _dateAppliedController,
                decoration: InputDecoration(
                  labelText: 'Date Applied',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context, 'dateApplied'),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a date';
                  }
                  try {
                    DateTime.parse(value);
                  } catch (e) {
                    return 'Please enter a valid date (YYYY-MM-DD)';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _deadlineController,
                decoration: InputDecoration(
                  labelText: 'Deadline',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context, 'deadline'),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a deadline';
                  }
                  try {
                    DateTime.parse(value);
                  } catch (e) {
                    return 'Please enter a valid date (YYYY-MM-DD)';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _salaryController,
                decoration: InputDecoration(
                  labelText: 'Salary (USD)',
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null; // Salary is optional
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _statusController.text.isNotEmpty ? _statusController.text : 'Applied',
                decoration: InputDecoration(labelText: 'Status'),
                items: ['Applied', 'Interviewed', 'Rejected', 'Accepted']
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _statusController.text = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a status';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              // Text('Attachments:', style: TextStyle(fontSize: 16)),
              // ListTile(
              //   title: Text('Resume'),
              //   subtitle: Text(resumeAttachmentText),
              //   trailing: IconButton(
              //     icon: Icon(Icons.attach_file),
              //     onPressed: () => _pickFile(true),
              //   ),
              // ),
              // ListTile(
              //   title: Text('Cover Letter'),
              //   subtitle: Text(coverLetterAttachmentText),
              //   trailing: IconButton(
              //     icon: Icon(Icons.attach_file),
              //     onPressed: () => _pickFile(false),
              //   ),
              // ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isButtonDisabled
                    ? null
                    : () async {
                        setState(() => _isButtonDisabled = true);
                        await _submitForm();
                        if (mounted) setState(() => _isButtonDisabled = false);
                      },
                child: _isSubmitting
                    ? CircularProgressIndicator()
                    : Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
