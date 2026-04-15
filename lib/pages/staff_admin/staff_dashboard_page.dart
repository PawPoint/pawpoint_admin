import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_api_service.dart';

class StaffDashboardPage extends StatefulWidget {
  const StaffDashboardPage({super.key});

  @override
  State<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends State<StaffDashboardPage> {
  List<dynamic> _pending = [];
  bool _loading = true;
  String? _doctorName;

  @override
  void initState() {
    super.initState();
    _loadNameThenData();
  }

  Future<void> _loadNameThenData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(uid)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            _doctorName =
                (doc.data() as Map<String, dynamic>)['name'] ?? 'Doctor';
          });
        }
      } catch (_) {}
    }
    _load();
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildStatRow(),
            _buildSectionTitle('Pending Appointments'),
            _loading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
                  )
                : _pending.isEmpty
                    ? _buildEmpty()
                    : _buildPendingList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good day, 👋',
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                Text(
                  _doctorName ?? 'Doctor',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22),
                ),
                const SizedBox(height: 4),
                Text('PawPoint Veterinary Staff',
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Text(
              (_doctorName ?? 'D')[0].toUpperCase(),
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow() {
    final today = _pending.where((a) {
      try {
        final dt = DateTime.parse(a['dateTime'] as String);
        final now = DateTime.now();
        return dt.year == now.year && dt.month == now.month && dt.day == now.day;
      } catch (_) { return false; }
    }).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _miniStat('Pending', '${_pending.length}', Icons.pending_actions_rounded, const Color(0xFFF59E0B)),
          const SizedBox(width: 12),
          _miniStat('Today', '$today', Icons.today_rounded, const Color(0xFF6366F1)),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF1E293B), fontWeight: FontWeight.w700, fontSize: 22)),
                Text(label,
                    style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(t,
          style: GoogleFonts.poppins(
              color: const Color(0xFF1E293B), fontWeight: FontWeight.w700, fontSize: 16)),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: Color(0xFF10B981), size: 56),
            const SizedBox(height: 16),
            Text('All caught up!',
                style: GoogleFonts.poppins(
                    color: const Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 16)),
            Text('No pending appointments.',
                style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _pending.take(5).length,
      itemBuilder: (_, i) => _buildPendingCard(_pending[i]),
    );
  }

  Widget _buildPendingCard(Map<String, dynamic> appt) {
    DateTime? dt;
    try { dt = DateTime.parse(appt['dateTime'] as String); } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
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
                        color: const Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 13)),
                Text('${appt['user_name'] ?? 'Owner'} · ${appt['pet'] ?? 'Pet'}',
                    style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 11)),
                if (dt != null)
                  Text(_formatDate(dt),
                      style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 10)),
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
                style: GoogleFonts.poppins(
                    color: const Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${months[d.month-1]} ${d.day}, ${d.year}  $h:${d.minute.toString().padLeft(2,'0')} $ampm';
  }
}
