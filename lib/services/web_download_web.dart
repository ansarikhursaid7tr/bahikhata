import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Web implementation: triggers a browser file download.
/// On iOS Safari (which doesn't support the download attribute),
/// opens the PDF in a new tab so the user can use the native share/save.
void triggerWebDownload(Uint8List bytes, String filename, String mimeType) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);

  // Detect iOS Safari: doesn't support <a download> properly
  final userAgent = web.window.navigator.userAgent.toLowerCase();
  final isIOS = userAgent.contains('iphone') ||
      userAgent.contains('ipad') ||
      userAgent.contains('ipod') ||
      (userAgent.contains('macintosh') && web.window.navigator.maxTouchPoints > 0);

  if (isIOS) {
    // On iOS, open the blob URL in a new tab.
    // Safari will show its native PDF viewer with share/save options.
    web.window.open(url, '_blank');
  } else {
    // On all other browsers, use the standard anchor-click trick.
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = filename;
    anchor.style.display = 'none';
    web.document.body?.appendChild(anchor);
    anchor.click();
    web.document.body?.removeChild(anchor);
    web.URL.revokeObjectURL(url);
  }
}
