import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ofoq_student_app/core/api/api_provider.dart';
import 'package:ofoq_student_app/core/api/end_points.dart';
import 'package:ofoq_student_app/features/home/data/models/tenant_layout_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

final layoutProvider = FutureProvider<TenantLayoutModel>((ref) async {
  final api = ref.watch(apiConsumerProvider);
  final slug = dotenv.env['TEACHER_SLUG'] ?? 'alwody';
  final prefs = await SharedPreferences.getInstance();
  const cacheKey = 'cached_layout_data';

  // 1. Try to load from cache first
  final cachedData = prefs.getString(cacheKey);
  if (cachedData != null) {
    try {
      print('📦 Loading Layout from Cache...');
      final decoded = jsonDecode(cachedData);
      // Return cached data but still trigger a background refresh
      return TenantLayoutModel.fromJson(decoded);
    } catch (e) {
      print('⚠️ Cache corrupted, ignoring.');
    }
  }

  // 2. Fetch from API
  try {
    print('📡 Fetching Fresh Layout from API for: $slug...');
    final response = await api.get(
      EndPoints.layout,
      queryParameters: {'slug': slug},
    );

    // Save to cache
    await prefs.setString(cacheKey, jsonEncode(response));
    print('✅ Layout Saved to Cache.');

    return TenantLayoutModel.fromJson(response as Map<String, dynamic>);
  } catch (e) {
    // If API fails and we have no cache, rethrow
    if (cachedData == null) rethrow;

    // If API fails but we have cache, we've already returned it above,
    // but in FutureProvider it might be better to return the model directly here if we reached this far.
    final decoded = jsonDecode(cachedData);
    return TenantLayoutModel.fromJson(decoded);
  }
});
