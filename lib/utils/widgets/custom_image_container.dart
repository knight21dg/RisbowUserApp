import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local/config/constant.dart';

import 'cache_manager.dart';

class CustomImageContainer extends StatefulWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool? isForCategoryTab;
  final String? fallbackAsset;

  const CustomImageContainer({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.backgroundColor,
    this.placeholder,
    this.errorWidget,
    this.isForCategoryTab = false,
    this.fallbackAsset,
  });
  @override
  State<CustomImageContainer> createState() => _CustomImageContainerState();
}

class _CustomImageContainerState extends State<CustomImageContainer> {
  // In-memory cache of recently failed URLs to avoid hammering the server
  // with repeated requests for images that returned 404. Key -> timestamp.
  static final Map<String, DateTime> _failedUrlCache = {};
  static const Duration _failedCacheTtl = Duration(minutes: 5);

  String _formatImagePath(String path) {
    if (path.isEmpty) return '';
    final cleanPath = path.trim();
    if (cleanPath.isEmpty) return '';
    if (cleanPath.startsWith('assets/')) return cleanPath;

    // Allow both relative paths and absolute URLs to be resolved
    final resolved = resolveImageUrl(cleanPath);
    if (resolved != null && resolved.isNotEmpty) return resolved;
    return '';
  }

  bool _isNetworkImage(String path) {
    if (path.isEmpty) return false;
    return path.startsWith('http://') || path.startsWith('https://');
  }

  bool _isRecentlyFailed(String url) {
    if (url.isEmpty) return false;
    final t = _failedUrlCache[url];
    if (t == null) return false;
    if (DateTime.now().difference(t) > _failedCacheTtl) {
      _failedUrlCache.remove(url);
      return false;
    }
    return true;
  }

  void _markFailed(String url) {
    if (url.isEmpty) return;
    _failedUrlCache[url] = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final safeImagePath = _formatImagePath(widget.imagePath);

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: widget.borderRadius,
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: safeImagePath.isEmpty
            ? Image.asset(
                widget.fallbackAsset ?? 'assets/images/placeholder.png',
                width: widget.width,
                height: widget.height,
                fit: widget.fit,
                errorBuilder: (context, error, stackTrace) {
                  return widget.errorWidget ??
                      Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 100,
                        ),
                      );
                },
              )
            : (_isNetworkImage(safeImagePath) && !_isRecentlyFailed(safeImagePath))
                ? CachedNetworkImage(
                    imageUrl: safeImagePath,
                    cacheManager: customCacheManager,
                    width: widget.width,
                    height: widget.height,
                    fit: widget.fit,
                    filterQuality: FilterQuality.high,
                    fadeInDuration: const Duration(milliseconds: 100),
                    useOldImageOnUrlChange: true,
                    placeholder: (context, url) => widget.placeholder ?? Container(color: widget.backgroundColor),
                    errorWidget: (context, url, error) {
                      // Mark as failed to avoid immediate re-requests and show fallback
                      _markFailed(url ?? safeImagePath);
                      return widget.errorWidget ?? Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      );
                    },
                  )
                : Image.asset(
                    safeImagePath,
                    width: widget.width,
                    height: widget.height,
                    fit: widget.fit,
                    errorBuilder: (context, error, stackTrace) {
                      return widget.errorWidget ??
                          Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 100,
                            ),
                          );
                    },
                  ),
      ),
    );
  }
}
