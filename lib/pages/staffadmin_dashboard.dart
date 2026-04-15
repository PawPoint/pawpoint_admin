import 'package:flutter/material.dart';
import 'staff_admin/staff_admin_shell.dart';

/// Route entry-point for /staff_admin — delegates immediately to the shell.
class StaffAdminDashboard extends StatelessWidget {
  const StaffAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) => const StaffAdminShell();
}