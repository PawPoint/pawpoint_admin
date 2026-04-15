import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/admin_api_service.dart';

class SuperMessagesPage extends StatefulWidget {
  const SuperMessagesPage({super.key});

  @override
  State<SuperMessagesPage> createState() => _SuperMessagesPageState();
}

class _SuperMessagesPageState extends State<SuperMessagesPage> {
  List<dynamic> _conversations = [];
  bool _loading = true;
  Map<String, dynamic>? _active; // active conversation
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';

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
      final data = await AdminApiService.fetchAllConversations();
      if (mounted) setState(() { _conversations = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    if (_active == null || _msgCtrl.text.trim().isEmpty) return;
    final convId = _active!['conversation_id'] as String;
    final parts = convId.split('__');
    final receiverId = parts.firstWhere((p) => p != _myUid, orElse: () => parts[0]);
    try {
      await AdminApiService.sendMessage(
        senderId: _myUid,
        receiverId: receiverId,
        content: _msgCtrl.text.trim(),
        senderName: FirebaseAuth.instance.currentUser?.displayName ?? 'Super Admin',
        senderRole: 'super_admin',
      );
      _msgCtrl.clear();
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : Row(
              children: [
                // Conversation list
                Container(
                  width: 260,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    border: Border(right: BorderSide(color: Color(0xFF334155))),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Conversations',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                      Expanded(
                        child: _conversations.isEmpty
                            ? Center(
                                child: Text('No messages',
                                    style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 13)),
                              )
                            : ListView.builder(
                                itemCount: _conversations.length,
                                itemBuilder: (_, i) {
                                  final conv = _conversations[i];
                                  final msgs = conv['messages'] as List? ?? [];
                                  final last = msgs.isNotEmpty ? msgs.last : null;
                                  final isActive = _active != null &&
                                      _active!['conversation_id'] == conv['conversation_id'];
                                  return ListTile(
                                    selected: isActive,
                                    selectedTileColor: const Color(0xFF6366F1).withOpacity(0.1),
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
                                      child: const Icon(Icons.medical_services_rounded,
                                          color: Color(0xFF6366F1), size: 18),
                                    ),
                                    title: Text(
                                      conv['conversation_id'] as String,
                                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: last != null
                                        ? Text(last['content'] as String? ?? '',
                                            style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 11),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis)
                                        : null,
                                    onTap: () => setState(() => _active = conv),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                // Chat panel
                Expanded(
                  child: _active == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.chat_bubble_outline_rounded,
                                  color: Color(0xFF334155), size: 56),
                              const SizedBox(height: 16),
                              Text('Select a conversation',
                                  style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 15)),
                            ],
                          ),
                        )
                      : _buildChatPanel(),
                ),
              ],
            ),
    );
  }

  Widget _buildChatPanel() {
    final msgs = (_active!['messages'] as List?) ?? [];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            border: Border(bottom: BorderSide(color: Color(0xFF334155))),
          ),
          child: Row(
            children: [
              const Icon(Icons.medical_services_rounded, color: Color(0xFF6366F1), size: 20),
              const SizedBox(width: 10),
              Text(_active!['conversation_id'] as String,
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(16),
            itemCount: msgs.length,
            itemBuilder: (_, i) => _buildBubble(msgs[i]),
          ),
        ),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final isMe = msg['sender_id'] == _myUid;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe ? null : Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(msg['sender_name'] ?? (isMe ? 'Super Admin' : 'Doctor'),
                style: GoogleFonts.poppins(
                  color: isMe ? Colors.white70 : const Color(0xFF94A3B8), fontSize: 10)),
            const SizedBox(height: 2),
            Text(msg['content'] ?? '',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(top: BorderSide(color: Color(0xFF334155))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
