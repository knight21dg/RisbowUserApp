import 'dart:async';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/notification_service.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import '../data/sdui_page_data.dart';
import '../model/sdui_schema.dart';
import 'sdui_renderer.dart';

class SduiSalesPage extends StatefulWidget {
  const SduiSalesPage({super.key});

  @override
  State<SduiSalesPage> createState() => _SduiSalesPageState();
}

class _SduiSalesPageState extends State<SduiSalesPage> {
  List<SduiNode>? _sections;
  bool _isLoading = true;
  String? _error;
  StreamSubscription<void>? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    _fetchSchema();
    _refreshSubscription = NotificationService.sduiUpdateStream.listen((_) {
      debugPrint('SDUI live reload triggered by FCM');
      _fetchSchema();
    });
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchSchema() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final schema = await _fetchFromApi();
      if (schema != null) {
        setState(() {
          _sections = schema;
          _isLoading = false;
        });
        return;
      }
      throw Exception('API returned no schema');
    } catch (e) {
      debugPrint('Failed to fetch SDUI schema from API: $e');
      await _fallbackToOffline(e);
    }
  }

  Future<List<SduiNode>?> _fetchFromApi() async {
    final response = await ApiBaseHelper().getAPICall(
      ApiRoutes.sduiSchemaApi,
      {},
    );
    final data = response.data;
    if (data['success'] == true && data['data']['schema'] != null) {
      final page = SduiPage.fromJson(
        data['data']['schema'] as Map<String, dynamic>,
      );
      return page.sections;
    }
    return null;
  }

  Future<void> _fallbackToOffline(dynamic error) async {
    try {
      final page = SduiPage.fromJson(
        jsonDecode(sduiPageData) as Map<String, dynamic>,
      );
      setState(() {
        _sections = page.sections;
        _isLoading = false;
        _error = 'Using offline schema (server unavailable)';
      });
    } catch (fallbackError) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load schema';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showAppBar: false,
      showViewCart: false,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomCircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading schema...'),
          ],
        ),
      );
    }

    if (_error != null && _sections == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchSchema,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSchema,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.orange.shade100,
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ...SduiRegistry.renderSections(_sections!, context),
          ],
        ),
      ),
    );
  }
}
