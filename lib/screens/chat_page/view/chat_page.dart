import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/chat_page/model/bow_model.dart';
import 'package:hyper_local/screens/chat_page/repo/bow_repository.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final BowRepository _repository = BowRepository();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  List<BowMessage> _messages = [];
  List<BowConversation> _conversations = [];
  bool _isLoading = false;
  bool _isSending = false;
  int? _conversationId;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final conversations = await _repository.getConversationHistory(_conversationId ?? 0);
      if (mounted) {
        setState(() {
          _messages = conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _messages.add(BowMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'user',
        content: message,
        createdAt: DateTime.now(),
      ));
      _messages.add(BowMessage(
        id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant',
        content: '',
        createdAt: DateTime.now(),
      ));
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      final response = await _repository.sendMessage(
        message: message,
      );

      if (mounted) {
        setState(() {
          if (_messages.isNotEmpty) {
            _messages[_messages.length - 1] = response;
          }
          _isSending = false;
        });
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_messages.isNotEmpty) {
            _messages[_messages.length - 1] = BowMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              role: 'assistant',
              content: 'Sorry, I encountered an error. Please try again.',
              createdAt: DateTime.now(),
            );
          }
          _isSending = false;
        });
      }
      _scrollToBottom();
    }
  }

  Future<void> _sendMessageWithImage() async {
    final message = _messageController.text.trim();
    if ((message.isEmpty && _selectedImage == null) || _isSending) return;

    setState(() {
      _isSending = true;
      _messages.add(BowMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'user',
        content: message.isNotEmpty ? message : 'What is this?',
        imageUrl: _selectedImage?.path,
        createdAt: DateTime.now(),
      ));
      _messages.add(BowMessage(
        id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant',
        content: '',
        createdAt: DateTime.now(),
      ));
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      final response = await _repository.sendMessage(
        message: message.isNotEmpty ? message : 'What is this?',
        imageUrl: _selectedImage?.path,
      );

      if (mounted) {
        setState(() {
          if (_messages.isNotEmpty) {
            _messages[_messages.length - 1] = response;
          }
          _isSending = false;
          _selectedImage = null;
        });
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_messages.isNotEmpty) {
            _messages[_messages.length - 1] = BowMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              role: 'assistant',
              content: 'Sorry, I encountered an error. Please try again.',
              createdAt: DateTime.now(),
            );
          }
          _isSending = false;
          _selectedImage = null;
        });
      }
      _scrollToBottom();
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take Photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (source != null) {
      final image = await _imagePicker.pickImage(source: source, imageQuality: 80);
      if (image != null && mounted) {
        setState(() {
          _selectedImage = image;
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startNewConversation() {
    setState(() {
      _conversationId = null;
      _messages = [];
    });
  }

  final List<BowSuggestion> _suggestions = BowSuggestion.getDefaultSuggestions();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CustomScaffold(
      title: l10n.bowAssistant,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Image.asset(
                'assets/images/icons/bot.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  TablerIcons.robot,
                  size: 20.w,
                  color: AppColors.white,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              l10n.bowAssistant,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(TablerIcons.refresh),
            onPressed: _startNewConversation,
            tooltip: 'New Conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcomeView(l10n)
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.w),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          _buildInputArea(l10n),
        ],
      ),
    );
  }

  Widget _buildWelcomeView(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          SizedBox(height: 40.h),
          Container(
            width: 120.w,
            height: 120.w,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Image.asset(
              'assets/images/icons/bot.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                TablerIcons.robot,
                size: 64.w,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Hello! I\'m BOW',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your AI Shopping Assistant',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.grey,
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            'Try asking me:',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.grey.shade600,
            ),
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            alignment: WrapAlignment.center,
            children: _suggestions.take(8).map((suggestion) {
              return ActionChip(
                avatar: Text(suggestion.icon),
                label: Text(
                  suggestion.text,
                  style: TextStyle(fontSize: 12.sp),
                ),
                onPressed: () {
                  _messageController.text = suggestion.text;
                  _sendMessage();
                },
                backgroundColor: AppColors.grey.shade50,
                side: BorderSide(color: AppColors.grey.shade200),
              );
            }).toList(),
          ),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BowMessage message) {
    final isUser = message.role == 'user';
    final isLoading = message.content.isEmpty && message.role == 'assistant';
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Image.asset(
                'assets/images/icons/bot.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  TablerIcons.robot,
                  size: 18.w,
                  color: AppColors.white,
                ),
              ),
            ),
          if (!isUser) SizedBox(width: 8.w),
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: 280.w),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                  bottomLeft: Radius.circular(isUser ? 16.r : 4.r),
                  bottomRight: Radius.circular(isUser ? 4.r : 16.r),
                ),
              ),
              child: isLoading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Thinking...',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      message.content,
                      style: TextStyle(
                        color: isUser ? AppColors.white : AppColors.black,
                        fontSize: 14.sp,
                      ),
                    ),
            ),
          ),
          if (isUser) SizedBox(width: 8.w),
          if (isUser)
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                TablerIcons.user,
                size: 18.w,
                color: AppColors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedImage != null) ...[
              Container(
                height: 80.h,
                margin: EdgeInsets.only(bottom: 8.h),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.file(
                        File(_selectedImage!.path),
                        height: 80.h,
                        width: 80.w,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, size: 16.w, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.image, color: Colors.grey[600]),
                    onPressed: _pickImage,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.grey.shade100,
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask BOW anything...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessageWithImage(),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(TablerIcons.send, color: AppColors.white),
                    onPressed: _isSending ? null : _sendMessageWithImage,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
