import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:ofoq_student_app/features/home/data/models/course_model.dart';
import 'package:ofoq_student_app/core/utils/content_protection.dart';
import 'package:ofoq_student_app/features/home/presentation/widgets/lesson_players/watermark_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class LessonLivePlayer extends StatefulWidget {
  final LessonModel lesson;
  final VoidCallback onClose;
  final String studentName;
  final String? studentPhone;

  const LessonLivePlayer({
    super.key,
    required this.lesson,
    required this.onClose,
    required this.studentName,
    this.studentPhone,
  });

  @override
  State<LessonLivePlayer> createState() => _LessonLivePlayerState();
}

class _LessonLivePlayerState extends State<LessonLivePlayer> {
  bool _isLoading = true;
  String? _error;
  WebSocket? _ws;
  RTCPeerConnection? _pc;
  final _remoteRenderer = RTCVideoRenderer();
  bool _isConnected = false;

  // ignore: unused_field
  Map<String, dynamic>? _sessionData;

  @override
  void initState() {
    super.initState();
    _remoteRenderer.initialize();
    _joinLive();
    ContentProtection.enable();
  }

  Future<void> _joinLive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw 'غير مصرح لك بالدخول، يرجى تسجيل الدخول.';
      }

      final sessionId =
          widget.lesson.liveSessionId ?? widget.lesson.id.toString();

      // Simulated network call like React code behavior
      // A Real API call should be made pointing to /api/v1/live/join/$sessionId
      final response = await http
          .get(
            // Fallback for demo, assume standard local if base URL not available easily here
            Uri.parse('http://10.0.2.2:8000/api/v1/live/join/$sessionId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw 'انتهى وقت الاتصال بالخادم';
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _sessionData = data;
        await _connectWebRTC(data['websocket_url']);
      } else {
        final data = jsonDecode(response.body);
        throw data['error'] ?? 'فشل الانضمام للبث';
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _connectWebRTC(String wsUrl) async {
    try {
      _pc?.close();
      _ws?.close();

      String normalizedUrl = wsUrl;
      if (!wsUrl.startsWith('ws://') && !wsUrl.startsWith('wss://')) {
        normalizedUrl =
            'ws://10.0.2.2:8000$wsUrl'; // Adjust origin for emulator
      }

      _ws = await WebSocket.connect(normalizedUrl);

      _pc = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
      });

      _pc!.onIceConnectionState = (state) {
        if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          _reconnect(wsUrl);
        }
      };

      _pc!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
      _pc!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      _pc!.onTrack = (event) {
        if (event.track.kind == 'video') {
          _remoteRenderer.srcObject = event.streams[0];
          setState(() {
            _isConnected = true;
          });
        }
      };

      _pc!.onIceCandidate = (candidate) {
        if (candidate.candidate != null) {
          _ws!.add(
            jsonEncode({
              'event': 'candidate',
              'data': jsonEncode({
                'candidate': candidate.candidate,
                'sdpMid': candidate.sdpMid,
                'sdpMLineIndex': candidate.sdpMLineIndex,
              }),
            }),
          );
        }
      };

      _ws!.listen(
        (message) async {
          final msg = jsonDecode(message);
          if (msg['event'] == 'answer') {
            final answer = jsonDecode(msg['data']);
            await _pc!.setRemoteDescription(
              RTCSessionDescription(answer['sdp'], answer['type']),
            );
          } else if (msg['event'] == 'candidate') {
            final candidate = jsonDecode(msg['data']);
            await _pc!.addCandidate(
              RTCIceCandidate(
                candidate['candidate'],
                candidate['sdpMid'],
                candidate['sdpMLineIndex'],
              ),
            );
          } else if (msg['event'] == 'teacher_joined') {
            _reconnect(wsUrl);
          }
        },
        onDone: () => _pc?.close(),
        onError: (e) => print('WS Error: $e'),
      );

      final offer = await _pc!.createOffer();
      await _pc!.setLocalDescription(offer);

      _ws!.add(
        jsonEncode({
          'event': 'offer',
          'data': jsonEncode({'type': offer.type, 'sdp': offer.sdp}),
        }),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ في الاتصال: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _reconnect(String wsUrl) {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _connectWebRTC(wsUrl);
    });
  }

  @override
  void dispose() {
    _pc?.close();
    _ws?.close();
    _remoteRenderer.dispose();
    ContentProtection.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(children: [_buildHeader(), _buildBody()]),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1117),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.emergency_recording,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'بث مباشر: ${widget.lesson.title}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const Text(
                    'LIVE NOW',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white54),
              SizedBox(height: 16),
              Text(
                'جاري الاتصال بالبث...',
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'قد يكون البث قد انتهى أو وصلت القاعة للحد الأقصى',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          RTCVideoView(
            _remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
          ),
          if (!_isConnected)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Text(
                  'بانتظار المدرب لبدء البث...',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          WatermarkOverlay(
            studentName: widget.studentName,
            studentPhone: widget.studentPhone,
            animate: false,
          ),
          WatermarkOverlay(
            studentName: widget.studentName,
            studentPhone: widget.studentPhone,
            animate: true,
          ),
        ],
      ),
    );
  }
}
