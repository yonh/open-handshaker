import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Shared formatting helpers for the host pages.

final _dateFmt = DateFormat('yyyy-MM-dd HH:mm');

/// 1234567 -> "1.2 MB"
String fmtBytes(int bytes) {
  if (bytes < 0) return '-';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var v = bytes.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  final s = v >= 100 || i == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  return '$s ${units[i]}';
}

/// Seconds -> "mm:ss" or "h:mm:ss"
String fmtDuration(double seconds) {
  final d = Duration(milliseconds: (seconds * 1000).round());
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

/// Unix epoch seconds -> "yyyy-MM-dd HH:mm"; 0/negative -> "-"
String fmtDate(int epochSeconds) {
  if (epochSeconds <= 0) return '-';
  return _dateFmt
      .format(DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000));
}

/// Basename of a POSIX-style remote path.
String baseName(String path) {
  final p = path.endsWith('/') && path.length > 1
      ? path.substring(0, path.length - 1)
      : path;
  final i = p.lastIndexOf('/');
  return i < 0 ? p : p.substring(i + 1);
}

/// Directory portion of a POSIX-style remote path ('/a/b/c' -> '/a/b').
String parentPath(String path) {
  final p = path.endsWith('/') && path.length > 1
      ? path.substring(0, path.length - 1)
      : path;
  final i = p.lastIndexOf('/');
  if (i <= 0) return '/';
  return p.substring(0, i);
}

/// Join a remote dir with a child name.
String joinPath(String dir, String name) =>
    dir.endsWith('/') ? '$dir$name' : '$dir/$name';

IconData fileIcon(String name, {bool isDir = false}) {
  if (isDir) return Icons.folder;
  final ext = name.contains('.')
      ? name.substring(name.lastIndexOf('.')).toLowerCase()
      : '';
  switch (ext) {
    case '.jpg':
    case '.jpeg':
    case '.png':
    case '.gif':
    case '.webp':
    case '.heic':
    case '.bmp':
      return Icons.image;
    case '.mp4':
    case '.mov':
    case '.mkv':
    case '.avi':
    case '.webm':
    case '.3gp':
      return Icons.movie;
    case '.mp3':
    case '.aac':
    case '.m4a':
    case '.flac':
    case '.ogg':
    case '.wav':
      return Icons.music_note;
    case '.apk':
      return Icons.android;
    case '.pdf':
      return Icons.picture_as_pdf;
    case '.txt':
    case '.md':
    case '.log':
      return Icons.description;
    case '.zip':
    case '.tar':
    case '.gz':
    case '.7z':
    case '.rar':
      return Icons.archive;
    case '.doc':
    case '.docx':
    case '.xls':
    case '.xlsx':
    case '.ppt':
    case '.pptx':
      return Icons.article;
    default:
      return Icons.insert_drive_file;
  }
}
