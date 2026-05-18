/// Web implementation for file downloads
/// This file is used when the app is running on web browsers

import 'dart:html' as html;
import 'dart:typed_data';

/// Download a file using browser's download functionality
void downloadFile(Uint8List bytes, String filename, String mimeType) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

