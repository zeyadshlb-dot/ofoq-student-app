import 'dart:convert';

class DownloadedLessonModel {
  final int lessonId;
  final String lessonTitle;
  final int courseId;
  final String courseTitle;
  final String? courseImage;
  final String localPath;
  final int fileSizeBytes;
  final DateTime downloadedAt;
  final String originalUrl;

  DownloadedLessonModel({
    required this.lessonId,
    required this.lessonTitle,
    required this.courseId,
    required this.courseTitle,
    this.courseImage,
    required this.localPath,
    required this.fileSizeBytes,
    required this.downloadedAt,
    required this.originalUrl,
  });

  Map<String, dynamic> toJson() => {
    'lessonId': lessonId,
    'lessonTitle': lessonTitle,
    'courseId': courseId,
    'courseTitle': courseTitle,
    'courseImage': courseImage,
    'localPath': localPath,
    'fileSizeBytes': fileSizeBytes,
    'downloadedAt': downloadedAt.toIso8601String(),
    'originalUrl': originalUrl,
  };

  factory DownloadedLessonModel.fromJson(Map<String, dynamic> json) =>
      DownloadedLessonModel(
        lessonId: json['lessonId'],
        lessonTitle: json['lessonTitle'],
        courseId: json['courseId'],
        courseTitle: json['courseTitle'],
        courseImage: json['courseImage'],
        localPath: json['localPath'],
        fileSizeBytes: json['fileSizeBytes'] ?? 0,
        downloadedAt: DateTime.parse(json['downloadedAt']),
        originalUrl: json['originalUrl'] ?? '',
      );

  static List<DownloadedLessonModel> listFromJson(String jsonString) {
    final List<dynamic> decoded = json.decode(jsonString);
    return decoded
        .map((e) => DownloadedLessonModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<DownloadedLessonModel> list) {
    return json.encode(list.map((e) => e.toJson()).toList());
  }

  String get fileSizeFormatted {
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
