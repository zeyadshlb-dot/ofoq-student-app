import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ofoq_student_app/core/api/api_provider.dart';
import 'package:ofoq_student_app/core/api/end_points.dart';
import 'package:ofoq_student_app/features/home/presentation/providers/layout_provider.dart';
import 'package:ofoq_student_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:ofoq_student_app/features/home/data/models/course_model.dart';

final courseDetailsProvider = FutureProvider.family<CourseModel?, int>((
  ref,
  courseId,
) async {
  final api = ref.read(apiConsumerProvider);
  final response = await api.get("${EndPoints.courses}/$courseId");
  if (response is Map) {
    return CourseModel.fromJson(response['data'] ?? response);
  }
  return null;
});

final coursesProvider = FutureProvider<List<dynamic>>((ref) async {
  final layout = ref.watch(layoutProvider).value;
  final authState = ref.watch(authProvider);
  if (layout == null) return [];

  final api = ref.read(apiConsumerProvider);

  final queryParams = <String, dynamic>{'slug': layout.tenantSlug};

  if (authState.studentData != null &&
      authState.studentData!['educational_stage_id'] != null) {
    queryParams['educational_stage_id'] = authState
        .studentData!['educational_stage_id']
        .toString();
  }

  final response = await api.get(
    EndPoints.courses,
    queryParameters: queryParams,
  );

  if (response is Map) return response['data'] ?? [];
  if (response is List) return response;
  return [];
});

final progressProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiConsumerProvider);
  final response = await api.get(EndPoints.lessonsProgress);
  if (response is Map) return response['data'] ?? [];
  if (response is List) return response;
  return [];
});

final availableExamsProvider = FutureProvider<List<dynamic>>((ref) async {
  final layout = ref.watch(layoutProvider).value;
  if (layout == null) return [];

  final api = ref.read(apiConsumerProvider);
  final response = await api.get(
    EndPoints.exams,
    queryParameters: {'slug': layout.tenantSlug},
  );

  if (response is Map) return response['data'] ?? [];
  if (response is List) return response;
  return [];
});

final examHistoryProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiConsumerProvider);
  final response = await api.get(EndPoints.examsAttempts);

  if (response is Map) return response['data'] ?? [];
  if (response is List) return response;
  return [];
});

final assignmentsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiConsumerProvider);
  final response = await api.get(EndPoints.assignments);

  if (response is Map) return response['data'] ?? [];
  if (response is List) return response;
  return [];
});

final leaderboardProvider = FutureProvider<List<dynamic>>((ref) async {
  final layout = ref.watch(layoutProvider).value;
  if (layout == null) return [];

  final api = ref.read(apiConsumerProvider);
  final response = await api.get(
    EndPoints.leaderboard,
    queryParameters: {'slug': layout.tenantSlug},
  );

  if (response is Map) return response['data'] ?? [];
  if (response is List) return response;
  return [];
});

class ActiveTabNotifier extends Notifier<String> {
  @override
  String build() => 'courses';

  void setTab(String tab) {
    state = tab;
  }
}

final activeTabProvider = NotifierProvider<ActiveTabNotifier, String>(() {
  return ActiveTabNotifier();
});
