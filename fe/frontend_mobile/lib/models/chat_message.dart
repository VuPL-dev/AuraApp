/// Model đại diện cho một tin nhắn trong cuộc hội thoại chat.
///
/// Sử dụng cho [ChatScreen] và [GeminiService] khi gửi/nhận tin nhắn.
class ChatMessage {
  /// Nội dung tin nhắn (văn bản thuần, có thể chứa Markdown đơn giản).
  final String content;

  /// `true` nếu tin nhắn từ phía người dùng, `false` nếu từ AI bot.
  final bool isUser;

  /// Thời điểm tạo tin nhắn. Mặc định là thời điểm hiện tại.
  final DateTime createdAt;

  /// Trạng thái gửi — dùng để hiển thị loading hoặc lỗi.
  /// - [MessageStatus.sent]: đã gửi/đã nhận thành công
  /// - [MessageStatus.sending]: đang chờ AI trả lời
  /// - [MessageStatus.error]: gửi thất bại
  final MessageStatus status;

  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? createdAt,
    this.status = MessageStatus.sent,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Tin nhắn tạm thời hiển thị trong khi chờ AI (typing indicator).
  factory ChatMessage.typing() => ChatMessage(
        content: '',
        isUser: false,
        status: MessageStatus.sending,
      );
}

enum MessageStatus { sent, sending, error }
