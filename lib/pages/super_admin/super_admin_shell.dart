import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'super_dashboard_page.dart';
import 'super_appointments_page.dart';
import 'super_manage_staff_page.dart';
import 'super_users_page.dart';
import 'super_services_pricing_page.dart';
import 'super_calendar_page.dart';
import 'super_messages_page.dart';
import 'super_financials_page.dart';

class SuperAdminShell extends StatefulWidget {
  const SuperAdminShell({super.key});

  @override
  State<SuperAdminShell> createState() => _SuperAdminShellState();
}

class _SuperAdminShellState extends State<SuperAdminShell> {
  int _selectedIndex = 0;
  bool _sidebarExpanded = true;
  String _adminName = 'Super Admin';
  String _adminInitials = 'SA';

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  Future<void> _loadAdminInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'Super Admin';
        final parts = name.trim().split(' ');
        final initials = parts.length >= 2
            ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
            : name.isNotEmpty ? name[0].toUpperCase() : 'SA';
        setState(() {
          _adminName = name;
          _adminInitials = initials;
        });
      }
    } catch (_) {}
  }

  // ── Navigation items (blueprint order) ────────────────────────────────
  final List<_NavItem> _navItems = [
    _NavItem(Icons.dashboard_rounded,          'System Overview'),
    _NavItem(Icons.calendar_month_rounded,     'Master Schedule'),
    _NavItem(Icons.pending_actions_rounded,    'Appointments'),
    _NavItem(Icons.people_alt_rounded,         'Manage Users'),
    _NavItem(Icons.badge_rounded,              'Manage Staff'),
    _NavItem(Icons.local_offer_rounded,        'Services & Pricing'),
    _NavItem(Icons.chat_bubble_rounded,        'Messages'),
    _NavItem(Icons.bar_chart_rounded,          'Financials'),
  ];

  late final List<Widget> _pages = [
    const SuperDashboardPage(),
    const SuperCalendarPage(),
    const SuperAppointmentsPage(),
    const SuperUsersPage(),
    const SuperManageStaffPage(),
    const SuperServicesPricingPage(),
    const SuperMessagesPage(),
    const SuperFinancialsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(isMobile),
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
      drawer: isMobile ? _buildDrawer() : null,
    );
  }

  // ── Sidebar ────────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: _sidebarExpanded ? 240 : 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.black.withValues(alpha: 0.08), width: 1)),
      ),
      child: Column(
        children: [
          _buildSidebarHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: _navItems.length,
              itemBuilder: (_, i) => _buildNavTile(i),
            ),
          ),
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.07))),
      ),
      child: Row(
        children: [
          if (_sidebarExpanded)
            Expanded(
              child: Image.asset(
                'assets/images/logo1.png',
                height: 28,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
              ),
            )
          else
            const Icon(Icons.pets_rounded, color: Colors.black87, size: 28),
          IconButton(
            icon: Icon(
              _sidebarExpanded ? Icons.menu_open : Icons.menu,
              color: Colors.black54,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _sidebarExpanded = !_sidebarExpanded),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile(int index) {
    final item     = _navItems[index];
    final selected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: selected ? Colors.black : Colors.transparent,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(item.icon,
            color: selected ? Colors.white : Colors.black54,
            size: 22),
        title: _sidebarExpanded
            ? Text(item.label,
                style: GoogleFonts.poppins(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13.5))
            : null,
        selected: selected,
        onTap: () => setState(() => _selectedIndex = index),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListTile(
        dense: true,
        leading: Icon(Icons.logout_rounded,
            color: Colors.red.shade400, size: 20),
        title: _sidebarExpanded
            ? Text('Logout',
                style: GoogleFonts.poppins(
                    color: Colors.red.shade400, fontSize: 13))
            : null,
        onTap: _handleLogout,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────
  Widget _buildTopBar(bool isMobile) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black87),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          Text(
            _navItems[_selectedIndex].label,
            style: GoogleFonts.poppins(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 18),
          ),
          const Spacer(),
          if (!isMobile)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black12),
              ),
              child: Text(_adminName,
                  style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.black,
            child: Text(_adminInitials,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Mobile Drawer ──────────────────────────────────────────────────────
  Drawer _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 50),
          _buildSidebarHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (_, i) => _buildNavTile(i),
            ),
          ),
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
