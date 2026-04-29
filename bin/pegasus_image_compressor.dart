import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  // 📖 Help
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    print('''
📦 Pegasus Image Compressor (CLI)

Developed internally at PremiumTrust Bank  
Author: Olawale Ajepe  

💡 Usage:
  pegasus_image_compressor <source_folder> <output_folder> [options]

Example:
  pegasus_image_compressor ~/Pictures ~/CompressedImages --min-size=300

Options:
  -h, --help              Show this help message
  -c, --copyright         Show copyright
  --min-size=<KB>         Minimum file size to start compression (default: 500KB)

📝 Note:
- Only .jpg, .jpeg, and .png files are processed.
- Files are compressed based on size thresholds.
- All other files are copied untouched.
''');
    exit(0);
  }

  // 📜 Copyright
  if (args.contains('--copyright') || args.contains('-c')) {
    print('''
Pegasus Image Compressor CLI
Version: 1.1.0
Author: Olawale Ajepe
Copyright © 2025
License: Personal Use Only (non-commercial)
''');
    exit(0);
  }

  // 🎯 Extract flag: --min-size
  double minSizeKB = 500; // default

  final minSizeArg = args.firstWhere(
    (arg) => arg.startsWith('--min-size='),
    orElse: () => '',
  );

  if (minSizeArg.isNotEmpty) {
    final value = minSizeArg.split('=').last;
    final parsed = double.tryParse(value);

    if (parsed != null && parsed > 0) {
      minSizeKB = parsed;
    } else {
      print('❗ Invalid value for --min-size. Using default (500KB).');
    }
  }

  final compressThresholdMB = minSizeKB / 1024;

  // 🧠 Extract positional args (ignore flags)
  final positionalArgs =
      args.where((arg) => !arg.startsWith('--') && !arg.startsWith('-')).toList();

  if (positionalArgs.length < 2) {
    print('❗ Error: Missing arguments.\nRun with --help to see usage.');
    exit(1);
  }

  final sourcePath = positionalArgs[0];
  final outputPath = positionalArgs[1];

  final sourceDir = Directory(sourcePath);
  final targetDir = Directory(outputPath);

  if (!sourceDir.existsSync()) {
    print('❌ Source folder does not exist: $sourcePath');
    exit(1);
  }

  if (!targetDir.existsSync()) {
    targetDir.createSync(recursive: true);
  }

  final imageExtensions = ['.jpg', '.jpeg', '.png'];
  final files = <File>[];

  // 📁 Collect files
  await for (final entity in sourceDir.list()) {
    if (entity is File && !p.basename(entity.path).startsWith('.')) {
      files.add(entity);
    }
  }

  final totalOriginalSize = await _getTotalSize(files);
  int processed = 0;

  // 🔄 Process files
  for (final file in files) {
    final ext = p.extension(file.path).toLowerCase();
    final fileName = p.basename(file.path);
    final targetPath = p.join(targetDir.path, fileName);

    try {
      if (imageExtensions.contains(ext)) {
        final sizeInMB = await file.length() / (1024 * 1024);
        final bytes = await file.readAsBytes();
        final image = img.decodeImage(bytes);

        if (image != null && sizeInMB > 3) {
          // 🔴 Large
          final resized = img.copyResize(
            image,
            width: (image.width * 0.6).toInt(),
            height: (image.height * 0.6).toInt(),
          );

          await _writeResized(targetPath, resized, ext, quality: 60);
          print('✅ Resized (large): $fileName');

        } else if (image != null && sizeInMB >= 1) {
          // 🟠 Medium
          final resized = img.copyResize(
            image,
            width: (image.width * 0.7).toInt(),
            height: (image.height * 0.7).toInt(),
          );

          await _writeResized(targetPath, resized, ext, quality: 65);
          print('✅ Resized (medium): $fileName');

        } else if (image != null && sizeInMB >= compressThresholdMB) {
          // 🟡 Small but above threshold
          await _writeResized(targetPath, image, ext, quality: 75);
          print(
              '🟡 Compressed (≥${minSizeKB.toInt()}KB): $fileName');

        } else {
          // 🟢 Very small
          await file.copy(targetPath);
          print('📂 Copied (<${minSizeKB.toInt()}KB): $fileName');
        }
      } else {
        // 📁 Non-image
        await file.copy(targetPath);
        print('📁 Copied (non-image): $fileName');
      }
    } catch (e) {
      print('⚠️ Error processing $fileName: $e');
    }

    processed++;
    _drawProgressBar(processed, files.length);
  }

  // 📊 Final stats
  final convertedFiles = <File>[];
  await for (final entity in targetDir.list()) {
    if (entity is File) convertedFiles.add(entity);
  }

  final totalConvertedSize = await _getTotalSize(convertedFiles);

  print('\n✅ Completed!');
  print(
    'Original Size: ${(totalOriginalSize / (1024 * 1024)).toStringAsFixed(2)} MB',
  );
  print(
    'Converted Size: ${(totalConvertedSize / (1024 * 1024)).toStringAsFixed(2)} MB',
  );
  print('Output Folder: ${targetDir.path}');
}

// 📊 Calculate total size
Future<int> _getTotalSize(List<File> files) async {
  int totalSize = 0;
  for (final file in files) {
    totalSize += await file.length();
  }
  return totalSize;
}

// 💾 Write image with quality control
Future<void> _writeResized(
  String path,
  img.Image image,
  String ext, {
  int quality = 60,
}) async {
  List<int> encoded;

  if (ext == '.png') {
    encoded = img.encodePng(image);
  } else {
    encoded = img.encodeJpg(image, quality: quality);
  }

  await File(path).writeAsBytes(encoded, flush: true);
}

// 📊 CLI Progress bar
void _drawProgressBar(int current, int total) {
  const barLength = 40;
  final percent = current / total;
  final filledLength = (barLength * percent).round();
  final bar = '=' * filledLength + ' ' * (barLength - filledLength);
  final percentDisplay = (percent * 100).toStringAsFixed(1).padLeft(5);

  stdout.write('\r📊 Progress: |$bar| $percentDisplay% ($current of $total)');
  if (current == total) stdout.writeln();
}