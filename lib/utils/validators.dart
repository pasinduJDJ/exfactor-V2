import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void _showToast(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: Colors.red,
    textColor: Colors.white,
    fontSize: 14.0,
  );
}

// Example validation methods
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email cannot be empty';
  }
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  if (!emailRegex.hasMatch(value)) {
    return 'Invalid email format';
  }
  return null;
}

String? validatePhoneNumber(String? value) {
  if (value == null || value.isEmpty) {
    return 'Phone number cannot be empty';
  }
  final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
  if (!phoneRegex.hasMatch(value)) {
    return 'Invalid phone number format';
  }
  return null;
}

String? validateRequired(String? value) {
  if (value == null || value.isEmpty) {
    return 'This field is required';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password cannot be empty';
  }
  if (value.length < 6) {
    return 'Password must be at least 6 characters long';
  }
  return null;
}

String? validateConfirmPassword(String? value, String? password) {
  if (value == null || value.isEmpty) {
    return 'Confirm password cannot be empty';
  }
  if (value != password) {
    return 'Passwords do not match';
  }
  return null;
}

int? validateAge(String? value) {
  if (value == null || value.isEmpty) {
    return null; // Age is optional
  }
  final age = int.tryParse(value);
  if (age == null || age < 0 || age > 100) {
    return null; // Invalid age
  }
  return age;
}

String? validateUrl(String? value) {
  if (value == null || value.isEmpty) {
    return 'URL cannot be empty';
  }
  final urlRegex =
      RegExp(r'^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([\/\w .-]*)*\/?$');
  if (!urlRegex.hasMatch(value)) {
    return 'Invalid URL format';
  }
  return null;
}

String? validateNumber(String? value) {
  if (value == null || value.isEmpty) {
    return 'Number cannot be empty';
  }
  final numberRegex = RegExp(r'^\d+$');
  if (!numberRegex.hasMatch(value)) {
    return 'Invalid number format';
  }
  return null;
}


