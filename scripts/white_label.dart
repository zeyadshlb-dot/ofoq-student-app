import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';

Future<void> main(List<String> arguments) async {
  print('🚀 Ofoq White-Label Engine Started...\n');

  // 1. تعريف الأوامر اللي السكريبت هيقبلها
  final parser = ArgParser()
    ..addOption('slug', abbr: 's', help: 'The tenant slug (e.g. elkemiawy)')
    ..addOption(
      'build',
      abbr: 'b',
      help: 'Choose build type',
      allowed: ['apk', 'aab', 'ipa', 'none'],
      defaultsTo: 'none',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show commands');

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    print('❌ Error parsing arguments: $e');
    print(parser.usage);
    exit(1);
  }

  // لو المستخدم طلب مساعدة أو مدخلش الـ slug
  if (argResults['help'] || argResults['slug'] == null) {
    print('🛠️ Usage: dart run scripts/build_tenant.dart [options]');
    print(parser.usage);
    exit(0);
  }

  final slug = argResults['slug'];
  final buildTarget = argResults['build'];

  print('📡 Fetching layout for slug: $slug...');
  // غير اللينك ده للـ Production لما ترفع السيرفر
  final url = 'https://unglowing-jovita-expectable.ngrok-free.dev/api/v1/tenants/layout?slug=$slug';

  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();

    if (response.statusCode != 200) {
      print('❌ Failed to fetch layout. Status: ${response.statusCode}');
      exit(1);
    }

    final responseBody = await response.transform(utf8.decoder).join();
    final jsonResponse = jsonDecode(responseBody);
    final data = jsonResponse['data'];
    final theme = data['theme'];
    final platformName = theme['platformName'];
    final logoUrl = theme['logo'];
    final packageName = 'com.ofoq.$slug';

    print('\n✅ Data Fetched Successfully:');
    print('   -------------------------');
    print('   App Name:    $platformName');
    print('   Package ID:  $packageName');
    print('   Build Type:  ${buildTarget.toUpperCase()}');
    print('   -------------------------\n');

    // 2. تحديث ملف الـ .env عشان التطبيق يقراه وقت التشغيل
    final envDir = Directory('assets');
    if (!envDir.existsSync()) envDir.createSync();
    File('assets/.env').writeAsStringSync('TEACHER_SLUG=$slug\n');
    print('📝 Saved slug to assets/.env');

    // 3. تحميل اللوجو
    print('📥 Downloading logo...');
    final logoRequest = await client.getUrl(Uri.parse(logoUrl));
    final logoResponse = await logoRequest.close();
    final logoBytes = await logoResponse.fold<List<int>>(
      [],
      (p, e) => p..addAll(e),
    );

    final logoDir = Directory('assets/images');
    if (!logoDir.existsSync()) logoDir.createSync(recursive: true);
    await File('assets/images/logo.png').writeAsBytes(logoBytes);
    print('✅ Logo saved.');

    // 4. تغيير الباكدج والاسم (استخدمنا dart run عشان أحدث وأسرع)
    print('🏷️ Updating Package Name and App Name...');
    await _runCommand('dart', [
      'run',
      'rename',
      'setBundleId',
      '--value',
      packageName,
    ]);
    await _runCommand('dart', [
      'run',
      'rename',
      'setAppName',
      '--value',
      platformName,
    ]);

    // 5. توليد الأيقونات
    print('🛠️ Generating Launcher Icons...');
    await _runCommand('dart', ['run', 'flutter_launcher_icons']);

    // 6. خطوة الـ Build الفعلي
    if (buildTarget != 'none') {
      print('\n⚙️ Starting Flutter Build for $buildTarget...');
      if (buildTarget == 'apk' || buildTarget == 'aab') {
        await _runCommand('flutter', ['build', buildTarget, '--release']);
      } else if (buildTarget == 'ipa') {
        // الـ IPA بيحتاج أجهزة ماك، الكوماند ده هيشتغل لو شغال على ماك أو في GitHub Actions Mac Runner
        await _runCommand('flutter', ['build', 'ipa', '--release']);
      }
      print('🎉 Build Completed! Check the build/app/outputs folder.');
    } else {
      print('\n✨ Setup completed! Ready for manual run (flutter run).');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}

Future<void> _runCommand(String command, List<String> args) async {
  final result = await Process.run(command, args);
  if (result.exitCode != 0) {
    print('⚠️ Notes for $command ${args.join(' ')}:');
    if (result.stderr.toString().isNotEmpty) print(result.stderr);
  } else {
    print('✅ Success: $command ${args.join(' ')}');
  }
}
