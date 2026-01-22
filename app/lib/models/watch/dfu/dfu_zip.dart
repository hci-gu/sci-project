import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:scimovement/models/watch/dfu/dfu_package.dart';

class DfuZipParser {
  static DfuPackage parse(Uint8List zipBytes, {String? version}) {
    final archive = ZipDecoder().decodeBytes(zipBytes);

    ArchiveFile? datFile;
    ArchiveFile? binFile;

    for (final file in archive.files) {
      final name = file.name.toLowerCase();
      if (file.isFile && name.endsWith('.dat')) {
        datFile = file;
      } else if (file.isFile && name.endsWith('.bin')) {
        binFile = file;
      }
    }

    if (datFile == null || binFile == null) {
      throw StateError('dfu_zip_missing_dat_or_bin');
    }

    final datBytes = Uint8List.fromList(datFile!.content as List<int>);
    final binBytes = Uint8List.fromList(binFile!.content as List<int>);

    return DfuPackage(
      datBytes: datBytes,
      binBytes: binBytes,
      imageSize: binBytes.length,
      version: version,
    );
  }
}
