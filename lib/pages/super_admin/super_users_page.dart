import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_api_service.dart';

class SuperUsersPage extends StatefulWidget {
  const SuperUsersPage({super.key});

  @override
  State<SuperUsersPage> createState() => _SuperUsersPageState();
}

class _SuperUsersPageState extends State<SuperUsersPage> {
  List<dynamic> _users = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await AdminApiService.fetchAllUsers();
      if (mounted) {
        setState(() {
          _users = data;
          _filtered = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _users
          : _users.where((u) {
              final name = (u['name'] ?? '').toString().toLowerCase();
              final email = (u['email'] ?? '').toString().toLowerCase();
              return name.contains(q) || email.contains(q);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : _buildGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  hintStyle: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF94A3B8)),
            onPressed: _load,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text('No users found',
          style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 15)),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisExtent: 160,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _buildUserCard(_filtered[i]),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final role = user['role'] ?? 'user';
    final roleColor = role == 'super_admin'
        ? const Color(0xFF8B5CF6)
        : role == 'staff_admin'
            ? const Color(0xFF10B981)
            : const Color(0xFF3B82F6);
    final initials = _initials(user['name'] ?? 'U');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: roleColor.withOpacity(0.2),
                backgroundImage: user['photoUrl'] != null && (user['photoUrl'] as String).isNotEmpty
                    ? NetworkImage(user['photoUrl'])
                    : null,
                child: user['photoUrl'] == null || (user['photoUrl'] as String).isEmpty
                    ? Text(initials,
                        style: GoogleFonts.poppins(
                            color: roleColor, fontWeight: FontWeight.w700, fontSize: 14))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['name'] ?? 'Unknown',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(role,
                          style: GoogleFonts.poppins(color: roleColor, fontSize: 9, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(Icons.email_outlined, user['email'] ?? '-'),
          const SizedBox(height: 4),
          _infoRow(Icons.phone_outlined, user['phone'] ?? '-'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}
