class CourseModel {
  final int id;
  final String title;
  final String? description;
  final String? image;
  final String? fullImageUrl;
  final double price;
  final double? discountPrice;
  final String? pricingType;
  final List<ChapterModel>? chapters;
  final String? createdAt;
  final String? updatedAt;

  CourseModel({
    required this.id,
    required this.title,
    this.description,
    this.image,
    this.fullImageUrl,
    required this.price,
    this.discountPrice,
    this.pricingType,
    this.chapters,
    this.createdAt,
    this.updatedAt,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] is String ? int.parse(json['id']) : (json['id'] ?? 0),
      title: json['title'] ?? '',
      description: json['description'],
      image: json['image'],
      fullImageUrl: json['full_image_url'],
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      discountPrice: double.tryParse(json['discount_price']?.toString() ?? '0'),
      pricingType: json['pricing_type'],
      chapters: (json['chapters'] as List?)
          ?.map((e) => ChapterModel.fromJson(e))
          .toList(),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class ChapterModel {
  final int id;
  final String title;
  final List<LessonModel>? lessons;

  ChapterModel({required this.id, required this.title, this.lessons});

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      id: json['id'] is String ? int.parse(json['id']) : (json['id'] ?? 0),
      title: json['title'] ?? '',
      lessons: (json['lessons'] as List?)
          ?.map((e) => LessonModel.fromJson(e))
          .toList(),
    );
  }
}

class LessonModel {
  final int id;
  final String title;
  final String type;
  final String? videoUrl;
  final String? duration;
  final bool isFree;
  final int? examId;
  final String? pdfPath;
  final String? fullPdfUrl;
  final String? liveSessionId;
  final String? description;
  final int? videoDurationSeconds;

  LessonModel({
    required this.id,
    required this.title,
    required this.type,
    this.videoUrl,
    this.duration,
    required this.isFree,
    this.examId,
    this.pdfPath,
    this.fullPdfUrl,
    this.liveSessionId,
    this.description,
    this.videoDurationSeconds,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] is String ? int.parse(json['id']) : (json['id'] ?? 0),
      title: json['title'] ?? '',
      type: json['type'] ?? 'video',
      videoUrl: json['video_url'],
      duration: json['duration'],
      isFree:
          json['is_free'] == 1 ||
          json['is_free'] == true ||
          json['is_free'] == '1' ||
          json['is_free_preview'] == 1 ||
          json['is_free_preview'] == true,
      examId: json['exam_id'] != null
          ? int.tryParse(json['exam_id'].toString())
          : null,
      pdfPath: json['pdf_path'],
      fullPdfUrl: json['full_pdf_url'],
      liveSessionId: json['live_session_id']?.toString(),
      description: json['description'],
      videoDurationSeconds: json['video_duration_seconds'] != null
          ? int.tryParse(json['video_duration_seconds'].toString())
          : null,
    );
  }
}
