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
  -h, --help                Show this help message
  -c, --copyright           Show copyright
  --min-size=<KB>           Minimum file size to start compression (default: 300KB)
  --max-size=<KB>           Maximum file size after compression (default: 600KB)

📝 Note:
- Only .jpg, .jpeg, and .png files are processed.
- Files are compressed iteratively to ensure they stay under max-size.
- All other files are copied untouched.
''');
    exit(0);
  }

  // 📜 Copyright
  if (args.contains('--copyright') || args.contains('-c')) {
    print('''
Pegasus Image Compressor CLI
Version: 2.0.0
Author: Olawale Ajepe
Copyright © 2025
License: Personal Use Only (non-commercial)
''');
    exit(0);
  }

  // 🎯 Extract flags
  double minSizeKB = 300;
  double maxSizeKB = 600;

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
      print('❗ Invalid value for --min-size. Using default (300KB).');
    }
  }

  final maxSizeArg = args.firstWhere(
    (arg) => arg.startsWith('--max-size='),
    orElse: () => '',
  );

  if (maxSizeArg.isNotEmpty) {
    final value = maxSizeArg.split('=').last;
    final parsed = double.tryParse(value);

    if (parsed != null && parsed > 0) {
      maxSizeKB = parsed;
    } else {
      print('❗ Invalid value for --max-size. Using default (600KB).');
    }
  }

  final compressThresholdMB = minSizeKB / 1024;

  // 🧠 Extract positional args (ignore flags)
  final positionalArgs =
      args
          .where((arg) => !arg.startsWith('--') && !arg.startsWith('-'))
          .toList();

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

        if (image != null && sizeInMB >= compressThresholdMB) {
          await _compressToMaxSize(targetPath, image, ext, maxSizeKB);
          print('✅ Compressed: $fileName');
        } else {
          await file.copy(targetPath);
          print('📂 Copied (<${minSizeKB.toInt()}KB): $fileName');
        }
      } else {
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

// 🔁 Iteratively compress until under maxSizeKB
Future<void> _compressToMaxSize(
  String path,
  img.Image original,
  String ext,
  double maxSizeKB,
) async {
  const maxDimensionLimit = 0.05;
  int quality = 85;
  double scale = 1.0;
  int width = original.width;
  int height = original.height;

  while (true) {
    final currentWidth = (width * scale).round().clamp(1, original.width);
    final currentHeight = (height * scale).round().clamp(1, original.height);
    final resized = img.copyResize(
      original,
      width: currentWidth,
      height: currentHeight,
    );

    List<int> encoded;
    if (ext == '.png') {
      encoded = img.encodePng(resized);
    } else {
      encoded = img.encodeJpg(resized, quality: quality);
    }

    if (encoded.length <= (maxSizeKB * 1024).toInt()) {
      await File(path).writeAsBytes(encoded, flush: true);
      return;
    }

    if (quality > 20) {
      quality -= 10;
    } else if (scale > maxDimensionLimit) {
      scale *= 0.85;
      quality = 85;
    } else {
      // best effort — write at lowest quality and minimal scale
      final minimal = img.copyResize(
        original,
        width: (original.width * maxDimensionLimit).round().clamp(
          1,
          original.width,
        ),
        height: (original.height * maxDimensionLimit).round().clamp(
          1,
          original.height,
        ),
      );
      final minimalEncoded =
          ext == '.png'
              ? img.encodePng(minimal)
              : img.encodeJpg(minimal, quality: 10);
      await File(path).writeAsBytes(minimalEncoded, flush: true);
      return;
    }
  }
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
