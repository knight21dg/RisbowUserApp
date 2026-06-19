import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/services/feature_settings_service.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:http/http.dart' as http;

class LiveChatPage extends StatefulWidget {
  const LiveChatPage({super.key});

  @override
  State<LiveChatPage> createState() => _LiveChatPageState();
}

class _LiveChatPageState extends State<LiveChatPage> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final bool _isLoading = false;
  bool _isSending = false;
  final String _currentAgent = 'Support Team';
  final String _agentStatus = 'Online';

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add({
        'id': '1',
        'role': 'agent',
        'content': 'Hello! Welcome to Risbow Support. How can I help you today?',
        'time': DateTime.now(),
      });
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _messages.add({
        'id': userMessageId,
        'role': 'user',
        'content': text,
        'time': DateTime.now(),
      });
      _isSending = true;
    });
    _messageController.clear();

    try {
      final response = await http.post(
        Uri.parse('${AppConstant.baseUrl}live-chat/messages'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({'message': text}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          setState(() {
            _messages.add({
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
              'role': 'agent',
              'content': data['data']['reply'] ?? data['data']['message'] ?? 'Thank you for your message. An agent will respond shortly.',
              'time': DateTime.now(),
            });
          });
          return;
        }
      }
      setState(() {
        _messages.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'role': 'agent',
          'content': 'Thank you for your message. An agent will respond shortly.',
          'time': DateTime.now(),
        });
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'role': 'agent',
          'content': 'Thank you for your message. An agent will respond shortly.',
          'time': DateTime.now(),
        });
      });
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!FeatureSettingsService.instance.liveChatEnabled) {
      return Scaffold(
        appBar: AppBar(title: Text('Live Chat')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Live Chat is currently unavailable',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentAgent, style: TextStyle(fontSize: 16)),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _agentStatus == 'Online' ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  _agentStatus,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () => _showOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Questions
          Container(
            height: 60.h,
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              itemCount: 5,
              itemBuilder: (context, index) {
                final suggestions = [
                  'Where is my order?',
                  'How to return?',
                  'Payment issues',
                  'Cancel order',
                  'Contact agent',
                ];
                final q = suggestions[index];
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: ActionChip(
                    label: Text(q, style: TextStyle(fontSize: 12)),
                    onPressed: () => _sendMessage(q),
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Messages
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          // Input Area
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      ),
                      onSubmitted: (text) => _sendMessage(text),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(_messageController.text),
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

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['role'] == 'user';
    final isLoading = message['content'] == 'Typing...';

    if (isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Icon(TablerIcons.headset, size: 16, color: AppTheme.primaryColor),
            ),
            SizedBox(width: 8.w),
            Text('Typing...', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Icon(TablerIcons.headset, size: 16, color: AppTheme.primaryColor),
            ),
          if (!isUser) SizedBox(width: 8.w),
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primaryColor : Colors.grey[100],
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                message['content'] ?? '',
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (isUser) SizedBox(width: 8.w),
          if (isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Icon(TablerIcons.user, size: 16, color: Colors.white),
            ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.help_outline),
              title: Text('FAQ'),
              onTap: () {
                Navigator.pop(context);
                context.push('/faq');
              },
            ),
            ListTile(
              leading: Icon(Icons.email_outlined),
              title: Text('Email Support'),
              onTap: () async {
                Navigator.pop(context);
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'support@risbow.com',
                );
                if (await canLaunchUrl(emailLaunchUri)) {
                  await launchUrl(emailLaunchUri);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.phone_outlined),
              title: Text('Call Support'),
              onTap: () async {
                Navigator.pop(context);
                final Uri phoneLaunchUri = Uri(
                  scheme: 'tel',
                  path: '+1234567890',
                );
                if (await canLaunchUrl(phoneLaunchUri)) {
                  await launchUrl(phoneLaunchUri);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.close),
              title: Text('End Chat'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}