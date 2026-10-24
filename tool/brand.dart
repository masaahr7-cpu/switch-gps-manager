import 'dart:io';

const appName = 'Switch GPS Manager';
const packageId = 'com.switchmicrofinance.gps';
const version = '1.0.0+1';
const url = 'http://84.247.172.135:8082';
const iconPath = './icon.png';
const keystoreFilePath = 'android/android.keystore';
const keystoreAlias = 'key';
const keystorePassword = 'Switch@2024!';
const poweredBy = 'Powered by Masaa24 Networks';
const website = 'www.switchmicrofinance.co.tz';

Future<void> main() async {
  stdout.writeln('Branding to $appName - $poweredBy - $website');
  await _generateIcons(iconPath);
  await _updateTitle(appName);
  await _updatePackageId(packageId);
  await _updateVersion(version);
  await _updateUrl(url);
  await _updateBrandingStrings();
  await _createKeystore();
  stdout.writeln('SUCCESS: Branded to $appName - $poweredBy');
}

Future<void> _generateIcons(String icon) async {
  try {
    final dir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
  } catch (_) {}

  try {
    final f1 = File('android/app/src/main/res/drawable/ic_launcher_foreground.xml');
    if (await f1.exists()) await f1.delete();
  } catch (_) {}
  
  try {
    final f2 = File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml');
    if (await f2.exists()) await f2.delete();
  } catch (_) {}

  final f = await _writeTempYaml('flutter_launcher_icons.yaml', '''
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "$icon"
  remove_alpha_ios: true
  web:
    generate: true
''');
  
  try {
    // New command for flutter_launcher_icons 0.13.1+
    await _run('dart', ['run', 'flutter_launcher_icons', '-f', 'flutter_launcher_icons.yaml']);
  } catch (e) {
    // Fallback old command
    await _run('flutter', ['pub', 'run', 'flutter_launcher_icons']);
  }
  await f.delete();

  await _replaceInFile(
    'android/app/src/main/AndroidManifest.xml',
    RegExp(r'\s*<meta-data\s+android:name="com\.google\.firebase\.messaging\.default_notification_icon"[\s\S]*?/>', multiLine: true),
    '',
  );
}

Future<void> _updateTitle(String name) async {
  await _replaceInFile(
    'android/app/src/main/AndroidManifest.xml',
    RegExp(r'android:label="[^"]*"'),
    'android:label="$name"',
  );

  await _replaceInFile(
    'ios/Runner/Info.plist',
    RegExp(r'<key>CFBundleDisplayName</key>\s*<string>.*?</string>'),
    '<key>CFBundleDisplayName</key>\n\t<string>$name</string>',
  );
  
  await _replaceInFile(
    'ios/Runner/Info.plist',
    RegExp(r'<key>CFBundleName</key>\s*<string>.*?</string>'),
    '<key>CFBundleName</key>\n\t<string>$name</string>',
  );
}

Future<void> _updatePackageId(String id) async {
  await _replaceInFile(
    'android/app/build.gradle.kts',
    RegExp(r'applicationId = ".*?"'),
    'applicationId = "$id"',
  );
  
  await _replaceInFile(
    'android/app/build.gradle',
    RegExp(r'applicationId ".*?"'),
    'applicationId "$id"',
  );

  await _replaceInFile(
    'ios/Runner.xcodeproj/project.pbxproj',
    RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = org\.traccar.*?;'),
    'PRODUCT_BUNDLE_IDENTIFIER = $id;',
  );
}

Future<void> _updateVersion(String version) async {
  await _replaceInFile(
    'pubspec.yaml',
    RegExp(r'^version:\s*.*$', multiLine: true),
    'version: $version',
  );
}

Future<void> _updateUrl(String url) async {
  await _replaceInFile(
    'lib/main_screen.dart',
    RegExp(r'https://demo\.traccar\.org'),
    url,
  );
  
  // Update any other demo urls
  await _replaceInFile(
    'lib/main.dart',
    RegExp(r'https://demo\.traccar\.org'),
    url,
  );
}

Future<void> _updateBrandingStrings() async {
  // Change all Traccar mentions to Switch + Masaa24
  final filesToBrand = [
    'lib/main.dart',
    'lib/main_screen.dart',
    'lib/settings/about_screen.dart',
    'lib/l10n/app_en.arb',
    'lib/l10n/app_en.i18n.json',
    'README.md',
  ];
  
  for (final path in filesToBrand) {
    // Replace "Powered by Traccar" -> "Powered by Masaa24 Networks"
    await _replaceInFile(path, RegExp(r'Powered by Traccar', caseSensitive: false), poweredBy);
    await _replaceInFile(path, RegExp(r'Traccar Manager', caseSensitive: false), appName);
    await _replaceInFile(path, RegExp(r'\bTraccar\b'), 'Switch GPS');
    await _replaceInFile(path, RegExp(r'www\.traccar\.org', caseSensitive: false), website);
    await _replaceInFile(path, RegExp(r'traccar\.org', caseSensitive: false), website);
  }
  
  // Update pubspec description
  await _replaceInFile(
    'pubspec.yaml',
    RegExp(r'^description:\s*.*$', multiLine: true),
    'description: "$appName - $poweredBy | $website"',
  );
}

Future<void> _createKeystore() async {
  final keystoreFile = File(keystoreFilePath);
  if (await keystoreFile.exists()) {
    stdout.writeln('Keystore already exists, skipping creation');
  } else {
    final args = [
      '-genkeypair',
      '-v',
      '-keystore', keystoreFilePath,
      '-alias', keystoreAlias,
      '-keyalg', 'RSA',
      '-keysize', '2048',
      '-validity', '10000',
      '-storepass', keystorePassword,
      '-keypass', keystorePassword,
      '-dname', 'CN=Switch Microfinance, OU=GPS Division, O=Masaa24 Networks, L=Dar es Salaam, S=Dar, C=TZ',
    ];
    await _run('keytool', args);
  }

  final file = File('android/key.properties');
  final content = '''
storePassword=$keystorePassword
keyPassword=$keystorePassword
keyAlias=$keystoreAlias
storeFile=../../$keystoreFilePath
''';
  await file.writeAsString(content);

  await _replaceInFile(
    'android/app/build.gradle.kts',
    RegExp(r'val\s+keystorePropertiesFile\s*=.*'),
    'val keystorePropertiesFile = rootProject.file("key.properties")',
  );
}

Future<File> _writeTempYaml(String name, String content) async {
  final file = File(name);
  await file.writeAsString(content);
  return file;
}

Future<void> _replaceInFile(String path, RegExp pattern, String replacement) async {
  final file = File(path);
  if (!await file.exists()) return;
  final text = await file.readAsString();
  final newText = text.replaceAll(pattern, replacement);
  if (newText != text) {
    await file.writeAsString(newText);
    stdout.writeln('Updated: $path');
  }
}

Future<void> _run(String cmd, List<String> args) async {
  stdout.writeln('Running: $cmd ${args.join(" ")}');
  final proc = await Process.start(cmd, args);
  await stdout.addStream(proc.stdout);
  await stderr.addStream(proc.stderr);
  final code = await proc.exitCode;
  if (code != 0) throw Exception('$cmd ${args.join(" ")} failed ($code)');
}
