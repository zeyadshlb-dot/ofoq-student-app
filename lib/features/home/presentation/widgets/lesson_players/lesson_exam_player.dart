import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ofoq_student_app/features/home/data/models/course_model.dart';
import 'package:ofoq_student_app/core/api/api_provider.dart';
import 'package:ofoq_student_app/core/api/end_points.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ofoq_student_app/features/home/presentation/widgets/lesson_players/watermark_overlay.dart';

class LessonExamPlayer extends ConsumerStatefulWidget {
  final LessonModel lesson;
  final VoidCallback onClose;
  final String studentName;
  final String? studentPhone;

  const LessonExamPlayer({
    super.key,
    required this.lesson,
    required this.onClose,
    required this.studentName,
    this.studentPhone,
  });

  @override
  ConsumerState<LessonExamPlayer> createState() => _LessonExamPlayerState();
}

class _LessonExamPlayerState extends ConsumerState<LessonExamPlayer> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _exam;
  bool _started = false;
  Map<int, dynamic> _answers = {};
  bool _submitted = false;
  Map<String, dynamic>? _score;
  int? _timeLeft;
  Timer? _timer;
  dynamic _activeAttempt;
  List<dynamic>? _questions;

  @override
  void initState() {
    super.initState();
    _fetchExam();
  }

  Future<void> _fetchExam() async {
    if (widget.lesson.examId == null) {
      setState(() {
        _error = "لا يوجد امتحان مرتبط بهذا الدرس";
        _isLoading = false;
      });
      return;
    }

    try {
      final api = ref.read(apiConsumerProvider);
      final response = await api.get(
        "${EndPoints.exams}/${widget.lesson.examId}",
      );
      if (response is Map) {
        setState(() {
          _exam = response['data'] ?? response;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _startExam() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiConsumerProvider);
      final response = await api.post(
        "${EndPoints.exams}/start",
        data: {"exam_id": widget.lesson.examId},
      );
      if (response != null) {
        setState(() {
          _activeAttempt = response;
          _questions = response['questions'];
          _started = true;
          _timeLeft = response['remaining_seconds'];
          _isLoading = false;
        });
        _startTimer();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    if (_timeLeft == null || _timeLeft! <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft! <= 1) {
        _timer?.cancel();
        _submitExam();
      } else {
        setState(() => _timeLeft = _timeLeft! - 1);
      }
    });
  }

  Future<void> _saveAnswer(int questionId, dynamic answer) async {
    setState(() => _answers[questionId] = answer);
    try {
      final api = ref.read(apiConsumerProvider);
      await api.post(
        "${EndPoints.exams}/answer",
        data: {
          "attempt_id": _activeAttempt['attempt_id'],
          "question_id": questionId,
          "answer_text": answer is String ? answer : "",
          "answer_json": answer is! String ? answer : null,
        },
      );
    } catch (e) {
      debugPrint("Failed to save answer: $e");
    }
  }

  Future<void> _submitExam() async {
    setState(() => _isLoading = true);
    _timer?.cancel();
    try {
      final api = ref.read(apiConsumerProvider);
      final response = await api.post(
        "${EndPoints.exams}/submit",
        data: {"attempt_id": _activeAttempt['attempt_id']},
      );
      if (response != null) {
        setState(() {
          _score = response;
          _submitted = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(children: [_buildHeader(), _buildBody()]),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _exam?['title'] ?? widget.lesson.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          if (_started && !_submitted && _timeLeft != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatTime(_timeLeft!),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(40.0),
        child: Center(
          child: Text('❌ $_error', style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_submitted) {
      return _buildResults();
    }

    if (!_started) {
      return _buildIntro();
    }

    return _buildQuestions();
  }

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const Text(
            "📋 تعليمات الامتحان",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            _exam?['description'] ?? "امتحان تقييمي لمستوى استيعاب الدرس.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _infoTile("${_exam?['questions_count'] ?? 0} سؤال", Icons.quiz),
              const SizedBox(width: 8),
              _infoTile(
                "${_exam?['duration_minutes'] ?? 0} دقيقة",
                Icons.timer,
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startExam,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "🚀 ابدأ الامتحان الآن",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.purple),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestions() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 500),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _questions?.length ?? 0,
        itemBuilder: (context, index) {
          final q = _questions![index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        q['question_text'] ?? "",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...(q['options'] as List).map((opt) {
                  final isSelected = _answers[q['id']] == opt['id'];
                  return InkWell(
                    onTap: () => _saveAnswer(q['id'], opt['id']),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.purple[50] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.purple : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSelected ? Colors.purple : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(opt['text'] ?? "")),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResults() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green, width: 4),
              color: Colors.green[50],
            ),
            child: Center(
              child: Text(
                "${_score?['percentage']}%",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _score?['passed'] == true ? "🎉 مبروك! نجحت!" : "😔 حاول مرة أخرى",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "حصلت على ${_score?['score']} من ${_score?['total_points']} درجة",
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onClose,
              child: const Text("إغلاق"),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }
}
