import 'package:ofoq_student_app/core/api/end_points.dart';

class ImageHelper {
  static String getFullUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?q=80&w=2071';
    }

    // If it's already a full URL (Cloudinary, etc.)
    if (path.startsWith('http')) return path;

    // Handle relative path (e.g. students/image.png or courses/image.png)
    final baseUrl = EndPoints.imageBaseUrl;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;

    return '$baseUrl$cleanPath';
  }
}
