import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

Future<File?> comprimirImagen(File file, {int maxSizeInMB = 5}) async {
  final int maxSizeInBytes = maxSizeInMB * 1024 * 1024;
  int quality = 95;
  Uint8List? result;
  //
  while (quality > 10) {
    result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: quality,
      format: CompressFormat.jpeg,
    );

    if (result == null) break;

    if (result.lengthInBytes <= maxSizeInBytes) {
      break;
    }

    quality -= 5;
  }

  if (result == null) return null;

  final tempDir = await getTemporaryDirectory();
  final targetPath = path.join(tempDir.path, "imagen_comprimida.jpg");
  final compressedFile = await File(targetPath).writeAsBytes(result);

  //mostramos el tamaño original del archivo y como quedo comprimido
  print("Tamaño original: ${file.lengthSync() / (1024 * 1024)} MB");
  print("Tamaño comprimido: ${compressedFile.lengthSync() / (1024 * 1024)} MB");

  return compressedFile;
}

