# 📦 Pegasus Image Compressor (CLI)

A high-performance **command-line image compression tool** built with Dart.  
Developed by **Olawale Ajepe**.

This tool scans a folder, compresses large images, and outputs optimized versions with minimal loss of quality — ideal for bulk media cleanup, storage optimization, and workflow automation.

---

## Features

- Compress **JPG, JPEG, PNG** images
- Automatically resizes images based on file size:
  - > 3MB → 60% resize  
  - ≥ 1MB → 70% resize
- Preserves all small or unsupported-files (copies untouched)
- Fast, memory-efficient processing using the `image` package
- Beautiful CLI progress bar
- Cross-platform (Windows, macOS, Linux)
- Supports global installation via `dart pub global activate`

---

## Installation

### **Install Globally**

From the project folder:

```sh
dart pub global activate --source path .
