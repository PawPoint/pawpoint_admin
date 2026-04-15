import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_api_service.dart';

class StaffAppointmentsPage extends StatefulWidget {
  const StaffAppointmentsPage({super.key});

  @override
  State<StaffAppointmentsPage> createState() => _StaffAppointmentsPageState();
}

class _StaffAppointmentsPageState extends State<StaffAppointmentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _pending = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await AdminApiService.fetchPendingAppointments();
      if (mounted) setState(() { _pending = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(Map<String, dynamic> appt) async {
    final noteCtrl = TextEditingController();
    final doctorCtrl = TextEditingController(text: appt['doctor'] ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Approve Appointment',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Service: ${appt['service']}\nPet: ${appt['pet']}',
                style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: doctorCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecor('Assigned Doctor'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: _inputDecor('Doctor Note (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Approve', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminApiService.approveAppointment(
          appt['user_id'] as String,
          appt['id'] as String,
          doctorNote: noteCtrl.text.trim(),
          assignedDoctor: doctorCtrl.text.trim(),
        );
        _showSnack('Appointment approved ✓', const Color(0xFF10B981));
        _load();
      } catch (e) {
        _showSnack('Error: $e', const Color(0xFFEF4444));
      }
    }
  }

  Future<void> _reject(Map<String, dynamic> appt) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reject Appointment',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Service: ${appt['service']}\nPet: ${appt['pet']}',
                style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: noteCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: _inputDecor('Reason for rejection'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Reject', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminApiService.rejectAppointment(
          appt['user_id'] as String,
          appt['id'] as String,
          doctorNote: noteCtrl.text.trim(),
        );
        _showSnack('Appointment rejected', const Color(0xFFEF4444));
        _load();
      } catch (e) {
        _showSnack('Error: $e', const Color(0xFFEF4444));
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  InputDecoration _inputDecor(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF64748B)),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildTabs(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildPendingList(),
                      _buildEmptyApproved(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      color: const Color(0xFFF8FAFF),
      child: Row(
        children: [
          Text('Patients',
              style: GoogleFonts.poppins(
                  color: const Color(0xFF1E293B), fontWeight: FontWeight.w700, fontSize: 20)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF10B981)),
            onPressed: _load,
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0,2))],
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(12),
        ),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF94A3B8),
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: [
          Tab(text: 'Pending (${_pending.length})'),
          const Tab(text: 'Approved'),
        ],
      ),
    );
  }

  Widget _buildPendingList() {
    if (_pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 56),
            const SizedBox(height: 16),
            Text('No pending appointments!',
                style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pending.length,
      itemBuilder: (_, i) => _buildApptCard(_pending[i]),
    );
  }

  Widget _buildEmptyApproved() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_available_rounded, color: Color(0xFF6366F1), size: 56),
          const SizedBox(height: 16),
          Text('View approved appointments in Super Admin',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildApptCard(Map<String, dynamic> appt) {
    DateTime? dt;
    try { dt = DateTime.parse(appt['dateTime'] as String); } catch (_) {}
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.pets_rounded, color: Color(0xFFF59E0B), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appt['service'] ?? 'Service',
                          style: GoogleFonts.poppins(
                              color: const Color(0xFF1E293B), fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('${appt['user_name'] ?? 'Owner'} · Pet: ${appt['pet'] ?? '-'}',
                          style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Pending',
                      style: GoogleFonts.poppins(color: const Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: Color(0xFF6366F1), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    dt != null
                        ? '${months[dt.month-1]} ${dt.day}, ${dt.year}  ${_timeStr(dt)}'
                        : 'Date unknown',
                    style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            if ((appt['doctor'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.medical_services_outlined, color: Color(0xFF10B981), size: 14),
                  const SizedBox(width: 6),
                  Text('Dr. ${appt['doctor']}',
                      style: GoogleFonts.poppins(color: const Color(0xFF10B981), fontSize: 12)),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(appt),
                    icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFEF4444)),
                    label: Text('Reject',
                        style: GoogleFonts.poppins(color: const Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approve(appt),
                    icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                    label: Text('Approve',
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeStr(DateTime d) {
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:${d.minute.toString().padLeft(2,'0')} $ampm';
  }
}
