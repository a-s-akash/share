import 'dart:io';
import 'dart:typed_data';
import 'dart:developer';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageCompressionUtil {
  static Future<String> compressAndSaveImage({
    required String originalImagePath,
    required String fileName,
    int targetSizeKB = 75, // Target 75KB (between 50-100KB)
    int maxWidth = 1024,
    int maxHeight = 1024,
  }) async {
    try {
      log('Starting image compression for: $originalImagePath');

      final originalFile = File(originalImagePath);
      if (!await originalFile.exists()) {
        throw Exception('Original image file does not exist');
      }

      final originalBytes = await originalFile.readAsBytes();
      log('Original image size: ${(originalBytes.length / 1024).toStringAsFixed(2)} KB');

      img.Image? image = img.decodeImage(originalBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      log('Original image dimensions: ${image.width}x${image.height}');

      // Resize image if it's too large
      if (image.width > maxWidth || image.height > maxHeight) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? maxWidth : null,
          height: image.height > image.width ? maxHeight : null,
          maintainAspect: true,
        );
        log('Resized image dimensions: ${image.width}x${image.height}');
      }

      final appDocDir = await getApplicationDocumentsDirectory();
      final compressedImagesDir =
          Directory('${appDocDir.path}/compressed_images');

      // Create directory if it doesn't exist
      if (!await compressedImagesDir.exists()) {
        await compressedImagesDir.create(recursive: true);
      }

      final compressedFilePath = path.join(compressedImagesDir.path, fileName);

      int quality = 85;
      Uint8List compressedBytes;

      do {
        compressedBytes =
            Uint8List.fromList(img.encodeJpg(image, quality: quality));
        final compressedSizeKB = compressedBytes.length / 1024;

        log('Quality: $quality, Size: ${compressedSizeKB.toStringAsFixed(2)} KB');

        if (compressedSizeKB <= targetSizeKB) {
          break;
        }

        quality -= 10;

        if (quality < 20) {
          log('Warning: Reached minimum quality (20), final size: ${compressedSizeKB.toStringAsFixed(2)} KB');
          break;
        }
      } while (quality >= 20);

      final compressedFile = File(compressedFilePath);
      await compressedFile.writeAsBytes(compressedBytes);

      final finalSizeKB = compressedBytes.length / 1024;
      log('Image compression completed. Final size: ${finalSizeKB.toStringAsFixed(2)} KB');
      log('Compression ratio: ${((originalBytes.length - compressedBytes.length) / originalBytes.length * 100).toStringAsFixed(1)}%');

      return compressedFilePath;
    } catch (e) {
      log('Error compressing image: $e');
      rethrow;
    }
  }

  static Future<void> deleteCompressedImage(String filePath) async {
    try {
      if (filePath.isNotEmpty) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          log('Deleted compressed image: $filePath');
        }
      }
    } catch (e) {
      log('Error deleting compressed image: $e');
    }
  }

  // static Future<void> cleanupOldCompressedImages({int daysOld = 7}) async {
  //   try {
  //     final appDocDir = await getApplicationDocumentsDirectory();
  //     final compressedImagesDir = Directory('${appDocDir.path}/compressed_images');

  //     if (await compressedImagesDir.exists()) {
  //       final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

  //       await for (final entity in compressedImagesDir.list()) {
  //         if (entity is File) {
  //           final stat = await entity.stat();
  //           if (stat.modified.isBefore(cutoffDate)) {
  //             await entity.delete();
  //             log('Cleaned up old compressed image: ${entity.path}');
  //           }
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     log('Error cleaning up old compressed images: $e');
  //   }
  // }
}
