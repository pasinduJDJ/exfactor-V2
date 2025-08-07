import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../services/superbase_service.dart';
import '../../models/notification_model.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AdminAddNotificationScreen extends StatefulWidget {
  const AdminAddNotificationScreen({Key? key}) : super(key: key);

  @override
  State<AdminAddNotificationScreen> createState() =>
      _AdminAddNotificationScreenState();
}

class _AdminAddNotificationScreenState
    extends State<AdminAddNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedType;
  DateTime? _scheduleDate;
  bool _isLoading = false;

  final List<String> _noticeTypes = ['Event', 'Birthday', 'Alert'];

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _scheduleDate = picked;
      });
    }
  }

  // Handle notification creation
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      _showToast('Please fill all required fields.');
      return;
    }
    if (_scheduleDate == null) {
      _showToast('Please select a schedule date.');
      return;
    }
    if (_selectedType == null) {
      _showToast('Please select a notice type.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final notification = NotificationModel(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        type: _selectedType!,
        schedule_date: _scheduleDate!.toIso8601String(),
      );

      await SupabaseService.insertNotification(notification);
      _showToast('Notification published successfully!');
      Navigator.of(context).pop('notification_added');
    } catch (e) {
      _showToast('Error publishing notification: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: message.toLowerCase().contains('error') ||
              message.toLowerCase().contains('failed') ||
              message.toLowerCase().contains('please')
          ? Colors.red
          : Colors.green,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Add New Event',
            style: TextStyle(fontWeight: FontWeight.bold)),
        toolbarHeight: 70,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 15),
              Text("Title"),
              SizedBox(
                height: 5,
              ),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              Text("Type Of Notice"),
              SizedBox(
                height: 5,
              ),
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: _noticeTypes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedType = val),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              Text("Message"),
              SizedBox(
                height: 5,
              ),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Text("Schedule Date"),
              SizedBox(
                height: 5,
              ),
              GestureDetector(
                onTap: () => _pickDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      suffixIcon: const Icon(Icons.calendar_today, size: 20),
                    ),
                    controller: TextEditingController(
                        text: _scheduleDate == null
                            ? ''
                            : '${_scheduleDate!.year}-${_scheduleDate!.month.toString().padLeft(2, '0')}-${_scheduleDate!.day.toString().padLeft(2, '0')}'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _handleSubmit,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
