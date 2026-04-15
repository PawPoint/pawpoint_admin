import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/admin_api_service.dart';

class StaffMessagesPage extends StatefulWidget {
  const StaffMessagesPage({super.key});

  @override
  State<StaffMessagesPage> createState() => _StaffMessagesPageState();
}

class _StaffMessagesPageState extends State<StaffMessagesPage> {
  // Super Admin UID — hardcoded as the primary contact
  static const String _superAdminUid = 'JqvuhfEo8baJblJEl8qW1smm3KC3';
  static const String _superAdminName = 'Super Admin';

  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _myName =>
      FirebaseAuth.instance.currentUser?.displayName ?? 'Doctor';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final convs = await AdminApiService.fetchConversations(_myUid);
      // Find the conversation with super admin
      List<Map<String, dynamic>> msgs = [];
      for (final conv in convs) {
        final id = conv['conversation_id'] as String;
        if (id.contains(_superAdminUid)) {
          msgs = List<Map<String, dynamic>>.from(conv['messages'] ?? []);
          break;
        }
      }
      if (mounted) setState(() { _messages = msgs; _loading = false; });
      _scrollToBottom();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    try {
      await AdminApiService.sendMessage(
        senderId: _myUid,
        receiverId: _superAdminUid,
        content: text,
        senderName: _myName,
        senderRole: 'staff_admin',
      );
      _load();
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : _messages.isEmpty
                    ? _buildEmpty()
                    : _buildMessages(),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFF6366F1),
            child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_superAdminName,
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF1E293B), fontWeight: FontWeight.w700, fontSize: 15)),
              Row(
                children: [
                  Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text('Online', style: GoogleFonts.poppins(color: const Color(0xFF10B981), fontSize: 11)),
                ],
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF10B981)),
            onPressed: _load,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFE2E8F0), size: 64),
          const SizedBox(height: 16),
          Text('No messages yet', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 15)),
          Text('Send a message to Super Admin',
              style: GoogleFonts.poppins(color: const Color(0xFFCBD5E1), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildBubble(_messages[i]),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final isMe = msg['sender_id'] == _myUid;
    final time = (msg['timestamp'] as String? ?? '').length >= 16
        ? msg['timestamp'].substring(11, 16)
        : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                    : null,
                color: isMe ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))
                ],
              ),
              child: Text(
                msg['content'] ?? '',
                style: GoogleFonts.poppins(
                  color: isMe ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 13.5,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(time,
                style: GoogleFonts.poppins(color: const Color(0xFFCBD5E1), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _msgCtrl,
                style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Message Super Admin...',
                  hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
