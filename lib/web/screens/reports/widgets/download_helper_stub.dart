/// Stub implementation for non-web platforms
/// This file is used when the app is running on mobile (Android/iOS)

import 'dart:typed_data';

/// Download a file (stub - not supported on mobile)
void downloadFile(Uint8List bytes, String filename, String mimeType) {
  throw UnsupportedError(
    'File download is only supported on web platform. '
    'This screen should not be accessible on mobile.',
  );
}

