class TenantLayoutModel {
  final String id;
  final String tenantSlug;
  final TenantTheme theme;
  final List<dynamic> pages;
  final List<RegisterField> registerFields;

  TenantLayoutModel({
    required this.id,
    required this.tenantSlug,
    required this.theme,
    required this.pages,
    required this.registerFields,
  });

  factory TenantLayoutModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return TenantLayoutModel(
      id: data['id'],
      tenantSlug: data['tenant_slug'],
      theme: TenantTheme.fromJson(data['theme']),
      pages: data['pages'] ?? [],
      registerFields: (data['register-fields'] as List? ?? [])
          .map((e) => RegisterField.fromJson(e))
          .toList(),
    );
  }
}

class TenantTheme {
  final String borderRadius;
  final String buttonStyle;
  final String coursesLayout;
  final int coursesPerRow;
  final String favicon;
  final String font;
  final String fontUrl;
  final String forceTheme;
  final String heroImage;
  final String loginBanner;
  final String logo;
  final String metaDescription;
  final String platformName;
  final String primaryColor;
  final String secondaryColor;
  final String shadowLevel;
  final Map<String, String> socialLinks;

  TenantTheme({
    required this.borderRadius,
    required this.buttonStyle,
    required this.coursesLayout,
    required this.coursesPerRow,
    required this.favicon,
    required this.font,
    required this.fontUrl,
    required this.forceTheme,
    required this.heroImage,
    required this.loginBanner,
    required this.logo,
    required this.metaDescription,
    required this.platformName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.shadowLevel,
    required this.socialLinks,
  });

  factory TenantTheme.fromJson(Map<String, dynamic> json) {
    return TenantTheme(
      borderRadius: json['borderRadius'],
      buttonStyle: json['buttonStyle'],
      coursesLayout: json['coursesLayout'],
      coursesPerRow: json['coursesPerRow'],
      favicon: json['favicon'],
      font: json['font'],
      fontUrl: json['fontUrl'],
      forceTheme: json['forceTheme'],
      heroImage: json['heroImage'],
      loginBanner: json['loginBanner'],
      logo: json['logo'],
      metaDescription: json['metaDescription'],
      platformName: json['platformName'],
      primaryColor: json['primary'],
      secondaryColor: json['secondary'],
      shadowLevel: json['shadowLevel'],
      socialLinks: Map<String, String>.from(json['socialLinks'] ?? {}),
    );
  }
}

class RegisterField {
  final String label;
  final String name;
  final bool required;
  final String type;
  final List<String>? options;

  RegisterField({
    required this.label,
    required this.name,
    required this.required,
    required this.type,
    this.options,
  });

  factory RegisterField.fromJson(Map<String, dynamic> json) {
    return RegisterField(
      label: json['label'],
      name: json['name'],
      required: json['required'] ?? false,
      type: json['type'],
      options: json['options'] != null
          ? (json['options'] as String).split(',')
          : null,
    );
  }
}
