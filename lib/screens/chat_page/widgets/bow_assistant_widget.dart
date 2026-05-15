import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/screens/chat_page/bloc/bow/bow_bloc.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/chat_page/model/bow_model.dart';
import 'package:image_picker/image_picker.dart';

class BowAssistantWidget extends StatefulWidget {
  const BowAssistantWidget({super.key});

  @override
  State<BowAssistantWidget> createState() => _BowAssistantWidgetState();
}

class _BowAssistantWidgetState extends State<BowAssistantWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isExpanded = false;
  double _dragStartY = 0;
  double _currentHeight = 0;
  bool _isListening = false;
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      context.read<BowBloc>().add(BowSendMessage(message: message));
      _messageController.clear();
    }
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
    });
    if (_isListening) {
      context.read<BowBloc>().add(BowSpeechToText(audioPath: ''));
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
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    }
  }

  void _sendMessageWithImage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty || _selectedImage != null) {
      context.read<BowBloc>().add(BowSendMessage(
        message: message.isNotEmpty ? message : 'What is this?',
        imageUrl: _selectedImage?.path,
      ));
      _messageController.clear();
      setState(() {
        _selectedImage = null;
      });
    }
  }

  Widget _buildBotIcon({double size = 32, Color? color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Image.asset(
        'assets/images/icons/bot.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          TablerIcons.robot,
          size: size * 0.6,
          color: AppColors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BowBloc, BowState>(
      builder: (context, state) {
        if (state is BowLoading) {
          return _buildLoading(context);
        } else if (state is BowReady) {
          return _buildContent(context, state);
        } else if (state is BowError) {
          return _buildError(context, state.message);
        }
        return _buildLoading(context);
      },
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 24.h),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          _buildBotIcon(size: 64.w),
          SizedBox(height: 16.h),
          Text(
            'BOW Assistant',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            'Initializing your AI helper...',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 32.h),
          CircularProgressIndicator(),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(TablerIcons.alert_circle, color: Colors.red, size: 48),
          SizedBox(height: 16.h),
          Text('Something went wrong', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => context.read<BowBloc>().add(BowInitialize()),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, BowReady state) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = _isExpanded ? screenHeight * 0.95 : screenHeight * 0.55;
    final minHeight = screenHeight * 0.25;
    
    return GestureDetector(
      onVerticalDragStart: (details) {
        _dragStartY = details.globalPosition.dy;
        _currentHeight = maxHeight;
      },
      onVerticalDragUpdate: (details) {
        final delta = _dragStartY - details.globalPosition.dy;
        final newHeight = (_currentHeight + delta).clamp(minHeight, screenHeight * 0.95);
        if (newHeight > screenHeight * 0.65) {
          if (!_isExpanded) {
            setState(() {
              _isExpanded = true;
            });
          }
        } else {
          if (_isExpanded) {
            setState(() {
              _isExpanded = false;
            });
          }
        }
      },
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          minHeight: minHeight,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            GestureDetector(
              onVerticalDragUpdate: (details) {
                final delta = _dragStartY - details.globalPosition.dy;
                if (delta > 60 && !_isExpanded) {
                  Navigator.pop(context);
                  context.push('/chat');
                }
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Column(
                  children: [
                    Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  _buildBotIcon(size: 40.w),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BOW AI Assistant', 
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                        Text(_isListening ? 'Listening...' : 'Always here to help', 
                          style: TextStyle(fontSize: 12.sp, color: _isListening ? AppTheme.primaryColor : Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(TablerIcons.arrow_up_right),
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/chat');
                    },
                    tooltip: 'Full Chat',
                  ),
                  IconButton(
                    icon: const Icon(TablerIcons.x),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1.h, color: Colors.grey.shade200),
            Flexible(
              child: BlocListener<BowBloc, BowState>(
                  listener: (context, state) {
                    if (state is BowReady) {
                      // Check for navigation actions in messages
                      if (state.messages.isNotEmpty) {
                        final lastMsg = state.messages.last;
                        if (lastMsg.role == 'assistant' && lastMsg.action?.type == 'navigate') {
                          final path = lastMsg.action?.data?['path']?.toString();
                          if (path != null && path.isNotEmpty) {
                            print('[BOW_MOBILE] UI Navigating to: $path');
                            Navigator.pop(context); // Close the assistant sheet
                            if (path == '/rooms' || path == 'rooms') {
                              context.push('/rooms'); // GroupBuyHomePage
                            } else {
                              context.push(path);
                            }
                            return;
                          }
                        }
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                    }
                  },
                child: ListView(
                  controller: _scrollController,
                  padding: EdgeInsets.all(20.w),
                  shrinkWrap: true,
                  children: [
                    if (state.messages.isEmpty) ...[
                      Text(
                        'Try asking me something like:',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: state.suggestions.map((s) => ActionChip(
                          avatar: Text(s.icon),
                          label: Text(s.text),
                          onPressed: () => context.read<BowBloc>().add(BowSendSuggestion(suggestion: s)),
                          backgroundColor: Colors.grey[50],
                          side: BorderSide(color: Colors.grey[200]!),
                        )).toList(),
                      ),
                    ] else ...[
                      ...state.messages.map((msg) {
                        final isLoading = msg.id == 'loading';
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: msg.role == 'user' ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              if (msg.role == 'assistant')
                                Padding(
                                  padding: EdgeInsets.only(right: 8.w, top: 4.h),
                                  child: _buildBotIcon(size: 20.w),
                                ),
                              Flexible(
                                child: Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: msg.role == 'user' 
                                        ? AppTheme.primaryColor 
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(16.r),
                                      topRight: Radius.circular(16.r),
                                      bottomLeft: msg.role == 'user' ? Radius.circular(16.r) : Radius.circular(4.r),
                                      bottomRight: msg.role == 'user' ? Radius.circular(4.r) : Radius.circular(16.r),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                   child: isLoading
                                       ? SizedBox(
                                           width: 30.w,
                                           height: 16.h,
                                           child: Row(
                                             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                             children: List.generate(3, (i) => Container(
                                               width: 4.w,
                                               height: 4.w,
                                               decoration: BoxDecoration(
                                                 color: Colors.grey[400],
                                                 shape: BoxShape.circle,
                                               ),
                                             )),
                                           ),
                                         )
                                       : (() {
                                           final related = _filterProductsForMessage(msg);
                                           return Column(
                                             crossAxisAlignment: CrossAxisAlignment.start,
                                             mainAxisSize: MainAxisSize.min,
                                             children: [
                                               Text(
                                                 msg.content,
                                                 style: TextStyle(
                                                   color: msg.role == 'user' ? Colors.white : Colors.black87,
                                                   fontSize: 14.sp,
                                                 ),
                                               ),
                                               if (related.isNotEmpty) ...[
                                                 SizedBox(height: 12.h),
                                                 ConstrainedBox(
                                                   constraints: BoxConstraints(maxHeight: 180.h),
                                                   child: ListView.builder(
                                                     shrinkWrap: true,
                                                     scrollDirection: Axis.horizontal,
                                                     itemCount: related.length,
                                                     itemBuilder: (context, index) {
                                                       final product = related[index];
                                                       return _buildProductCard(product, context);
                                                     },
                                                   ),
                                                 ),
                                               ],
                                             ],
                                           );
                                         })(),
                                ),
                              ),
                              if (msg.role == 'user')
                                Padding(
                                  padding: EdgeInsets.only(left: 8.w, top: 4.h),
                                  child: Container(
                                    width: 20.w,
                                    height: 20.w,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(TablerIcons.user, size: 12.w, color: AppColors.white),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                    if (state.error != null)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Text(state.error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h + MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedImage != null) ...[
                    Container(
                      height: 60.h,
                      margin: EdgeInsets.only(bottom: 8.h),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Image.file(
                              File(_selectedImage!.path),
                              height: 60.h,
                              width: 60.w,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImage = null),
                              child: Container(
                                padding: EdgeInsets.all(2.w),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close, size: 14.w, color: Colors.white),
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
                          color: _isListening ? Colors.red : Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening ? AppColors.white : Colors.grey[600],
                          ),
                          onPressed: _toggleListening,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.image,
                            color: Colors.grey[600],
                          ),
                          onPressed: _pickImage,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Ask BOW anything...',
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.r),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                          ),
                          onSubmitted: (_) => _sendMessageWithImage(),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(TablerIcons.send, color: AppColors.white),
                          onPressed: _sendMessageWithImage,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BowProduct product, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (product.slug.isNotEmpty) {
          GoRouter.of(context).push('/product-detail?slug=${product.slug}');
        } else if (product.id > 0) {
          GoRouter.of(context).push('/product-detail?id=${product.id}');
        }
      },
      child: Container(
        width: 120.w,
        margin: EdgeInsets.only(right: 8.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 120.w,
                  height: 90.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
                  ),
child: _buildProductImage(product.mainImage),
                ),
                if (product.discount != null && product.discount! > 0)
                  Positioned(
                    top: 4.w,
                    left: 4.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                      child: Text(
                        '-${product.discount}%',
                        style: TextStyle(fontSize: 8.sp, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(6.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w500, height: 1.2),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        if (product.price > 0)
                          Text(
                            '₹${product.price.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          )
                        else
                          Text(
                            'Free',
                            style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600, color: Colors.green),
                          ),
                        if (product.mrp != null && product.mrp! > product.price) ...[
                          SizedBox(width: 4.w),
                          Text(
                            '₹${product.mrp!.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 9.sp, color: Colors.grey, decoration: TextDecoration.lineThrough),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (product.rating != null && product.rating! > 0)
                          Row(
                            children: [
                              Icon(TablerIcons.star, size: 8.w, color: Colors.amber),
                              SizedBox(width: 2.w),
                              Text(
                                product.rating!.toStringAsFixed(1),
                                style: TextStyle(fontSize: 8.sp, color: Colors.grey[700]),
                              ),
                            ],
                          )
                        else
                          SizedBox(width: 1),
                        GestureDetector(
                          onTap: () => _addToCart(product, context),
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Icon(TablerIcons.plus, size: 12.w, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(BowProduct product, BuildContext context) {
    context.read<BowBloc>().add(BowExecuteAction(
      action: BowAction(
        type: 'add_to_cart',
        data: {
          'product_id': product.id,
          'product_slug': product.slug,
          'quantity': 1,
        },
      ),
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Adding ${product.title} to cart...'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    final lowerUrl = url.toLowerCase();
    return lowerUrl.startsWith('http://') || 
           lowerUrl.startsWith('https://') ||
           lowerUrl.startsWith('www.') ||
           lowerUrl.contains('.jpg') ||
           lowerUrl.contains('.jpeg') ||
           lowerUrl.contains('.png') ||
           lowerUrl.contains('.webp') ||
           lowerUrl.contains('.gif') ||
           lowerUrl.contains('.svg') ||
           lowerUrl.contains('storage') ||
           lowerUrl.contains('public/storage') ||
           lowerUrl.contains('api.risbow.com') ||
           lowerUrl.contains('cdn');
  }

  Widget _buildProductImage(String imageUrl) {
    // Resolve and normalize the image URL (handles relative paths and malformed values)
    final resolved = resolveImageUrl(imageUrl) ?? '';
    if (resolved.isEmpty) return _buildPlaceholderIcon();

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
      child: CustomImageContainer(
        imagePath: resolved,
        width: 120.w,
        height: 90.h,
        fit: BoxFit.cover,
        fallbackAsset: 'assets/images/placeholder.png',
        borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
      ),
    );
  }

  List<BowProduct> _filterProductsForMessage(BowMessage msg) {
    final products = msg.suggestedProducts ?? [];
    if (products.isEmpty) return [];

    final rawQuery = (msg.intent?.query ?? msg.content ?? '').toLowerCase().trim();
    
    // Deduplicate by product ID to avoid showing same product multiple times
    final uniqueProducts = <int, BowProduct>{};
    for (final p in products) {
      uniqueProducts[p.id] = p;
    }
    final deduped = uniqueProducts.values.toList();

    if (rawQuery.isEmpty) {
      return deduped;
    }

    final terms = rawQuery.split(RegExp(r'\s+')).where((t) => t.length > 1).toList();
    if (terms.isEmpty) return deduped;

    final filtered = deduped.where((p) {
      final hay = '${p.title} ${p.category ?? ''} ${p.slug} ${p.url ?? ''} ${p.mainImage}'.toLowerCase();
      return terms.any((t) => hay.contains(t));
    }).toList();

    // Fallback: if filtering removed everything, return deduped list
    if (filtered.isEmpty) return deduped;
    return filtered;
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(Icons.shopping_bag_outlined, color: Colors.grey[400], size: 30.w),
    );
  }
}

extension ListTakeLast<T> on List<T> {
  List<T> takeLast(int n) {
    if (length <= n) return this;
    return sublist(length - n);
  }
}
