import 'package:flutter/material.dart';

class RdvRequest {
  final String serviceType;
  final String fullName;
  final String phone;
  final String? email;
  final String quartier;
  final String? address;
  final DateTime date;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String? notes;
  final bool consented;
  final String? clientId;
  final String? userId;

  RdvRequest({
    required this.serviceType,
    required this.fullName,
    required this.phone,
    this.email,
    required this.quartier,
    this.address,
    required this.date,
    this.startTime,
    this.endTime,
    this.notes,
    required this.consented,
    this.clientId,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': serviceType,
      'service_type': serviceType,
      'name': fullName,
      'client_name': fullName,
      'phone': phone,
      'client_phone': phone,
      'email': email,
      'client_email': email,
      'client_id': clientId,
      'user_id': userId,
      'firebase_uid': userId,
      'quartier': quartier,
      'address': address,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD
      'start_time': startTime != null
          ? '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'end_time': endTime != null
          ? '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'notes': notes,
      'consented': consented,
    };
  }
}
