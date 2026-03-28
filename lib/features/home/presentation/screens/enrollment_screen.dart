import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ofoq_student_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:ofoq_student_app/core/api/api_provider.dart';
import 'package:ofoq_student_app/core/api/end_points.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ofoq_student_app/core/utils/image_helper.dart';
import 'package:ofoq_student_app/features/home/data/models/course_model.dart';

class EnrollmentScreen extends ConsumerStatefulWidget {
  final CourseModel course;

  const EnrollmentScreen({super.key, required this.course});

  @override
  ConsumerState<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends ConsumerState<EnrollmentScreen> {
  bool _isEnrolling = false;

  Future<void> _enroll() async {
    setState(() => _isEnrolling = true);
    try {
      final api = ref.read(apiConsumerProvider);
      await api.post(
        EndPoints.courseEnroll,
        data: {'course_id': widget.course.id},
      );
      ref.refresh(authProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم الاشتراك بنجاح! 🎉')));
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isEnrolling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(authProvider).studentData;
    final balance = (student?['balance'] ?? 0).toDouble();
    final price = widget.course.price;
    final canEnroll = balance >= price;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF12131E)
          : const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'تأكيد الاشتراك',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1A1B2E) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1B2E),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Course Summary Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222340) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.withOpacity(0.06),
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: Image.network(
                      ImageHelper.getFullUrl(
                        widget.course.image ?? widget.course.fullImageUrl,
                      ),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary.withOpacity(0.3),
                              colorScheme.secondary.withOpacity(0.2),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.white.withOpacity(0.5),
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.course.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1B2E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          'سعر الكورس',
                          '${price.toInt()} جنية',
                          isDark,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          'رصيدك الحالي',
                          '${balance.toInt()} جنية',
                          isDark,
                          valueColor: canEnroll
                              ? const Color(0xFF10B981)
                              : Colors.red,
                        ),
                        const SizedBox(height: 10),
                        Divider(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.grey.withOpacity(0.1),
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          'المتبقي بعد الشراء',
                          '${(balance - price).toInt()} جنية',
                          isDark,
                          valueColor: canEnroll ? null : Colors.red,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (canEnroll)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isEnrolling ? null : _enroll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: _isEnrolling
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'تأكيد الاشتراك الآن 🎉',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              )
            else
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(isDark ? 0.1 : 0.05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.red.withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        const Text('⚠️', style: TextStyle(fontSize: 32)),
                        const SizedBox(height: 12),
                        Text(
                          'رصيدك الحالي غير كافي',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1B2E),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'تواصل مع المنصة لشحن رصيدك أو أضف كود شحن من المحفظة.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade600,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        const phone = '201032920099';
                        final msg =
                            'مرحباً، أنا ${student?['name']} واريد اشحن رصيدي لشراء كورس ${widget.course.title}';
                        final url = Uri.parse(
                          'https://wa.me/$phone?text=${Uri.encodeComponent(msg)}',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.chat_rounded),
                      label: const Text(
                        'تواصل عبر واتساب',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    bool isDark, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            fontSize: isBold ? 18 : 15,
            color:
                valueColor ?? (isDark ? Colors.white : const Color(0xFF1A1B2E)),
          ),
        ),
      ],
    );
  }
}
