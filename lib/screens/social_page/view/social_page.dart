import 'package:flutter/material.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/screens/social_page/model/social_model.dart';
import 'package:hyper_local/screens/social_page/repo/social_repository.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import 'package:hyper_local/screens/social_page/view/reels_feed_page.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SocialRepository _repository = SocialRepository();
  List<StoryModel> _stories = [];
  List<ReelModel> _reels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stories = await _repository.getStories();
      final reels = await _repository.getReels();
      setState(() {
        _stories = stories;
        _reels = reels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: AppLocalizations.of(context)!.social,
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.stories),
              Tab(text: AppLocalizations.of(context)!.reels),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CustomCircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStoriesList(),
                      _buildReelsList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesList() {
    if (_stories.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.noStories),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _stories.length,
        itemBuilder: (context, index) {
          final story = _stories[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (story.mediaUrl.trim().isNotEmpty)
                  CustomImageContainer(
                    imagePath: story.mediaUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    fallbackAsset: 'assets/images/placeholder.png',
                    errorWidget: Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.image, size: 50)),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (story.caption != null)
                        Text(story.caption!, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.visibility, size: 16),
                          const SizedBox(width: 4),
                          Text('${story.viewCount} views'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReelsList() {
    if (_reels.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.noReels),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reels.length,
        itemBuilder: (context, index) {
          final reel = _reels[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReelsFeedPage(
                    reels: _reels,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((reel.thumbnailUrl ?? '').trim().isNotEmpty)
                  Stack(
                    children: [
                      CustomImageContainer(
                        imagePath: reel.thumbnailUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        fallbackAsset: 'assets/images/placeholder.png',
                        errorWidget: Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.video_library, size: 50)),
                        ),
                      ),
                      const Positioned.fill(
                        child: Center(
                          child: Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (reel.caption != null)
                        Text(reel.caption!, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            reel.isLiked ? Icons.favorite : Icons.favorite_border,
                            color: reel.isLiked ? Colors.red : null,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text('${reel.likeCount}'),
                          const SizedBox(width: 16),
                          const Icon(Icons.comment, size: 20),
                          const SizedBox(width: 4),
                          Text('${reel.commentCount}'),
                          const SizedBox(width: 16),
                          const Icon(Icons.visibility, size: 20),
                          const SizedBox(width: 4),
                          Text('${reel.viewCount}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ));
        },
      ),
    );
  }
}
