import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../services/superbase_service.dart';
import '../../models/notification_model.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AdminNotificationEditScreen extends StatefulWidget {
  final Map<String, dynamic> notification;
  const AdminNotificationEditScreen({Key? key, required this.notification})
      : super(key: key);

  @override
  State<AdminNotificationEditScreen> createState() =>
      _AdminNotificationEditScreenState();
}

class _AdminNotificationEditScreenState
    extends State<AdminNotificationEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _messageController;
  String? _selectedType;
  DateTime? _scheduleDate;
  bool _isLoading = false;

  final List<String> _noticeTypes = ['Event', 'Birthday', 'Alert'];

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.notification['title'] ?? '');
    _messageController =
        TextEditingController(text: widget.notification['subtitle'] ?? '');
    _selectedType = widget.notification['type'] ?? null;
    final dateStr = widget.notification['submission_date'] ?? '';
    if (dateStr.isNotEmpty) {
      try {
        _scheduleDate = DateTime.parse(dateStr);
      } catch (_) {}
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduleDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _scheduleDate = picked;
      });
    }
  }

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
        notification_id: widget.notification['notification_id'],
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        type: _selectedType!,
        schedule_date: _scheduleDate!.toIso8601String(),
      );
      // Use updateNotification instead of insertNotification
      await SupabaseService.updateNotification(notification);
      _showToast('Notification updated successfully!');
      Navigator.of(context).pop(true);
    } catch (e) {
      _showToast('Error updating notification: ${e.toString()}');
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
      backgroundColor: KbgColor,
      appBar: AppBar(
        title: const Text('Update Event',
            style: TextStyle(fontWeight: FontWeight.bold)),
        toolbarHeight: 70,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 15,
              ),
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
              Text("Notice Type"),
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
              const SizedBox(height: 10),
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
