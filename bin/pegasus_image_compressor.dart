#!/usr/bin/env dart

import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    print('''
📦 Pegasus Image Compressor (CLI)

Developed internally at PremiumTrust Bank  
Author: Olawale Ajepe  
Role: Software Developer

💡 Usage:
  pegasus_image_compressor <source_folder> <output_folder>

Example:
  pegasus_image_compressor ~/Pictures ~/CompressedImages

Options:
  -h, --help        Show this help message
  -c, --copyright   Show copyright

📝 Note:
- Only .jpg, .jpeg, and .png files are processed.
- Files larger than 1MB will be resized.
- All other files will be copied untouched.
''');
    exit(0);
  }

  if (args.contains('--copyright') || args.contains('-c')) {
    print('''
Pegasus Image Compressor CLI
Version: 1.0.0
Author: Olawale Ajepe
Copyright © 2025
License: Personal Use Only (non-commercial)
''');
    exit(0);
  }

  if (args.length < 2) {
    print('❗ Error: Missing arguments.\nRun with --help to see usage.');
    exit(1);
  }

  final sourcePath = args[0];
  final outputPath = args[1];

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

  await for (final entity in sourceDir.list()) {
    if (entity is File && !p.basename(entity.path).startsWith('.')) {
      files.add(entity);
    }
  }

  final totalOriginalSize = await _getTotalSize(files);
  int processed = 0;

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
          final resized = img.copyResize(
            image,
            width: (image.width * 0.6).toInt(),
            height: (image.height * 0.6).toInt(),
          );

          await _writeResized(targetPath, resized, ext);
          print('✅ Resized (large): $fileName');
        } else if (image != null && sizeInMB >= 1) {
          final resized = img.copyResize(
            image,
            width: (image.width * 0.7).toInt(),
            height: (image.height * 0.7).toInt(),
          );

          await _writeResized(targetPath, resized, ext);
          print('✅ Resized (medium): $fileName');
        } else {
          await file.copy(targetPath);
          print('📂 Copied (small): $fileName');
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

Future<int> _getTotalSize(List<File> files) async {
  int totalSize = 0;
  for (final file in files) {
    totalSize += await file.length();
  }
  return totalSize;
}

Future<void> _writeResized(String path, img.Image resized, String ext) async {
  List<int> encoded;
  if (ext == '.png') {
    encoded = img.encodePng(resized);
  } else {
    encoded = img.encodeJpg(resized, quality: 60);
  }
  await File(path).writeAsBytes(encoded, flush: true);
}

void _drawProgressBar(int current, int total) {
  const barLength = 40;
  final percent = current / total;
  final filledLength = (barLength * percent).round();
  final bar = '=' * filledLength + ' ' * (barLength - filledLength);
  final percentDisplay = (percent * 100).toStringAsFixed(1).padLeft(5);

  stdout.write('\r📊 Progress: |$bar| $percentDisplay% ($current of $total)');
  if (current == total) stdout.writeln();
}



// import 'dart:io';
// import 'package:image/image.dart' as img;
// import 'package:path/path.dart' as p;

// Future<void> main(List<String> args) async {
//   // help
//   if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
//     print('''
// 📦 Pegasus Image Compressor (CLI)

// Role: Software Developer

// 💡 Usage:
//   pegasus_image_compressor <source_folder> <output_folder>

// Example:
//   pegasus_image_compressor ~/Pictures ~/CompressedImages

// Options:
//   -h, --help        Show this help message
//   -c, --copyright   show copyright

// 📝 Note:
// - Only .jpg, .jpeg, and .png files are processed.
// - Files larger than 1MB will be resized.
// - All other files will be copied untouched.

// ''');
//     exit(0);
//   }
//   // copyright
//   if (args.isEmpty || args.contains('--copyright') || args.contains('-c')) {
//     print('''
// Pegasus Image Compressor CLI
// Version: 1.0.0
// Author: Olawale Ajepe
// Copyright © 2025 Olawale Ajepe
// License: Personal Use Only (non-commercial)
// ''');
//     exit(1);
//   }

//   if (args.length < 2) {
//     print('❗ Error: Missing arguments.\nRun with --help to see usage.');
//     exit(1);
//   }

//   final sourcePath = args[0];
//   final outputPath = args[1];

//   final sourceDir = Directory(sourcePath);
//   final targetDir = Directory(outputPath);

//   if (!await sourceDir.exists()) {
//     print('❌ Source folder does not exist: $sourcePath');
//     exit(1);
//   }

//   if (!await targetDir.exists()) {
//     await targetDir.create(recursive: true);
//   }

//   final imageExtensions = ['.jpg', '.jpeg', '.png'];
//   final files = <File>[];

//   await for (final entity in sourceDir.list()) {
//     if (entity is File && !p.basename(entity.path).startsWith('.')) {
//       files.add(entity);
//     }
//   }

//   final totalOriginalSize = await _getTotalSize(files);
//   // ignore: unused_local_variable
//   int processed = 0;

//   for (final file in files) {
//     final ext = p.extension(file.path).toLowerCase();
//     final fileName = p.basename(file.path);
//     final targetPath = p.join(targetDir.path, fileName);

//     try {
//       if (imageExtensions.contains(ext)) {
//         final sizeInMB = await file.length() / (1024 * 1024);
//         final bytes = await file.readAsBytes();
//         final image = img.decodeImage(bytes);

//         if (image != null && sizeInMB > 3) {
//           final resized = img.copyResize(
//             image,
//             width: (image.width * 0.6).toInt(),
//             height: (image.height * 0.6).toInt(),
//             interpolation: img.Interpolation.average,
//           );

//           await _writeResized(targetPath, resized, ext);
//           print('✅ Resized: $fileName');
//         } else if (image != null && sizeInMB >= 1) {
//           final resized = img.copyResize(
//             image,
//             width: (image.width * 0.7).toInt(),
//             height: (image.height * 0.7).toInt(),
//             interpolation: img.Interpolation.average,
//           );

//           await _writeResized(targetPath, resized, ext);
//           print('✅ Resized: $fileName');
//         } else {
//           await file.copy(targetPath);
//           print('📂 Copied (small or undecodable): $fileName');
//         }
//       } else {
//         await file.copy(targetPath);
//         print('📁 Copied (non-image): $fileName');
//       }
//     } catch (e) {
//       print('⚠️ Error processing $fileName: $e');
//     }
//     processed++;
//     _drawProgressBar(processed, files.length);
//   }

//   final convertedFiles = <File>[];
//   await for (final entity in targetDir.list()) {
//     if (entity is File) convertedFiles.add(entity);
//   }

//   final totalConvertedSize = await _getTotalSize(convertedFiles);
//   print('\n✅ Completed!');
//   print(
//     'Original Size: ${(totalOriginalSize / (1024 * 1024)).toStringAsFixed(2)} MB',
//   );
//   print(
//     'Converted Size: ${(totalConvertedSize / (1024 * 1024)).toStringAsFixed(2)} MB',
//   );
//   print('Output Folder: ${targetDir.path}');
// }

// Future<int> _getTotalSize(List<File> files) async {
//   int totalSize = 0;
//   for (final file in files) {
//     totalSize += await file.length();
//   }
//   return totalSize;
// }

// Future<void> _writeResized(String path, img.Image resized, String ext) async {
//   List<int> encoded;
//   if (ext == '.png') {
//     encoded = img.encodePng(resized);
//   } else {
//     encoded = img.encodeJpg(resized, quality: 60);
//   }
//   await File(path).writeAsBytes(encoded, flush: true);
// }

// void _drawProgressBar(int current, int total) {
//   const barLength = 40;
//   final percent = current / total;
//   final filledLength = (barLength * percent).round();
//   final bar = '=' * filledLength + ' ' * (barLength - filledLength);
//   final percentDisplay = (percent * 100).toStringAsFixed(1).padLeft(5);

//   stdout.write('\r📊 Progress: |$bar| $percentDisplay% ($current of $total)');
//   if (current == total) {
//     stdout.writeln(); // Newline at the end
//   }
// }
