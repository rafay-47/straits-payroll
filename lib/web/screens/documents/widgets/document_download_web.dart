import 'dart:html' as html;

/// Web implementation that uses an invisible `<a>` element with
/// `target="_blank"` to hand the URL to the browser, which then either
/// opens it in a new tab or triggers a file download depending on the
/// response's `Content-Disposition` header.
void triggerBrowserDownload(String url, {String? filename}) {
  final anchor = html.AnchorElement(href: url)
    ..target = '_blank'
    ..rel = 'noopener noreferrer'
    ..style.display = 'none';
  if (filename != null && filename.isNotEmpty) {
    anchor.download = filename;
  }
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
