import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Web implementation: triggers a browser file download via a Blob URL.
/// Works on all browsers including iOS Safari.
void triggerWebDownload(Uint8List bytes, String filename, String mimeType) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  web.document.body?.removeChild(anchor);
  web.URL.revokeObjectURL(url);
}
