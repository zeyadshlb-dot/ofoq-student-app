import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ofoq_student_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:ofoq_student_app/features/home/presentation/providers/layout_provider.dart';
import 'package:ofoq_student_app/features/home/data/models/tenant_layout_model.dart';
import 'package:ofoq_student_app/core/widgets/premium_widgets.dart';
import 'package:ofoq_student_app/core/api/api_provider.dart';
import 'package:ofoq_student_app/core/api/end_points.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:ofoq_student_app/features/home/presentation/screens/main_navigation_screen.dart';

final stagesProvider = FutureProvider<List<dynamic>>((ref) async {
  final layout = ref.watch(layoutProvider).value;
  if (layout == null) return [];

  final api = ref.read(apiConsumerProvider);
  final response = await api.get(
    EndPoints.stages,
    queryParameters: {'slug': layout.tenantSlug},
  );

  // Assuming the API returns a list or a map with 'data'
  if (response is List) return response;
  if (response is Map) return response['data'] ?? [];
  return [];
});

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  final Map<String, dynamic> _customData = {};
  final Map<String, TextEditingController> _controllers = {
    'name': TextEditingController(),
    'phone': TextEditingController(),
    'password': TextEditingController(),
  };

  final Map<String, XFile> _imageFiles = {};
  final Map<String, bool> _uploadingFields = {};
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<String?> _uploadToCloudinary(XFile file) async {
    try {
      final cloudinary = CloudinaryPublic(
        'dwsqpv4s6',
        's8z3f75e',
        cache: false,
      );
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(file.path, folder: 'ofoq-platform'),
      );
      return response.secureUrl;
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final layoutAsync = ref.watch(layoutProvider);
    final stagesAsync = ref.watch(stagesProvider);
    final authState = ref.watch(authProvider);
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen for auth state changes to navigate
    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    });

    return layoutAsync.when(
      data: (layout) => Scaffold(
        body: Row(
          children: [
            // Right Side: Image section for Desktop
            if (isDesktop)
              Expanded(
                flex: 42,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                            layout.theme.heroImage.isNotEmpty
                                ? layout.theme.heroImage
                                : 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?q=80&w=2071',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            colorScheme.primary.withOpacity(0.9),
                            colorScheme.primary.withOpacity(0.3),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 50,
                      left: 40,
                      right: 40,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (layout.theme.logo.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Image.network(
                                layout.theme.logo,
                                height: 60,
                              ),
                            ),
                          const SizedBox(height: 24),
                          Text(
                            'انضم لـ ${layout.theme.platformName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'أنشئ حسابك الآن واستمتع بمحاضرات حصرية وأفضل بيئة تعلم.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Left Side: Registration Form
            Expanded(
              flex: 58,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [const Color(0xFF12131E), const Color(0xFF1A1B2E)]
                        : [Colors.white, const Color(0xFFF8F9FD)],
                  ),
                ),
                child: Stack(
                  children: [
                    const FloatingParticles(),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 40,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'حساب جديد بانتظارك',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1A1B2E),
                                        letterSpacing: -0.5,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'أكمل البيانات التالية واشترك في منصتنا في خطوة واحدة',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.grey.shade500,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                    const SizedBox(height: 36),

                                    // Basic Fields
                                    AnimatedInput(
                                      icon: Icons.person_outline_rounded,
                                      label: 'الاسم بالكامل',
                                      controller: _controllers['name']!,
                                      hint: 'محمد أحمد محمود',
                                    ),
                                    const SizedBox(height: 16),

                                    Row(
                                      children: [
                                        // Stages Select
                                        Expanded(
                                          child: stagesAsync.when(
                                            data: (stages) =>
                                                _buildSelectionField(
                                                  'المرحلة الدراسية',
                                                  stages
                                                      .map(
                                                        (s) =>
                                                            s['name'] as String,
                                                      )
                                                      .toList(),
                                                  (val) {
                                                    final stage = stages
                                                        .firstWhere(
                                                          (s) =>
                                                              s['name'] == val,
                                                        );
                                                    _formData['stage_id'] =
                                                        stage['id'];
                                                  },
                                                ),
                                            loading: () => const Center(
                                              child: SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            ),
                                            error: (err, _) =>
                                                const Text('فشل تحميل المراحل'),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Phone Field
                                        Expanded(
                                          child: AnimatedInput(
                                            icon: Icons.phone_android_outlined,
                                            label: 'رقم الهاتف',
                                            controller: _controllers['phone']!,
                                            keyboardType: TextInputType.phone,
                                            hint: '01xxxxxxxxx',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 28),

                                    // Dynamic Fields from API
                                    if (layout.registerFields.isNotEmpty) ...[
                                      Row(
                                        children: [
                                          Container(
                                            width: 4,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: colorScheme.primary,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'بيانات إضافية',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF1A1B2E),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 14,
                                              mainAxisSpacing: 14,
                                              childAspectRatio: 2.2,
                                            ),
                                        itemCount: layout.registerFields.length,
                                        itemBuilder: (context, index) {
                                          final field =
                                              layout.registerFields[index];
                                          return _buildDynamicFieldWidget(
                                            field,
                                          );
                                        },
                                      ),
                                    ],

                                    const SizedBox(height: 28),
                                    AnimatedInput(
                                      icon: Icons.lock_outline_rounded,
                                      label: 'كلمة السر',
                                      controller: _controllers['password']!,
                                      isPassword: true,
                                      hint: '••••••••',
                                    ),
                                    const SizedBox(height: 36),

                                    SizedBox(
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed:
                                            authState.status ==
                                                AuthStatus.loading
                                            ? null
                                            : () {
                                                if (_formKey.currentState!
                                                    .validate()) {
                                                  _formData['name'] =
                                                      _controllers['name']!
                                                          .text;
                                                  _formData['phone'] =
                                                      _controllers['phone']!
                                                          .text;
                                                  _formData['password'] =
                                                      _controllers['password']!
                                                          .text;
                                                  _formData['tenant_slug'] =
                                                      layout.tenantSlug;
                                                  _formData['custom_data'] =
                                                      _customData;

                                                  ref
                                                      .read(
                                                        authProvider.notifier,
                                                      )
                                                      .register(_formData);
                                                }
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colorScheme.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child:
                                            authState.status ==
                                                AuthStatus.loading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.5,
                                                    ),
                                              )
                                            : const Text(
                                                'إنشاء الحساب الآن 🚀',
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                      ),
                                    ),

                                    const SizedBox(height: 20),
                                    Center(
                                      child: TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: TextButton.styleFrom(
                                          foregroundColor: colorScheme.primary,
                                        ),
                                        child: const Text(
                                          'تمتلك حساباً بالفعل؟ سجل دخولك من هنا',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildSelectionField(
    String label,
    List<String> options,
    Function(String) onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.grey.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.grey,
          ),
        ),
        dropdownColor: isDark ? const Color(0xFF222340) : Colors.white,
        items: options
            .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
            .toList(),
        onChanged: (val) {
          if (val != null) onChanged(val);
        },
        validator: (val) => val == null ? 'مطلوب' : null,
      ),
    );
  }

  Widget _buildDynamicFieldWidget(RegisterField field) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    if (field.type == 'select') {
      final options = field.options ?? <String>[];
      return _buildSelectionField(
        field.label,
        options,
        (val) => _customData[field.name] = val,
      );
    }

    if (field.type == 'image') {
      final isUploading = _uploadingFields[field.name] == true;

      return InkWell(
        onTap: isUploading
            ? null
            : () async {
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null) {
                  setState(() {
                    _imageFiles[field.name] = image;
                    _uploadingFields[field.name] = true;
                  });

                  // Upload to Cloudinary
                  final url = await _uploadToCloudinary(image);

                  setState(() {
                    _uploadingFields[field.name] = false;
                  });

                  if (url != null) {
                    _customData[field.name] = url;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم رفع الصورة بنجاح')),
                    );
                  } else {
                    setState(() {
                      _imageFiles.remove(field.name);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('فشل رفع الصورة')),
                    );
                  }
                }
              },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.grey.withOpacity(0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.image_outlined,
                  color: colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  field.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF1A1B2E),
                  ),
                ),
              ),
              if (isUploading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  ),
                )
              else if (_customData[field.name] != null)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 18,
                ),
            ],
          ),
        ),
      );
    }

    // Default text/number field
    final controller = TextEditingController();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.grey.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: TextFormField(
        controller: controller,
        onChanged: (val) => _customData[field.name] = val,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1A1B2E),
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: field.label,
          border: InputBorder.none,
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.grey,
          ),
        ),
        validator: field.required
            ? (val) => val == null || val.isEmpty ? 'مطلوب' : null
            : null,
      ),
    );
  }
}
