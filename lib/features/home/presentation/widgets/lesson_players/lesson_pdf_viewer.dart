import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:ofoq_student_app/features/home/data/models/course_model.dart';
import 'package:ofoq_student_app/core/utils/content_protection.dart';
import 'package:ofoq_student_app/features/home/presentation/widgets/lesson_players/watermark_overlay.dart';
import 'package:ofoq_student_app/core/api/end_points.dart';
import 'dart:math';

class DrawingItem {
  final String type; // 'path', 'shape', 'text'
  final String
  tool; // 'pen', 'highlighter', 'eraser', 'rect', 'circle', 'arrow'
  final List<Offset>? points;
  final Offset? start;
  final Offset? end;
  final String? text;
  final Color color;
  final double width;
  final double? fontSize;

  DrawingItem({
    required this.type,
    required this.tool,
    this.points,
    this.start,
    this.end,
    this.text,
    required this.color,
    required this.width,
    this.fontSize,
  });
}

class LessonPDFViewer extends StatefulWidget {
  final LessonModel lesson;
  final VoidCallback onClose;
  final String studentName;
  final String? studentPhone;

  const LessonPDFViewer({
    super.key,
    required this.lesson,
    required this.onClose,
    required this.studentName,
    this.studentPhone,
  });

  @override
  State<LessonPDFViewer> createState() => _LessonPDFViewerState();
}

class _LessonPDFViewerState extends State<LessonPDFViewer> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isLoading = true;
  String? _error;
  int _numPages = 0;
  int _currentPage = 1;

  bool _showToolbar = false;
  String?
  _activeTool; // null (pan), 'pen', 'highlighter', 'text', 'rect', 'circle', 'arrow', 'eraser'
  Color _drawColor = Colors.red;
  double _drawWidth = 3.0;

  Map<int, List<DrawingItem>> _history = {};
  Map<int, List<DrawingItem>> _undoStack = {};

  bool _isDrawing = false;
  List<Offset> _currentPath = [];
  Offset? _startPoint;

  Offset? _textInputPos;
  final TextEditingController _textController = TextEditingController();

  final List<Color> _colors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.black,
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    ContentProtection.enable();
  }

  @override
  void dispose() {
    ContentProtection.disable();
    _pdfViewerController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _addHistoryItem(DrawingItem item) {
    setState(() {
      final items = _history[_currentPage] ?? [];
      _history[_currentPage] = [...items, item];
      _undoStack[_currentPage] = [];
    });
  }

  void _handleUndo() {
    final items = _history[_currentPage] ?? [];
    if (items.isEmpty) return;
    setState(() {
      final last = items.last;
      _history[_currentPage] = items.sublist(0, items.length - 1);
      final undoneItems = _undoStack[_currentPage] ?? [];
      _undoStack[_currentPage] = [...undoneItems, last];
    });
  }

  void _handleRedo() {
    final redoItems = _undoStack[_currentPage] ?? [];
    if (redoItems.isEmpty) return;
    setState(() {
      final last = redoItems.last;
      _undoStack[_currentPage] = redoItems.sublist(0, redoItems.length - 1);
      final items = _history[_currentPage] ?? [];
      _history[_currentPage] = [...items, last];
    });
  }

  void _handleClearPage() {
    setState(() {
      _history[_currentPage] = [];
      _undoStack[_currentPage] = [];
    });
  }

  void _handlePanStart(DragStartDetails details) {
    if (_activeTool == null) return;

    if (_activeTool == 'text') {
      setState(() {
        _textInputPos = details.localPosition;
        _textController.clear();
      });
      return;
    }

    setState(() {
      _isDrawing = true;
      _startPoint = details.localPosition;
      _currentPath = [details.localPosition];
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isDrawing || _activeTool == null) return;
    setState(() {
      _currentPath.add(details.localPosition);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!_isDrawing || _activeTool == null) return;
    setState(() {
      _isDrawing = false;

      if (_activeTool == 'eraser') {
        final items = List<DrawingItem>.from(_history[_currentPage] ?? []);
        items.removeWhere((item) {
          if (item.type == 'path' && item.points != null) {
            return item.points!.any(
              (pt) => _currentPath.any((ep) => (pt - ep).distance < 20),
            );
          }
          if (item.type == 'text' && item.start != null) {
            return _currentPath.any((ep) => (item.start! - ep).distance < 30);
          }
          return false;
        });
        _history[_currentPage] = items;
      } else if (['pen', 'highlighter'].contains(_activeTool)) {
        _addHistoryItem(
          DrawingItem(
            type: 'path',
            tool: _activeTool!,
            points: List.from(_currentPath),
            color: _activeTool == 'highlighter'
                ? _drawColor.withOpacity(0.4)
                : _drawColor,
            width: _activeTool == 'highlighter' ? _drawWidth * 4 : _drawWidth,
          ),
        );
      } else if (['rect', 'circle', 'arrow'].contains(_activeTool) &&
          _startPoint != null) {
        final endPoint = _currentPath.isNotEmpty
            ? _currentPath.last
            : _startPoint!;
        _addHistoryItem(
          DrawingItem(
            type: 'shape',
            tool: _activeTool!,
            start: _startPoint,
            end: endPoint,
            color: _drawColor,
            width: _drawWidth,
          ),
        );
      }

      _currentPath = [];
      _startPoint = null;
    });
  }

  void _submitText() {
    if (_textInputPos != null && _textController.text.trim().isNotEmpty) {
      _addHistoryItem(
        DrawingItem(
          type: 'text',
          tool: 'text',
          start: _textInputPos,
          text: _textController.text.trim(),
          color: _drawColor,
          width: _drawWidth,
          fontSize: 16.0 * _pdfViewerController.zoomLevel,
        ),
      );
    }
    setState(() {
      _textInputPos = null;
    });
  }

  Widget _buildToolbar() {
    if (!_showToolbar) return const SizedBox.shrink();

    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'الأدوات: ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                _toolBtn('pen', '✏️', 'قلم'),
                _toolBtn('highlighter', '🖍️', 'تخطيط'),
                _toolBtn('text', '📝', 'نص'),
                _toolBtn('rect', '⬜', 'مستطيل'),
                _toolBtn('circle', '⭕', 'دائرة'),
                _toolBtn('arrow', '➡️', 'سهم'),
                _toolBtn('eraser', '🧹', 'ممحاة'),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                InkWell(
                  onTap: () => setState(() => _activeTool = null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _activeTool == null ? Colors.blue : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      '👆 تصفح',
                      style: TextStyle(
                        color: _activeTool == null
                            ? Colors.white
                            : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'الألوان: ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                ..._colors.map(
                  (c) => GestureDetector(
                    onTap: () => setState(() => _drawColor = c),
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _drawColor == c
                              ? Colors.green
                              : Colors.grey[300]!,
                          width: _drawColor == c ? 2 : 1,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                SizedBox(
                  width: 100,
                  child: Slider(
                    value: _drawWidth,
                    min: 1,
                    max: 10,
                    activeColor: Colors.green,
                    onChanged: (v) => setState(() => _drawWidth = v),
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                IconButton(
                  icon: const Icon(Icons.undo, size: 20),
                  onPressed: _history[_currentPage]?.isNotEmpty == true
                      ? _handleUndo
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.redo, size: 20),
                  onPressed: _undoStack[_currentPage]?.isNotEmpty == true
                      ? _handleRedo
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _handleClearPage,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Colors.red,
                  ),
                  label: const Text(
                    'مسح الكل',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolBtn(String id, String icon, String label) {
    final isActive = _activeTool == id;
    return InkWell(
      onTap: () => setState(() => _activeTool = id),
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.green : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 600,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF047857), Color(0xFF10B981)],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('📄', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lesson.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (_numPages > 0)
                          Text(
                            '🎁 عرض مجاني • $_numPages صفحة',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _showToolbar = !_showToolbar),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _showToolbar ? Colors.white : Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '🎨 أدوات الشرح',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _showToolbar
                              ? Colors.green[800]
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            _buildToolbar(),

            // PDF Body
            Expanded(
              child: Stack(
                children: [
                  SfPdfViewer.network(
                    () {
                      String url =
                          widget.lesson.fullPdfUrl ??
                          widget.lesson.pdfPath ??
                          '';
                      if (url.isEmpty) return '';

                      if (url.startsWith('http')) return url;

                      if (url.startsWith('/')) url = url.substring(1);

                      if (url.startsWith('public/storage/')) {
                        return '${EndPoints.imageBaseUrl}$url';
                      } else if (url.startsWith('storage/')) {
                        return '${EndPoints.imageBaseUrl}public/$url';
                      } else {
                        return '${EndPoints.imageBaseUrl}public/storage/$url';
                      }
                    }(),
                    key: _pdfViewerKey,
                    controller: _pdfViewerController,
                    canShowScrollHead: _activeTool == null,
                    interactionMode: _activeTool == null
                        ? PdfInteractionMode.pan
                        : PdfInteractionMode.selection,
                    onDocumentLoadFailed: (details) => setState(() {
                      _error = details.error;
                      _isLoading = false;
                    }),
                    onDocumentLoaded: (details) => setState(() {
                      _isLoading = false;
                      _numPages = details.document.pages.count;
                    }),
                    onPageChanged: (details) =>
                        setState(() => _currentPage = details.newPageNumber),
                  ),

                  if (_isLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (_error != null)
                    Center(
                      child: Text(
                        'خطأ في تحميل PDF: $_error',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  // Custom Drawing Overlay intercepting gestures when tool is active (Pan disabled mentally, gestures overridden)
                  if (_activeTool != null)
                    Positioned.fill(
                      child: GestureDetector(
                        onPanStart: _handlePanStart,
                        onPanUpdate: _handlePanUpdate,
                        onPanEnd: _handlePanEnd,
                        child: CustomPaint(
                          painter: CanvasDrawingPainter(
                            items: _history[_currentPage] ?? [],
                            currentPath: _currentPath,
                            activeTool: _activeTool,
                            drawColor: _drawColor,
                            drawWidth: _drawWidth,
                            startPoint: _startPoint,
                          ),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    ),

                  // Text Input Overlay
                  if (_textInputPos != null)
                    Positioned(
                      left: _textInputPos!.dx,
                      top: _textInputPos!.dy,
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 10),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 150,
                                child: TextField(
                                  controller: _textController,
                                  autofocus: true,
                                  style: TextStyle(
                                    color: _drawColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'اكتب هنا...',
                                  ),
                                  onSubmitted: (_) => _submitText(),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                ),
                                onPressed: _submitText,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.grey,
                                ),
                                onPressed: () =>
                                    setState(() => _textInputPos = null),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Watermarks
                  WatermarkOverlay(
                    studentName: widget.studentName,
                    studentPhone: widget.studentPhone,
                    animate: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CanvasDrawingPainter extends CustomPainter {
  final List<DrawingItem> items;
  final List<Offset> currentPath;
  final String? activeTool;
  final Color drawColor;
  final double drawWidth;
  final Offset? startPoint;

  CanvasDrawingPainter({
    required this.items,
    required this.currentPath,
    required this.activeTool,
    required this.drawColor,
    required this.drawWidth,
    required this.startPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var item in items) {
      if (item.type == 'path' &&
          item.points != null &&
          item.points!.isNotEmpty) {
        final paint = Paint()
          ..color = item.color
          ..strokeWidth = item.width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        final path = Path()
          ..moveTo(item.points!.first.dx, item.points!.first.dy);
        for (int i = 1; i < item.points!.length; i++) {
          path.lineTo(item.points![i].dx, item.points![i].dy);
        }
        canvas.drawPath(path, paint);
      } else if (item.type == 'shape' &&
          item.start != null &&
          item.end != null) {
        final paint = Paint()
          ..color = item.color
          ..strokeWidth = item.width
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        if (item.tool == 'rect') {
          canvas.drawRect(Rect.fromPoints(item.start!, item.end!), paint);
        } else if (item.tool == 'circle') {
          final rect = Rect.fromPoints(item.start!, item.end!);
          canvas.drawOval(rect, paint);
        } else if (item.tool == 'arrow') {
          _drawArrow(canvas, paint, item.start!, item.end!);
        }
      } else if (item.type == 'text' &&
          item.text != null &&
          item.start != null) {
        final textStyle = TextStyle(
          color: item.color,
          fontSize: item.fontSize ?? 16.0,
          fontWeight: FontWeight.bold,
        );
        final textSpan = TextSpan(text: item.text, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.rtl,
        );
        textPainter.layout();
        textPainter.paint(canvas, item.start!);
      }
    }

    // Draw active path
    if (activeTool != null && currentPath.isNotEmpty) {
      if (['pen', 'highlighter', 'eraser'].contains(activeTool)) {
        final paint = Paint()
          ..color = activeTool == 'highlighter'
              ? drawColor.withOpacity(0.4)
              : (activeTool == 'eraser' ? Colors.white : drawColor)
          ..strokeWidth = activeTool == 'highlighter'
              ? drawWidth * 4
              : (activeTool == 'eraser' ? 20.0 : drawWidth)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        final path = Path()..moveTo(currentPath.first.dx, currentPath.first.dy);
        for (int i = 1; i < currentPath.length; i++) {
          path.lineTo(currentPath[i].dx, currentPath[i].dy);
        }
        canvas.drawPath(path, paint);
      } else if (['rect', 'circle', 'arrow'].contains(activeTool) &&
          startPoint != null) {
        final paint = Paint()
          ..color = drawColor
          ..strokeWidth = drawWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        final endPoint = currentPath.last;
        if (activeTool == 'rect') {
          canvas.drawRect(Rect.fromPoints(startPoint!, endPoint), paint);
        } else if (activeTool == 'circle') {
          canvas.drawOval(Rect.fromPoints(startPoint!, endPoint), paint);
        } else if (activeTool == 'arrow') {
          _drawArrow(canvas, paint, startPoint!, endPoint);
        }
      }
    }
  }

  void _drawArrow(Canvas canvas, Paint paint, Offset start, Offset end) {
    canvas.drawLine(start, end, paint);
    final angle = atan2(end.dy - start.dy, end.dx - start.dx);
    final headLen = 15.0;
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - headLen * cos(angle - pi / 6),
        end.dy - headLen * sin(angle - pi / 6),
      )
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - headLen * cos(angle + pi / 6),
        end.dy - headLen * sin(angle + pi / 6),
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CanvasDrawingPainter oldDelegate) => true;
}
