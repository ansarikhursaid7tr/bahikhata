import 'dart:typed_data';

/// Stub implementation for non-web platforms.
/// This file is imported when NOT compiling for web.
void triggerWebDownload(Uint8List bytes, String filename, String mimeType) {
  // No-op on non-web platforms; the native share sheet is used instead.
}
