import 'package:flutter/material.dart';
import '../shared/models/chat_model.dart'; // Import model ChatMessage

class AIController extends ChangeNotifier {
  final ScrollController scrollController = ScrollController();
  final TextEditingController inputController = TextEditingController();
  bool isTyping = false;

  // Mock Data (Dữ liệu giả)
  List<ChatMessage> messages = [
    ChatMessage(
      id: '1',
      text: 'Chào buổi sáng! Tôi đã tổng hợp báo cáo đầu ngày cho bạn. Hôm nay có 5 công việc quan trọng và 1 cuộc họp lúc 14:00.',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    ChatMessage(
      id: '2',
      text: '⚠️ Cảnh báo: Bạn có hóa đơn tiền điện 450,000₫ cần thanh toán trước 20/01.',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  // Hàm gửi tin nhắn
  void sendMessage() async {
    final text = inputController.text.trim();
    if (text.isEmpty) return;

    // 1. Thêm tin nhắn của User
    messages.add(ChatMessage(
      id: DateTime.now().toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    inputController.clear();
    isTyping = true;
    notifyListeners();
    _scrollToBottom();

    // 2. Giả lập AI đang suy nghĩ (1 giây)
    await Future.delayed(const Duration(seconds: 1));

    // 3. AI trả lời
    messages.add(ChatMessage(
      id: DateTime.now().toString(),
      text: "Tôi đã hiểu yêu cầu: '$text'. Đang xử lý...", 
      isUser: false,
      timestamp: DateTime.now(),
    ));
    isTyping = false;
    notifyListeners();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  @override
  void dispose() {
    scrollController.dispose();
    inputController.dispose();
    super.dispose();
  }
}