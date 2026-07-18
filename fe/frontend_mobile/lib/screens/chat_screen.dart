import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import '../services/gemini_service.dart';

/// Màn hình chatbot AI tư vấn sản phẩm — dùng Gemini API với RAG pipeline.
///
/// Mở từ `WelcomeScreen` qua nút chat, hoặc từ `BottomNavigationBar`.
/// Theme đồng nhất với app Aura Accessories (đỏ 0xFFC8102E + vàng 0xFFFFD700).
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final GeminiService _geminiService = GeminiService();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Theme màu đồng nhất với app Aura (đỏ rượu vang + vàng kim).
  static const Color _primary = Color(0xFFC8102E);
  static const Color _primaryDark = Color(0xFF8B0000);
  static const Color _accentGold = Color(0xFFFFD700);
  static const Color _bgPage = Color(0xFFFAF8F5);
  static const Color _bgBubble = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1A1A2E);
  static const Color _textSecondary = Color(0xFF6B7280);

  // Gợi ý câu hỏi khi mở app lần đầu.
  static const List<String> _suggestions = [
    'Có những đồng hồ nào đang bán?',
    'Đồng hồ Luxury giá bao nhiêu?',
    'Chính sách đổi trả như thế nào?',
    'Combo quà tặng có gì hot?',
    'Vòng cổ bạc 925 có phù hợp không?',
    'Shop có miễn phí vận chuyển không?',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _geminiService.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage({String? override}) async {
    final text = (override ?? _textController.text).trim();
    if (text.isEmpty || _isLoading) return;

    if (override == null) _textController.clear();
    HapticFeedback.selectionClick();

    setState(() {
      _messages.add(ChatMessage(content: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    final response = await _geminiService.sendMessage(text);

    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(content: response, isUser: false));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty ? _buildWelcome() : _buildList(),
          ),
          if (_isLoading) _buildTypingIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // AppBar
  // ──────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_primary, _primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 2,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _accentGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: _accentGold,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AURA Assistant',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Tư vấn phụ kiện thời trang',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Xóa hội thoại',
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _messages.isEmpty
              ? null
              : () {
                  setState(() => _messages.clear());
                  HapticFeedback.lightImpact();
                },
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Màn hình chào mừng khi chưa có tin nhắn
  // ──────────────────────────────────────────────────────────────────
  Widget _buildWelcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Logo gradient
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primary.withOpacity(0.3),
                  _accentGold.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _primary.withOpacity(0.3), width: 1.5),
            ),
            child: const Icon(
              Icons.diamond,
              size: 44,
              color: _accentGold,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Xin chào! Tôi là AURA Assistant',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hỏi tôi về sản phẩm, giá cả, chính sách đổi trả,\nvà các chương trình khuyến mãi hiện tại.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: _textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          // Section: câu hỏi gợi ý
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Gợi ý câu hỏi:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ..._suggestions.map((q) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildSuggestionChip(q),
              )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _sendMessage(override: text),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _primary.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 16, color: _primary.withOpacity(0.7)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: _primary.withOpacity(0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 11, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Danh sách tin nhắn
  // ──────────────────────────────────────────────────────────────────
  Widget _buildList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildBubble(_messages[i]),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    final time = '${msg.createdAt.hour.toString().padLeft(2, '0')}:'
        '${msg.createdAt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primary, _accentGold],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: const Icon(
                Icons.diamond,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [_primary, _primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : _bgBubble,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isUser ? null : Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SelectableText(
                    msg.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : _textPrimary,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey.shade500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Typing indicator (3 chấm nhảy)
  // ──────────────────────────────────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_primary, _accentGold],
              ),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: const Icon(Icons.diamond, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Ô nhập tin nhắn
  // ──────────────────────────────────────────────────────────────────
  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        8,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _bgPage,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                style: const TextStyle(color: _textPrimary, fontSize: 14),
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Hỏi về sản phẩm AURA...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13.5,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Nút gửi gradient
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: _isLoading ? null : _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primary, _primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Widget 3 chấm nhảy khi AI đang xử lý
// ──────────────────────────────────────────────────────────────────────
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      ),
    );
    _animations = _controllers
        .map((c) => Tween<double>(begin: 0, end: -6).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            child: Transform.translate(
              offset: Offset(0, _animations[i].value),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFFC8102E).withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
