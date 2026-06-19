import 'package:flutter/material.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/services/feature_settings_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/constant.dart';

class StoriesPage extends StatefulWidget {
  const StoriesPage({super.key});

  @override
  State<StoriesPage> createState() => _StoriesPageState();
}

class _StoriesPageState extends State<StoriesPage> {
  List<Map<String, dynamic>> _stories = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.storiesApi,
        {}
      );

      final data = response.data;
      if (data != null && data['success'] == true && data['data'] != null) {
        final transformed = _transformStories(data['data']);
        setState(() {
          _stories = transformed;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = data?['message'] ?? 'Failed to load stories';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
      debugPrint('Error loading stories: $e');
    }
  }

  List<Map<String, dynamic>> _transformStories(dynamic data) {
    if (data is List) {
      return data.map((s) => _mapStory(s)).toList();
    } else if (data is Map) {
      final list = data['stories'] ?? data['data'] ?? [];
      if (list is List) return list.map((s) => _mapStory(s)).toList();
    }
    return [];
  }

  Map<String, dynamic> _mapStory(dynamic s) {
    final items = (s['items'] ?? s['story_items'] ?? []).map((item) => ({
      'id': item['id'] ?? 0,
      'image': item['image'] ?? item['url'] ?? '',
      'views': item['views_count'] ?? item['views'] ?? 0,
      'type': item['type'] ?? 'image',
    })).toList();

    return {
      'id': s['id'] ?? 0,
      'user': {
        'name': s['user_name'] ?? s['seller_name'] ?? s['name'] ?? 'User',
        'avatar': s['user_avatar'] ?? s['seller_image'] ?? s['avatar'] ?? '',
      },
      'items': items,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureSettingsService.instance.storiesEnabled) {
      return Scaffold(
        appBar: AppBar(title: Text('Stories')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Stories feature is currently unavailable', 
                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              SizedBox(height: 8),
              Text('Please check back later', 
                  style: TextStyle(fontSize: 14, color: Colors.grey[400])),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_stories.isEmpty) {
      return _buildEmptyState();
    }

    return _buildContent();
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverFillRemaining(child: Center(child: CustomCircularProgressIndicator())),
      ],
    );
  }

  Widget _buildErrorState() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  SizedBox(height: 16.h),
                  Text('Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.h),
                  Text(_errorMessage ?? 'Unable to load stories', style: TextStyle(color: Colors.grey[600])),
                  SizedBox(height: 24.h),
                  ElevatedButton.icon(onPressed: _loadStories, icon: Icon(Icons.refresh), label: Text('Try Again')),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[300]),
                  SizedBox(height: 16.h),
                  Text('No stories available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.h),
                  Text('Check back later for new stories', style: TextStyle(color: Colors.grey[400])),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverPadding(
          padding: EdgeInsets.all(16.w),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildStoryCard(_stories[index], index),
              childCount: _stories.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120.h,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(top: 60.h, left: 16.w, right: 16.w),
            child: Row(
              children: [
                Icon(Icons.photo_library, color: Colors.white, size: 32),
                SizedBox(width: 8.w),
                Text('Stories', style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> story, int index) {
    final user = story['user'] as Map<String, dynamic>;
    final items = story['items'] as List;

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: user['avatar']?.isNotEmpty == true
                      ? CachedNetworkImageProvider(user['avatar'])
                      : null,
                  child: user['avatar']?.isNotEmpty != true
                      ? Text(user['name']?.substring(0, 1).toUpperCase() ?? 'U')
                      : null,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${items.length} stories', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
          SizedBox(
            height: 80.h,
            child: items.isEmpty
                ? Center(child: Text('No items'))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    itemCount: items.length,
                    itemBuilder: (context, itemIndex) {
                      final item = items[itemIndex];
                      return Container(
                        width: 60.w,
                        height: 60.h,
                        margin: EdgeInsets.only(right: 8.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          color: Colors.grey[200],
                        ),
                        child: item['image']?.isNotEmpty == true
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: CachedNetworkImage(
                                  imageUrl: item['image'],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(child: CustomCircularProgressIndicator()),
                                  errorWidget: (context, url, error) => Icon(Icons.image, color: Colors.grey),
                                ),
                              )
                            : Icon(Icons.image, color: Colors.grey),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}