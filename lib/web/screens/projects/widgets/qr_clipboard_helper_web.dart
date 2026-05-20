import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:typed_data';

Future<bool> copyImageToClipboard(Uint8List bytes) async {
  try {
    final clipboard = html.window.navigator.clipboard;
    if (clipboard == null) return false;

    final blob = html.Blob([bytes], 'image/png');
    final clipboardItemCtor = js_util.getProperty(html.window, 'ClipboardItem');
    if (clipboardItemCtor == null) return false;

    final itemData = js_util.jsify({'image/png': blob});
    final clipboardItem =
        js_util.callConstructor(clipboardItemCtor as Object, [itemData]);

    await js_util.promiseToFuture<void>(
      js_util.callMethod<Object>(clipboard, 'write', [
        [clipboardItem]
      ]),
    );
    return true;
  } catch (_) {
    return false;
  }
}

void downloadPng(Uint8List bytes, String filename) {
  final blob = html.Blob([bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

String toDataUrl(Uint8List bytes) {
  final b64 = base64Encode(bytes);
  return 'data:image/png;base64,$b64';
}
