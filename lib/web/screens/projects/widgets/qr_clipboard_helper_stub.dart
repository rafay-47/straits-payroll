import 'dart:typed_data';

Future<bool> copyImageToClipboard(Uint8List bytes) async {
  return false;
}

void downloadPng(Uint8List bytes, String filename) {
  throw UnsupportedError('QR image download is only supported on web.');
}
