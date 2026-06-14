import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'database_service.dart';

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

  bool _isSubmitting = false;
  bool _isButtonDisabled = false;

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
    } else {
      _statusController.text = 'Applied';
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

  Future<void> _submitForm() async {
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

      final userId = AuthService().userId;
      if (userId == null) throw Exception('User not authenticated');

      final now = DateTime.now().toIso8601String().substring(0, 19).replaceFirst('T', ' ');

      if (widget.job != null && widget.job!.containsKey('id')) {
        final jobId = int.parse(widget.job!['id']);
        await DatabaseService.updateJob(jobId, {
          'company': _companyController.text,
          'position': _positionController.text,
          'date_applied': _dateAppliedController.text,
          'deadline': _deadlineController.text,
          'notes': _notesController.text,
          'status': _statusController.text,
          'salary': _salaryController.text.isNotEmpty
              ? double.tryParse(_salaryController.text) ?? 0
              : 0,
          'updated_at': now,
        });
      } else {
        final exists = await DatabaseService.jobExists(
          userId,
          _companyController.text,
          _positionController.text,
        );
        if (exists) {
          throw Exception('This job already exists in your applications');
        }

        await DatabaseService.addJob({
          'user_id': userId,
          'company': _companyController.text,
          'position': _positionController.text,
          'date_applied': _dateAppliedController.text,
          'deadline': _deadlineController.text,
          'notes': _notesController.text,
          'status': _statusController.text,
          'salary': _salaryController.text.isNotEmpty
              ? double.tryParse(_salaryController.text) ?? 0
              : 0,
          'created_at': now,
          'updated_at': now,
        });
      }

      widget.onSubmit({});
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
                    return null;
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
