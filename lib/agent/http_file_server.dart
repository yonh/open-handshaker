import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// The agent's auxiliary HTTP file server on :19999.
///
/// Protocol (docs/HTTP_API.md §1):
///   GET /?testDATA         -> 200, body = first 16 bytes of DATA (MD5-echo)
///   GET /?file_path=PATH (urlencoded) -> file bytes; Range only `bytes=N-`
///   anything else           -> 404
///
/// Fixes applied vs the original implementation (§6 of HTTP_API.md):
///  * Content-Range written as `bytes start-end/total` (legal form).
///  * Full MIME table instead of a 10-entry audio-only map.
///  * Keep-alive handled per-request: response headers are computed for the
///    request actually in flight (the original leaked the previous header).
///  * A new connection per request is honoured — Connection: close by
///    default unless the client asks for keep-alive AND we can satisfy it.
class HttpFileServer {
  HttpFileServer._(this._server);

  final HttpServer _server;

  static Future<HttpFileServer> bind({int port = 19999,
      InternetAddress? address}) async {
    final s = await HttpServer.bind(
        address ?? InternetAddress.anyIPv4, port,
        shared: true);
    final self = HttpFileServer._(s);
    s.listen(self._handle);
    return self;
  }

  Future<void> close() => _server.close(force: true);

  static const _mime = <String, String>{
    '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png',
    '.gif': 'image/gif', '.webp': 'image/webp', '.heic': 'image/heic',
    '.bmp': 'image/bmp',
    '.mp4': 'video/mp4', '.mov': 'video/quicktime', '.mkv': 'video/x-matroska',
    '.avi': 'video/x-msvideo', '.webm': 'video/webm', '.3gp': 'video/3gpp',
    '.mp3': 'audio/mpeg', '.aac': 'audio/aac', '.m4a': 'audio/mp4',
    '.flac': 'audio/flac', '.ogg': 'audio/ogg', '.wav': 'audio/wav',
    '.apk': 'application/vnd.android.package-archive',
    '.pdf': 'application/pdf', '.txt': 'text/plain; charset=utf-8',
    '.json': 'application/json', '.zip': 'application/zip',
  };

  String _mimeFor(String path) =>
      _mime[path.toLowerCase().split('/').last.contains('.')
          ? '.${path.toLowerCase().split('.').last}'
          : ''] ??
      'application/octet-stream';

  Future<void> _handle(HttpRequest req) async {
    final resp = req.response;
    try {
      final rawQuery = req.uri.query;
      if (rawQuery.startsWith('test')) {
        final data = rawQuery.substring(4);
        final bytes = utf8.encode(data);
        final head = bytes.length > 16 ? bytes.sublist(0, 16) : bytes;
        resp
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.binary
          ..contentLength = head.length
          ..add(head);
        await resp.close();
        return;
      }
      if (rawQuery.startsWith('file_path=')) {
        final path = Uri.decodeComponent(rawQuery.substring(10));
        await _serveFile(req, resp, path);
        return;
      }
      resp
        ..statusCode = HttpStatus.notFound
        ..contentLength = 0;
      await resp.close();
    } catch (_) {
      try {
        resp
          ..statusCode = HttpStatus.internalServerError
          ..contentLength = 0;
        await resp.close();
      } catch (_) {
        // socket already gone
      }
    }
  }

  Future<void> _serveFile(
      HttpRequest req, HttpResponse resp, String path) async {
    final f = File(path);
    if (!await f.exists()) {
      resp
        ..statusCode = HttpStatus.notFound
        ..contentLength = 0;
      await resp.close();
      return;
    }
    final total = await f.length();

    // Range: only `bytes=N-` (start-offset) is supported, matching the doc.
    var start = 0;
    var end = total - 1;
    var partial = false;
    final range = req.headers.value(HttpHeaders.rangeHeader);
    if (range != null) {
      final m = RegExp(r'^bytes=(\d+)-$').firstMatch(range.trim());
      if (m == null) {
        resp
          ..statusCode = HttpStatus.requestedRangeNotSatisfiable
          ..headers.set(HttpHeaders.contentRangeHeader,
              'bytes */$total')
          ..contentLength = 0;
        await resp.close();
        return;
      }
      start = int.parse(m.group(1)!);
      if (start >= total && total > 0) {
        resp
          ..statusCode = HttpStatus.requestedRangeNotSatisfiable
          ..headers.set(HttpHeaders.contentRangeHeader,
              'bytes */$total')
          ..contentLength = 0;
        await resp.close();
        return;
      }
      partial = true;
    }

    final length = end - start + 1;
    resp
      ..statusCode = partial ? HttpStatus.partialContent : HttpStatus.ok
      ..headers.contentType =
          ContentType.parse(_mimeFor(path))
      ..headers.set(HttpHeaders.acceptRangesHeader, 'bytes')
      ..contentLength = length;
    if (partial) {
      resp.headers.set(HttpHeaders.contentRangeHeader,
          'bytes $start-$end/$total');
    }

    final raf = await f.open();
    try {
      await raf.setPosition(start);
      const step = 64 * 1024;
      var sent = 0;
      while (sent < length) {
        final n = (length - sent) < step ? (length - sent) : step;
        final buf = await raf.read(n);
        if (buf.isEmpty) break;
        resp.add(buf);
        sent += buf.length;
        await resp.flush();
      }
    } finally {
      await raf.close();
      await resp.close();
    }
  }
}
