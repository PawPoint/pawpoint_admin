import 'package:flutter/material.dart';
import 'super_admin/super_admin_shell.dart';

/// Route entry-point for /super_admin — delegates immediately to the shell.
class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) => const SuperAdminShell();
}