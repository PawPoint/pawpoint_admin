import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service that talks to the Admin Backend (port 8001).
class AdminApiService {
  static const String _base = 'http://localhost:8001';

  // ─────────────────────────── Dashboard Stats ──────────────────────────────
  static Future<Map<String, dynamic>> fetchStats() async {
    final res = await http.get(Uri.parse('$_base/api/admin/stats'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load stats: ${res.body}');
  }

  // ─────────────────────────── Users ───────────────────────────────────────
  static Future<List<dynamic>> fetchAllUsers() async {
    final res = await http.get(Uri.parse('$_base/api/admin/users'));
    if (res.statusCode == 200) return jsonDecode(res.body)['users'];
    throw Exception('Failed to load users');
  }

  // ─────────────────────────── Pending Appointments ────────────────────────
  static Future<List<dynamic>> fetchPendingAppointments() async {
    final res = await http.get(
        Uri.parse('$_base/api/admin/appointments/pending'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['appointments'];
    }
    throw Exception('Failed to load pending appointments');
  }

  // ─────────────────────────── Approved/All Appointments ───────────────────
  static Future<List<dynamic>> fetchApprovedAppointments() async {
    final res = await http.get(
        Uri.parse('$_base/api/admin/appointments/approved'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['appointments'];
    }
    throw Exception('Failed to load approved appointments');
  }

  // ─────────────────────────── Approve ─────────────────────────────────────
  static Future<void> approveAppointment(
    String userId,
    String appointmentId, {
    String doctorNote = '',
    String assignedDoctor = '',
  }) async {
    final res = await http.put(
      Uri.parse(
          '$_base/api/admin/appointments/$userId/$appointmentId/approve'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'status': 'approved',
        'doctor_note': doctorNote,
        'assigned_doctor': assignedDoctor,
      }),
    );
    if (res.statusCode != 200) throw Exception('Failed to approve');
  }

  // ─────────────────────────── Reject ──────────────────────────────────────
  static Future<void> rejectAppointment(
    String userId,
    String appointmentId, {
    String doctorNote = '',
  }) async {
    final res = await http.put(
      Uri.parse(
          '$_base/api/admin/appointments/$userId/$appointmentId/reject'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': 'rejected', 'doctor_note': doctorNote}),
    );
    if (res.statusCode != 200) throw Exception('Failed to reject');
  }

  // ─────────────────────────── Complete ────────────────────────────────────
  static Future<void> completeAppointment(
      String userId, String appointmentId) async {
    final res = await http.put(
      Uri.parse(
          '$_base/api/admin/appointments/$userId/$appointmentId/complete'),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode != 200) throw Exception('Failed to complete');
  }

  // ─────────────────────────── Staff/Admins ────────────────────────────────

  /// List all admin accounts (from the 'admins' Firestore collection).
  static Future<List<dynamic>> fetchStaff() async {
    final res =
        await http.get(Uri.parse('$_base/api/admin/staff'));
    if (res.statusCode == 200) return jsonDecode(res.body)['staff'];
    throw Exception('Failed to load staff');
  }

  /// Provision a new doctor account via the backend.
  static Future<void> createStaffAccount({
    required String name,
    required String email,
    required String password,
    String specialty = 'Veterinarian',
  }) async {
    final res = await http.post(
      Uri.parse('$_base/api/admin/staff'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'specialty': specialty,
        'role': 'staff_admin',
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      final detail =
          jsonDecode(res.body)['detail'] ?? 'Failed to create staff account';
      throw Exception(detail);
    }
  }

  // ─────────────────────────── Services & Pricing ──────────────────────────

  /// Fetch all clinic services.
  static Future<List<dynamic>> fetchServices() async {
    final res =
        await http.get(Uri.parse('$_base/api/admin/services'));
    if (res.statusCode == 200) return jsonDecode(res.body)['services'];
    throw Exception('Failed to load services');
  }

  /// Create a new service.
  static Future<void> createService({
    required String name,
    required double price,
    String description = '',
  }) async {
    final res = await http.post(
      Uri.parse('$_base/api/admin/services'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'name': name, 'price': price, 'description': description}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to create service');
    }
  }

  /// Update an existing service.
  static Future<void> updateService({
    required String id,
    required String name,
    required double price,
    String description = '',
  }) async {
    final res = await http.put(
      Uri.parse('$_base/api/admin/services/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'name': name, 'price': price, 'description': description}),
    );
    if (res.statusCode != 200) throw Exception('Failed to update service');
  }

  /// Delete a service.
  static Future<void> deleteService(String id) async {
    final res =
        await http.delete(Uri.parse('$_base/api/admin/services/$id'));
    if (res.statusCode != 200) throw Exception('Failed to delete service');
  }

  // ─────────────────────────── Messages ────────────────────────────────────
  static Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String senderName = '',
    String senderRole = 'staff_admin',
  }) async {
    await http.post(
      Uri.parse('$_base/api/admin/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
        'sender_name': senderName,
        'sender_role': senderRole,
      }),
    );
  }

  static Future<List<dynamic>> fetchConversations(String uid) async {
    final res =
        await http.get(Uri.parse('$_base/api/admin/messages/$uid'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['conversations'];
    }
    throw Exception('Failed to load messages');
  }

  static Future<List<dynamic>> fetchAllConversations() async {
    final res =
        await http.get(Uri.parse('$_base/api/admin/messages'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['conversations'];
    }
    throw Exception('Failed to load conversations');
  }

  // ─────────────────────────── Phase 3: Financials ─────────────────────────

  /// Fetch gross revenue, cash collected, pending receivables & per-service breakdown.
  static Future<Map<String, dynamic>> fetchFinancials() async {
    final res = await http.get(Uri.parse('$_base/api/admin/financials'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load financials');
  }

  /// Fetch the full transaction ledger.
  static Future<List<dynamic>> fetchTransactions() async {
    final res = await http.get(Uri.parse('$_base/api/admin/transactions'));
    if (res.statusCode == 200) return jsonDecode(res.body)['transactions'];
    throw Exception('Failed to load transactions');
  }

  /// Staff action: mark the OTC balance as paid for an appointment.
  static Future<void> markBalancePaid({
    required String userId,
    required String appointmentId,
  }) async {
    final res = await http.put(
      Uri.parse('$_base/api/payments/mark-paid'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'appointment_id': appointmentId,
      }),
    );
    if (res.statusCode != 200) {
      final detail = jsonDecode(res.body)['detail'] ?? 'Failed to mark balance paid';
      throw Exception(detail);
    }
  }
}
