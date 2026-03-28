import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ofoq_student_app/core/api/dio_consumer.dart';

final apiConsumerProvider = Provider<ApiConsumer>((ref) {
  final dio = Dio();
  return DioConsumer(dio);
});
