import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/constant.dart';

class BannerMediaWidget extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final bool autoPlay;
  final bool muteVideos;

  const BannerMediaWidget({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.autoPlay = true,
    this.muteVideos = true,
  });

  @override
  State<BannerMediaWidget> createState() => _BannerMediaWidgetState();
}

class _BannerMediaWidgetState extends State<BannerMediaWidget> {
  VideoPlayerController? _controller;
  bool _isVideo = false;
  bool _isInitialized = false;
  bool _hasError = false;
  String _currentUrl = '';
  String? _resolvedUrlValue;

  String? get _resolvedUrl {
    if (_resolvedUrlValue != null) return _resolvedUrlValue;
    if (widget.url.isEmpty) return null;
    final resolved = resolveImageUrl(widget.url);
    _resolvedUrlValue = resolved?.isNotEmpty == true ? resolved : null;
    return _resolvedUrlValue;
  }

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    _resolvedUrlValue = null;
    _checkMediaType();
  }



  bool _isVideoUrl(String url) {
    if (url.isEmpty) return false;
    final lowerUrl = url.toLowerCase();
    final videoExtensions = ['.mp4', '.mov', '.m4v', '.webm', '.avi', '.mkv'];
    for (final ext in videoExtensions) {
      if (lowerUrl.contains(ext)) return true;
    }
    return false;
  }

  void _checkMediaType() {
    if (widget.url.isEmpty) {
      setState(() => _hasError = true);
      return;
    }
    
    final resolved = _resolvedUrl;
    if (resolved == null) {
      setState(() => _hasError = true);
      return;
    }
    
    if (_isVideoUrl(resolved)) {
      _isVideo = true;
      _initializeVideo();
    } else {
      _isVideo = false;
    }
  }

  Future<void> _initializeVideo() async {
    final videoUrl = _resolvedUrl;
    if (videoUrl == null) return;
    
    _controller?.dispose();
    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    
    try {
      await _controller!.initialize();
      await _controller!.setLooping(true);
      
      if (widget.muteVideos) {
        await _controller!.setVolume(0);
      }
      
      if (widget.autoPlay) {
        await _controller!.play();
      }
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Video init error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isVideo = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BannerMediaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url && widget.url != _currentUrl) {
      _currentUrl = widget.url;
      _controller?.dispose();
      _isInitialized = false;
      _hasError = false;
      _isVideo = false;
      _checkMediaType();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url.isEmpty || _hasError) {
      return _buildErrorPlaceholder();
    }

    if (_isVideo) {
      return _buildVideoPlayer();
    }

    return _buildNetworkImage();
  }

  Widget _buildVideoPlayer() {
    if (!_isInitialized) {
      return _buildShimmer();
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: widget.fit,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }

  Widget _buildNetworkImage() {
    final resolved = _resolvedUrl;
    if (resolved == null) {
      return _buildErrorPlaceholder();
    }
    return CachedNetworkImage(
      imageUrl: resolved,
      fit: widget.fit,
      filterQuality: FilterQuality.medium,
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 200),
      memCacheWidth: 800,
      memCacheHeight: 600,
      placeholder: (context, url) => _buildShimmer(),
      errorWidget: (context, url, error) => _buildErrorPlaceholder(),
      imageBuilder: (context, imageProvider) {
        return Image(
          image: imageProvider,
          fit: widget.fit,
          gaplessPlayback: true,
        );
      },
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[200],
      width: double.infinity,
      height: double.infinity,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey,
          size: 40,
        ),
      ),
    );
  }
}

class BannerCarouselItem extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final VoidCallback? onTap;
  final bool showVideo;
  final bool autoPlayVideo;
  final bool muteVideo;

  const BannerCarouselItem({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.onTap,
    this.showVideo = true,
    this.autoPlayVideo = true,
    this.muteVideo = true,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = _checkIsVideo(url);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: showVideo && isVideo
              ? BannerMediaWidget(
                  url: url,
                  fit: fit,
                  autoPlay: autoPlayVideo,
                  muteVideos: muteVideo,
                )
              : BannerMediaWidget(
                  url: url,
                  fit: fit,
                ),
        ),
      ),
    );
  }

  bool _checkIsVideo(String url) {
    if (url.isEmpty) return false;
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') || 
           lower.endsWith('.mov') || 
           lower.endsWith('.m4v') || 
           lower.endsWith('.webm');
  }
}