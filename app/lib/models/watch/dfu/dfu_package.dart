import 'dart:typed_data';

class DfuPackage {
  final Uint8List datBytes;
  final Uint8List binBytes;
  final int imageSize;
  final String? version;

  const DfuPackage({
    required this.datBytes,
    required this.binBytes,
    required this.imageSize,
    this.version,
  });
}
