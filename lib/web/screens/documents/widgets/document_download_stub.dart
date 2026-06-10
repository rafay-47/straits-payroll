/// Stub used on non-web platforms (Android, iOS, desktop).
///
/// `dart:html` is not available off the web, so this is a no-op. On
/// Android/iOS the user can open the document URL with the platform
/// handler (browser share sheet, default browser, etc.) — there is no
/// "anchor + click" trick to perform. The web version of this file
/// does the actual download trigger.
void triggerBrowserDownload(String url, {String? filename}) {
  // Intentionally a no-op on non-web platforms. The web entry point
  // is selected via conditional import in the calling screen.
}
