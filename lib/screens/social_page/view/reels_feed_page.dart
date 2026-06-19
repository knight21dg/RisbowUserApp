import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/screens/social_page/model/social_model.dart';
import 'package:hyper_local/screens/social_page/repo/social_repository.dart';

class ReelsFeedPage extends StatefulWidget {
  final List<ReelModel> reels;
  final int initialIndex;

  const ReelsFeedPage({super.key, required this.reels, this.initialIndex = 0});

  @override
  State<ReelsFeedPage> createState() => _ReelsFeedPageState();
}

class _ReelsFeedPageState extends State<ReelsFeedPage> {
  late PageController _pageController;
  final SocialRepository _repo = SocialRepository();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: widget.reels.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.video_library_outlined, size: 64, color: Colors.white54),
                  const SizedBox(height: 16),
                  const Text('No reels available yet', style: TextStyle(color: Colors.white70, fontSize: 18)),
                ],
              ),
            )
          : PageView.builder(
        scrollDirection: Axis.vertical,
        controller: _pageController,
        itemCount: widget.reels.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return ReelVideoPlayer(
            reel: widget.reels[index],
            isActive: _currentIndex == index,
            onLikeToggled: (liked) async {
              setState(() {
                widget.reels[index] = widget.reels[index].copyWith(
                  isLiked: liked,
                  likeCount: widget.reels[index].likeCount + (liked ? 1 : -1)
                );
              });
              try {
                await _repo.likeReel(widget.reels[index].id);
              } catch (_) {}
            },
          );
        },
      ),
    );
  }
}

class ReelVideoPlayer extends StatefulWidget {
  final ReelModel reel;
  final bool isActive;
  final Function(bool) onLikeToggled;

  const ReelVideoPlayer({
    super.key,
    required this.reel,
    required this.isActive,
    required this.onLikeToggled,
  });

  @override
  State<ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(ReelVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller?.play();
      _isPlaying = true;
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller?.pause();
      _isPlaying = false;
    }
  }

  Future<void> _initializeVideo() async {
    final url = widget.reel.videoUrl;
    if (url.isNotEmpty) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(url))
        ..setLooping(true)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _initialized = true;
            });
            if (widget.isActive) {
              _controller?.play();
            }
          }
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller == null) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  void _showCommentsBottomSheet(BuildContext context) {
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Comments (${widget.reel.commentCount})',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(color: Colors.grey, height: 1),
                  Expanded(
                    child: widget.reel.comments.isEmpty
                        ? const Center(
                            child: Text('No comments yet', style: TextStyle(color: Colors.grey)),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: widget.reel.comments.length,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemBuilder: (_, index) {
                              final comment = widget.reel.comments[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.grey,
                                      child: Icon(Icons.person, size: 18, color: Colors.white),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (comment.user is Map ? comment.user['name'] : null) ?? 'User',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            comment.comment,
                                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(color: Colors.grey, height: 1),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 8,
                      top: 8,
                      bottom: MediaQuery.of(ctx).viewInsets.bottom + 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle: const TextStyle(color: Colors.grey),
                              filled: true,
                              fillColor: Colors.grey[800],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.blueAccent),
                          onPressed: () {
                            final text = commentController.text.trim();
                            if (text.isNotEmpty) {
                              // TODO: Call API to post comment
                              commentController.clear();
                              Navigator.pop(ctx);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Player
          if (_initialized && _controller != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            )
          else if (widget.reel.thumbnailUrl != null)
            Image.network(widget.reel.thumbnailUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.black))
          else
            Container(color: Colors.black),

          // Play/Pause Overlay
          if (!_isPlaying)
            const Center(
              child: Icon(Icons.play_arrow, size: 80, color: Colors.white54),
            ),

          // Right Interaction Column
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Seller Profile
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.person, color: Colors.black),
                ),
                const SizedBox(height: 20),
                
                // Like Button
                IconButton(
                  icon: Icon(
                    widget.reel.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: widget.reel.isLiked ? Colors.red : Colors.white,
                    size: 36,
                  ),
                  onPressed: () => widget.onLikeToggled(!widget.reel.isLiked),
                ),
                Text(
                  '${widget.reel.likeCount}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                // Comment Button
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 36),
                  onPressed: () => _showCommentsBottomSheet(context),
                ),
                Text(
                  '${widget.reel.commentCount}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Bottom Info Row
          Positioned(
            left: 16,
            bottom: 30,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.reel.seller != null)
                  Text(
                    '@${widget.reel.seller['name'] ?? 'Seller'}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                const SizedBox(height: 8),
                if (widget.reel.caption != null)
                  Text(
                    widget.reel.caption!,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (widget.reel.productId != null) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.shopping_bag, size: 16),
                    label: const Text('View Product'),
                    onPressed: () {
                      final product = widget.reel.product;
                      if (product is Map && product['slug'] != null) {
                        context.push('/product-detail?slug=${product['slug']}');
                      }
                    },
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
