// This is a generated file - do not edit.
//
// Generated from SmartSyncProtocol.recovered.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'SmartSyncProtocol.recovered.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'SmartSyncProtocol.recovered.pbenum.dart';

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:2
class SSPFile extends $pb.GeneratedMessage {
  factory SSPFile({
    $core.String? path,
    $fixnum.Int64? fileSize,
    $fixnum.Int64? createdTimestamp,
    $fixnum.Int64? modifiedTimestamp,
    $core.bool? isDirectory,
    $core.String? checksum,
    SSPFileType? fileType,
    $core.String? prefixMd5,
    $core.String? extData,
  }) {
    final result = SSPFile._();
    if (path != null) result.path = path;
    if (fileSize != null) result.fileSize = fileSize;
    if (createdTimestamp != null) result.createdTimestamp = createdTimestamp;
    if (modifiedTimestamp != null) result.modifiedTimestamp = modifiedTimestamp;
    if (isDirectory != null) result.isDirectory = isDirectory;
    if (checksum != null) result.checksum = checksum;
    if (fileType != null) result.fileType = fileType;
    if (prefixMd5 != null) result.prefixMd5 = prefixMd5;
    if (extData != null) result.extData = extData;
    return result;
  }

  SSPFile._();

  factory SSPFile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPFile()..mergeFromBuffer(data, registry);
  factory SSPFile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPFile()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPFile',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPFile.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'fileSize', $pb.PbFieldType.OU6,
        protoName: 'fileSize', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'createdTimestamp', $pb.PbFieldType.OU6,
        protoName: 'createdTimestamp', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'modifiedTimestamp', $pb.PbFieldType.OU6,
        protoName: 'modifiedTimestamp', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(6, _omitFieldNames ? '' : 'isDirectory', protoName: 'isDirectory')
    ..aOS(7, _omitFieldNames ? '' : 'checksum')
    ..aE<SSPFileType>(8, _omitFieldNames ? '' : 'fileType',
        protoName: 'fileType', enumValues: SSPFileType.values)
    ..aOS(9, _omitFieldNames ? '' : 'prefixMd5', protoName: 'prefixMd5')
    ..aOS(10, _omitFieldNames ? '' : 'extData', protoName: 'extData')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPFile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPFile copyWith(void Function(SSPFile) updates) =>
      super.copyWith((message) => updates(message as SSPFile)) as SSPFile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SSPFile() / SSPFile.new instead')
  static SSPFile create() => SSPFile._();
  static $pb.GeneratedMessage $_createMessage() => SSPFile._();
  @$core.override
  SSPFile createEmptyInstance() => SSPFile._();
  @$core.pragma('dart2js:noInline')
  static SSPFile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPFile>(SSPFile.$_createMessage);
  static SSPFile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get fileSize => $_getI64(1);
  @$pb.TagNumber(2)
  set fileSize($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFileSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearFileSize() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get createdTimestamp => $_getI64(2);
  @$pb.TagNumber(3)
  set createdTimestamp($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCreatedTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearCreatedTimestamp() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get modifiedTimestamp => $_getI64(3);
  @$pb.TagNumber(4)
  set modifiedTimestamp($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasModifiedTimestamp() => $_has(3);
  @$pb.TagNumber(4)
  void clearModifiedTimestamp() => $_clearField(4);

  @$pb.TagNumber(6)
  $core.bool get isDirectory => $_getBF(4);
  @$pb.TagNumber(6)
  set isDirectory($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(6)
  $core.bool hasIsDirectory() => $_has(4);
  @$pb.TagNumber(6)
  void clearIsDirectory() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get checksum => $_getSZ(5);
  @$pb.TagNumber(7)
  set checksum($core.String value) => $_setString(5, value);
  @$pb.TagNumber(7)
  $core.bool hasChecksum() => $_has(5);
  @$pb.TagNumber(7)
  void clearChecksum() => $_clearField(7);

  @$pb.TagNumber(8)
  SSPFileType get fileType => $_getN(6);
  @$pb.TagNumber(8)
  set fileType(SSPFileType value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasFileType() => $_has(6);
  @$pb.TagNumber(8)
  void clearFileType() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get prefixMd5 => $_getSZ(7);
  @$pb.TagNumber(9)
  set prefixMd5($core.String value) => $_setString(7, value);
  @$pb.TagNumber(9)
  $core.bool hasPrefixMd5() => $_has(7);
  @$pb.TagNumber(9)
  void clearPrefixMd5() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get extData => $_getSZ(8);
  @$pb.TagNumber(10)
  set extData($core.String value) => $_setString(8, value);
  @$pb.TagNumber(10)
  $core.bool hasExtData() => $_has(8);
  @$pb.TagNumber(10)
  void clearExtData() => $_clearField(10);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:12
class SSPImageFile extends $pb.GeneratedMessage {
  factory SSPImageFile({
    $core.String? path,
    $fixnum.Int64? fileSize,
    $fixnum.Int64? createdTimestamp,
    $fixnum.Int64? modifiedTimestamp,
    $core.int? width,
    $core.int? height,
    $core.int? orientation,
    $fixnum.Int64? mediaId,
    $fixnum.Int64? albumId,
    $core.String? mimeType,
    $core.List<$core.int>? thumbnail,
    $core.String? albumName,
    $fixnum.Int64? dateTaken,
    $core.String? latitude,
    $core.String? longitude,
    $core.String? miniThumbMagic,
    $core.String? title,
    $core.bool? getThumbnailError,
    $core.bool? starred,
  }) {
    final result = SSPImageFile._();
    if (path != null) result.path = path;
    if (fileSize != null) result.fileSize = fileSize;
    if (createdTimestamp != null) result.createdTimestamp = createdTimestamp;
    if (modifiedTimestamp != null) result.modifiedTimestamp = modifiedTimestamp;
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    if (orientation != null) result.orientation = orientation;
    if (mediaId != null) result.mediaId = mediaId;
    if (albumId != null) result.albumId = albumId;
    if (mimeType != null) result.mimeType = mimeType;
    if (thumbnail != null) result.thumbnail = thumbnail;
    if (albumName != null) result.albumName = albumName;
    if (dateTaken != null) result.dateTaken = dateTaken;
    if (latitude != null) result.latitude = latitude;
    if (longitude != null) result.longitude = longitude;
    if (miniThumbMagic != null) result.miniThumbMagic = miniThumbMagic;
    if (title != null) result.title = title;
    if (getThumbnailError != null) result.getThumbnailError = getThumbnailError;
    if (starred != null) result.starred = starred;
    return result;
  }

  SSPImageFile._();

  factory SSPImageFile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPImageFile()..mergeFromBuffer(data, registry);
  factory SSPImageFile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPImageFile()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPImageFile',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPImageFile.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'fileSize', $pb.PbFieldType.OU6,
        protoName: 'fileSize', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'createdTimestamp', $pb.PbFieldType.OU6,
        protoName: 'createdTimestamp', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'modifiedTimestamp', $pb.PbFieldType.OU6,
        protoName: 'modifiedTimestamp', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(5, _omitFieldNames ? '' : 'width', fieldType: $pb.PbFieldType.OU3)
    ..aI(6, _omitFieldNames ? '' : 'height', fieldType: $pb.PbFieldType.OU3)
    ..aI(7, _omitFieldNames ? '' : 'orientation',
        fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(8, _omitFieldNames ? '' : 'mediaId', $pb.PbFieldType.OU6,
        protoName: 'mediaId', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(9, _omitFieldNames ? '' : 'albumId', $pb.PbFieldType.OU6,
        protoName: 'albumId', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(10, _omitFieldNames ? '' : 'mimeType', protoName: 'mimeType')
    ..a<$core.List<$core.int>>(
        11, _omitFieldNames ? '' : 'thumbnail', $pb.PbFieldType.OY)
    ..aOS(12, _omitFieldNames ? '' : 'albumName', protoName: 'albumName')
    ..a<$fixnum.Int64>(
        13, _omitFieldNames ? '' : 'dateTaken', $pb.PbFieldType.OU6,
        protoName: 'dateTaken', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(14, _omitFieldNames ? '' : 'latitude')
    ..aOS(15, _omitFieldNames ? '' : 'longitude')
    ..aOS(16, _omitFieldNames ? '' : 'miniThumbMagic',
        protoName: 'miniThumbMagic')
    ..aOS(17, _omitFieldNames ? '' : 'title')
    ..aOB(18, _omitFieldNames ? '' : 'getThumbnailError',
        protoName: 'getThumbnailError')
    ..aOB(19, _omitFieldNames ? '' : 'starred')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPImageFile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPImageFile copyWith(void Function(SSPImageFile) updates) =>
      super.copyWith((message) => updates(message as SSPImageFile))
          as SSPImageFile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SSPImageFile() / SSPImageFile.new instead')
  static SSPImageFile create() => SSPImageFile._();
  static $pb.GeneratedMessage $_createMessage() => SSPImageFile._();
  @$core.override
  SSPImageFile createEmptyInstance() => SSPImageFile._();
  @$core.pragma('dart2js:noInline')
  static SSPImageFile getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SSPImageFile>(
          SSPImageFile.$_createMessage);
  static SSPImageFile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get fileSize => $_getI64(1);
  @$pb.TagNumber(2)
  set fileSize($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFileSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearFileSize() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get createdTimestamp => $_getI64(2);
  @$pb.TagNumber(3)
  set createdTimestamp($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCreatedTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearCreatedTimestamp() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get modifiedTimestamp => $_getI64(3);
  @$pb.TagNumber(4)
  set modifiedTimestamp($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasModifiedTimestamp() => $_has(3);
  @$pb.TagNumber(4)
  void clearModifiedTimestamp() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get width => $_getIZ(4);
  @$pb.TagNumber(5)
  set width($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasWidth() => $_has(4);
  @$pb.TagNumber(5)
  void clearWidth() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get height => $_getIZ(5);
  @$pb.TagNumber(6)
  set height($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasHeight() => $_has(5);
  @$pb.TagNumber(6)
  void clearHeight() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get orientation => $_getIZ(6);
  @$pb.TagNumber(7)
  set orientation($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasOrientation() => $_has(6);
  @$pb.TagNumber(7)
  void clearOrientation() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get mediaId => $_getI64(7);
  @$pb.TagNumber(8)
  set mediaId($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMediaId() => $_has(7);
  @$pb.TagNumber(8)
  void clearMediaId() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get albumId => $_getI64(8);
  @$pb.TagNumber(9)
  set albumId($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasAlbumId() => $_has(8);
  @$pb.TagNumber(9)
  void clearAlbumId() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get mimeType => $_getSZ(9);
  @$pb.TagNumber(10)
  set mimeType($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasMimeType() => $_has(9);
  @$pb.TagNumber(10)
  void clearMimeType() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.List<$core.int> get thumbnail => $_getN(10);
  @$pb.TagNumber(11)
  set thumbnail($core.List<$core.int> value) => $_setBytes(10, value);
  @$pb.TagNumber(11)
  $core.bool hasThumbnail() => $_has(10);
  @$pb.TagNumber(11)
  void clearThumbnail() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get albumName => $_getSZ(11);
  @$pb.TagNumber(12)
  set albumName($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasAlbumName() => $_has(11);
  @$pb.TagNumber(12)
  void clearAlbumName() => $_clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get dateTaken => $_getI64(12);
  @$pb.TagNumber(13)
  set dateTaken($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(13)
  $core.bool hasDateTaken() => $_has(12);
  @$pb.TagNumber(13)
  void clearDateTaken() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get latitude => $_getSZ(13);
  @$pb.TagNumber(14)
  set latitude($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasLatitude() => $_has(13);
  @$pb.TagNumber(14)
  void clearLatitude() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get longitude => $_getSZ(14);
  @$pb.TagNumber(15)
  set longitude($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasLongitude() => $_has(14);
  @$pb.TagNumber(15)
  void clearLongitude() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.String get miniThumbMagic => $_getSZ(15);
  @$pb.TagNumber(16)
  set miniThumbMagic($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasMiniThumbMagic() => $_has(15);
  @$pb.TagNumber(16)
  void clearMiniThumbMagic() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.String get title => $_getSZ(16);
  @$pb.TagNumber(17)
  set title($core.String value) => $_setString(16, value);
  @$pb.TagNumber(17)
  $core.bool hasTitle() => $_has(16);
  @$pb.TagNumber(17)
  void clearTitle() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.bool get getThumbnailError => $_getBF(17);
  @$pb.TagNumber(18)
  set getThumbnailError($core.bool value) => $_setBool(17, value);
  @$pb.TagNumber(18)
  $core.bool hasGetThumbnailError() => $_has(17);
  @$pb.TagNumber(18)
  void clearGetThumbnailError() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.bool get starred => $_getBF(18);
  @$pb.TagNumber(19)
  set starred($core.bool value) => $_setBool(18, value);
  @$pb.TagNumber(19)
  $core.bool hasStarred() => $_has(18);
  @$pb.TagNumber(19)
  void clearStarred() => $_clearField(19);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:32
class SSPImageAlbum extends $pb.GeneratedMessage {
  factory SSPImageAlbum({
    $core.String? albumPath,
    $fixnum.Int64? albumId,
    $core.String? albumName,
    SSPImageFile? coverImage,
  }) {
    final result = SSPImageAlbum._();
    if (albumPath != null) result.albumPath = albumPath;
    if (albumId != null) result.albumId = albumId;
    if (albumName != null) result.albumName = albumName;
    if (coverImage != null) result.coverImage = coverImage;
    return result;
  }

  SSPImageAlbum._();

  factory SSPImageAlbum.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPImageAlbum()..mergeFromBuffer(data, registry);
  factory SSPImageAlbum.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPImageAlbum()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPImageAlbum',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPImageAlbum.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'albumPath', protoName: 'albumPath')
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'albumId', $pb.PbFieldType.OU6,
        protoName: 'albumId', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(3, _omitFieldNames ? '' : 'albumName', protoName: 'albumName')
    ..aOM<SSPImageFile>(4, _omitFieldNames ? '' : 'coverImage',
        protoName: 'coverImage', subBuilder: SSPImageFile.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPImageAlbum clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPImageAlbum copyWith(void Function(SSPImageAlbum) updates) =>
      super.copyWith((message) => updates(message as SSPImageAlbum))
          as SSPImageAlbum;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SSPImageAlbum() / SSPImageAlbum.new instead')
  static SSPImageAlbum create() => SSPImageAlbum._();
  static $pb.GeneratedMessage $_createMessage() => SSPImageAlbum._();
  @$core.override
  SSPImageAlbum createEmptyInstance() => SSPImageAlbum._();
  @$core.pragma('dart2js:noInline')
  static SSPImageAlbum getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SSPImageAlbum>(
          SSPImageAlbum.$_createMessage);
  static SSPImageAlbum? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get albumPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set albumPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAlbumPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearAlbumPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get albumId => $_getI64(1);
  @$pb.TagNumber(2)
  set albumId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAlbumId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAlbumId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get albumName => $_getSZ(2);
  @$pb.TagNumber(3)
  set albumName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAlbumName() => $_has(2);
  @$pb.TagNumber(3)
  void clearAlbumName() => $_clearField(3);

  @$pb.TagNumber(4)
  SSPImageFile get coverImage => $_getN(3);
  @$pb.TagNumber(4)
  set coverImage(SSPImageFile value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasCoverImage() => $_has(3);
  @$pb.TagNumber(4)
  void clearCoverImage() => $_clearField(4);
  @$pb.TagNumber(4)
  SSPImageFile ensureCoverImage() => $_ensure(3);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:37
class SSPAudioFile extends $pb.GeneratedMessage {
  factory SSPAudioFile({
    $core.String? path,
    $fixnum.Int64? fileSize,
    $fixnum.Int64? createdTimestamp,
    $fixnum.Int64? modifiedTimestamp,
    $fixnum.Int64? mediaId,
    $fixnum.Int64? albumId,
    $core.String? title,
    $core.String? mimeType,
    $fixnum.Int64? artistId,
    $core.String? artist,
    $core.String? composer,
    $core.int? genre,
    $core.String? comment,
    $core.String? copyright,
    $core.String? audioCodec,
    $core.int? track,
    $core.double? duration,
    $core.double? startOffset,
    $core.int? year,
    $core.int? bitrate,
    $core.double? sampleRate,
    $core.int? playCount,
    $core.double? rating,
    $core.int? totalFrames,
    $core.int? bitspersample,
    $core.int? channels,
    $core.String? genreName,
  }) {
    final result = SSPAudioFile._();
    if (path != null) result.path = path;
    if (fileSize != null) result.fileSize = fileSize;
    if (createdTimestamp != null) result.createdTimestamp = createdTimestamp;
    if (modifiedTimestamp != null) result.modifiedTimestamp = modifiedTimestamp;
    if (mediaId != null) result.mediaId = mediaId;
    if (albumId != null) result.albumId = albumId;
    if (title != null) result.title = title;
    if (mimeType != null) result.mimeType = mimeType;
    if (artistId != null) result.artistId = artistId;
    if (artist != null) result.artist = artist;
    if (composer != null) result.composer = composer;
    if (genre != null) result.genre = genre;
    if (comment != null) result.comment = comment;
    if (copyright != null) result.copyright = copyright;
    if (audioCodec != null) result.audioCodec = audioCodec;
    if (track != null) result.track = track;
    if (duration != null) result.duration = duration;
    if (startOffset != null) result.startOffset = startOffset;
    if (year != null) result.year = year;
    if (bitrate != null) result.bitrate = bitrate;
    if (sampleRate != null) result.sampleRate = sampleRate;
    if (playCount != null) result.playCount = playCount;
    if (rating != null) result.rating = rating;
    if (totalFrames != null) result.totalFrames = totalFrames;
    if (bitspersample != null) result.bitspersample = bitspersample;
    if (channels != null) result.channels = channels;
    if (genreName != null) result.genreName = genreName;
    return result;
  }

  SSPAudioFile._();

  factory SSPAudioFile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPAudioFile()..mergeFromBuffer(data, registry);
  factory SSPAudioFile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPAudioFile()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPAudioFile',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPAudioFile.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'fileSize', $pb.PbFieldType.OU6,
        protoName: 'fileSize', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'createdTimestamp', $pb.PbFieldType.OU6,
        protoName: 'createdTimestamp', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'modifiedTimestamp', $pb.PbFieldType.OU6,
        protoName: 'modifiedTimestamp', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(5, _omitFieldNames ? '' : 'mediaId', $pb.PbFieldType.OU6,
        protoName: 'mediaId', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(6, _omitFieldNames ? '' : 'albumId', $pb.PbFieldType.OU6,
        protoName: 'albumId', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(7, _omitFieldNames ? '' : 'title')
    ..aOS(8, _omitFieldNames ? '' : 'mimeType', protoName: 'mimeType')
    ..a<$fixnum.Int64>(
        9, _omitFieldNames ? '' : 'artistId', $pb.PbFieldType.OU6,
        protoName: 'artistId', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(10, _omitFieldNames ? '' : 'artist')
    ..aOS(11, _omitFieldNames ? '' : 'composer')
    ..aI(12, _omitFieldNames ? '' : 'genre', fieldType: $pb.PbFieldType.OU3)
    ..aOS(13, _omitFieldNames ? '' : 'comment')
    ..aOS(14, _omitFieldNames ? '' : 'copyright')
    ..aOS(15, _omitFieldNames ? '' : 'audioCodec', protoName: 'audioCodec')
    ..aI(16, _omitFieldNames ? '' : 'track', fieldType: $pb.PbFieldType.OU3)
    ..aD(17, _omitFieldNames ? '' : 'duration')
    ..aD(18, _omitFieldNames ? '' : 'startOffset', protoName: 'startOffset')
    ..aI(19, _omitFieldNames ? '' : 'year', fieldType: $pb.PbFieldType.OU3)
    ..aI(20, _omitFieldNames ? '' : 'bitrate', fieldType: $pb.PbFieldType.OU3)
    ..aD(21, _omitFieldNames ? '' : 'sampleRate', protoName: 'sampleRate')
    ..aI(22, _omitFieldNames ? '' : 'playCount',
        protoName: 'playCount', fieldType: $pb.PbFieldType.OU3)
    ..aD(23, _omitFieldNames ? '' : 'rating')
    ..aI(24, _omitFieldNames ? '' : 'totalFrames',
        protoName: 'totalFrames', fieldType: $pb.PbFieldType.OU3)
    ..aI(25, _omitFieldNames ? '' : 'bitspersample',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(26, _omitFieldNames ? '' : 'channels', fieldType: $pb.PbFieldType.OU3)
    ..aOS(27, _omitFieldNames ? '' : 'genreName', protoName: 'genreName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPAudioFile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPAudioFile copyWith(void Function(SSPAudioFile) updates) =>
      super.copyWith((message) => updates(message as SSPAudioFile))
          as SSPAudioFile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SSPAudioFile() / SSPAudioFile.new instead')
  static SSPAudioFile create() => SSPAudioFile._();
  static $pb.GeneratedMessage $_createMessage() => SSPAudioFile._();
  @$core.override
  SSPAudioFile createEmptyInstance() => SSPAudioFile._();
  @$core.pragma('dart2js:noInline')
  static SSPAudioFile getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SSPAudioFile>(
          SSPAudioFile.$_createMessage);
  static SSPAudioFile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get fileSize => $_getI64(1);
  @$pb.TagNumber(2)
  set fileSize($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFileSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearFileSize() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get createdTimestamp => $_getI64(2);
  @$pb.TagNumber(3)
  set createdTimestamp($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCreatedTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearCreatedTimestamp() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get modifiedTimestamp => $_getI64(3);
  @$pb.TagNumber(4)
  set modifiedTimestamp($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasModifiedTimestamp() => $_has(3);
  @$pb.TagNumber(4)
  void clearModifiedTimestamp() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get mediaId => $_getI64(4);
  @$pb.TagNumber(5)
  set mediaId($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMediaId() => $_has(4);
  @$pb.TagNumber(5)
  void clearMediaId() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get albumId => $_getI64(5);
  @$pb.TagNumber(6)
  set albumId($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAlbumId() => $_has(5);
  @$pb.TagNumber(6)
  void clearAlbumId() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get title => $_getSZ(6);
  @$pb.TagNumber(7)
  set title($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasTitle() => $_has(6);
  @$pb.TagNumber(7)
  void clearTitle() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get mimeType => $_getSZ(7);
  @$pb.TagNumber(8)
  set mimeType($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMimeType() => $_has(7);
  @$pb.TagNumber(8)
  void clearMimeType() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get artistId => $_getI64(8);
  @$pb.TagNumber(9)
  set artistId($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasArtistId() => $_has(8);
  @$pb.TagNumber(9)
  void clearArtistId() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get artist => $_getSZ(9);
  @$pb.TagNumber(10)
  set artist($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasArtist() => $_has(9);
  @$pb.TagNumber(10)
  void clearArtist() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get composer => $_getSZ(10);
  @$pb.TagNumber(11)
  set composer($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasComposer() => $_has(10);
  @$pb.TagNumber(11)
  void clearComposer() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get genre => $_getIZ(11);
  @$pb.TagNumber(12)
  set genre($core.int value) => $_setUnsignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasGenre() => $_has(11);
  @$pb.TagNumber(12)
  void clearGenre() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get comment => $_getSZ(12);
  @$pb.TagNumber(13)
  set comment($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasComment() => $_has(12);
  @$pb.TagNumber(13)
  void clearComment() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get copyright => $_getSZ(13);
  @$pb.TagNumber(14)
  set copyright($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasCopyright() => $_has(13);
  @$pb.TagNumber(14)
  void clearCopyright() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get audioCodec => $_getSZ(14);
  @$pb.TagNumber(15)
  set audioCodec($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasAudioCodec() => $_has(14);
  @$pb.TagNumber(15)
  void clearAudioCodec() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.int get track => $_getIZ(15);
  @$pb.TagNumber(16)
  set track($core.int value) => $_setUnsignedInt32(15, value);
  @$pb.TagNumber(16)
  $core.bool hasTrack() => $_has(15);
  @$pb.TagNumber(16)
  void clearTrack() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.double get duration => $_getN(16);
  @$pb.TagNumber(17)
  set duration($core.double value) => $_setDouble(16, value);
  @$pb.TagNumber(17)
  $core.bool hasDuration() => $_has(16);
  @$pb.TagNumber(17)
  void clearDuration() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.double get startOffset => $_getN(17);
  @$pb.TagNumber(18)
  set startOffset($core.double value) => $_setDouble(17, value);
  @$pb.TagNumber(18)
  $core.bool hasStartOffset() => $_has(17);
  @$pb.TagNumber(18)
  void clearStartOffset() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.int get year => $_getIZ(18);
  @$pb.TagNumber(19)
  set year($core.int value) => $_setUnsignedInt32(18, value);
  @$pb.TagNumber(19)
  $core.bool hasYear() => $_has(18);
  @$pb.TagNumber(19)
  void clearYear() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.int get bitrate => $_getIZ(19);
  @$pb.TagNumber(20)
  set bitrate($core.int value) => $_setUnsignedInt32(19, value);
  @$pb.TagNumber(20)
  $core.bool hasBitrate() => $_has(19);
  @$pb.TagNumber(20)
  void clearBitrate() => $_clearField(20);

  @$pb.TagNumber(21)
  $core.double get sampleRate => $_getN(20);
  @$pb.TagNumber(21)
  set sampleRate($core.double value) => $_setDouble(20, value);
  @$pb.TagNumber(21)
  $core.bool hasSampleRate() => $_has(20);
  @$pb.TagNumber(21)
  void clearSampleRate() => $_clearField(21);

  @$pb.TagNumber(22)
  $core.int get playCount => $_getIZ(21);
  @$pb.TagNumber(22)
  set playCount($core.int value) => $_setUnsignedInt32(21, value);
  @$pb.TagNumber(22)
  $core.bool hasPlayCount() => $_has(21);
  @$pb.TagNumber(22)
  void clearPlayCount() => $_clearField(22);

  @$pb.TagNumber(23)
  $core.double get rating => $_getN(22);
  @$pb.TagNumber(23)
  set rating($core.double value) => $_setDouble(22, value);
  @$pb.TagNumber(23)
  $core.bool hasRating() => $_has(22);
  @$pb.TagNumber(23)
  void clearRating() => $_clearField(23);

  @$pb.TagNumber(24)
  $core.int get totalFrames => $_getIZ(23);
  @$pb.TagNumber(24)
  set totalFrames($core.int value) => $_setUnsignedInt32(23, value);
  @$pb.TagNumber(24)
  $core.bool hasTotalFrames() => $_has(23);
  @$pb.TagNumber(24)
  void clearTotalFrames() => $_clearField(24);

  @$pb.TagNumber(25)
  $core.int get bitspersample => $_getIZ(24);
  @$pb.TagNumber(25)
  set bitspersample($core.int value) => $_setUnsignedInt32(24, value);
  @$pb.TagNumber(25)
  $core.bool hasBitspersample() => $_has(24);
  @$pb.TagNumber(25)
  void clearBitspersample() => $_clearField(25);

  @$pb.TagNumber(26)
  $core.int get channels => $_getIZ(25);
  @$pb.TagNumber(26)
  set channels($core.int value) => $_setUnsignedInt32(25, value);
  @$pb.TagNumber(26)
  $core.bool hasChannels() => $_has(25);
  @$pb.TagNumber(26)
  void clearChannels() => $_clearField(26);

  @$pb.TagNumber(27)
  $core.String get genreName => $_getSZ(26);
  @$pb.TagNumber(27)
  set genreName($core.String value) => $_setString(26, value);
  @$pb.TagNumber(27)
  $core.bool hasGenreName() => $_has(26);
  @$pb.TagNumber(27)
  void clearGenreName() => $_clearField(27);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:65
class SSPAudioAlbum extends $pb.GeneratedMessage {
  factory SSPAudioAlbum({
    $core.String? albumPath,
    $fixnum.Int64? albumId,
    $core.String? albumName,
    $fixnum.Int64? artistId,
    $core.String? artist,
    $core.int? year,
    $core.List<$core.int>? thumbnail,
    $core.bool? getThumbnailError,
  }) {
    final result = SSPAudioAlbum._();
    if (albumPath != null) result.albumPath = albumPath;
    if (albumId != null) result.albumId = albumId;
    if (albumName != null) result.albumName = albumName;
    if (artistId != null) result.artistId = artistId;
    if (artist != null) result.artist = artist;
    if (year != null) result.year = year;
    if (thumbnail != null) result.thumbnail = thumbnail;
    if (getThumbnailError != null) result.getThumbnailError = getThumbnailError;
    return result;
  }

  SSPAudioAlbum._();

  factory SSPAudioAlbum.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPAudioAlbum()..mergeFromBuffer(data, registry);
  factory SSPAudioAlbum.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPAudioAlbum()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPAudioAlbum',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPAudioAlbum.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'albumPath', protoName: 'albumPath')
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'albumId', $pb.PbFieldType.OU6,
        protoName: 'albumId', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(3, _omitFieldNames ? '' : 'albumName', protoName: 'albumName')
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'artistId', $pb.PbFieldType.OU6,
        protoName: 'artistId', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(5, _omitFieldNames ? '' : 'artist')
    ..aI(6, _omitFieldNames ? '' : 'year', fieldType: $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        7, _omitFieldNames ? '' : 'thumbnail', $pb.PbFieldType.OY)
    ..aOB(8, _omitFieldNames ? '' : 'getThumbnailError',
        protoName: 'getThumbnailError')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPAudioAlbum clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPAudioAlbum copyWith(void Function(SSPAudioAlbum) updates) =>
      super.copyWith((message) => updates(message as SSPAudioAlbum))
          as SSPAudioAlbum;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SSPAudioAlbum() / SSPAudioAlbum.new instead')
  static SSPAudioAlbum create() => SSPAudioAlbum._();
  static $pb.GeneratedMessage $_createMessage() => SSPAudioAlbum._();
  @$core.override
  SSPAudioAlbum createEmptyInstance() => SSPAudioAlbum._();
  @$core.pragma('dart2js:noInline')
  static SSPAudioAlbum getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SSPAudioAlbum>(
          SSPAudioAlbum.$_createMessage);
  static SSPAudioAlbum? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get albumPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set albumPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAlbumPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearAlbumPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get albumId => $_getI64(1);
  @$pb.TagNumber(2)
  set albumId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAlbumId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAlbumId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get albumName => $_getSZ(2);
  @$pb.TagNumber(3)
  set albumName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAlbumName() => $_has(2);
  @$pb.TagNumber(3)
  void clearAlbumName() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get artistId => $_getI64(3);
  @$pb.TagNumber(4)
  set artistId($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasArtistId() => $_has(3);
  @$pb.TagNumber(4)
  void clearArtistId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get artist => $_getSZ(4);
  @$pb.TagNumber(5)
  set artist($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasArtist() => $_has(4);
  @$pb.TagNumber(5)
  void clearArtist() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get year => $_getIZ(5);
  @$pb.TagNumber(6)
  set year($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasYear() => $_has(5);
  @$pb.TagNumber(6)
  void clearYear() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.List<$core.int> get thumbnail => $_getN(6);
  @$pb.TagNumber(7)
  set thumbnail($core.List<$core.int> value) => $_setBytes(6, value);
  @$pb.TagNumber(7)
  $core.bool hasThumbnail() => $_has(6);
  @$pb.TagNumber(7)
  void clearThumbnail() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get getThumbnailError => $_getBF(7);
  @$pb.TagNumber(8)
  set getThumbnailError($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasGetThumbnailError() => $_has(7);
  @$pb.TagNumber(8)
  void clearGetThumbnailError() => $_clearField(8);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:74
class SSPVideoFile extends $pb.GeneratedMessage {
  factory SSPVideoFile({
    $core.String? path,
    $fixnum.Int64? fileSize,
    $core.int? createdTimestamp,
    $core.int? modifiedTimestamp,
    $core.int? width,
    $core.int? height,
    $core.int? orientation,
    $fixnum.Int64? mediaId,
    $fixnum.Int64? albumId,
    $core.String? mimeType,
    $core.List<$core.int>? thumbnail,
    $core.bool? getThumbnailError,
    $core.double? duration,
  }) {
    final result = SSPVideoFile._();
    if (path != null) result.path = path;
    if (fileSize != null) result.fileSize = fileSize;
    if (createdTimestamp != null) result.createdTimestamp = createdTimestamp;
    if (modifiedTimestamp != null) result.modifiedTimestamp = modifiedTimestamp;
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    if (orientation != null) result.orientation = orientation;
    if (mediaId != null) result.mediaId = mediaId;
    if (albumId != null) result.albumId = albumId;
    if (mimeType != null) result.mimeType = mimeType;
    if (thumbnail != null) result.thumbnail = thumbnail;
    if (getThumbnailError != null) result.getThumbnailError = getThumbnailError;
    if (duration != null) result.duration = duration;
    return result;
  }

  SSPVideoFile._();

  factory SSPVideoFile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPVideoFile()..mergeFromBuffer(data, registry);
  factory SSPVideoFile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPVideoFile()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPVideoFile',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPVideoFile.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'fileSize', $pb.PbFieldType.OU6,
        protoName: 'fileSize', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(3, _omitFieldNames ? '' : 'createdTimestamp',
        protoName: 'createdTimestamp', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'modifiedTimestamp',
        protoName: 'modifiedTimestamp', fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'width', fieldType: $pb.PbFieldType.OU3)
    ..aI(6, _omitFieldNames ? '' : 'height', fieldType: $pb.PbFieldType.OU3)
    ..aI(7, _omitFieldNames ? '' : 'orientation',
        fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(8, _omitFieldNames ? '' : 'mediaId', $pb.PbFieldType.OU6,
        protoName: 'mediaId', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(9, _omitFieldNames ? '' : 'albumId', $pb.PbFieldType.OU6,
        protoName: 'albumId', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(10, _omitFieldNames ? '' : 'mimeType', protoName: 'mimeType')
    ..a<$core.List<$core.int>>(
        11, _omitFieldNames ? '' : 'thumbnail', $pb.PbFieldType.OY)
    ..aOB(12, _omitFieldNames ? '' : 'getThumbnailError',
        protoName: 'getThumbnailError')
    ..aD(13, _omitFieldNames ? '' : 'duration')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPVideoFile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPVideoFile copyWith(void Function(SSPVideoFile) updates) =>
      super.copyWith((message) => updates(message as SSPVideoFile))
          as SSPVideoFile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SSPVideoFile() / SSPVideoFile.new instead')
  static SSPVideoFile create() => SSPVideoFile._();
  static $pb.GeneratedMessage $_createMessage() => SSPVideoFile._();
  @$core.override
  SSPVideoFile createEmptyInstance() => SSPVideoFile._();
  @$core.pragma('dart2js:noInline')
  static SSPVideoFile getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SSPVideoFile>(
          SSPVideoFile.$_createMessage);
  static SSPVideoFile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get fileSize => $_getI64(1);
  @$pb.TagNumber(2)
  set fileSize($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFileSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearFileSize() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get createdTimestamp => $_getIZ(2);
  @$pb.TagNumber(3)
  set createdTimestamp($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCreatedTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearCreatedTimestamp() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get modifiedTimestamp => $_getIZ(3);
  @$pb.TagNumber(4)
  set modifiedTimestamp($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasModifiedTimestamp() => $_has(3);
  @$pb.TagNumber(4)
  void clearModifiedTimestamp() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get width => $_getIZ(4);
  @$pb.TagNumber(5)
  set width($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasWidth() => $_has(4);
  @$pb.TagNumber(5)
  void clearWidth() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get height => $_getIZ(5);
  @$pb.TagNumber(6)
  set height($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasHeight() => $_has(5);
  @$pb.TagNumber(6)
  void clearHeight() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get orientation => $_getIZ(6);
  @$pb.TagNumber(7)
  set orientation($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasOrientation() => $_has(6);
  @$pb.TagNumber(7)
  void clearOrientation() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get mediaId => $_getI64(7);
  @$pb.TagNumber(8)
  set mediaId($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMediaId() => $_has(7);
  @$pb.TagNumber(8)
  void clearMediaId() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get albumId => $_getI64(8);
  @$pb.TagNumber(9)
  set albumId($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasAlbumId() => $_has(8);
  @$pb.TagNumber(9)
  void clearAlbumId() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get mimeType => $_getSZ(9);
  @$pb.TagNumber(10)
  set mimeType($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasMimeType() => $_has(9);
  @$pb.TagNumber(10)
  void clearMimeType() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.List<$core.int> get thumbnail => $_getN(10);
  @$pb.TagNumber(11)
  set thumbnail($core.List<$core.int> value) => $_setBytes(10, value);
  @$pb.TagNumber(11)
  $core.bool hasThumbnail() => $_has(10);
  @$pb.TagNumber(11)
  void clearThumbnail() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.bool get getThumbnailError => $_getBF(11);
  @$pb.TagNumber(12)
  set getThumbnailError($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasGetThumbnailError() => $_has(11);
  @$pb.TagNumber(12)
  void clearGetThumbnailError() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.double get duration => $_getN(12);
  @$pb.TagNumber(13)
  set duration($core.double value) => $_setDouble(12, value);
  @$pb.TagNumber(13)
  $core.bool hasDuration() => $_has(12);
  @$pb.TagNumber(13)
  void clearDuration() => $_clearField(13);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:88
class SSPVideoAlbum extends $pb.GeneratedMessage {
  factory SSPVideoAlbum({
    $core.String? albumPath,
    $fixnum.Int64? albumId,
    $core.String? albumName,
  }) {
    final result = SSPVideoAlbum._();
    if (albumPath != null) result.albumPath = albumPath;
    if (albumId != null) result.albumId = albumId;
    if (albumName != null) result.albumName = albumName;
    return result;
  }

  SSPVideoAlbum._();

  factory SSPVideoAlbum.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPVideoAlbum()..mergeFromBuffer(data, registry);
  factory SSPVideoAlbum.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPVideoAlbum()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPVideoAlbum',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPVideoAlbum.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'albumPath', protoName: 'albumPath')
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'albumId', $pb.PbFieldType.OU6,
        protoName: 'albumId', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(3, _omitFieldNames ? '' : 'albumName', protoName: 'albumName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPVideoAlbum clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPVideoAlbum copyWith(void Function(SSPVideoAlbum) updates) =>
      super.copyWith((message) => updates(message as SSPVideoAlbum))
          as SSPVideoAlbum;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SSPVideoAlbum() / SSPVideoAlbum.new instead')
  static SSPVideoAlbum create() => SSPVideoAlbum._();
  static $pb.GeneratedMessage $_createMessage() => SSPVideoAlbum._();
  @$core.override
  SSPVideoAlbum createEmptyInstance() => SSPVideoAlbum._();
  @$core.pragma('dart2js:noInline')
  static SSPVideoAlbum getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SSPVideoAlbum>(
          SSPVideoAlbum.$_createMessage);
  static SSPVideoAlbum? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get albumPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set albumPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAlbumPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearAlbumPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get albumId => $_getI64(1);
  @$pb.TagNumber(2)
  set albumId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAlbumId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAlbumId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get albumName => $_getSZ(2);
  @$pb.TagNumber(3)
  set albumName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAlbumName() => $_has(2);
  @$pb.TagNumber(3)
  void clearAlbumName() => $_clearField(3);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:92
class SSPDataRange extends $pb.GeneratedMessage {
  factory SSPDataRange({
    $fixnum.Int64? offset,
    $fixnum.Int64? length,
  }) {
    final result = SSPDataRange._();
    if (offset != null) result.offset = offset;
    if (length != null) result.length = length;
    return result;
  }

  SSPDataRange._();

  factory SSPDataRange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPDataRange()..mergeFromBuffer(data, registry);
  factory SSPDataRange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPDataRange()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPDataRange',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPDataRange.$_createMessage)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'offset', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'length', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPDataRange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPDataRange copyWith(void Function(SSPDataRange) updates) =>
      super.copyWith((message) => updates(message as SSPDataRange))
          as SSPDataRange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SSPDataRange() / SSPDataRange.new instead')
  static SSPDataRange create() => SSPDataRange._();
  static $pb.GeneratedMessage $_createMessage() => SSPDataRange._();
  @$core.override
  SSPDataRange createEmptyInstance() => SSPDataRange._();
  @$core.pragma('dart2js:noInline')
  static SSPDataRange getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SSPDataRange>(
          SSPDataRange.$_createMessage);
  static SSPDataRange? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get offset => $_getI64(0);
  @$pb.TagNumber(1)
  set offset($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOffset() => $_has(0);
  @$pb.TagNumber(1)
  void clearOffset() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get length => $_getI64(1);
  @$pb.TagNumber(2)
  set length($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLength() => $_has(1);
  @$pb.TagNumber(2)
  void clearLength() => $_clearField(2);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:95
class SSPFileEvent extends $pb.GeneratedMessage {
  factory SSPFileEvent({
    SSPFile? file,
    SSPFileEventType? event,
  }) {
    final result = SSPFileEvent._();
    if (file != null) result.file = file;
    if (event != null) result.event = event;
    return result;
  }

  SSPFileEvent._();

  factory SSPFileEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPFileEvent()..mergeFromBuffer(data, registry);
  factory SSPFileEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPFileEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPFileEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPFileEvent.$_createMessage)
    ..aOM<SSPFile>(1, _omitFieldNames ? '' : 'file',
        subBuilder: SSPFile.$_createMessage)
    ..aE<SSPFileEventType>(2, _omitFieldNames ? '' : 'event',
        enumValues: SSPFileEventType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPFileEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPFileEvent copyWith(void Function(SSPFileEvent) updates) =>
      super.copyWith((message) => updates(message as SSPFileEvent))
          as SSPFileEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SSPFileEvent() / SSPFileEvent.new instead')
  static SSPFileEvent create() => SSPFileEvent._();
  static $pb.GeneratedMessage $_createMessage() => SSPFileEvent._();
  @$core.override
  SSPFileEvent createEmptyInstance() => SSPFileEvent._();
  @$core.pragma('dart2js:noInline')
  static SSPFileEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SSPFileEvent>(
          SSPFileEvent.$_createMessage);
  static SSPFileEvent? _defaultInstance;

  @$pb.TagNumber(1)
  SSPFile get file => $_getN(0);
  @$pb.TagNumber(1)
  set file(SSPFile value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasFile() => $_has(0);
  @$pb.TagNumber(1)
  void clearFile() => $_clearField(1);
  @$pb.TagNumber(1)
  SSPFile ensureFile() => $_ensure(0);

  @$pb.TagNumber(2)
  SSPFileEventType get event => $_getN(1);
  @$pb.TagNumber(2)
  set event(SSPFileEventType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasEvent() => $_has(1);
  @$pb.TagNumber(2)
  void clearEvent() => $_clearField(2);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:98
class SSPRequest extends $pb.GeneratedMessage {
  factory SSPRequest({
    SSPRequestType? type,
  }) {
    final result = SSPRequest._();
    if (type != null) result.type = type;
    return result;
  }

  SSPRequest._();

  factory SSPRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPRequest()..mergeFromBuffer(data, registry);
  factory SSPRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        enumValues: SSPRequestType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPRequest copyWith(void Function(SSPRequest) updates) =>
      super.copyWith((message) => updates(message as SSPRequest)) as SSPRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SSPRequest() / SSPRequest.new instead')
  static SSPRequest create() => SSPRequest._();
  static $pb.GeneratedMessage $_createMessage() => SSPRequest._();
  @$core.override
  SSPRequest createEmptyInstance() => SSPRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPRequest>(SSPRequest.$_createMessage);
  static SSPRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:100
class SSPHandShakeRequest01 extends $pb.GeneratedMessage {
  factory SSPHandShakeRequest01({
    SSPRequestType? type,
    $core.String? hostUuid,
    $core.String? hostName,
    $fixnum.Int64? hostTimestamp,
    $core.String? hostSmartSyncProtocolVersion,
    $core.String? hostAppVersion,
    $core.String? hostMinClientVersion,
    $core.List<$core.int>? md5,
    $core.List<$core.int>? enckey,
    $core.String? hostModel,
    $fixnum.Int64? heartbeatTimeoutSecond,
  }) {
    final result = SSPHandShakeRequest01._();
    if (type != null) result.type = type;
    if (hostUuid != null) result.hostUuid = hostUuid;
    if (hostName != null) result.hostName = hostName;
    if (hostTimestamp != null) result.hostTimestamp = hostTimestamp;
    if (hostSmartSyncProtocolVersion != null)
      result.hostSmartSyncProtocolVersion = hostSmartSyncProtocolVersion;
    if (hostAppVersion != null) result.hostAppVersion = hostAppVersion;
    if (hostMinClientVersion != null)
      result.hostMinClientVersion = hostMinClientVersion;
    if (md5 != null) result.md5 = md5;
    if (enckey != null) result.enckey = enckey;
    if (hostModel != null) result.hostModel = hostModel;
    if (heartbeatTimeoutSecond != null)
      result.heartbeatTimeoutSecond = heartbeatTimeoutSecond;
    return result;
  }

  SSPHandShakeRequest01._();

  factory SSPHandShakeRequest01.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPHandShakeRequest01()..mergeFromBuffer(data, registry);
  factory SSPHandShakeRequest01.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPHandShakeRequest01()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPHandShakeRequest01',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPHandShakeRequest01.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_HandshakeRequest01,
        enumValues: SSPRequestType.values)
    ..aOS(2, _omitFieldNames ? '' : 'hostUuid', protoName: 'hostUuid')
    ..aOS(3, _omitFieldNames ? '' : 'hostName', protoName: 'hostName')
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'hostTimestamp', $pb.PbFieldType.OU6,
        protoName: 'hostTimestamp', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(5, _omitFieldNames ? '' : 'hostSmartSyncProtocolVersion',
        protoName: 'hostSmartSyncProtocolVersion')
    ..aOS(6, _omitFieldNames ? '' : 'hostAppVersion',
        protoName: 'hostAppVersion')
    ..aOS(7, _omitFieldNames ? '' : 'hostMinClientVersion',
        protoName: 'hostMinClientVersion')
    ..a<$core.List<$core.int>>(
        8, _omitFieldNames ? '' : 'md5', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        9, _omitFieldNames ? '' : 'enckey', $pb.PbFieldType.OY)
    ..aOS(10, _omitFieldNames ? '' : 'hostModel', protoName: 'hostModel')
    ..a<$fixnum.Int64>(11, _omitFieldNames ? '' : 'heartbeatTimeoutSecond',
        $pb.PbFieldType.OU6,
        protoName: 'heartbeatTimeoutSecond', defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPHandShakeRequest01 clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPHandShakeRequest01 copyWith(
          void Function(SSPHandShakeRequest01) updates) =>
      super.copyWith((message) => updates(message as SSPHandShakeRequest01))
          as SSPHandShakeRequest01;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPHandShakeRequest01() / SSPHandShakeRequest01.new instead')
  static SSPHandShakeRequest01 create() => SSPHandShakeRequest01._();
  static $pb.GeneratedMessage $_createMessage() => SSPHandShakeRequest01._();
  @$core.override
  SSPHandShakeRequest01 createEmptyInstance() => SSPHandShakeRequest01._();
  @$core.pragma('dart2js:noInline')
  static SSPHandShakeRequest01 getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPHandShakeRequest01>(
          SSPHandShakeRequest01.$_createMessage);
  static SSPHandShakeRequest01? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get hostUuid => $_getSZ(1);
  @$pb.TagNumber(2)
  set hostUuid($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHostUuid() => $_has(1);
  @$pb.TagNumber(2)
  void clearHostUuid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get hostName => $_getSZ(2);
  @$pb.TagNumber(3)
  set hostName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHostName() => $_has(2);
  @$pb.TagNumber(3)
  void clearHostName() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get hostTimestamp => $_getI64(3);
  @$pb.TagNumber(4)
  set hostTimestamp($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHostTimestamp() => $_has(3);
  @$pb.TagNumber(4)
  void clearHostTimestamp() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get hostSmartSyncProtocolVersion => $_getSZ(4);
  @$pb.TagNumber(5)
  set hostSmartSyncProtocolVersion($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasHostSmartSyncProtocolVersion() => $_has(4);
  @$pb.TagNumber(5)
  void clearHostSmartSyncProtocolVersion() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get hostAppVersion => $_getSZ(5);
  @$pb.TagNumber(6)
  set hostAppVersion($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasHostAppVersion() => $_has(5);
  @$pb.TagNumber(6)
  void clearHostAppVersion() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get hostMinClientVersion => $_getSZ(6);
  @$pb.TagNumber(7)
  set hostMinClientVersion($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasHostMinClientVersion() => $_has(6);
  @$pb.TagNumber(7)
  void clearHostMinClientVersion() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.List<$core.int> get md5 => $_getN(7);
  @$pb.TagNumber(8)
  set md5($core.List<$core.int> value) => $_setBytes(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMd5() => $_has(7);
  @$pb.TagNumber(8)
  void clearMd5() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.List<$core.int> get enckey => $_getN(8);
  @$pb.TagNumber(9)
  set enckey($core.List<$core.int> value) => $_setBytes(8, value);
  @$pb.TagNumber(9)
  $core.bool hasEnckey() => $_has(8);
  @$pb.TagNumber(9)
  void clearEnckey() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get hostModel => $_getSZ(9);
  @$pb.TagNumber(10)
  set hostModel($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasHostModel() => $_has(9);
  @$pb.TagNumber(10)
  void clearHostModel() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get heartbeatTimeoutSecond => $_getI64(10);
  @$pb.TagNumber(11)
  set heartbeatTimeoutSecond($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasHeartbeatTimeoutSecond() => $_has(10);
  @$pb.TagNumber(11)
  void clearHeartbeatTimeoutSecond() => $_clearField(11);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:112
class SSPHandShakeResponse01 extends $pb.GeneratedMessage {
  factory SSPHandShakeResponse01({
    SSPRequestType? type,
    $core.String? apkVersion,
    $core.String? apkVersionName,
    $fixnum.Int64? clientTimestamp,
    $core.String? clientSmartSyncProtocolVersion,
    $core.String? clientMinHostVersion,
    $core.String? deviceUuid,
    $core.String? deviceName,
    $core.String? usbSerial,
    $core.bool? isSmartisanDevice,
    $fixnum.Int64? clientMinHostVersionCode,
  }) {
    final result = SSPHandShakeResponse01._();
    if (type != null) result.type = type;
    if (apkVersion != null) result.apkVersion = apkVersion;
    if (apkVersionName != null) result.apkVersionName = apkVersionName;
    if (clientTimestamp != null) result.clientTimestamp = clientTimestamp;
    if (clientSmartSyncProtocolVersion != null)
      result.clientSmartSyncProtocolVersion = clientSmartSyncProtocolVersion;
    if (clientMinHostVersion != null)
      result.clientMinHostVersion = clientMinHostVersion;
    if (deviceUuid != null) result.deviceUuid = deviceUuid;
    if (deviceName != null) result.deviceName = deviceName;
    if (usbSerial != null) result.usbSerial = usbSerial;
    if (isSmartisanDevice != null) result.isSmartisanDevice = isSmartisanDevice;
    if (clientMinHostVersionCode != null)
      result.clientMinHostVersionCode = clientMinHostVersionCode;
    return result;
  }

  SSPHandShakeResponse01._();

  factory SSPHandShakeResponse01.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPHandShakeResponse01()..mergeFromBuffer(data, registry);
  factory SSPHandShakeResponse01.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPHandShakeResponse01()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPHandShakeResponse01',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPHandShakeResponse01.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_HandshakeResponse01,
        enumValues: SSPRequestType.values)
    ..aOS(2, _omitFieldNames ? '' : 'apkVersion', protoName: 'apkVersion')
    ..aOS(3, _omitFieldNames ? '' : 'apkVersionName',
        protoName: 'apkVersionName')
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'clientTimestamp', $pb.PbFieldType.OU6,
        protoName: 'clientTimestamp', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(5, _omitFieldNames ? '' : 'clientSmartSyncProtocolVersion',
        protoName: 'clientSmartSyncProtocolVersion')
    ..aOS(6, _omitFieldNames ? '' : 'clientMinHostVersion',
        protoName: 'clientMinHostVersion')
    ..aOS(7, _omitFieldNames ? '' : 'deviceUuid', protoName: 'deviceUuid')
    ..aOS(8, _omitFieldNames ? '' : 'deviceName', protoName: 'deviceName')
    ..aOS(9, _omitFieldNames ? '' : 'usbSerial', protoName: 'usbSerial')
    ..aOB(10, _omitFieldNames ? '' : 'isSmartisanDevice',
        protoName: 'isSmartisanDevice')
    ..a<$fixnum.Int64>(11, _omitFieldNames ? '' : 'clientMinHostVersionCode',
        $pb.PbFieldType.OU6,
        protoName: 'clientMinHostVersionCode',
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPHandShakeResponse01 clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPHandShakeResponse01 copyWith(
          void Function(SSPHandShakeResponse01) updates) =>
      super.copyWith((message) => updates(message as SSPHandShakeResponse01))
          as SSPHandShakeResponse01;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPHandShakeResponse01() / SSPHandShakeResponse01.new instead')
  static SSPHandShakeResponse01 create() => SSPHandShakeResponse01._();
  static $pb.GeneratedMessage $_createMessage() => SSPHandShakeResponse01._();
  @$core.override
  SSPHandShakeResponse01 createEmptyInstance() => SSPHandShakeResponse01._();
  @$core.pragma('dart2js:noInline')
  static SSPHandShakeResponse01 getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPHandShakeResponse01>(
          SSPHandShakeResponse01.$_createMessage);
  static SSPHandShakeResponse01? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get apkVersion => $_getSZ(1);
  @$pb.TagNumber(2)
  set apkVersion($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasApkVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearApkVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get apkVersionName => $_getSZ(2);
  @$pb.TagNumber(3)
  set apkVersionName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasApkVersionName() => $_has(2);
  @$pb.TagNumber(3)
  void clearApkVersionName() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get clientTimestamp => $_getI64(3);
  @$pb.TagNumber(4)
  set clientTimestamp($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasClientTimestamp() => $_has(3);
  @$pb.TagNumber(4)
  void clearClientTimestamp() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get clientSmartSyncProtocolVersion => $_getSZ(4);
  @$pb.TagNumber(5)
  set clientSmartSyncProtocolVersion($core.String value) =>
      $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasClientSmartSyncProtocolVersion() => $_has(4);
  @$pb.TagNumber(5)
  void clearClientSmartSyncProtocolVersion() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get clientMinHostVersion => $_getSZ(5);
  @$pb.TagNumber(6)
  set clientMinHostVersion($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasClientMinHostVersion() => $_has(5);
  @$pb.TagNumber(6)
  void clearClientMinHostVersion() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get deviceUuid => $_getSZ(6);
  @$pb.TagNumber(7)
  set deviceUuid($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDeviceUuid() => $_has(6);
  @$pb.TagNumber(7)
  void clearDeviceUuid() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get deviceName => $_getSZ(7);
  @$pb.TagNumber(8)
  set deviceName($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDeviceName() => $_has(7);
  @$pb.TagNumber(8)
  void clearDeviceName() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get usbSerial => $_getSZ(8);
  @$pb.TagNumber(9)
  set usbSerial($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasUsbSerial() => $_has(8);
  @$pb.TagNumber(9)
  void clearUsbSerial() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get isSmartisanDevice => $_getBF(9);
  @$pb.TagNumber(10)
  set isSmartisanDevice($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasIsSmartisanDevice() => $_has(9);
  @$pb.TagNumber(10)
  void clearIsSmartisanDevice() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get clientMinHostVersionCode => $_getI64(10);
  @$pb.TagNumber(11)
  set clientMinHostVersionCode($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasClientMinHostVersionCode() => $_has(10);
  @$pb.TagNumber(11)
  void clearClientMinHostVersionCode() => $_clearField(11);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:124
class SSPHandShakeRequest02 extends $pb.GeneratedMessage {
  factory SSPHandShakeRequest02({
    SSPRequestType? type,
    $core.String? hostUuid,
    $core.List<$core.int>? derivedKey,
    SSPHandShakeTrustType? trustType,
  }) {
    final result = SSPHandShakeRequest02._();
    if (type != null) result.type = type;
    if (hostUuid != null) result.hostUuid = hostUuid;
    if (derivedKey != null) result.derivedKey = derivedKey;
    if (trustType != null) result.trustType = trustType;
    return result;
  }

  SSPHandShakeRequest02._();

  factory SSPHandShakeRequest02.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPHandShakeRequest02()..mergeFromBuffer(data, registry);
  factory SSPHandShakeRequest02.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPHandShakeRequest02()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPHandShakeRequest02',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPHandShakeRequest02.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_HandshakeRequest02,
        enumValues: SSPRequestType.values)
    ..aOS(2, _omitFieldNames ? '' : 'hostUuid', protoName: 'hostUuid')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'derivedKey', $pb.PbFieldType.OY,
        protoName: 'derivedKey')
    ..aE<SSPHandShakeTrustType>(4, _omitFieldNames ? '' : 'trustType',
        protoName: 'trustType', enumValues: SSPHandShakeTrustType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPHandShakeRequest02 clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPHandShakeRequest02 copyWith(
          void Function(SSPHandShakeRequest02) updates) =>
      super.copyWith((message) => updates(message as SSPHandShakeRequest02))
          as SSPHandShakeRequest02;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPHandShakeRequest02() / SSPHandShakeRequest02.new instead')
  static SSPHandShakeRequest02 create() => SSPHandShakeRequest02._();
  static $pb.GeneratedMessage $_createMessage() => SSPHandShakeRequest02._();
  @$core.override
  SSPHandShakeRequest02 createEmptyInstance() => SSPHandShakeRequest02._();
  @$core.pragma('dart2js:noInline')
  static SSPHandShakeRequest02 getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPHandShakeRequest02>(
          SSPHandShakeRequest02.$_createMessage);
  static SSPHandShakeRequest02? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get hostUuid => $_getSZ(1);
  @$pb.TagNumber(2)
  set hostUuid($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHostUuid() => $_has(1);
  @$pb.TagNumber(2)
  void clearHostUuid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get derivedKey => $_getN(2);
  @$pb.TagNumber(3)
  set derivedKey($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDerivedKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearDerivedKey() => $_clearField(3);

  @$pb.TagNumber(4)
  SSPHandShakeTrustType get trustType => $_getN(3);
  @$pb.TagNumber(4)
  set trustType(SSPHandShakeTrustType value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasTrustType() => $_has(3);
  @$pb.TagNumber(4)
  void clearTrustType() => $_clearField(4);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:129
class SSPHandShakeResponse02 extends $pb.GeneratedMessage {
  factory SSPHandShakeResponse02({
    SSPRequestType? type,
    SSPHandShakeTrustType? trustType,
    $core.String? deviceUuid,
    $core.String? deviceName,
    $core.List<$core.int>? derivedKey,
    $core.String? result,
  }) {
    final result$ = SSPHandShakeResponse02._();
    if (type != null) result$.type = type;
    if (trustType != null) result$.trustType = trustType;
    if (deviceUuid != null) result$.deviceUuid = deviceUuid;
    if (deviceName != null) result$.deviceName = deviceName;
    if (derivedKey != null) result$.derivedKey = derivedKey;
    if (result != null) result$.result = result;
    return result$;
  }

  SSPHandShakeResponse02._();

  factory SSPHandShakeResponse02.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPHandShakeResponse02()..mergeFromBuffer(data, registry);
  factory SSPHandShakeResponse02.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPHandShakeResponse02()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPHandShakeResponse02',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPHandShakeResponse02.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_HandshakeResponse02,
        enumValues: SSPRequestType.values)
    ..aE<SSPHandShakeTrustType>(2, _omitFieldNames ? '' : 'trustType',
        protoName: 'trustType', enumValues: SSPHandShakeTrustType.values)
    ..aOS(3, _omitFieldNames ? '' : 'deviceUuid', protoName: 'deviceUuid')
    ..aOS(4, _omitFieldNames ? '' : 'deviceName', protoName: 'deviceName')
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'derivedKey', $pb.PbFieldType.OY,
        protoName: 'derivedKey')
    ..aOS(6, _omitFieldNames ? '' : 'result')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPHandShakeResponse02 clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPHandShakeResponse02 copyWith(
          void Function(SSPHandShakeResponse02) updates) =>
      super.copyWith((message) => updates(message as SSPHandShakeResponse02))
          as SSPHandShakeResponse02;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPHandShakeResponse02() / SSPHandShakeResponse02.new instead')
  static SSPHandShakeResponse02 create() => SSPHandShakeResponse02._();
  static $pb.GeneratedMessage $_createMessage() => SSPHandShakeResponse02._();
  @$core.override
  SSPHandShakeResponse02 createEmptyInstance() => SSPHandShakeResponse02._();
  @$core.pragma('dart2js:noInline')
  static SSPHandShakeResponse02 getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPHandShakeResponse02>(
          SSPHandShakeResponse02.$_createMessage);
  static SSPHandShakeResponse02? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  SSPHandShakeTrustType get trustType => $_getN(1);
  @$pb.TagNumber(2)
  set trustType(SSPHandShakeTrustType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTrustType() => $_has(1);
  @$pb.TagNumber(2)
  void clearTrustType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get deviceUuid => $_getSZ(2);
  @$pb.TagNumber(3)
  set deviceUuid($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDeviceUuid() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeviceUuid() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get deviceName => $_getSZ(3);
  @$pb.TagNumber(4)
  set deviceName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDeviceName() => $_has(3);
  @$pb.TagNumber(4)
  void clearDeviceName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get derivedKey => $_getN(4);
  @$pb.TagNumber(5)
  set derivedKey($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDerivedKey() => $_has(4);
  @$pb.TagNumber(5)
  void clearDerivedKey() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get result => $_getSZ(5);
  @$pb.TagNumber(6)
  set result($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasResult() => $_has(5);
  @$pb.TagNumber(6)
  void clearResult() => $_clearField(6);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:136
class SSPHeartBeatRequest extends $pb.GeneratedMessage {
  factory SSPHeartBeatRequest({
    SSPRequestType? type,
    $fixnum.Int64? hostTimestamp,
  }) {
    final result = SSPHeartBeatRequest._();
    if (type != null) result.type = type;
    if (hostTimestamp != null) result.hostTimestamp = hostTimestamp;
    return result;
  }

  SSPHeartBeatRequest._();

  factory SSPHeartBeatRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPHeartBeatRequest()..mergeFromBuffer(data, registry);
  factory SSPHeartBeatRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPHeartBeatRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPHeartBeatRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPHeartBeatRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_HeartBeatRequest,
        enumValues: SSPRequestType.values)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'hostTimestamp', $pb.PbFieldType.OU6,
        protoName: 'hostTimestamp', defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPHeartBeatRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPHeartBeatRequest copyWith(void Function(SSPHeartBeatRequest) updates) =>
      super.copyWith((message) => updates(message as SSPHeartBeatRequest))
          as SSPHeartBeatRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use SSPHeartBeatRequest() / SSPHeartBeatRequest.new instead')
  static SSPHeartBeatRequest create() => SSPHeartBeatRequest._();
  static $pb.GeneratedMessage $_createMessage() => SSPHeartBeatRequest._();
  @$core.override
  SSPHeartBeatRequest createEmptyInstance() => SSPHeartBeatRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPHeartBeatRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPHeartBeatRequest>(
          SSPHeartBeatRequest.$_createMessage);
  static SSPHeartBeatRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get hostTimestamp => $_getI64(1);
  @$pb.TagNumber(2)
  set hostTimestamp($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHostTimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearHostTimestamp() => $_clearField(2);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:139
class SSPHeartBeatResponse extends $pb.GeneratedMessage {
  factory SSPHeartBeatResponse({
    SSPRequestType? type,
    $fixnum.Int64? hostTimestamp,
    $fixnum.Int64? clientTimestamp,
  }) {
    final result = SSPHeartBeatResponse._();
    if (type != null) result.type = type;
    if (hostTimestamp != null) result.hostTimestamp = hostTimestamp;
    if (clientTimestamp != null) result.clientTimestamp = clientTimestamp;
    return result;
  }

  SSPHeartBeatResponse._();

  factory SSPHeartBeatResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPHeartBeatResponse()..mergeFromBuffer(data, registry);
  factory SSPHeartBeatResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPHeartBeatResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPHeartBeatResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPHeartBeatResponse.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_HeartBeatRequest,
        enumValues: SSPRequestType.values)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'hostTimestamp', $pb.PbFieldType.OU6,
        protoName: 'hostTimestamp', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'clientTimestamp', $pb.PbFieldType.OU6,
        protoName: 'clientTimestamp', defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPHeartBeatResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPHeartBeatResponse copyWith(void Function(SSPHeartBeatResponse) updates) =>
      super.copyWith((message) => updates(message as SSPHeartBeatResponse))
          as SSPHeartBeatResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPHeartBeatResponse() / SSPHeartBeatResponse.new instead')
  static SSPHeartBeatResponse create() => SSPHeartBeatResponse._();
  static $pb.GeneratedMessage $_createMessage() => SSPHeartBeatResponse._();
  @$core.override
  SSPHeartBeatResponse createEmptyInstance() => SSPHeartBeatResponse._();
  @$core.pragma('dart2js:noInline')
  static SSPHeartBeatResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPHeartBeatResponse>(
          SSPHeartBeatResponse.$_createMessage);
  static SSPHeartBeatResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get hostTimestamp => $_getI64(1);
  @$pb.TagNumber(2)
  set hostTimestamp($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHostTimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearHostTimestamp() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get clientTimestamp => $_getI64(2);
  @$pb.TagNumber(3)
  set clientTimestamp($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasClientTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearClientTimestamp() => $_clearField(3);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:143
class SSPQuitRequest extends $pb.GeneratedMessage {
  factory SSPQuitRequest({
    SSPRequestType? type,
  }) {
    final result = SSPQuitRequest._();
    if (type != null) result.type = type;
    return result;
  }

  SSPQuitRequest._();

  factory SSPQuitRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPQuitRequest()..mergeFromBuffer(data, registry);
  factory SSPQuitRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPQuitRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPQuitRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPQuitRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_QuitRequest,
        enumValues: SSPRequestType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPQuitRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPQuitRequest copyWith(void Function(SSPQuitRequest) updates) =>
      super.copyWith((message) => updates(message as SSPQuitRequest))
          as SSPQuitRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SSPQuitRequest() / SSPQuitRequest.new instead')
  static SSPQuitRequest create() => SSPQuitRequest._();
  static $pb.GeneratedMessage $_createMessage() => SSPQuitRequest._();
  @$core.override
  SSPQuitRequest createEmptyInstance() => SSPQuitRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPQuitRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SSPQuitRequest>(
          SSPQuitRequest.$_createMessage);
  static SSPQuitRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:145
class SSPGetDeviceInfoRequest extends $pb.GeneratedMessage {
  factory SSPGetDeviceInfoRequest({
    SSPRequestType? type,
    $fixnum.Int64? hostTimestamp,
    $core.String? hostSmartSyncProtocolVersion,
    $core.bool? needDeviceInfoCallback,
    $core.bool? needPhotoLibraryCallback,
    $core.bool? needAudioLibraryCallback,
    $core.bool? needVideoLibraryCallback,
    $core.String? hostAppVersion,
    $core.String? hostMinClientVersion,
    $core.int? hostType,
    $core.int? hostAppVersionCode,
  }) {
    final result = SSPGetDeviceInfoRequest._();
    if (type != null) result.type = type;
    if (hostTimestamp != null) result.hostTimestamp = hostTimestamp;
    if (hostSmartSyncProtocolVersion != null)
      result.hostSmartSyncProtocolVersion = hostSmartSyncProtocolVersion;
    if (needDeviceInfoCallback != null)
      result.needDeviceInfoCallback = needDeviceInfoCallback;
    if (needPhotoLibraryCallback != null)
      result.needPhotoLibraryCallback = needPhotoLibraryCallback;
    if (needAudioLibraryCallback != null)
      result.needAudioLibraryCallback = needAudioLibraryCallback;
    if (needVideoLibraryCallback != null)
      result.needVideoLibraryCallback = needVideoLibraryCallback;
    if (hostAppVersion != null) result.hostAppVersion = hostAppVersion;
    if (hostMinClientVersion != null)
      result.hostMinClientVersion = hostMinClientVersion;
    if (hostType != null) result.hostType = hostType;
    if (hostAppVersionCode != null)
      result.hostAppVersionCode = hostAppVersionCode;
    return result;
  }

  SSPGetDeviceInfoRequest._();

  factory SSPGetDeviceInfoRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetDeviceInfoRequest()..mergeFromBuffer(data, registry);
  factory SSPGetDeviceInfoRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetDeviceInfoRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPGetDeviceInfoRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPGetDeviceInfoRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetDeviceInfoRequest,
        enumValues: SSPRequestType.values)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'hostTimestamp', $pb.PbFieldType.OU6,
        protoName: 'hostTimestamp', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(3, _omitFieldNames ? '' : 'hostSmartSyncProtocolVersion',
        protoName: 'hostSmartSyncProtocolVersion')
    ..aOB(4, _omitFieldNames ? '' : 'needDeviceInfoCallback',
        protoName: 'needDeviceInfoCallback')
    ..aOB(5, _omitFieldNames ? '' : 'needPhotoLibraryCallback',
        protoName: 'needPhotoLibraryCallback')
    ..aOB(6, _omitFieldNames ? '' : 'needAudioLibraryCallback',
        protoName: 'needAudioLibraryCallback')
    ..aOB(7, _omitFieldNames ? '' : 'needVideoLibraryCallback',
        protoName: 'needVideoLibraryCallback')
    ..aOS(8, _omitFieldNames ? '' : 'hostAppVersion',
        protoName: 'hostAppVersion')
    ..aOS(9, _omitFieldNames ? '' : 'hostMinClientVersion',
        protoName: 'hostMinClientVersion')
    ..aI(10, _omitFieldNames ? '' : 'hostType',
        protoName: 'hostType',
        fieldType: $pb.PbFieldType.OU3,
        defaultOrMaker: 1)
    ..aI(11, _omitFieldNames ? '' : 'hostAppVersionCode',
        protoName: 'hostAppVersionCode', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetDeviceInfoRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetDeviceInfoRequest copyWith(
          void Function(SSPGetDeviceInfoRequest) updates) =>
      super.copyWith((message) => updates(message as SSPGetDeviceInfoRequest))
          as SSPGetDeviceInfoRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPGetDeviceInfoRequest() / SSPGetDeviceInfoRequest.new instead')
  static SSPGetDeviceInfoRequest create() => SSPGetDeviceInfoRequest._();
  static $pb.GeneratedMessage $_createMessage() => SSPGetDeviceInfoRequest._();
  @$core.override
  SSPGetDeviceInfoRequest createEmptyInstance() => SSPGetDeviceInfoRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPGetDeviceInfoRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPGetDeviceInfoRequest>(
          SSPGetDeviceInfoRequest.$_createMessage);
  static SSPGetDeviceInfoRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get hostTimestamp => $_getI64(1);
  @$pb.TagNumber(2)
  set hostTimestamp($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHostTimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearHostTimestamp() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get hostSmartSyncProtocolVersion => $_getSZ(2);
  @$pb.TagNumber(3)
  set hostSmartSyncProtocolVersion($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHostSmartSyncProtocolVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearHostSmartSyncProtocolVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get needDeviceInfoCallback => $_getBF(3);
  @$pb.TagNumber(4)
  set needDeviceInfoCallback($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNeedDeviceInfoCallback() => $_has(3);
  @$pb.TagNumber(4)
  void clearNeedDeviceInfoCallback() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get needPhotoLibraryCallback => $_getBF(4);
  @$pb.TagNumber(5)
  set needPhotoLibraryCallback($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasNeedPhotoLibraryCallback() => $_has(4);
  @$pb.TagNumber(5)
  void clearNeedPhotoLibraryCallback() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get needAudioLibraryCallback => $_getBF(5);
  @$pb.TagNumber(6)
  set needAudioLibraryCallback($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasNeedAudioLibraryCallback() => $_has(5);
  @$pb.TagNumber(6)
  void clearNeedAudioLibraryCallback() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get needVideoLibraryCallback => $_getBF(6);
  @$pb.TagNumber(7)
  set needVideoLibraryCallback($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasNeedVideoLibraryCallback() => $_has(6);
  @$pb.TagNumber(7)
  void clearNeedVideoLibraryCallback() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get hostAppVersion => $_getSZ(7);
  @$pb.TagNumber(8)
  set hostAppVersion($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasHostAppVersion() => $_has(7);
  @$pb.TagNumber(8)
  void clearHostAppVersion() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get hostMinClientVersion => $_getSZ(8);
  @$pb.TagNumber(9)
  set hostMinClientVersion($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasHostMinClientVersion() => $_has(8);
  @$pb.TagNumber(9)
  void clearHostMinClientVersion() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get hostType => $_getI(9, 1);
  @$pb.TagNumber(10)
  set hostType($core.int value) => $_setUnsignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasHostType() => $_has(9);
  @$pb.TagNumber(10)
  void clearHostType() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get hostAppVersionCode => $_getIZ(10);
  @$pb.TagNumber(11)
  set hostAppVersionCode($core.int value) => $_setUnsignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasHostAppVersionCode() => $_has(10);
  @$pb.TagNumber(11)
  void clearHostAppVersionCode() => $_clearField(11);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:157
class SSPGetDeviceInfoResponse extends $pb.GeneratedMessage {
  factory SSPGetDeviceInfoResponse({
    SSPRequestType? type,
    $fixnum.Int64? hostTimestamp,
    $core.String? hostSmartSyncProtocolVersion,
    $core.String? apkVersion,
    $fixnum.Int64? clientTimestamp,
    $core.String? clientSmartSyncProtocolVersion,
    $core.String? hostAppVersion,
    $core.String? hostMinClientVersion,
    $core.String? phoneModel,
    $core.String? phoneColor,
    $fixnum.Int64? diskSize,
    $fixnum.Int64? ramSize,
    $core.double? batteryCapacity,
    $core.int? batteryPercentage,
    $core.String? phoneName,
    $fixnum.Int64? usedDiskSize,
    $core.String? rootPath,
    $core.String? productBrand,
    $core.String? productManufacturer,
    $core.String? smartisanVersion,
    $core.bool? phoneLocked,
    $core.String? clientMinHostVersion,
    $core.String? apkVersionName,
    $core.String? externalStoragePath,
    SSPFileIOPermission? externalStoragePermission,
    $fixnum.Int64? extDiskSize,
    $fixnum.Int64? extUsedDiskSize,
    $core.String? phoneId,
    $fixnum.Int64? audioSize,
    $fixnum.Int64? picVideoSize,
    $fixnum.Int64? downloadSize,
    $fixnum.Int64? otherSize,
    $fixnum.Int64? appSize,
    $fixnum.Int64? cacheSize,
    $core.String? debugBuildTime,
    $fixnum.Int64? clientMinHostVersionCode,
  }) {
    final result = SSPGetDeviceInfoResponse._();
    if (type != null) result.type = type;
    if (hostTimestamp != null) result.hostTimestamp = hostTimestamp;
    if (hostSmartSyncProtocolVersion != null)
      result.hostSmartSyncProtocolVersion = hostSmartSyncProtocolVersion;
    if (apkVersion != null) result.apkVersion = apkVersion;
    if (clientTimestamp != null) result.clientTimestamp = clientTimestamp;
    if (clientSmartSyncProtocolVersion != null)
      result.clientSmartSyncProtocolVersion = clientSmartSyncProtocolVersion;
    if (hostAppVersion != null) result.hostAppVersion = hostAppVersion;
    if (hostMinClientVersion != null)
      result.hostMinClientVersion = hostMinClientVersion;
    if (phoneModel != null) result.phoneModel = phoneModel;
    if (phoneColor != null) result.phoneColor = phoneColor;
    if (diskSize != null) result.diskSize = diskSize;
    if (ramSize != null) result.ramSize = ramSize;
    if (batteryCapacity != null) result.batteryCapacity = batteryCapacity;
    if (batteryPercentage != null) result.batteryPercentage = batteryPercentage;
    if (phoneName != null) result.phoneName = phoneName;
    if (usedDiskSize != null) result.usedDiskSize = usedDiskSize;
    if (rootPath != null) result.rootPath = rootPath;
    if (productBrand != null) result.productBrand = productBrand;
    if (productManufacturer != null)
      result.productManufacturer = productManufacturer;
    if (smartisanVersion != null) result.smartisanVersion = smartisanVersion;
    if (phoneLocked != null) result.phoneLocked = phoneLocked;
    if (clientMinHostVersion != null)
      result.clientMinHostVersion = clientMinHostVersion;
    if (apkVersionName != null) result.apkVersionName = apkVersionName;
    if (externalStoragePath != null)
      result.externalStoragePath = externalStoragePath;
    if (externalStoragePermission != null)
      result.externalStoragePermission = externalStoragePermission;
    if (extDiskSize != null) result.extDiskSize = extDiskSize;
    if (extUsedDiskSize != null) result.extUsedDiskSize = extUsedDiskSize;
    if (phoneId != null) result.phoneId = phoneId;
    if (audioSize != null) result.audioSize = audioSize;
    if (picVideoSize != null) result.picVideoSize = picVideoSize;
    if (downloadSize != null) result.downloadSize = downloadSize;
    if (otherSize != null) result.otherSize = otherSize;
    if (appSize != null) result.appSize = appSize;
    if (cacheSize != null) result.cacheSize = cacheSize;
    if (debugBuildTime != null) result.debugBuildTime = debugBuildTime;
    if (clientMinHostVersionCode != null)
      result.clientMinHostVersionCode = clientMinHostVersionCode;
    return result;
  }

  SSPGetDeviceInfoResponse._();

  factory SSPGetDeviceInfoResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetDeviceInfoResponse()..mergeFromBuffer(data, registry);
  factory SSPGetDeviceInfoResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetDeviceInfoResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPGetDeviceInfoResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPGetDeviceInfoResponse.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetDeviceInfoRequest,
        enumValues: SSPRequestType.values)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'hostTimestamp', $pb.PbFieldType.OU6,
        protoName: 'hostTimestamp', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(3, _omitFieldNames ? '' : 'hostSmartSyncProtocolVersion',
        protoName: 'hostSmartSyncProtocolVersion')
    ..aOS(4, _omitFieldNames ? '' : 'apkVersion', protoName: 'apkVersion')
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'clientTimestamp', $pb.PbFieldType.OU6,
        protoName: 'clientTimestamp', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(6, _omitFieldNames ? '' : 'clientSmartSyncProtocolVersion',
        protoName: 'clientSmartSyncProtocolVersion')
    ..aOS(7, _omitFieldNames ? '' : 'hostAppVersion',
        protoName: 'hostAppVersion')
    ..aOS(8, _omitFieldNames ? '' : 'hostMinClientVersion',
        protoName: 'hostMinClientVersion')
    ..aOS(9, _omitFieldNames ? '' : 'phoneModel', protoName: 'phoneModel')
    ..aOS(10, _omitFieldNames ? '' : 'phoneColor', protoName: 'phoneColor')
    ..a<$fixnum.Int64>(
        11, _omitFieldNames ? '' : 'diskSize', $pb.PbFieldType.OU6,
        protoName: 'diskSize', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        12, _omitFieldNames ? '' : 'ramSize', $pb.PbFieldType.OU6,
        protoName: 'ramSize', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aD(13, _omitFieldNames ? '' : 'batteryCapacity',
        protoName: 'batteryCapacity')
    ..aI(14, _omitFieldNames ? '' : 'batteryPercentage',
        protoName: 'batteryPercentage', fieldType: $pb.PbFieldType.OU3)
    ..aOS(15, _omitFieldNames ? '' : 'phoneName', protoName: 'phoneName')
    ..a<$fixnum.Int64>(
        16, _omitFieldNames ? '' : 'usedDiskSize', $pb.PbFieldType.OU6,
        protoName: 'usedDiskSize', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(17, _omitFieldNames ? '' : 'rootPath', protoName: 'rootPath')
    ..aOS(18, _omitFieldNames ? '' : 'productBrand', protoName: 'productBrand')
    ..aOS(19, _omitFieldNames ? '' : 'productManufacturer',
        protoName: 'productManufacturer')
    ..aOS(20, _omitFieldNames ? '' : 'smartisanVersion',
        protoName: 'smartisanVersion')
    ..aOB(21, _omitFieldNames ? '' : 'phoneLocked', protoName: 'phoneLocked')
    ..aOS(22, _omitFieldNames ? '' : 'clientMinHostVersion',
        protoName: 'clientMinHostVersion')
    ..aOS(23, _omitFieldNames ? '' : 'apkVersionName',
        protoName: 'apkVersionName')
    ..aOS(24, _omitFieldNames ? '' : 'externalStoragePath',
        protoName: 'externalStoragePath')
    ..aE<SSPFileIOPermission>(
        25, _omitFieldNames ? '' : 'externalStoragePermission',
        protoName: 'externalStoragePermission',
        enumValues: SSPFileIOPermission.values)
    ..a<$fixnum.Int64>(
        26, _omitFieldNames ? '' : 'extDiskSize', $pb.PbFieldType.OU6,
        protoName: 'extDiskSize', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        27, _omitFieldNames ? '' : 'extUsedDiskSize', $pb.PbFieldType.OU6,
        protoName: 'extUsedDiskSize', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(28, _omitFieldNames ? '' : 'phoneId', protoName: 'phoneId')
    ..aInt64(29, _omitFieldNames ? '' : 'audioSize', protoName: 'audioSize')
    ..aInt64(30, _omitFieldNames ? '' : 'picVideoSize',
        protoName: 'picVideoSize')
    ..aInt64(31, _omitFieldNames ? '' : 'downloadSize',
        protoName: 'downloadSize')
    ..aInt64(32, _omitFieldNames ? '' : 'otherSize', protoName: 'otherSize')
    ..aInt64(33, _omitFieldNames ? '' : 'appSize', protoName: 'appSize')
    ..aInt64(34, _omitFieldNames ? '' : 'cacheSize', protoName: 'cacheSize')
    ..aOS(35, _omitFieldNames ? '' : 'debugBuildTime',
        protoName: 'debugBuildTime')
    ..aInt64(36, _omitFieldNames ? '' : 'clientMinHostVersionCode',
        protoName: 'clientMinHostVersionCode')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetDeviceInfoResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetDeviceInfoResponse copyWith(
          void Function(SSPGetDeviceInfoResponse) updates) =>
      super.copyWith((message) => updates(message as SSPGetDeviceInfoResponse))
          as SSPGetDeviceInfoResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPGetDeviceInfoResponse() / SSPGetDeviceInfoResponse.new instead')
  static SSPGetDeviceInfoResponse create() => SSPGetDeviceInfoResponse._();
  static $pb.GeneratedMessage $_createMessage() => SSPGetDeviceInfoResponse._();
  @$core.override
  SSPGetDeviceInfoResponse createEmptyInstance() =>
      SSPGetDeviceInfoResponse._();
  @$core.pragma('dart2js:noInline')
  static SSPGetDeviceInfoResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPGetDeviceInfoResponse>(
          SSPGetDeviceInfoResponse.$_createMessage);
  static SSPGetDeviceInfoResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get hostTimestamp => $_getI64(1);
  @$pb.TagNumber(2)
  set hostTimestamp($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHostTimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearHostTimestamp() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get hostSmartSyncProtocolVersion => $_getSZ(2);
  @$pb.TagNumber(3)
  set hostSmartSyncProtocolVersion($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHostSmartSyncProtocolVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearHostSmartSyncProtocolVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get apkVersion => $_getSZ(3);
  @$pb.TagNumber(4)
  set apkVersion($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasApkVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearApkVersion() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get clientTimestamp => $_getI64(4);
  @$pb.TagNumber(5)
  set clientTimestamp($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasClientTimestamp() => $_has(4);
  @$pb.TagNumber(5)
  void clearClientTimestamp() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get clientSmartSyncProtocolVersion => $_getSZ(5);
  @$pb.TagNumber(6)
  set clientSmartSyncProtocolVersion($core.String value) =>
      $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasClientSmartSyncProtocolVersion() => $_has(5);
  @$pb.TagNumber(6)
  void clearClientSmartSyncProtocolVersion() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get hostAppVersion => $_getSZ(6);
  @$pb.TagNumber(7)
  set hostAppVersion($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasHostAppVersion() => $_has(6);
  @$pb.TagNumber(7)
  void clearHostAppVersion() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get hostMinClientVersion => $_getSZ(7);
  @$pb.TagNumber(8)
  set hostMinClientVersion($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasHostMinClientVersion() => $_has(7);
  @$pb.TagNumber(8)
  void clearHostMinClientVersion() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get phoneModel => $_getSZ(8);
  @$pb.TagNumber(9)
  set phoneModel($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPhoneModel() => $_has(8);
  @$pb.TagNumber(9)
  void clearPhoneModel() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get phoneColor => $_getSZ(9);
  @$pb.TagNumber(10)
  set phoneColor($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasPhoneColor() => $_has(9);
  @$pb.TagNumber(10)
  void clearPhoneColor() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get diskSize => $_getI64(10);
  @$pb.TagNumber(11)
  set diskSize($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasDiskSize() => $_has(10);
  @$pb.TagNumber(11)
  void clearDiskSize() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get ramSize => $_getI64(11);
  @$pb.TagNumber(12)
  set ramSize($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasRamSize() => $_has(11);
  @$pb.TagNumber(12)
  void clearRamSize() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.double get batteryCapacity => $_getN(12);
  @$pb.TagNumber(13)
  set batteryCapacity($core.double value) => $_setDouble(12, value);
  @$pb.TagNumber(13)
  $core.bool hasBatteryCapacity() => $_has(12);
  @$pb.TagNumber(13)
  void clearBatteryCapacity() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.int get batteryPercentage => $_getIZ(13);
  @$pb.TagNumber(14)
  set batteryPercentage($core.int value) => $_setUnsignedInt32(13, value);
  @$pb.TagNumber(14)
  $core.bool hasBatteryPercentage() => $_has(13);
  @$pb.TagNumber(14)
  void clearBatteryPercentage() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get phoneName => $_getSZ(14);
  @$pb.TagNumber(15)
  set phoneName($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasPhoneName() => $_has(14);
  @$pb.TagNumber(15)
  void clearPhoneName() => $_clearField(15);

  @$pb.TagNumber(16)
  $fixnum.Int64 get usedDiskSize => $_getI64(15);
  @$pb.TagNumber(16)
  set usedDiskSize($fixnum.Int64 value) => $_setInt64(15, value);
  @$pb.TagNumber(16)
  $core.bool hasUsedDiskSize() => $_has(15);
  @$pb.TagNumber(16)
  void clearUsedDiskSize() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.String get rootPath => $_getSZ(16);
  @$pb.TagNumber(17)
  set rootPath($core.String value) => $_setString(16, value);
  @$pb.TagNumber(17)
  $core.bool hasRootPath() => $_has(16);
  @$pb.TagNumber(17)
  void clearRootPath() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.String get productBrand => $_getSZ(17);
  @$pb.TagNumber(18)
  set productBrand($core.String value) => $_setString(17, value);
  @$pb.TagNumber(18)
  $core.bool hasProductBrand() => $_has(17);
  @$pb.TagNumber(18)
  void clearProductBrand() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.String get productManufacturer => $_getSZ(18);
  @$pb.TagNumber(19)
  set productManufacturer($core.String value) => $_setString(18, value);
  @$pb.TagNumber(19)
  $core.bool hasProductManufacturer() => $_has(18);
  @$pb.TagNumber(19)
  void clearProductManufacturer() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.String get smartisanVersion => $_getSZ(19);
  @$pb.TagNumber(20)
  set smartisanVersion($core.String value) => $_setString(19, value);
  @$pb.TagNumber(20)
  $core.bool hasSmartisanVersion() => $_has(19);
  @$pb.TagNumber(20)
  void clearSmartisanVersion() => $_clearField(20);

  @$pb.TagNumber(21)
  $core.bool get phoneLocked => $_getBF(20);
  @$pb.TagNumber(21)
  set phoneLocked($core.bool value) => $_setBool(20, value);
  @$pb.TagNumber(21)
  $core.bool hasPhoneLocked() => $_has(20);
  @$pb.TagNumber(21)
  void clearPhoneLocked() => $_clearField(21);

  @$pb.TagNumber(22)
  $core.String get clientMinHostVersion => $_getSZ(21);
  @$pb.TagNumber(22)
  set clientMinHostVersion($core.String value) => $_setString(21, value);
  @$pb.TagNumber(22)
  $core.bool hasClientMinHostVersion() => $_has(21);
  @$pb.TagNumber(22)
  void clearClientMinHostVersion() => $_clearField(22);

  @$pb.TagNumber(23)
  $core.String get apkVersionName => $_getSZ(22);
  @$pb.TagNumber(23)
  set apkVersionName($core.String value) => $_setString(22, value);
  @$pb.TagNumber(23)
  $core.bool hasApkVersionName() => $_has(22);
  @$pb.TagNumber(23)
  void clearApkVersionName() => $_clearField(23);

  @$pb.TagNumber(24)
  $core.String get externalStoragePath => $_getSZ(23);
  @$pb.TagNumber(24)
  set externalStoragePath($core.String value) => $_setString(23, value);
  @$pb.TagNumber(24)
  $core.bool hasExternalStoragePath() => $_has(23);
  @$pb.TagNumber(24)
  void clearExternalStoragePath() => $_clearField(24);

  @$pb.TagNumber(25)
  SSPFileIOPermission get externalStoragePermission => $_getN(24);
  @$pb.TagNumber(25)
  set externalStoragePermission(SSPFileIOPermission value) =>
      $_setField(25, value);
  @$pb.TagNumber(25)
  $core.bool hasExternalStoragePermission() => $_has(24);
  @$pb.TagNumber(25)
  void clearExternalStoragePermission() => $_clearField(25);

  @$pb.TagNumber(26)
  $fixnum.Int64 get extDiskSize => $_getI64(25);
  @$pb.TagNumber(26)
  set extDiskSize($fixnum.Int64 value) => $_setInt64(25, value);
  @$pb.TagNumber(26)
  $core.bool hasExtDiskSize() => $_has(25);
  @$pb.TagNumber(26)
  void clearExtDiskSize() => $_clearField(26);

  @$pb.TagNumber(27)
  $fixnum.Int64 get extUsedDiskSize => $_getI64(26);
  @$pb.TagNumber(27)
  set extUsedDiskSize($fixnum.Int64 value) => $_setInt64(26, value);
  @$pb.TagNumber(27)
  $core.bool hasExtUsedDiskSize() => $_has(26);
  @$pb.TagNumber(27)
  void clearExtUsedDiskSize() => $_clearField(27);

  @$pb.TagNumber(28)
  $core.String get phoneId => $_getSZ(27);
  @$pb.TagNumber(28)
  set phoneId($core.String value) => $_setString(27, value);
  @$pb.TagNumber(28)
  $core.bool hasPhoneId() => $_has(27);
  @$pb.TagNumber(28)
  void clearPhoneId() => $_clearField(28);

  @$pb.TagNumber(29)
  $fixnum.Int64 get audioSize => $_getI64(28);
  @$pb.TagNumber(29)
  set audioSize($fixnum.Int64 value) => $_setInt64(28, value);
  @$pb.TagNumber(29)
  $core.bool hasAudioSize() => $_has(28);
  @$pb.TagNumber(29)
  void clearAudioSize() => $_clearField(29);

  @$pb.TagNumber(30)
  $fixnum.Int64 get picVideoSize => $_getI64(29);
  @$pb.TagNumber(30)
  set picVideoSize($fixnum.Int64 value) => $_setInt64(29, value);
  @$pb.TagNumber(30)
  $core.bool hasPicVideoSize() => $_has(29);
  @$pb.TagNumber(30)
  void clearPicVideoSize() => $_clearField(30);

  @$pb.TagNumber(31)
  $fixnum.Int64 get downloadSize => $_getI64(30);
  @$pb.TagNumber(31)
  set downloadSize($fixnum.Int64 value) => $_setInt64(30, value);
  @$pb.TagNumber(31)
  $core.bool hasDownloadSize() => $_has(30);
  @$pb.TagNumber(31)
  void clearDownloadSize() => $_clearField(31);

  @$pb.TagNumber(32)
  $fixnum.Int64 get otherSize => $_getI64(31);
  @$pb.TagNumber(32)
  set otherSize($fixnum.Int64 value) => $_setInt64(31, value);
  @$pb.TagNumber(32)
  $core.bool hasOtherSize() => $_has(31);
  @$pb.TagNumber(32)
  void clearOtherSize() => $_clearField(32);

  @$pb.TagNumber(33)
  $fixnum.Int64 get appSize => $_getI64(32);
  @$pb.TagNumber(33)
  set appSize($fixnum.Int64 value) => $_setInt64(32, value);
  @$pb.TagNumber(33)
  $core.bool hasAppSize() => $_has(32);
  @$pb.TagNumber(33)
  void clearAppSize() => $_clearField(33);

  @$pb.TagNumber(34)
  $fixnum.Int64 get cacheSize => $_getI64(33);
  @$pb.TagNumber(34)
  set cacheSize($fixnum.Int64 value) => $_setInt64(33, value);
  @$pb.TagNumber(34)
  $core.bool hasCacheSize() => $_has(33);
  @$pb.TagNumber(34)
  void clearCacheSize() => $_clearField(34);

  @$pb.TagNumber(35)
  $core.String get debugBuildTime => $_getSZ(34);
  @$pb.TagNumber(35)
  set debugBuildTime($core.String value) => $_setString(34, value);
  @$pb.TagNumber(35)
  $core.bool hasDebugBuildTime() => $_has(34);
  @$pb.TagNumber(35)
  void clearDebugBuildTime() => $_clearField(35);

  @$pb.TagNumber(36)
  $fixnum.Int64 get clientMinHostVersionCode => $_getI64(35);
  @$pb.TagNumber(36)
  set clientMinHostVersionCode($fixnum.Int64 value) => $_setInt64(35, value);
  @$pb.TagNumber(36)
  $core.bool hasClientMinHostVersionCode() => $_has(35);
  @$pb.TagNumber(36)
  void clearClientMinHostVersionCode() => $_clearField(36);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:194
class SSPGetDirFilesRequest extends $pb.GeneratedMessage {
  factory SSPGetDirFilesRequest({
    SSPRequestType? type,
    SSPFile? dir,
    $core.int? maxdepth,
  }) {
    final result = SSPGetDirFilesRequest._();
    if (type != null) result.type = type;
    if (dir != null) result.dir = dir;
    if (maxdepth != null) result.maxdepth = maxdepth;
    return result;
  }

  SSPGetDirFilesRequest._();

  factory SSPGetDirFilesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetDirFilesRequest()..mergeFromBuffer(data, registry);
  factory SSPGetDirFilesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetDirFilesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPGetDirFilesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPGetDirFilesRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetDirFilesRequest,
        enumValues: SSPRequestType.values)
    ..aOM<SSPFile>(2, _omitFieldNames ? '' : 'dir',
        subBuilder: SSPFile.$_createMessage)
    ..aI(3, _omitFieldNames ? '' : 'maxdepth', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetDirFilesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetDirFilesRequest copyWith(
          void Function(SSPGetDirFilesRequest) updates) =>
      super.copyWith((message) => updates(message as SSPGetDirFilesRequest))
          as SSPGetDirFilesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPGetDirFilesRequest() / SSPGetDirFilesRequest.new instead')
  static SSPGetDirFilesRequest create() => SSPGetDirFilesRequest._();
  static $pb.GeneratedMessage $_createMessage() => SSPGetDirFilesRequest._();
  @$core.override
  SSPGetDirFilesRequest createEmptyInstance() => SSPGetDirFilesRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPGetDirFilesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPGetDirFilesRequest>(
          SSPGetDirFilesRequest.$_createMessage);
  static SSPGetDirFilesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  SSPFile get dir => $_getN(1);
  @$pb.TagNumber(2)
  set dir(SSPFile value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDir() => $_has(1);
  @$pb.TagNumber(2)
  void clearDir() => $_clearField(2);
  @$pb.TagNumber(2)
  SSPFile ensureDir() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.int get maxdepth => $_getIZ(2);
  @$pb.TagNumber(3)
  set maxdepth($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMaxdepth() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaxdepth() => $_clearField(3);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:198
class SSPGetDirFilesResponse extends $pb.GeneratedMessage {
  factory SSPGetDirFilesResponse({
    SSPRequestType? type,
    SSPFile? dir,
    $core.int? maxdepth,
    $core.int? timecost,
    $core.Iterable<SSPFile>? fileArray,
  }) {
    final result = SSPGetDirFilesResponse._();
    if (type != null) result.type = type;
    if (dir != null) result.dir = dir;
    if (maxdepth != null) result.maxdepth = maxdepth;
    if (timecost != null) result.timecost = timecost;
    if (fileArray != null) result.fileArray.addAll(fileArray);
    return result;
  }

  SSPGetDirFilesResponse._();

  factory SSPGetDirFilesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetDirFilesResponse()..mergeFromBuffer(data, registry);
  factory SSPGetDirFilesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetDirFilesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPGetDirFilesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPGetDirFilesResponse.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetDirFilesRequest,
        enumValues: SSPRequestType.values)
    ..aOM<SSPFile>(2, _omitFieldNames ? '' : 'dir',
        subBuilder: SSPFile.$_createMessage)
    ..aI(3, _omitFieldNames ? '' : 'maxdepth', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'timecost', fieldType: $pb.PbFieldType.OU3)
    ..pPM<SSPFile>(5, _omitFieldNames ? '' : 'fileArray',
        protoName: 'fileArray', subBuilder: SSPFile.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetDirFilesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetDirFilesResponse copyWith(
          void Function(SSPGetDirFilesResponse) updates) =>
      super.copyWith((message) => updates(message as SSPGetDirFilesResponse))
          as SSPGetDirFilesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPGetDirFilesResponse() / SSPGetDirFilesResponse.new instead')
  static SSPGetDirFilesResponse create() => SSPGetDirFilesResponse._();
  static $pb.GeneratedMessage $_createMessage() => SSPGetDirFilesResponse._();
  @$core.override
  SSPGetDirFilesResponse createEmptyInstance() => SSPGetDirFilesResponse._();
  @$core.pragma('dart2js:noInline')
  static SSPGetDirFilesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPGetDirFilesResponse>(
          SSPGetDirFilesResponse.$_createMessage);
  static SSPGetDirFilesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  SSPFile get dir => $_getN(1);
  @$pb.TagNumber(2)
  set dir(SSPFile value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDir() => $_has(1);
  @$pb.TagNumber(2)
  void clearDir() => $_clearField(2);
  @$pb.TagNumber(2)
  SSPFile ensureDir() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.int get maxdepth => $_getIZ(2);
  @$pb.TagNumber(3)
  set maxdepth($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMaxdepth() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaxdepth() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get timecost => $_getIZ(3);
  @$pb.TagNumber(4)
  set timecost($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTimecost() => $_has(3);
  @$pb.TagNumber(4)
  void clearTimecost() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<SSPFile> get fileArray => $_getList(4);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:204
class SSPGetFileCountRequest extends $pb.GeneratedMessage {
  factory SSPGetFileCountRequest({
    SSPRequestType? type,
    SSPFile? dir,
    $core.int? maxdepth,
    $core.Iterable<$core.String>? exclusionPatternArray,
  }) {
    final result = SSPGetFileCountRequest._();
    if (type != null) result.type = type;
    if (dir != null) result.dir = dir;
    if (maxdepth != null) result.maxdepth = maxdepth;
    if (exclusionPatternArray != null)
      result.exclusionPatternArray.addAll(exclusionPatternArray);
    return result;
  }

  SSPGetFileCountRequest._();

  factory SSPGetFileCountRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetFileCountRequest()..mergeFromBuffer(data, registry);
  factory SSPGetFileCountRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetFileCountRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPGetFileCountRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPGetFileCountRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetFileCountRequest,
        enumValues: SSPRequestType.values)
    ..aOM<SSPFile>(2, _omitFieldNames ? '' : 'dir',
        subBuilder: SSPFile.$_createMessage)
    ..aI(3, _omitFieldNames ? '' : 'maxdepth', fieldType: $pb.PbFieldType.OU3)
    ..pPS(4, _omitFieldNames ? '' : 'exclusionPatternArray',
        protoName: 'exclusionPatternArray')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetFileCountRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetFileCountRequest copyWith(
          void Function(SSPGetFileCountRequest) updates) =>
      super.copyWith((message) => updates(message as SSPGetFileCountRequest))
          as SSPGetFileCountRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPGetFileCountRequest() / SSPGetFileCountRequest.new instead')
  static SSPGetFileCountRequest create() => SSPGetFileCountRequest._();
  static $pb.GeneratedMessage $_createMessage() => SSPGetFileCountRequest._();
  @$core.override
  SSPGetFileCountRequest createEmptyInstance() => SSPGetFileCountRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPGetFileCountRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPGetFileCountRequest>(
          SSPGetFileCountRequest.$_createMessage);
  static SSPGetFileCountRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  SSPFile get dir => $_getN(1);
  @$pb.TagNumber(2)
  set dir(SSPFile value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDir() => $_has(1);
  @$pb.TagNumber(2)
  void clearDir() => $_clearField(2);
  @$pb.TagNumber(2)
  SSPFile ensureDir() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.int get maxdepth => $_getIZ(2);
  @$pb.TagNumber(3)
  set maxdepth($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMaxdepth() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaxdepth() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get exclusionPatternArray => $_getList(3);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:209
class SSPGetFileCountResponse extends $pb.GeneratedMessage {
  factory SSPGetFileCountResponse({
    SSPRequestType? type,
    SSPFile? dir,
    $core.int? maxdepth,
    $core.Iterable<$core.String>? exclusionPatternArray,
    $fixnum.Int64? count,
  }) {
    final result = SSPGetFileCountResponse._();
    if (type != null) result.type = type;
    if (dir != null) result.dir = dir;
    if (maxdepth != null) result.maxdepth = maxdepth;
    if (exclusionPatternArray != null)
      result.exclusionPatternArray.addAll(exclusionPatternArray);
    if (count != null) result.count = count;
    return result;
  }

  SSPGetFileCountResponse._();

  factory SSPGetFileCountResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetFileCountResponse()..mergeFromBuffer(data, registry);
  factory SSPGetFileCountResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetFileCountResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPGetFileCountResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPGetFileCountResponse.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetFileCountRequest,
        enumValues: SSPRequestType.values)
    ..aOM<SSPFile>(2, _omitFieldNames ? '' : 'dir',
        subBuilder: SSPFile.$_createMessage)
    ..aI(3, _omitFieldNames ? '' : 'maxdepth', fieldType: $pb.PbFieldType.OU3)
    ..pPS(4, _omitFieldNames ? '' : 'exclusionPatternArray',
        protoName: 'exclusionPatternArray')
    ..a<$fixnum.Int64>(5, _omitFieldNames ? '' : 'count', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetFileCountResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetFileCountResponse copyWith(
          void Function(SSPGetFileCountResponse) updates) =>
      super.copyWith((message) => updates(message as SSPGetFileCountResponse))
          as SSPGetFileCountResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPGetFileCountResponse() / SSPGetFileCountResponse.new instead')
  static SSPGetFileCountResponse create() => SSPGetFileCountResponse._();
  static $pb.GeneratedMessage $_createMessage() => SSPGetFileCountResponse._();
  @$core.override
  SSPGetFileCountResponse createEmptyInstance() => SSPGetFileCountResponse._();
  @$core.pragma('dart2js:noInline')
  static SSPGetFileCountResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPGetFileCountResponse>(
          SSPGetFileCountResponse.$_createMessage);
  static SSPGetFileCountResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  SSPFile get dir => $_getN(1);
  @$pb.TagNumber(2)
  set dir(SSPFile value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDir() => $_has(1);
  @$pb.TagNumber(2)
  void clearDir() => $_clearField(2);
  @$pb.TagNumber(2)
  SSPFile ensureDir() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.int get maxdepth => $_getIZ(2);
  @$pb.TagNumber(3)
  set maxdepth($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMaxdepth() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaxdepth() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get exclusionPatternArray => $_getList(3);

  @$pb.TagNumber(5)
  $fixnum.Int64 get count => $_getI64(4);
  @$pb.TagNumber(5)
  set count($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCount() => $_has(4);
  @$pb.TagNumber(5)
  void clearCount() => $_clearField(5);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:215
class SSPFileExistRequest extends $pb.GeneratedMessage {
  factory SSPFileExistRequest({
    SSPRequestType? type,
    SSPFile? file,
  }) {
    final result = SSPFileExistRequest._();
    if (type != null) result.type = type;
    if (file != null) result.file = file;
    return result;
  }

  SSPFileExistRequest._();

  factory SSPFileExistRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPFileExistRequest()..mergeFromBuffer(data, registry);
  factory SSPFileExistRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPFileExistRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPFileExistRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPFileExistRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetFileExistRequest,
        enumValues: SSPRequestType.values)
    ..aOM<SSPFile>(2, _omitFieldNames ? '' : 'file',
        subBuilder: SSPFile.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPFileExistRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPFileExistRequest copyWith(void Function(SSPFileExistRequest) updates) =>
      super.copyWith((message) => updates(message as SSPFileExistRequest))
          as SSPFileExistRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use SSPFileExistRequest() / SSPFileExistRequest.new instead')
  static SSPFileExistRequest create() => SSPFileExistRequest._();
  static $pb.GeneratedMessage $_createMessage() => SSPFileExistRequest._();
  @$core.override
  SSPFileExistRequest createEmptyInstance() => SSPFileExistRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPFileExistRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPFileExistRequest>(
          SSPFileExistRequest.$_createMessage);
  static SSPFileExistRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  SSPFile get file => $_getN(1);
  @$pb.TagNumber(2)
  set file(SSPFile value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFile() => $_has(1);
  @$pb.TagNumber(2)
  void clearFile() => $_clearField(2);
  @$pb.TagNumber(2)
  SSPFile ensureFile() => $_ensure(1);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:218
class SSPFileExistResponse extends $pb.GeneratedMessage {
  factory SSPFileExistResponse({
    SSPRequestType? type,
    SSPFile? file,
    $core.bool? exist,
  }) {
    final result = SSPFileExistResponse._();
    if (type != null) result.type = type;
    if (file != null) result.file = file;
    if (exist != null) result.exist = exist;
    return result;
  }

  SSPFileExistResponse._();

  factory SSPFileExistResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPFileExistResponse()..mergeFromBuffer(data, registry);
  factory SSPFileExistResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPFileExistResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPFileExistResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPFileExistResponse.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetFileExistRequest,
        enumValues: SSPRequestType.values)
    ..aOM<SSPFile>(2, _omitFieldNames ? '' : 'file',
        subBuilder: SSPFile.$_createMessage)
    ..aOB(3, _omitFieldNames ? '' : 'exist')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPFileExistResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPFileExistResponse copyWith(void Function(SSPFileExistResponse) updates) =>
      super.copyWith((message) => updates(message as SSPFileExistResponse))
          as SSPFileExistResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPFileExistResponse() / SSPFileExistResponse.new instead')
  static SSPFileExistResponse create() => SSPFileExistResponse._();
  static $pb.GeneratedMessage $_createMessage() => SSPFileExistResponse._();
  @$core.override
  SSPFileExistResponse createEmptyInstance() => SSPFileExistResponse._();
  @$core.pragma('dart2js:noInline')
  static SSPFileExistResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPFileExistResponse>(
          SSPFileExistResponse.$_createMessage);
  static SSPFileExistResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  SSPFile get file => $_getN(1);
  @$pb.TagNumber(2)
  set file(SSPFile value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFile() => $_has(1);
  @$pb.TagNumber(2)
  void clearFile() => $_clearField(2);
  @$pb.TagNumber(2)
  SSPFile ensureFile() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.bool get exist => $_getBF(2);
  @$pb.TagNumber(3)
  set exist($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExist() => $_has(2);
  @$pb.TagNumber(3)
  void clearExist() => $_clearField(3);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:222
class SSPCreateFolderRequest extends $pb.GeneratedMessage {
  factory SSPCreateFolderRequest({
    SSPRequestType? type,
    SSPFile? file,
  }) {
    final result = SSPCreateFolderRequest._();
    if (type != null) result.type = type;
    if (file != null) result.file = file;
    return result;
  }

  SSPCreateFolderRequest._();

  factory SSPCreateFolderRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPCreateFolderRequest()..mergeFromBuffer(data, registry);
  factory SSPCreateFolderRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPCreateFolderRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPCreateFolderRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPCreateFolderRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetCreateFolderRequest,
        enumValues: SSPRequestType.values)
    ..aOM<SSPFile>(2, _omitFieldNames ? '' : 'file',
        subBuilder: SSPFile.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPCreateFolderRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPCreateFolderRequest copyWith(
          void Function(SSPCreateFolderRequest) updates) =>
      super.copyWith((message) => updates(message as SSPCreateFolderRequest))
          as SSPCreateFolderRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPCreateFolderRequest() / SSPCreateFolderRequest.new instead')
  static SSPCreateFolderRequest create() => SSPCreateFolderRequest._();
  static $pb.GeneratedMessage $_createMessage() => SSPCreateFolderRequest._();
  @$core.override
  SSPCreateFolderRequest createEmptyInstance() => SSPCreateFolderRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPCreateFolderRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPCreateFolderRequest>(
          SSPCreateFolderRequest.$_createMessage);
  static SSPCreateFolderRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  SSPFile get file => $_getN(1);
  @$pb.TagNumber(2)
  set file(SSPFile value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFile() => $_has(1);
  @$pb.TagNumber(2)
  void clearFile() => $_clearField(2);
  @$pb.TagNumber(2)
  SSPFile ensureFile() => $_ensure(1);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:225
class SSPCreateFolderResponse extends $pb.GeneratedMessage {
  factory SSPCreateFolderResponse({
    SSPRequestType? type,
    SSPFile? file,
    $core.bool? succeed,
    SSPFileIOError? errorCode,
    $core.String? errorMessage,
  }) {
    final result = SSPCreateFolderResponse._();
    if (type != null) result.type = type;
    if (file != null) result.file = file;
    if (succeed != null) result.succeed = succeed;
    if (errorCode != null) result.errorCode = errorCode;
    if (errorMessage != null) result.errorMessage = errorMessage;
    return result;
  }

  SSPCreateFolderResponse._();

  factory SSPCreateFolderResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPCreateFolderResponse()..mergeFromBuffer(data, registry);
  factory SSPCreateFolderResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPCreateFolderResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPCreateFolderResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPCreateFolderResponse.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetCreateFolderRequest,
        enumValues: SSPRequestType.values)
    ..aOM<SSPFile>(2, _omitFieldNames ? '' : 'file',
        subBuilder: SSPFile.$_createMessage)
    ..aOB(3, _omitFieldNames ? '' : 'succeed')
    ..aE<SSPFileIOError>(4, _omitFieldNames ? '' : 'errorCode',
        protoName: 'errorCode', enumValues: SSPFileIOError.values)
    ..aOS(5, _omitFieldNames ? '' : 'errorMessage', protoName: 'errorMessage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPCreateFolderResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPCreateFolderResponse copyWith(
          void Function(SSPCreateFolderResponse) updates) =>
      super.copyWith((message) => updates(message as SSPCreateFolderResponse))
          as SSPCreateFolderResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPCreateFolderResponse() / SSPCreateFolderResponse.new instead')
  static SSPCreateFolderResponse create() => SSPCreateFolderResponse._();
  static $pb.GeneratedMessage $_createMessage() => SSPCreateFolderResponse._();
  @$core.override
  SSPCreateFolderResponse createEmptyInstance() => SSPCreateFolderResponse._();
  @$core.pragma('dart2js:noInline')
  static SSPCreateFolderResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPCreateFolderResponse>(
          SSPCreateFolderResponse.$_createMessage);
  static SSPCreateFolderResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  SSPFile get file => $_getN(1);
  @$pb.TagNumber(2)
  set file(SSPFile value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFile() => $_has(1);
  @$pb.TagNumber(2)
  void clearFile() => $_clearField(2);
  @$pb.TagNumber(2)
  SSPFile ensureFile() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.bool get succeed => $_getBF(2);
  @$pb.TagNumber(3)
  set succeed($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSucceed() => $_has(2);
  @$pb.TagNumber(3)
  void clearSucceed() => $_clearField(3);

  @$pb.TagNumber(4)
  SSPFileIOError get errorCode => $_getN(3);
  @$pb.TagNumber(4)
  set errorCode(SSPFileIOError value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasErrorCode() => $_has(3);
  @$pb.TagNumber(4)
  void clearErrorCode() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get errorMessage => $_getSZ(4);
  @$pb.TagNumber(5)
  set errorMessage($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasErrorMessage() => $_has(4);
  @$pb.TagNumber(5)
  void clearErrorMessage() => $_clearField(5);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:231
class SSPRenameFileRequest extends $pb.GeneratedMessage {
  factory SSPRenameFileRequest({
    SSPRequestType? type,
    SSPFile? sourceFile,
    SSPFile? targetFile,
  }) {
    final result = SSPRenameFileRequest._();
    if (type != null) result.type = type;
    if (sourceFile != null) result.sourceFile = sourceFile;
    if (targetFile != null) result.targetFile = targetFile;
    return result;
  }

  SSPRenameFileRequest._();

  factory SSPRenameFileRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPRenameFileRequest()..mergeFromBuffer(data, registry);
  factory SSPRenameFileRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPRenameFileRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPRenameFileRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPRenameFileRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetRenameFileRequest,
        enumValues: SSPRequestType.values)
    ..aOM<SSPFile>(2, _omitFieldNames ? '' : 'sourceFile',
        protoName: 'sourceFile', subBuilder: SSPFile.$_createMessage)
    ..aOM<SSPFile>(3, _omitFieldNames ? '' : 'targetFile',
        protoName: 'targetFile', subBuilder: SSPFile.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPRenameFileRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPRenameFileRequest copyWith(void Function(SSPRenameFileRequest) updates) =>
      super.copyWith((message) => updates(message as SSPRenameFileRequest))
          as SSPRenameFileRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPRenameFileRequest() / SSPRenameFileRequest.new instead')
  static SSPRenameFileRequest create() => SSPRenameFileRequest._();
  static $pb.GeneratedMessage $_createMessage() => SSPRenameFileRequest._();
  @$core.override
  SSPRenameFileRequest createEmptyInstance() => SSPRenameFileRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPRenameFileRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPRenameFileRequest>(
          SSPRenameFileRequest.$_createMessage);
  static SSPRenameFileRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  SSPFile get sourceFile => $_getN(1);
  @$pb.TagNumber(2)
  set sourceFile(SSPFile value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSourceFile() => $_has(1);
  @$pb.TagNumber(2)
  void clearSourceFile() => $_clearField(2);
  @$pb.TagNumber(2)
  SSPFile ensureSourceFile() => $_ensure(1);

  @$pb.TagNumber(3)
  SSPFile get targetFile => $_getN(2);
  @$pb.TagNumber(3)
  set targetFile(SSPFile value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasTargetFile() => $_has(2);
  @$pb.TagNumber(3)
  void clearTargetFile() => $_clearField(3);
  @$pb.TagNumber(3)
  SSPFile ensureTargetFile() => $_ensure(2);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:235
class SSPRenameFileResponse extends $pb.GeneratedMessage {
  factory SSPRenameFileResponse({
    SSPRequestType? type,
    SSPFile? sourceFile,
    SSPFile? targetFile,
    $core.bool? succeed,
    SSPFileIOError? errorCode,
    $core.String? errorMessage,
  }) {
    final result = SSPRenameFileResponse._();
    if (type != null) result.type = type;
    if (sourceFile != null) result.sourceFile = sourceFile;
    if (targetFile != null) result.targetFile = targetFile;
    if (succeed != null) result.succeed = succeed;
    if (errorCode != null) result.errorCode = errorCode;
    if (errorMessage != null) result.errorMessage = errorMessage;
    return result;
  }

  SSPRenameFileResponse._();

  factory SSPRenameFileResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPRenameFileResponse()..mergeFromBuffer(data, registry);
  factory SSPRenameFileResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPRenameFileResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPRenameFileResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPRenameFileResponse.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetRenameFileRequest,
        enumValues: SSPRequestType.values)
    ..aOM<SSPFile>(2, _omitFieldNames ? '' : 'sourceFile',
        protoName: 'sourceFile', subBuilder: SSPFile.$_createMessage)
    ..aOM<SSPFile>(3, _omitFieldNames ? '' : 'targetFile',
        protoName: 'targetFile', subBuilder: SSPFile.$_createMessage)
    ..aOB(4, _omitFieldNames ? '' : 'succeed')
    ..aE<SSPFileIOError>(5, _omitFieldNames ? '' : 'errorCode',
        protoName: 'errorCode', enumValues: SSPFileIOError.values)
    ..aOS(6, _omitFieldNames ? '' : 'errorMessage', protoName: 'errorMessage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPRenameFileResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPRenameFileResponse copyWith(
          void Function(SSPRenameFileResponse) updates) =>
      super.copyWith((message) => updates(message as SSPRenameFileResponse))
          as SSPRenameFileResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPRenameFileResponse() / SSPRenameFileResponse.new instead')
  static SSPRenameFileResponse create() => SSPRenameFileResponse._();
  static $pb.GeneratedMessage $_createMessage() => SSPRenameFileResponse._();
  @$core.override
  SSPRenameFileResponse createEmptyInstance() => SSPRenameFileResponse._();
  @$core.pragma('dart2js:noInline')
  static SSPRenameFileResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPRenameFileResponse>(
          SSPRenameFileResponse.$_createMessage);
  static SSPRenameFileResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  SSPFile get sourceFile => $_getN(1);
  @$pb.TagNumber(2)
  set sourceFile(SSPFile value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSourceFile() => $_has(1);
  @$pb.TagNumber(2)
  void clearSourceFile() => $_clearField(2);
  @$pb.TagNumber(2)
  SSPFile ensureSourceFile() => $_ensure(1);

  @$pb.TagNumber(3)
  SSPFile get targetFile => $_getN(2);
  @$pb.TagNumber(3)
  set targetFile(SSPFile value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasTargetFile() => $_has(2);
  @$pb.TagNumber(3)
  void clearTargetFile() => $_clearField(3);
  @$pb.TagNumber(3)
  SSPFile ensureTargetFile() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.bool get succeed => $_getBF(3);
  @$pb.TagNumber(4)
  set succeed($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSucceed() => $_has(3);
  @$pb.TagNumber(4)
  void clearSucceed() => $_clearField(4);

  @$pb.TagNumber(5)
  SSPFileIOError get errorCode => $_getN(4);
  @$pb.TagNumber(5)
  set errorCode(SSPFileIOError value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasErrorCode() => $_has(4);
  @$pb.TagNumber(5)
  void clearErrorCode() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get errorMessage => $_getSZ(5);
  @$pb.TagNumber(6)
  set errorMessage($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasErrorMessage() => $_has(5);
  @$pb.TagNumber(6)
  void clearErrorMessage() => $_clearField(6);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:242
class SSPDeleteFileRequest extends $pb.GeneratedMessage {
  factory SSPDeleteFileRequest({
    SSPRequestType? type,
    SSPFile? file,
    $core.bool? isSync,
    $core.bool? isTrash,
  }) {
    final result = SSPDeleteFileRequest._();
    if (type != null) result.type = type;
    if (file != null) result.file = file;
    if (isSync != null) result.isSync = isSync;
    if (isTrash != null) result.isTrash = isTrash;
    return result;
  }

  SSPDeleteFileRequest._();

  factory SSPDeleteFileRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPDeleteFileRequest()..mergeFromBuffer(data, registry);
  factory SSPDeleteFileRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPDeleteFileRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPDeleteFileRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPDeleteFileRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetDeleteFileRequest,
        enumValues: SSPRequestType.values)
    ..aOM<SSPFile>(2, _omitFieldNames ? '' : 'file',
        subBuilder: SSPFile.$_createMessage)
    ..aOB(3, _omitFieldNames ? '' : 'isSync', protoName: 'isSync')
    ..aOB(4, _omitFieldNames ? '' : 'isTrash', protoName: 'isTrash')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPDeleteFileRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPDeleteFileRequest copyWith(void Function(SSPDeleteFileRequest) updates) =>
      super.copyWith((message) => updates(message as SSPDeleteFileRequest))
          as SSPDeleteFileRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPDeleteFileRequest() / SSPDeleteFileRequest.new instead')
  static SSPDeleteFileRequest create() => SSPDeleteFileRequest._();
  static $pb.GeneratedMessage $_createMessage() => SSPDeleteFileRequest._();
  @$core.override
  SSPDeleteFileRequest createEmptyInstance() => SSPDeleteFileRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPDeleteFileRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPDeleteFileRequest>(
          SSPDeleteFileRequest.$_createMessage);
  static SSPDeleteFileRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  SSPFile get file => $_getN(1);
  @$pb.TagNumber(2)
  set file(SSPFile value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFile() => $_has(1);
  @$pb.TagNumber(2)
  void clearFile() => $_clearField(2);
  @$pb.TagNumber(2)
  SSPFile ensureFile() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.bool get isSync => $_getBF(2);
  @$pb.TagNumber(3)
  set isSync($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIsSync() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsSync() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get isTrash => $_getBF(3);
  @$pb.TagNumber(4)
  set isTrash($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIsTrash() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsTrash() => $_clearField(4);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:247
class SSPDeleteFileResponse extends $pb.GeneratedMessage {
  factory SSPDeleteFileResponse({
    SSPRequestType? type,
    SSPFile? file,
    $core.bool? succeed,
    SSPFileIOError? errorCode,
    $core.String? errorMessage,
  }) {
    final result = SSPDeleteFileResponse._();
    if (type != null) result.type = type;
    if (file != null) result.file = file;
    if (succeed != null) result.succeed = succeed;
    if (errorCode != null) result.errorCode = errorCode;
    if (errorMessage != null) result.errorMessage = errorMessage;
    return result;
  }

  SSPDeleteFileResponse._();

  factory SSPDeleteFileResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPDeleteFileResponse()..mergeFromBuffer(data, registry);
  factory SSPDeleteFileResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPDeleteFileResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPDeleteFileResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPDeleteFileResponse.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetDeleteFileRequest,
        enumValues: SSPRequestType.values)
    ..aOM<SSPFile>(2, _omitFieldNames ? '' : 'file',
        subBuilder: SSPFile.$_createMessage)
    ..aOB(4, _omitFieldNames ? '' : 'succeed')
    ..aE<SSPFileIOError>(5, _omitFieldNames ? '' : 'errorCode',
        protoName: 'errorCode', enumValues: SSPFileIOError.values)
    ..aOS(6, _omitFieldNames ? '' : 'errorMessage', protoName: 'errorMessage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPDeleteFileResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPDeleteFileResponse copyWith(
          void Function(SSPDeleteFileResponse) updates) =>
      super.copyWith((message) => updates(message as SSPDeleteFileResponse))
          as SSPDeleteFileResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPDeleteFileResponse() / SSPDeleteFileResponse.new instead')
  static SSPDeleteFileResponse create() => SSPDeleteFileResponse._();
  static $pb.GeneratedMessage $_createMessage() => SSPDeleteFileResponse._();
  @$core.override
  SSPDeleteFileResponse createEmptyInstance() => SSPDeleteFileResponse._();
  @$core.pragma('dart2js:noInline')
  static SSPDeleteFileResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPDeleteFileResponse>(
          SSPDeleteFileResponse.$_createMessage);
  static SSPDeleteFileResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  SSPFile get file => $_getN(1);
  @$pb.TagNumber(2)
  set file(SSPFile value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFile() => $_has(1);
  @$pb.TagNumber(2)
  void clearFile() => $_clearField(2);
  @$pb.TagNumber(2)
  SSPFile ensureFile() => $_ensure(1);

  @$pb.TagNumber(4)
  $core.bool get succeed => $_getBF(2);
  @$pb.TagNumber(4)
  set succeed($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(4)
  $core.bool hasSucceed() => $_has(2);
  @$pb.TagNumber(4)
  void clearSucceed() => $_clearField(4);

  @$pb.TagNumber(5)
  SSPFileIOError get errorCode => $_getN(3);
  @$pb.TagNumber(5)
  set errorCode(SSPFileIOError value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasErrorCode() => $_has(3);
  @$pb.TagNumber(5)
  void clearErrorCode() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get errorMessage => $_getSZ(4);
  @$pb.TagNumber(6)
  set errorMessage($core.String value) => $_setString(4, value);
  @$pb.TagNumber(6)
  $core.bool hasErrorMessage() => $_has(4);
  @$pb.TagNumber(6)
  void clearErrorMessage() => $_clearField(6);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:253
class SSPMonitorFolderRequest extends $pb.GeneratedMessage {
  factory SSPMonitorFolderRequest({
    SSPRequestType? type,
    SSPFile? file,
    $core.bool? registerP,
  }) {
    final result = SSPMonitorFolderRequest._();
    if (type != null) result.type = type;
    if (file != null) result.file = file;
    if (registerP != null) result.registerP = registerP;
    return result;
  }

  SSPMonitorFolderRequest._();

  factory SSPMonitorFolderRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPMonitorFolderRequest()..mergeFromBuffer(data, registry);
  factory SSPMonitorFolderRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPMonitorFolderRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPMonitorFolderRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPMonitorFolderRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_MonitorFolderRequest,
        enumValues: SSPRequestType.values)
    ..aOM<SSPFile>(2, _omitFieldNames ? '' : 'file',
        subBuilder: SSPFile.$_createMessage)
    ..aOB(3, _omitFieldNames ? '' : 'registerP')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPMonitorFolderRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPMonitorFolderRequest copyWith(
          void Function(SSPMonitorFolderRequest) updates) =>
      super.copyWith((message) => updates(message as SSPMonitorFolderRequest))
          as SSPMonitorFolderRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPMonitorFolderRequest() / SSPMonitorFolderRequest.new instead')
  static SSPMonitorFolderRequest create() => SSPMonitorFolderRequest._();
  static $pb.GeneratedMessage $_createMessage() => SSPMonitorFolderRequest._();
  @$core.override
  SSPMonitorFolderRequest createEmptyInstance() => SSPMonitorFolderRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPMonitorFolderRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPMonitorFolderRequest>(
          SSPMonitorFolderRequest.$_createMessage);
  static SSPMonitorFolderRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  SSPFile get file => $_getN(1);
  @$pb.TagNumber(2)
  set file(SSPFile value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFile() => $_has(1);
  @$pb.TagNumber(2)
  void clearFile() => $_clearField(2);
  @$pb.TagNumber(2)
  SSPFile ensureFile() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.bool get registerP => $_getBF(2);
  @$pb.TagNumber(3)
  set registerP($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRegisterP() => $_has(2);
  @$pb.TagNumber(3)
  void clearRegisterP() => $_clearField(3);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:257
class SSPMonitorFolderResponseHeader extends $pb.GeneratedMessage {
  factory SSPMonitorFolderResponseHeader({
    SSPRequestType? type,
    $core.bool? succeed,
    $core.String? errorMessage,
  }) {
    final result = SSPMonitorFolderResponseHeader._();
    if (type != null) result.type = type;
    if (succeed != null) result.succeed = succeed;
    if (errorMessage != null) result.errorMessage = errorMessage;
    return result;
  }

  SSPMonitorFolderResponseHeader._();

  factory SSPMonitorFolderResponseHeader.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPMonitorFolderResponseHeader()..mergeFromBuffer(data, registry);
  factory SSPMonitorFolderResponseHeader.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPMonitorFolderResponseHeader()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPMonitorFolderResponseHeader',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPMonitorFolderResponseHeader.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker:
            SSPRequestType.SSPRequestType_MonitorFolderResponseHeader,
        enumValues: SSPRequestType.values)
    ..aOB(2, _omitFieldNames ? '' : 'succeed')
    ..aOS(3, _omitFieldNames ? '' : 'errorMessage', protoName: 'errorMessage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPMonitorFolderResponseHeader clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPMonitorFolderResponseHeader copyWith(
          void Function(SSPMonitorFolderResponseHeader) updates) =>
      super.copyWith(
              (message) => updates(message as SSPMonitorFolderResponseHeader))
          as SSPMonitorFolderResponseHeader;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPMonitorFolderResponseHeader() / SSPMonitorFolderResponseHeader.new instead')
  static SSPMonitorFolderResponseHeader create() =>
      SSPMonitorFolderResponseHeader._();
  static $pb.GeneratedMessage $_createMessage() =>
      SSPMonitorFolderResponseHeader._();
  @$core.override
  SSPMonitorFolderResponseHeader createEmptyInstance() =>
      SSPMonitorFolderResponseHeader._();
  @$core.pragma('dart2js:noInline')
  static SSPMonitorFolderResponseHeader getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPMonitorFolderResponseHeader>(
          SSPMonitorFolderResponseHeader.$_createMessage);
  static SSPMonitorFolderResponseHeader? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get succeed => $_getBF(1);
  @$pb.TagNumber(2)
  set succeed($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSucceed() => $_has(1);
  @$pb.TagNumber(2)
  void clearSucceed() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get errorMessage => $_getSZ(2);
  @$pb.TagNumber(3)
  set errorMessage($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasErrorMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearErrorMessage() => $_clearField(3);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:261
class SSPMonitorFolderResponse extends $pb.GeneratedMessage {
  factory SSPMonitorFolderResponse({
    SSPRequestType? type,
    $core.Iterable<SSPFileEvent>? eventArray,
  }) {
    final result = SSPMonitorFolderResponse._();
    if (type != null) result.type = type;
    if (eventArray != null) result.eventArray.addAll(eventArray);
    return result;
  }

  SSPMonitorFolderResponse._();

  factory SSPMonitorFolderResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPMonitorFolderResponse()..mergeFromBuffer(data, registry);
  factory SSPMonitorFolderResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPMonitorFolderResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPMonitorFolderResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPMonitorFolderResponse.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_MonitorFolderResponse,
        enumValues: SSPRequestType.values)
    ..pPM<SSPFileEvent>(2, _omitFieldNames ? '' : 'eventArray',
        protoName: 'eventArray', subBuilder: SSPFileEvent.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPMonitorFolderResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPMonitorFolderResponse copyWith(
          void Function(SSPMonitorFolderResponse) updates) =>
      super.copyWith((message) => updates(message as SSPMonitorFolderResponse))
          as SSPMonitorFolderResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPMonitorFolderResponse() / SSPMonitorFolderResponse.new instead')
  static SSPMonitorFolderResponse create() => SSPMonitorFolderResponse._();
  static $pb.GeneratedMessage $_createMessage() => SSPMonitorFolderResponse._();
  @$core.override
  SSPMonitorFolderResponse createEmptyInstance() =>
      SSPMonitorFolderResponse._();
  @$core.pragma('dart2js:noInline')
  static SSPMonitorFolderResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPMonitorFolderResponse>(
          SSPMonitorFolderResponse.$_createMessage);
  static SSPMonitorFolderResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<SSPFileEvent> get eventArray => $_getList(1);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:264
class SSPDownloadFileRequest extends $pb.GeneratedMessage {
  factory SSPDownloadFileRequest({
    SSPRequestType? type,
    SSPFile? file,
    SSPDataRange? range,
    $core.bool? needMd5,
    $core.bool? gzip,
    $core.bool? isSync,
  }) {
    final result = SSPDownloadFileRequest._();
    if (type != null) result.type = type;
    if (file != null) result.file = file;
    if (range != null) result.range = range;
    if (needMd5 != null) result.needMd5 = needMd5;
    if (gzip != null) result.gzip = gzip;
    if (isSync != null) result.isSync = isSync;
    return result;
  }

  SSPDownloadFileRequest._();

  factory SSPDownloadFileRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPDownloadFileRequest()..mergeFromBuffer(data, registry);
  factory SSPDownloadFileRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPDownloadFileRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPDownloadFileRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPDownloadFileRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetDownloadFileRequest,
        enumValues: SSPRequestType.values)
    ..aOM<SSPFile>(2, _omitFieldNames ? '' : 'file',
        subBuilder: SSPFile.$_createMessage)
    ..aOM<SSPDataRange>(3, _omitFieldNames ? '' : 'range',
        subBuilder: SSPDataRange.$_createMessage)
    ..aOB(4, _omitFieldNames ? '' : 'needMd5', protoName: 'needMd5')
    ..aOB(5, _omitFieldNames ? '' : 'gzip')
    ..aOB(6, _omitFieldNames ? '' : 'isSync', protoName: 'isSync')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPDownloadFileRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPDownloadFileRequest copyWith(
          void Function(SSPDownloadFileRequest) updates) =>
      super.copyWith((message) => updates(message as SSPDownloadFileRequest))
          as SSPDownloadFileRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPDownloadFileRequest() / SSPDownloadFileRequest.new instead')
  static SSPDownloadFileRequest create() => SSPDownloadFileRequest._();
  static $pb.GeneratedMessage $_createMessage() => SSPDownloadFileRequest._();
  @$core.override
  SSPDownloadFileRequest createEmptyInstance() => SSPDownloadFileRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPDownloadFileRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPDownloadFileRequest>(
          SSPDownloadFileRequest.$_createMessage);
  static SSPDownloadFileRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  SSPFile get file => $_getN(1);
  @$pb.TagNumber(2)
  set file(SSPFile value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFile() => $_has(1);
  @$pb.TagNumber(2)
  void clearFile() => $_clearField(2);
  @$pb.TagNumber(2)
  SSPFile ensureFile() => $_ensure(1);

  @$pb.TagNumber(3)
  SSPDataRange get range => $_getN(2);
  @$pb.TagNumber(3)
  set range(SSPDataRange value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasRange() => $_has(2);
  @$pb.TagNumber(3)
  void clearRange() => $_clearField(3);
  @$pb.TagNumber(3)
  SSPDataRange ensureRange() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.bool get needMd5 => $_getBF(3);
  @$pb.TagNumber(4)
  set needMd5($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNeedMd5() => $_has(3);
  @$pb.TagNumber(4)
  void clearNeedMd5() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get gzip => $_getBF(4);
  @$pb.TagNumber(5)
  set gzip($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasGzip() => $_has(4);
  @$pb.TagNumber(5)
  void clearGzip() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get isSync => $_getBF(5);
  @$pb.TagNumber(6)
  set isSync($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasIsSync() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsSync() => $_clearField(6);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:271
class SSPDownloadFileResponseHeader extends $pb.GeneratedMessage {
  factory SSPDownloadFileResponseHeader({
    SSPRequestType? type,
    SSPFile? file,
    SSPDataRange? range,
    $core.bool? needMd5,
    $core.String? dataMd5,
    $core.bool? ready,
    SSPFileIOError? errorCode,
  }) {
    final result = SSPDownloadFileResponseHeader._();
    if (type != null) result.type = type;
    if (file != null) result.file = file;
    if (range != null) result.range = range;
    if (needMd5 != null) result.needMd5 = needMd5;
    if (dataMd5 != null) result.dataMd5 = dataMd5;
    if (ready != null) result.ready = ready;
    if (errorCode != null) result.errorCode = errorCode;
    return result;
  }

  SSPDownloadFileResponseHeader._();

  factory SSPDownloadFileResponseHeader.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPDownloadFileResponseHeader()..mergeFromBuffer(data, registry);
  factory SSPDownloadFileResponseHeader.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPDownloadFileResponseHeader()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPDownloadFileResponseHeader',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPDownloadFileResponseHeader.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker:
            SSPRequestType.SSPRequestType_GetDownloadFileResponseHeader,
        enumValues: SSPRequestType.values)
    ..aOM<SSPFile>(2, _omitFieldNames ? '' : 'file',
        subBuilder: SSPFile.$_createMessage)
    ..aOM<SSPDataRange>(3, _omitFieldNames ? '' : 'range',
        subBuilder: SSPDataRange.$_createMessage)
    ..aOB(4, _omitFieldNames ? '' : 'needMd5', protoName: 'needMd5')
    ..aOS(5, _omitFieldNames ? '' : 'dataMd5', protoName: 'dataMd5')
    ..aOB(6, _omitFieldNames ? '' : 'ready')
    ..aE<SSPFileIOError>(7, _omitFieldNames ? '' : 'errorCode',
        protoName: 'errorCode', enumValues: SSPFileIOError.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPDownloadFileResponseHeader clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPDownloadFileResponseHeader copyWith(
          void Function(SSPDownloadFileResponseHeader) updates) =>
      super.copyWith(
              (message) => updates(message as SSPDownloadFileResponseHeader))
          as SSPDownloadFileResponseHeader;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPDownloadFileResponseHeader() / SSPDownloadFileResponseHeader.new instead')
  static SSPDownloadFileResponseHeader create() =>
      SSPDownloadFileResponseHeader._();
  static $pb.GeneratedMessage $_createMessage() =>
      SSPDownloadFileResponseHeader._();
  @$core.override
  SSPDownloadFileResponseHeader createEmptyInstance() =>
      SSPDownloadFileResponseHeader._();
  @$core.pragma('dart2js:noInline')
  static SSPDownloadFileResponseHeader getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPDownloadFileResponseHeader>(
          SSPDownloadFileResponseHeader.$_createMessage);
  static SSPDownloadFileResponseHeader? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  SSPFile get file => $_getN(1);
  @$pb.TagNumber(2)
  set file(SSPFile value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFile() => $_has(1);
  @$pb.TagNumber(2)
  void clearFile() => $_clearField(2);
  @$pb.TagNumber(2)
  SSPFile ensureFile() => $_ensure(1);

  @$pb.TagNumber(3)
  SSPDataRange get range => $_getN(2);
  @$pb.TagNumber(3)
  set range(SSPDataRange value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasRange() => $_has(2);
  @$pb.TagNumber(3)
  void clearRange() => $_clearField(3);
  @$pb.TagNumber(3)
  SSPDataRange ensureRange() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.bool get needMd5 => $_getBF(3);
  @$pb.TagNumber(4)
  set needMd5($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNeedMd5() => $_has(3);
  @$pb.TagNumber(4)
  void clearNeedMd5() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get dataMd5 => $_getSZ(4);
  @$pb.TagNumber(5)
  set dataMd5($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDataMd5() => $_has(4);
  @$pb.TagNumber(5)
  void clearDataMd5() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get ready => $_getBF(5);
  @$pb.TagNumber(6)
  set ready($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasReady() => $_has(5);
  @$pb.TagNumber(6)
  void clearReady() => $_clearField(6);

  @$pb.TagNumber(7)
  SSPFileIOError get errorCode => $_getN(6);
  @$pb.TagNumber(7)
  set errorCode(SSPFileIOError value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasErrorCode() => $_has(6);
  @$pb.TagNumber(7)
  void clearErrorCode() => $_clearField(7);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:279
class SSPUploadFileRequest extends $pb.GeneratedMessage {
  factory SSPUploadFileRequest({
    SSPRequestType? type,
    SSPFile? file,
    $core.String? dataMd5,
    $core.bool? gzip,
    $core.bool? isSync,
  }) {
    final result = SSPUploadFileRequest._();
    if (type != null) result.type = type;
    if (file != null) result.file = file;
    if (dataMd5 != null) result.dataMd5 = dataMd5;
    if (gzip != null) result.gzip = gzip;
    if (isSync != null) result.isSync = isSync;
    return result;
  }

  SSPUploadFileRequest._();

  factory SSPUploadFileRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPUploadFileRequest()..mergeFromBuffer(data, registry);
  factory SSPUploadFileRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPUploadFileRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPUploadFileRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPUploadFileRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker:
            SSPRequestType.SSPRequestType_GetUploadFileRequestHeader,
        enumValues: SSPRequestType.values)
    ..aOM<SSPFile>(2, _omitFieldNames ? '' : 'file',
        subBuilder: SSPFile.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'dataMd5', protoName: 'dataMd5')
    ..aOB(4, _omitFieldNames ? '' : 'gzip')
    ..aOB(5, _omitFieldNames ? '' : 'isSync', protoName: 'isSync')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPUploadFileRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPUploadFileRequest copyWith(void Function(SSPUploadFileRequest) updates) =>
      super.copyWith((message) => updates(message as SSPUploadFileRequest))
          as SSPUploadFileRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPUploadFileRequest() / SSPUploadFileRequest.new instead')
  static SSPUploadFileRequest create() => SSPUploadFileRequest._();
  static $pb.GeneratedMessage $_createMessage() => SSPUploadFileRequest._();
  @$core.override
  SSPUploadFileRequest createEmptyInstance() => SSPUploadFileRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPUploadFileRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPUploadFileRequest>(
          SSPUploadFileRequest.$_createMessage);
  static SSPUploadFileRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  SSPFile get file => $_getN(1);
  @$pb.TagNumber(2)
  set file(SSPFile value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFile() => $_has(1);
  @$pb.TagNumber(2)
  void clearFile() => $_clearField(2);
  @$pb.TagNumber(2)
  SSPFile ensureFile() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get dataMd5 => $_getSZ(2);
  @$pb.TagNumber(3)
  set dataMd5($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDataMd5() => $_has(2);
  @$pb.TagNumber(3)
  void clearDataMd5() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get gzip => $_getBF(3);
  @$pb.TagNumber(4)
  set gzip($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGzip() => $_has(3);
  @$pb.TagNumber(4)
  void clearGzip() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get isSync => $_getBF(4);
  @$pb.TagNumber(5)
  set isSync($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIsSync() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsSync() => $_clearField(5);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:285
/// Raw default type=18 is intentional. Enum header value=16; operation override is unverified.
class SSPUploadFileResponseHeader extends $pb.GeneratedMessage {
  factory SSPUploadFileResponseHeader({
    SSPRequestType? type,
    SSPFile? file,
    $core.bool? ready,
    SSPFileIOError? errorCode,
  }) {
    final result = SSPUploadFileResponseHeader._();
    if (type != null) result.type = type;
    if (file != null) result.file = file;
    if (ready != null) result.ready = ready;
    if (errorCode != null) result.errorCode = errorCode;
    return result;
  }

  SSPUploadFileResponseHeader._();

  factory SSPUploadFileResponseHeader.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPUploadFileResponseHeader()..mergeFromBuffer(data, registry);
  factory SSPUploadFileResponseHeader.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPUploadFileResponseHeader()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPUploadFileResponseHeader',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPUploadFileResponseHeader.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetUploadFileResponse,
        enumValues: SSPRequestType.values)
    ..aOM<SSPFile>(2, _omitFieldNames ? '' : 'file',
        subBuilder: SSPFile.$_createMessage)
    ..aOB(3, _omitFieldNames ? '' : 'ready')
    ..aE<SSPFileIOError>(4, _omitFieldNames ? '' : 'errorCode',
        protoName: 'errorCode', enumValues: SSPFileIOError.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPUploadFileResponseHeader clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPUploadFileResponseHeader copyWith(
          void Function(SSPUploadFileResponseHeader) updates) =>
      super.copyWith(
              (message) => updates(message as SSPUploadFileResponseHeader))
          as SSPUploadFileResponseHeader;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPUploadFileResponseHeader() / SSPUploadFileResponseHeader.new instead')
  static SSPUploadFileResponseHeader create() =>
      SSPUploadFileResponseHeader._();
  static $pb.GeneratedMessage $_createMessage() =>
      SSPUploadFileResponseHeader._();
  @$core.override
  SSPUploadFileResponseHeader createEmptyInstance() =>
      SSPUploadFileResponseHeader._();
  @$core.pragma('dart2js:noInline')
  static SSPUploadFileResponseHeader getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPUploadFileResponseHeader>(
          SSPUploadFileResponseHeader.$_createMessage);
  static SSPUploadFileResponseHeader? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  SSPFile get file => $_getN(1);
  @$pb.TagNumber(2)
  set file(SSPFile value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFile() => $_has(1);
  @$pb.TagNumber(2)
  void clearFile() => $_clearField(2);
  @$pb.TagNumber(2)
  SSPFile ensureFile() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.bool get ready => $_getBF(2);
  @$pb.TagNumber(3)
  set ready($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReady() => $_has(2);
  @$pb.TagNumber(3)
  void clearReady() => $_clearField(3);

  @$pb.TagNumber(4)
  SSPFileIOError get errorCode => $_getN(3);
  @$pb.TagNumber(4)
  set errorCode(SSPFileIOError value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasErrorCode() => $_has(3);
  @$pb.TagNumber(4)
  void clearErrorCode() => $_clearField(4);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:290
class SSPUploadFileResponse extends $pb.GeneratedMessage {
  factory SSPUploadFileResponse({
    SSPRequestType? type,
    SSPFile? file,
    $core.bool? canceled,
    $core.bool? succeed,
    SSPFileIOError? errorCode,
  }) {
    final result = SSPUploadFileResponse._();
    if (type != null) result.type = type;
    if (file != null) result.file = file;
    if (canceled != null) result.canceled = canceled;
    if (succeed != null) result.succeed = succeed;
    if (errorCode != null) result.errorCode = errorCode;
    return result;
  }

  SSPUploadFileResponse._();

  factory SSPUploadFileResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPUploadFileResponse()..mergeFromBuffer(data, registry);
  factory SSPUploadFileResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPUploadFileResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPUploadFileResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPUploadFileResponse.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetUploadFileResponse,
        enumValues: SSPRequestType.values)
    ..aOM<SSPFile>(2, _omitFieldNames ? '' : 'file',
        subBuilder: SSPFile.$_createMessage)
    ..aOB(3, _omitFieldNames ? '' : 'canceled')
    ..aOB(4, _omitFieldNames ? '' : 'succeed')
    ..aE<SSPFileIOError>(5, _omitFieldNames ? '' : 'errorCode',
        protoName: 'errorCode', enumValues: SSPFileIOError.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPUploadFileResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPUploadFileResponse copyWith(
          void Function(SSPUploadFileResponse) updates) =>
      super.copyWith((message) => updates(message as SSPUploadFileResponse))
          as SSPUploadFileResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPUploadFileResponse() / SSPUploadFileResponse.new instead')
  static SSPUploadFileResponse create() => SSPUploadFileResponse._();
  static $pb.GeneratedMessage $_createMessage() => SSPUploadFileResponse._();
  @$core.override
  SSPUploadFileResponse createEmptyInstance() => SSPUploadFileResponse._();
  @$core.pragma('dart2js:noInline')
  static SSPUploadFileResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPUploadFileResponse>(
          SSPUploadFileResponse.$_createMessage);
  static SSPUploadFileResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  SSPFile get file => $_getN(1);
  @$pb.TagNumber(2)
  set file(SSPFile value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFile() => $_has(1);
  @$pb.TagNumber(2)
  void clearFile() => $_clearField(2);
  @$pb.TagNumber(2)
  SSPFile ensureFile() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.bool get canceled => $_getBF(2);
  @$pb.TagNumber(3)
  set canceled($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCanceled() => $_has(2);
  @$pb.TagNumber(3)
  void clearCanceled() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get succeed => $_getBF(3);
  @$pb.TagNumber(4)
  set succeed($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSucceed() => $_has(3);
  @$pb.TagNumber(4)
  void clearSucceed() => $_clearField(4);

  @$pb.TagNumber(5)
  SSPFileIOError get errorCode => $_getN(4);
  @$pb.TagNumber(5)
  set errorCode(SSPFileIOError value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasErrorCode() => $_has(4);
  @$pb.TagNumber(5)
  void clearErrorCode() => $_clearField(5);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:296
class SSPGetThumbnailRequest extends $pb.GeneratedMessage {
  factory SSPGetThumbnailRequest({
    SSPRequestType? type,
    $core.Iterable<SSPImageFile>? imageArray,
    $core.Iterable<SSPVideoFile>? videoArray,
    $core.Iterable<SSPAudioAlbum>? audioAlbumArray,
  }) {
    final result = SSPGetThumbnailRequest._();
    if (type != null) result.type = type;
    if (imageArray != null) result.imageArray.addAll(imageArray);
    if (videoArray != null) result.videoArray.addAll(videoArray);
    if (audioAlbumArray != null) result.audioAlbumArray.addAll(audioAlbumArray);
    return result;
  }

  SSPGetThumbnailRequest._();

  factory SSPGetThumbnailRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetThumbnailRequest()..mergeFromBuffer(data, registry);
  factory SSPGetThumbnailRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetThumbnailRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPGetThumbnailRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPGetThumbnailRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetThumbnailRequest,
        enumValues: SSPRequestType.values)
    ..pPM<SSPImageFile>(2, _omitFieldNames ? '' : 'imageArray',
        protoName: 'imageArray', subBuilder: SSPImageFile.$_createMessage)
    ..pPM<SSPVideoFile>(3, _omitFieldNames ? '' : 'videoArray',
        protoName: 'videoArray', subBuilder: SSPVideoFile.$_createMessage)
    ..pPM<SSPAudioAlbum>(4, _omitFieldNames ? '' : 'audioAlbumArray',
        protoName: 'audioAlbumArray', subBuilder: SSPAudioAlbum.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetThumbnailRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetThumbnailRequest copyWith(
          void Function(SSPGetThumbnailRequest) updates) =>
      super.copyWith((message) => updates(message as SSPGetThumbnailRequest))
          as SSPGetThumbnailRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPGetThumbnailRequest() / SSPGetThumbnailRequest.new instead')
  static SSPGetThumbnailRequest create() => SSPGetThumbnailRequest._();
  static $pb.GeneratedMessage $_createMessage() => SSPGetThumbnailRequest._();
  @$core.override
  SSPGetThumbnailRequest createEmptyInstance() => SSPGetThumbnailRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPGetThumbnailRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPGetThumbnailRequest>(
          SSPGetThumbnailRequest.$_createMessage);
  static SSPGetThumbnailRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<SSPImageFile> get imageArray => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<SSPVideoFile> get videoArray => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<SSPAudioAlbum> get audioAlbumArray => $_getList(3);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:301
class SSPGetThumbnailResponse extends $pb.GeneratedMessage {
  factory SSPGetThumbnailResponse({
    SSPRequestType? type,
    $core.Iterable<SSPImageFile>? imageArray,
    $core.Iterable<SSPVideoFile>? videoArray,
    $core.Iterable<SSPAudioAlbum>? audioAlbumArray,
  }) {
    final result = SSPGetThumbnailResponse._();
    if (type != null) result.type = type;
    if (imageArray != null) result.imageArray.addAll(imageArray);
    if (videoArray != null) result.videoArray.addAll(videoArray);
    if (audioAlbumArray != null) result.audioAlbumArray.addAll(audioAlbumArray);
    return result;
  }

  SSPGetThumbnailResponse._();

  factory SSPGetThumbnailResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetThumbnailResponse()..mergeFromBuffer(data, registry);
  factory SSPGetThumbnailResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetThumbnailResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPGetThumbnailResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPGetThumbnailResponse.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetThumbnailRequest,
        enumValues: SSPRequestType.values)
    ..pPM<SSPImageFile>(2, _omitFieldNames ? '' : 'imageArray',
        protoName: 'imageArray', subBuilder: SSPImageFile.$_createMessage)
    ..pPM<SSPVideoFile>(3, _omitFieldNames ? '' : 'videoArray',
        protoName: 'videoArray', subBuilder: SSPVideoFile.$_createMessage)
    ..pPM<SSPAudioAlbum>(4, _omitFieldNames ? '' : 'audioAlbumArray',
        protoName: 'audioAlbumArray', subBuilder: SSPAudioAlbum.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetThumbnailResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetThumbnailResponse copyWith(
          void Function(SSPGetThumbnailResponse) updates) =>
      super.copyWith((message) => updates(message as SSPGetThumbnailResponse))
          as SSPGetThumbnailResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPGetThumbnailResponse() / SSPGetThumbnailResponse.new instead')
  static SSPGetThumbnailResponse create() => SSPGetThumbnailResponse._();
  static $pb.GeneratedMessage $_createMessage() => SSPGetThumbnailResponse._();
  @$core.override
  SSPGetThumbnailResponse createEmptyInstance() => SSPGetThumbnailResponse._();
  @$core.pragma('dart2js:noInline')
  static SSPGetThumbnailResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPGetThumbnailResponse>(
          SSPGetThumbnailResponse.$_createMessage);
  static SSPGetThumbnailResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<SSPImageFile> get imageArray => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<SSPVideoFile> get videoArray => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<SSPAudioAlbum> get audioAlbumArray => $_getList(3);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:306
class SSPGetPhotoLibraryRequest extends $pb.GeneratedMessage {
  factory SSPGetPhotoLibraryRequest({
    SSPRequestType? type,
  }) {
    final result = SSPGetPhotoLibraryRequest._();
    if (type != null) result.type = type;
    return result;
  }

  SSPGetPhotoLibraryRequest._();

  factory SSPGetPhotoLibraryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetPhotoLibraryRequest()..mergeFromBuffer(data, registry);
  factory SSPGetPhotoLibraryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetPhotoLibraryRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPGetPhotoLibraryRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPGetPhotoLibraryRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetPhotoLibRequest,
        enumValues: SSPRequestType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetPhotoLibraryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetPhotoLibraryRequest copyWith(
          void Function(SSPGetPhotoLibraryRequest) updates) =>
      super.copyWith((message) => updates(message as SSPGetPhotoLibraryRequest))
          as SSPGetPhotoLibraryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPGetPhotoLibraryRequest() / SSPGetPhotoLibraryRequest.new instead')
  static SSPGetPhotoLibraryRequest create() => SSPGetPhotoLibraryRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      SSPGetPhotoLibraryRequest._();
  @$core.override
  SSPGetPhotoLibraryRequest createEmptyInstance() =>
      SSPGetPhotoLibraryRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPGetPhotoLibraryRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPGetPhotoLibraryRequest>(
          SSPGetPhotoLibraryRequest.$_createMessage);
  static SSPGetPhotoLibraryRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:308
class SSPGetPhotoLibraryResponse extends $pb.GeneratedMessage {
  factory SSPGetPhotoLibraryResponse({
    SSPRequestType? type,
    $core.Iterable<SSPImageFile>? imageArray,
    $core.Iterable<SSPImageAlbum>? albumArray,
    $fixnum.Int64? cameraAlbumId,
  }) {
    final result = SSPGetPhotoLibraryResponse._();
    if (type != null) result.type = type;
    if (imageArray != null) result.imageArray.addAll(imageArray);
    if (albumArray != null) result.albumArray.addAll(albumArray);
    if (cameraAlbumId != null) result.cameraAlbumId = cameraAlbumId;
    return result;
  }

  SSPGetPhotoLibraryResponse._();

  factory SSPGetPhotoLibraryResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetPhotoLibraryResponse()..mergeFromBuffer(data, registry);
  factory SSPGetPhotoLibraryResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetPhotoLibraryResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPGetPhotoLibraryResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPGetPhotoLibraryResponse.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetPhotoLibRequest,
        enumValues: SSPRequestType.values)
    ..pPM<SSPImageFile>(2, _omitFieldNames ? '' : 'imageArray',
        protoName: 'imageArray', subBuilder: SSPImageFile.$_createMessage)
    ..pPM<SSPImageAlbum>(3, _omitFieldNames ? '' : 'albumArray',
        protoName: 'albumArray', subBuilder: SSPImageAlbum.$_createMessage)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'cameraAlbumId', $pb.PbFieldType.OU6,
        protoName: 'cameraAlbumId', defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetPhotoLibraryResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetPhotoLibraryResponse copyWith(
          void Function(SSPGetPhotoLibraryResponse) updates) =>
      super.copyWith(
              (message) => updates(message as SSPGetPhotoLibraryResponse))
          as SSPGetPhotoLibraryResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPGetPhotoLibraryResponse() / SSPGetPhotoLibraryResponse.new instead')
  static SSPGetPhotoLibraryResponse create() => SSPGetPhotoLibraryResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      SSPGetPhotoLibraryResponse._();
  @$core.override
  SSPGetPhotoLibraryResponse createEmptyInstance() =>
      SSPGetPhotoLibraryResponse._();
  @$core.pragma('dart2js:noInline')
  static SSPGetPhotoLibraryResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPGetPhotoLibraryResponse>(
          SSPGetPhotoLibraryResponse.$_createMessage);
  static SSPGetPhotoLibraryResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<SSPImageFile> get imageArray => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<SSPImageAlbum> get albumArray => $_getList(2);

  @$pb.TagNumber(4)
  $fixnum.Int64 get cameraAlbumId => $_getI64(3);
  @$pb.TagNumber(4)
  set cameraAlbumId($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCameraAlbumId() => $_has(3);
  @$pb.TagNumber(4)
  void clearCameraAlbumId() => $_clearField(4);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:313
class SSPGetVideoLibraryRequest extends $pb.GeneratedMessage {
  factory SSPGetVideoLibraryRequest({
    SSPRequestType? type,
  }) {
    final result = SSPGetVideoLibraryRequest._();
    if (type != null) result.type = type;
    return result;
  }

  SSPGetVideoLibraryRequest._();

  factory SSPGetVideoLibraryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetVideoLibraryRequest()..mergeFromBuffer(data, registry);
  factory SSPGetVideoLibraryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetVideoLibraryRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPGetVideoLibraryRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPGetVideoLibraryRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetVideoLibRequest,
        enumValues: SSPRequestType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetVideoLibraryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetVideoLibraryRequest copyWith(
          void Function(SSPGetVideoLibraryRequest) updates) =>
      super.copyWith((message) => updates(message as SSPGetVideoLibraryRequest))
          as SSPGetVideoLibraryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPGetVideoLibraryRequest() / SSPGetVideoLibraryRequest.new instead')
  static SSPGetVideoLibraryRequest create() => SSPGetVideoLibraryRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      SSPGetVideoLibraryRequest._();
  @$core.override
  SSPGetVideoLibraryRequest createEmptyInstance() =>
      SSPGetVideoLibraryRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPGetVideoLibraryRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPGetVideoLibraryRequest>(
          SSPGetVideoLibraryRequest.$_createMessage);
  static SSPGetVideoLibraryRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:315
class SSPGetVideoLibraryResponse extends $pb.GeneratedMessage {
  factory SSPGetVideoLibraryResponse({
    SSPRequestType? type,
    $core.Iterable<SSPVideoFile>? videoArray,
    $core.Iterable<SSPVideoAlbum>? albumArray,
  }) {
    final result = SSPGetVideoLibraryResponse._();
    if (type != null) result.type = type;
    if (videoArray != null) result.videoArray.addAll(videoArray);
    if (albumArray != null) result.albumArray.addAll(albumArray);
    return result;
  }

  SSPGetVideoLibraryResponse._();

  factory SSPGetVideoLibraryResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetVideoLibraryResponse()..mergeFromBuffer(data, registry);
  factory SSPGetVideoLibraryResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetVideoLibraryResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPGetVideoLibraryResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPGetVideoLibraryResponse.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetVideoLibRequest,
        enumValues: SSPRequestType.values)
    ..pPM<SSPVideoFile>(2, _omitFieldNames ? '' : 'videoArray',
        protoName: 'videoArray', subBuilder: SSPVideoFile.$_createMessage)
    ..pPM<SSPVideoAlbum>(3, _omitFieldNames ? '' : 'albumArray',
        protoName: 'albumArray', subBuilder: SSPVideoAlbum.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetVideoLibraryResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetVideoLibraryResponse copyWith(
          void Function(SSPGetVideoLibraryResponse) updates) =>
      super.copyWith(
              (message) => updates(message as SSPGetVideoLibraryResponse))
          as SSPGetVideoLibraryResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPGetVideoLibraryResponse() / SSPGetVideoLibraryResponse.new instead')
  static SSPGetVideoLibraryResponse create() => SSPGetVideoLibraryResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      SSPGetVideoLibraryResponse._();
  @$core.override
  SSPGetVideoLibraryResponse createEmptyInstance() =>
      SSPGetVideoLibraryResponse._();
  @$core.pragma('dart2js:noInline')
  static SSPGetVideoLibraryResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPGetVideoLibraryResponse>(
          SSPGetVideoLibraryResponse.$_createMessage);
  static SSPGetVideoLibraryResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<SSPVideoFile> get videoArray => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<SSPVideoAlbum> get albumArray => $_getList(2);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:319
class SSPGetAudioLibraryRequest extends $pb.GeneratedMessage {
  factory SSPGetAudioLibraryRequest({
    SSPRequestType? type,
  }) {
    final result = SSPGetAudioLibraryRequest._();
    if (type != null) result.type = type;
    return result;
  }

  SSPGetAudioLibraryRequest._();

  factory SSPGetAudioLibraryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetAudioLibraryRequest()..mergeFromBuffer(data, registry);
  factory SSPGetAudioLibraryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetAudioLibraryRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPGetAudioLibraryRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPGetAudioLibraryRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetAudioLibRequest,
        enumValues: SSPRequestType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetAudioLibraryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetAudioLibraryRequest copyWith(
          void Function(SSPGetAudioLibraryRequest) updates) =>
      super.copyWith((message) => updates(message as SSPGetAudioLibraryRequest))
          as SSPGetAudioLibraryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPGetAudioLibraryRequest() / SSPGetAudioLibraryRequest.new instead')
  static SSPGetAudioLibraryRequest create() => SSPGetAudioLibraryRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      SSPGetAudioLibraryRequest._();
  @$core.override
  SSPGetAudioLibraryRequest createEmptyInstance() =>
      SSPGetAudioLibraryRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPGetAudioLibraryRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPGetAudioLibraryRequest>(
          SSPGetAudioLibraryRequest.$_createMessage);
  static SSPGetAudioLibraryRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:321
class SSPGetAudioLibraryResponse extends $pb.GeneratedMessage {
  factory SSPGetAudioLibraryResponse({
    SSPRequestType? type,
    $core.Iterable<SSPAudioFile>? audioArray,
    $core.Iterable<SSPAudioAlbum>? albumArray,
  }) {
    final result = SSPGetAudioLibraryResponse._();
    if (type != null) result.type = type;
    if (audioArray != null) result.audioArray.addAll(audioArray);
    if (albumArray != null) result.albumArray.addAll(albumArray);
    return result;
  }

  SSPGetAudioLibraryResponse._();

  factory SSPGetAudioLibraryResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetAudioLibraryResponse()..mergeFromBuffer(data, registry);
  factory SSPGetAudioLibraryResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetAudioLibraryResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPGetAudioLibraryResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPGetAudioLibraryResponse.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetAudioLibRequest,
        enumValues: SSPRequestType.values)
    ..pPM<SSPAudioFile>(2, _omitFieldNames ? '' : 'audioArray',
        protoName: 'audioArray', subBuilder: SSPAudioFile.$_createMessage)
    ..pPM<SSPAudioAlbum>(3, _omitFieldNames ? '' : 'albumArray',
        protoName: 'albumArray', subBuilder: SSPAudioAlbum.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetAudioLibraryResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetAudioLibraryResponse copyWith(
          void Function(SSPGetAudioLibraryResponse) updates) =>
      super.copyWith(
              (message) => updates(message as SSPGetAudioLibraryResponse))
          as SSPGetAudioLibraryResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPGetAudioLibraryResponse() / SSPGetAudioLibraryResponse.new instead')
  static SSPGetAudioLibraryResponse create() => SSPGetAudioLibraryResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      SSPGetAudioLibraryResponse._();
  @$core.override
  SSPGetAudioLibraryResponse createEmptyInstance() =>
      SSPGetAudioLibraryResponse._();
  @$core.pragma('dart2js:noInline')
  static SSPGetAudioLibraryResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPGetAudioLibraryResponse>(
          SSPGetAudioLibraryResponse.$_createMessage);
  static SSPGetAudioLibraryResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<SSPAudioFile> get audioArray => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<SSPAudioAlbum> get albumArray => $_getList(2);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:325
class SSPPhotoLibraryChange extends $pb.GeneratedMessage {
  factory SSPPhotoLibraryChange({
    SSPRequestType? type,
    $core.Iterable<SSPImageFile>? addedImageArray,
    $core.Iterable<SSPImageFile>? deletedImageArray,
  }) {
    final result = SSPPhotoLibraryChange._();
    if (type != null) result.type = type;
    if (addedImageArray != null) result.addedImageArray.addAll(addedImageArray);
    if (deletedImageArray != null)
      result.deletedImageArray.addAll(deletedImageArray);
    return result;
  }

  SSPPhotoLibraryChange._();

  factory SSPPhotoLibraryChange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPPhotoLibraryChange()..mergeFromBuffer(data, registry);
  factory SSPPhotoLibraryChange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPPhotoLibraryChange()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPPhotoLibraryChange',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPPhotoLibraryChange.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_PhotoLibChange,
        enumValues: SSPRequestType.values)
    ..pPM<SSPImageFile>(2, _omitFieldNames ? '' : 'addedImageArray',
        protoName: 'addedImageArray', subBuilder: SSPImageFile.$_createMessage)
    ..pPM<SSPImageFile>(3, _omitFieldNames ? '' : 'deletedImageArray',
        protoName: 'deletedImageArray',
        subBuilder: SSPImageFile.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPPhotoLibraryChange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPPhotoLibraryChange copyWith(
          void Function(SSPPhotoLibraryChange) updates) =>
      super.copyWith((message) => updates(message as SSPPhotoLibraryChange))
          as SSPPhotoLibraryChange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPPhotoLibraryChange() / SSPPhotoLibraryChange.new instead')
  static SSPPhotoLibraryChange create() => SSPPhotoLibraryChange._();
  static $pb.GeneratedMessage $_createMessage() => SSPPhotoLibraryChange._();
  @$core.override
  SSPPhotoLibraryChange createEmptyInstance() => SSPPhotoLibraryChange._();
  @$core.pragma('dart2js:noInline')
  static SSPPhotoLibraryChange getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPPhotoLibraryChange>(
          SSPPhotoLibraryChange.$_createMessage);
  static SSPPhotoLibraryChange? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<SSPImageFile> get addedImageArray => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<SSPImageFile> get deletedImageArray => $_getList(2);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:329
class SSPVideoLibraryChange extends $pb.GeneratedMessage {
  factory SSPVideoLibraryChange({
    SSPRequestType? type,
    $core.Iterable<SSPVideoFile>? addedVideoArray,
    $core.Iterable<SSPVideoFile>? deletedVideoArray,
    $core.Iterable<SSPVideoFile>? updatedVideoArray,
  }) {
    final result = SSPVideoLibraryChange._();
    if (type != null) result.type = type;
    if (addedVideoArray != null) result.addedVideoArray.addAll(addedVideoArray);
    if (deletedVideoArray != null)
      result.deletedVideoArray.addAll(deletedVideoArray);
    if (updatedVideoArray != null)
      result.updatedVideoArray.addAll(updatedVideoArray);
    return result;
  }

  SSPVideoLibraryChange._();

  factory SSPVideoLibraryChange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPVideoLibraryChange()..mergeFromBuffer(data, registry);
  factory SSPVideoLibraryChange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPVideoLibraryChange()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPVideoLibraryChange',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPVideoLibraryChange.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_VideoLibChange,
        enumValues: SSPRequestType.values)
    ..pPM<SSPVideoFile>(2, _omitFieldNames ? '' : 'addedVideoArray',
        protoName: 'addedVideoArray', subBuilder: SSPVideoFile.$_createMessage)
    ..pPM<SSPVideoFile>(3, _omitFieldNames ? '' : 'deletedVideoArray',
        protoName: 'deletedVideoArray',
        subBuilder: SSPVideoFile.$_createMessage)
    ..pPM<SSPVideoFile>(4, _omitFieldNames ? '' : 'updatedVideoArray',
        protoName: 'updatedVideoArray',
        subBuilder: SSPVideoFile.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPVideoLibraryChange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPVideoLibraryChange copyWith(
          void Function(SSPVideoLibraryChange) updates) =>
      super.copyWith((message) => updates(message as SSPVideoLibraryChange))
          as SSPVideoLibraryChange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPVideoLibraryChange() / SSPVideoLibraryChange.new instead')
  static SSPVideoLibraryChange create() => SSPVideoLibraryChange._();
  static $pb.GeneratedMessage $_createMessage() => SSPVideoLibraryChange._();
  @$core.override
  SSPVideoLibraryChange createEmptyInstance() => SSPVideoLibraryChange._();
  @$core.pragma('dart2js:noInline')
  static SSPVideoLibraryChange getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPVideoLibraryChange>(
          SSPVideoLibraryChange.$_createMessage);
  static SSPVideoLibraryChange? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<SSPVideoFile> get addedVideoArray => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<SSPVideoFile> get deletedVideoArray => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<SSPVideoFile> get updatedVideoArray => $_getList(3);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:334
class SSPAudioLibraryChange extends $pb.GeneratedMessage {
  factory SSPAudioLibraryChange({
    SSPRequestType? type,
    $core.Iterable<SSPAudioFile>? addedAudioArray,
    $core.Iterable<SSPAudioFile>? deletedAudioArray,
    $core.Iterable<SSPAudioAlbum>? addedAlbumArray,
  }) {
    final result = SSPAudioLibraryChange._();
    if (type != null) result.type = type;
    if (addedAudioArray != null) result.addedAudioArray.addAll(addedAudioArray);
    if (deletedAudioArray != null)
      result.deletedAudioArray.addAll(deletedAudioArray);
    if (addedAlbumArray != null) result.addedAlbumArray.addAll(addedAlbumArray);
    return result;
  }

  SSPAudioLibraryChange._();

  factory SSPAudioLibraryChange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPAudioLibraryChange()..mergeFromBuffer(data, registry);
  factory SSPAudioLibraryChange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPAudioLibraryChange()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPAudioLibraryChange',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPAudioLibraryChange.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_AudioLibChange,
        enumValues: SSPRequestType.values)
    ..pPM<SSPAudioFile>(2, _omitFieldNames ? '' : 'addedAudioArray',
        protoName: 'addedAudioArray', subBuilder: SSPAudioFile.$_createMessage)
    ..pPM<SSPAudioFile>(3, _omitFieldNames ? '' : 'deletedAudioArray',
        protoName: 'deletedAudioArray',
        subBuilder: SSPAudioFile.$_createMessage)
    ..pPM<SSPAudioAlbum>(4, _omitFieldNames ? '' : 'addedAlbumArray',
        protoName: 'addedAlbumArray', subBuilder: SSPAudioAlbum.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPAudioLibraryChange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPAudioLibraryChange copyWith(
          void Function(SSPAudioLibraryChange) updates) =>
      super.copyWith((message) => updates(message as SSPAudioLibraryChange))
          as SSPAudioLibraryChange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPAudioLibraryChange() / SSPAudioLibraryChange.new instead')
  static SSPAudioLibraryChange create() => SSPAudioLibraryChange._();
  static $pb.GeneratedMessage $_createMessage() => SSPAudioLibraryChange._();
  @$core.override
  SSPAudioLibraryChange createEmptyInstance() => SSPAudioLibraryChange._();
  @$core.pragma('dart2js:noInline')
  static SSPAudioLibraryChange getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPAudioLibraryChange>(
          SSPAudioLibraryChange.$_createMessage);
  static SSPAudioLibraryChange? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<SSPAudioFile> get addedAudioArray => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<SSPAudioFile> get deletedAudioArray => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<SSPAudioAlbum> get addedAlbumArray => $_getList(3);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:339
class SSPClipboard extends $pb.GeneratedMessage {
  factory SSPClipboard({
    $core.List<$core.int>? content,
    $fixnum.Int64? mstimestamp,
  }) {
    final result = SSPClipboard._();
    if (content != null) result.content = content;
    if (mstimestamp != null) result.mstimestamp = mstimestamp;
    return result;
  }

  SSPClipboard._();

  factory SSPClipboard.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPClipboard()..mergeFromBuffer(data, registry);
  factory SSPClipboard.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPClipboard()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPClipboard',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPClipboard.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'content', $pb.PbFieldType.OY)
    ..aInt64(2, _omitFieldNames ? '' : 'mstimestamp')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPClipboard clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPClipboard copyWith(void Function(SSPClipboard) updates) =>
      super.copyWith((message) => updates(message as SSPClipboard))
          as SSPClipboard;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SSPClipboard() / SSPClipboard.new instead')
  static SSPClipboard create() => SSPClipboard._();
  static $pb.GeneratedMessage $_createMessage() => SSPClipboard._();
  @$core.override
  SSPClipboard createEmptyInstance() => SSPClipboard._();
  @$core.pragma('dart2js:noInline')
  static SSPClipboard getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SSPClipboard>(
          SSPClipboard.$_createMessage);
  static SSPClipboard? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get content => $_getN(0);
  @$pb.TagNumber(1)
  set content($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasContent() => $_has(0);
  @$pb.TagNumber(1)
  void clearContent() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get mstimestamp => $_getI64(1);
  @$pb.TagNumber(2)
  set mstimestamp($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMstimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearMstimestamp() => $_clearField(2);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:342
class SSPGetClipboardRequest extends $pb.GeneratedMessage {
  factory SSPGetClipboardRequest({
    SSPRequestType? type,
  }) {
    final result = SSPGetClipboardRequest._();
    if (type != null) result.type = type;
    return result;
  }

  SSPGetClipboardRequest._();

  factory SSPGetClipboardRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetClipboardRequest()..mergeFromBuffer(data, registry);
  factory SSPGetClipboardRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetClipboardRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPGetClipboardRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPGetClipboardRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetClipboardRequest,
        enumValues: SSPRequestType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetClipboardRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetClipboardRequest copyWith(
          void Function(SSPGetClipboardRequest) updates) =>
      super.copyWith((message) => updates(message as SSPGetClipboardRequest))
          as SSPGetClipboardRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPGetClipboardRequest() / SSPGetClipboardRequest.new instead')
  static SSPGetClipboardRequest create() => SSPGetClipboardRequest._();
  static $pb.GeneratedMessage $_createMessage() => SSPGetClipboardRequest._();
  @$core.override
  SSPGetClipboardRequest createEmptyInstance() => SSPGetClipboardRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPGetClipboardRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPGetClipboardRequest>(
          SSPGetClipboardRequest.$_createMessage);
  static SSPGetClipboardRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:344
class SSPGetClipboardResponse extends $pb.GeneratedMessage {
  factory SSPGetClipboardResponse({
    SSPRequestType? type,
    $core.Iterable<SSPClipboard>? clipboardArray,
  }) {
    final result = SSPGetClipboardResponse._();
    if (type != null) result.type = type;
    if (clipboardArray != null) result.clipboardArray.addAll(clipboardArray);
    return result;
  }

  SSPGetClipboardResponse._();

  factory SSPGetClipboardResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetClipboardResponse()..mergeFromBuffer(data, registry);
  factory SSPGetClipboardResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPGetClipboardResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPGetClipboardResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPGetClipboardResponse.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_GetClipboardRequest,
        enumValues: SSPRequestType.values)
    ..pPM<SSPClipboard>(2, _omitFieldNames ? '' : 'clipboardArray',
        protoName: 'clipboardArray', subBuilder: SSPClipboard.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetClipboardResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPGetClipboardResponse copyWith(
          void Function(SSPGetClipboardResponse) updates) =>
      super.copyWith((message) => updates(message as SSPGetClipboardResponse))
          as SSPGetClipboardResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPGetClipboardResponse() / SSPGetClipboardResponse.new instead')
  static SSPGetClipboardResponse create() => SSPGetClipboardResponse._();
  static $pb.GeneratedMessage $_createMessage() => SSPGetClipboardResponse._();
  @$core.override
  SSPGetClipboardResponse createEmptyInstance() => SSPGetClipboardResponse._();
  @$core.pragma('dart2js:noInline')
  static SSPGetClipboardResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPGetClipboardResponse>(
          SSPGetClipboardResponse.$_createMessage);
  static SSPGetClipboardResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<SSPClipboard> get clipboardArray => $_getList(1);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:347
class SSPPostClipboardRequest extends $pb.GeneratedMessage {
  factory SSPPostClipboardRequest({
    SSPRequestType? type,
    SSPClipboard? clipboard,
  }) {
    final result = SSPPostClipboardRequest._();
    if (type != null) result.type = type;
    if (clipboard != null) result.clipboard = clipboard;
    return result;
  }

  SSPPostClipboardRequest._();

  factory SSPPostClipboardRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPPostClipboardRequest()..mergeFromBuffer(data, registry);
  factory SSPPostClipboardRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPPostClipboardRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPPostClipboardRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPPostClipboardRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_PostClipboardRequest,
        enumValues: SSPRequestType.values)
    ..aQM<SSPClipboard>(2, _omitFieldNames ? '' : 'clipboard',
        subBuilder: SSPClipboard.$_createMessage);

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPPostClipboardRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPPostClipboardRequest copyWith(
          void Function(SSPPostClipboardRequest) updates) =>
      super.copyWith((message) => updates(message as SSPPostClipboardRequest))
          as SSPPostClipboardRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPPostClipboardRequest() / SSPPostClipboardRequest.new instead')
  static SSPPostClipboardRequest create() => SSPPostClipboardRequest._();
  static $pb.GeneratedMessage $_createMessage() => SSPPostClipboardRequest._();
  @$core.override
  SSPPostClipboardRequest createEmptyInstance() => SSPPostClipboardRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPPostClipboardRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPPostClipboardRequest>(
          SSPPostClipboardRequest.$_createMessage);
  static SSPPostClipboardRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  SSPClipboard get clipboard => $_getN(1);
  @$pb.TagNumber(2)
  set clipboard(SSPClipboard value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasClipboard() => $_has(1);
  @$pb.TagNumber(2)
  void clearClipboard() => $_clearField(2);
  @$pb.TagNumber(2)
  SSPClipboard ensureClipboard() => $_ensure(1);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:350
class SSPPostClipboardResponse extends $pb.GeneratedMessage {
  factory SSPPostClipboardResponse({
    SSPRequestType? type,
    $core.bool? succeed,
  }) {
    final result = SSPPostClipboardResponse._();
    if (type != null) result.type = type;
    if (succeed != null) result.succeed = succeed;
    return result;
  }

  SSPPostClipboardResponse._();

  factory SSPPostClipboardResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPPostClipboardResponse()..mergeFromBuffer(data, registry);
  factory SSPPostClipboardResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPPostClipboardResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPPostClipboardResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPPostClipboardResponse.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_PostClipboardRequest,
        enumValues: SSPRequestType.values)
    ..aOB(2, _omitFieldNames ? '' : 'succeed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPPostClipboardResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPPostClipboardResponse copyWith(
          void Function(SSPPostClipboardResponse) updates) =>
      super.copyWith((message) => updates(message as SSPPostClipboardResponse))
          as SSPPostClipboardResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPPostClipboardResponse() / SSPPostClipboardResponse.new instead')
  static SSPPostClipboardResponse create() => SSPPostClipboardResponse._();
  static $pb.GeneratedMessage $_createMessage() => SSPPostClipboardResponse._();
  @$core.override
  SSPPostClipboardResponse createEmptyInstance() =>
      SSPPostClipboardResponse._();
  @$core.pragma('dart2js:noInline')
  static SSPPostClipboardResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPPostClipboardResponse>(
          SSPPostClipboardResponse.$_createMessage);
  static SSPPostClipboardResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get succeed => $_getBF(1);
  @$pb.TagNumber(2)
  set succeed($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSucceed() => $_has(1);
  @$pb.TagNumber(2)
  void clearSucceed() => $_clearField(2);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:353
class SSPClearClipboardRequest extends $pb.GeneratedMessage {
  factory SSPClearClipboardRequest({
    SSPRequestType? type,
  }) {
    final result = SSPClearClipboardRequest._();
    if (type != null) result.type = type;
    return result;
  }

  SSPClearClipboardRequest._();

  factory SSPClearClipboardRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPClearClipboardRequest()..mergeFromBuffer(data, registry);
  factory SSPClearClipboardRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPClearClipboardRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPClearClipboardRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPClearClipboardRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_ClearClipboardRequest,
        enumValues: SSPRequestType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPClearClipboardRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPClearClipboardRequest copyWith(
          void Function(SSPClearClipboardRequest) updates) =>
      super.copyWith((message) => updates(message as SSPClearClipboardRequest))
          as SSPClearClipboardRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPClearClipboardRequest() / SSPClearClipboardRequest.new instead')
  static SSPClearClipboardRequest create() => SSPClearClipboardRequest._();
  static $pb.GeneratedMessage $_createMessage() => SSPClearClipboardRequest._();
  @$core.override
  SSPClearClipboardRequest createEmptyInstance() =>
      SSPClearClipboardRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPClearClipboardRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPClearClipboardRequest>(
          SSPClearClipboardRequest.$_createMessage);
  static SSPClearClipboardRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:355
class SSPClearClipboardResponse extends $pb.GeneratedMessage {
  factory SSPClearClipboardResponse({
    SSPRequestType? type,
    $core.bool? succeed,
  }) {
    final result = SSPClearClipboardResponse._();
    if (type != null) result.type = type;
    if (succeed != null) result.succeed = succeed;
    return result;
  }

  SSPClearClipboardResponse._();

  factory SSPClearClipboardResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPClearClipboardResponse()..mergeFromBuffer(data, registry);
  factory SSPClearClipboardResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPClearClipboardResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPClearClipboardResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPClearClipboardResponse.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_ClearClipboardRequest,
        enumValues: SSPRequestType.values)
    ..aOB(2, _omitFieldNames ? '' : 'succeed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPClearClipboardResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPClearClipboardResponse copyWith(
          void Function(SSPClearClipboardResponse) updates) =>
      super.copyWith((message) => updates(message as SSPClearClipboardResponse))
          as SSPClearClipboardResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPClearClipboardResponse() / SSPClearClipboardResponse.new instead')
  static SSPClearClipboardResponse create() => SSPClearClipboardResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      SSPClearClipboardResponse._();
  @$core.override
  SSPClearClipboardResponse createEmptyInstance() =>
      SSPClearClipboardResponse._();
  @$core.pragma('dart2js:noInline')
  static SSPClearClipboardResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPClearClipboardResponse>(
          SSPClearClipboardResponse.$_createMessage);
  static SSPClearClipboardResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get succeed => $_getBF(1);
  @$pb.TagNumber(2)
  set succeed($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSucceed() => $_has(1);
  @$pb.TagNumber(2)
  void clearSucceed() => $_clearField(2);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:358
class SSPDeleteClipboardRequest extends $pb.GeneratedMessage {
  factory SSPDeleteClipboardRequest({
    SSPRequestType? type,
    SSPClipboard? clipboard,
  }) {
    final result = SSPDeleteClipboardRequest._();
    if (type != null) result.type = type;
    if (clipboard != null) result.clipboard = clipboard;
    return result;
  }

  SSPDeleteClipboardRequest._();

  factory SSPDeleteClipboardRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPDeleteClipboardRequest()..mergeFromBuffer(data, registry);
  factory SSPDeleteClipboardRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPDeleteClipboardRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPDeleteClipboardRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPDeleteClipboardRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_DeleteClipboardRequest,
        enumValues: SSPRequestType.values)
    ..aQM<SSPClipboard>(2, _omitFieldNames ? '' : 'clipboard',
        subBuilder: SSPClipboard.$_createMessage);

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPDeleteClipboardRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPDeleteClipboardRequest copyWith(
          void Function(SSPDeleteClipboardRequest) updates) =>
      super.copyWith((message) => updates(message as SSPDeleteClipboardRequest))
          as SSPDeleteClipboardRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPDeleteClipboardRequest() / SSPDeleteClipboardRequest.new instead')
  static SSPDeleteClipboardRequest create() => SSPDeleteClipboardRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      SSPDeleteClipboardRequest._();
  @$core.override
  SSPDeleteClipboardRequest createEmptyInstance() =>
      SSPDeleteClipboardRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPDeleteClipboardRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPDeleteClipboardRequest>(
          SSPDeleteClipboardRequest.$_createMessage);
  static SSPDeleteClipboardRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  SSPClipboard get clipboard => $_getN(1);
  @$pb.TagNumber(2)
  set clipboard(SSPClipboard value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasClipboard() => $_has(1);
  @$pb.TagNumber(2)
  void clearClipboard() => $_clearField(2);
  @$pb.TagNumber(2)
  SSPClipboard ensureClipboard() => $_ensure(1);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:361
class SSPDeleteClipboardResponse extends $pb.GeneratedMessage {
  factory SSPDeleteClipboardResponse({
    SSPRequestType? type,
    $core.bool? succeed,
  }) {
    final result = SSPDeleteClipboardResponse._();
    if (type != null) result.type = type;
    if (succeed != null) result.succeed = succeed;
    return result;
  }

  SSPDeleteClipboardResponse._();

  factory SSPDeleteClipboardResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPDeleteClipboardResponse()..mergeFromBuffer(data, registry);
  factory SSPDeleteClipboardResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPDeleteClipboardResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPDeleteClipboardResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPDeleteClipboardResponse.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_DeleteClipboardRequest,
        enumValues: SSPRequestType.values)
    ..aOB(2, _omitFieldNames ? '' : 'succeed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPDeleteClipboardResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPDeleteClipboardResponse copyWith(
          void Function(SSPDeleteClipboardResponse) updates) =>
      super.copyWith(
              (message) => updates(message as SSPDeleteClipboardResponse))
          as SSPDeleteClipboardResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPDeleteClipboardResponse() / SSPDeleteClipboardResponse.new instead')
  static SSPDeleteClipboardResponse create() => SSPDeleteClipboardResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      SSPDeleteClipboardResponse._();
  @$core.override
  SSPDeleteClipboardResponse createEmptyInstance() =>
      SSPDeleteClipboardResponse._();
  @$core.pragma('dart2js:noInline')
  static SSPDeleteClipboardResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPDeleteClipboardResponse>(
          SSPDeleteClipboardResponse.$_createMessage);
  static SSPDeleteClipboardResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get succeed => $_getBF(1);
  @$pb.TagNumber(2)
  set succeed($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSucceed() => $_has(1);
  @$pb.TagNumber(2)
  void clearSucceed() => $_clearField(2);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:364
class SSPClipboardChange extends $pb.GeneratedMessage {
  factory SSPClipboardChange({
    SSPRequestType? type,
    $core.Iterable<SSPClipboard>? clipboardArray,
  }) {
    final result = SSPClipboardChange._();
    if (type != null) result.type = type;
    if (clipboardArray != null) result.clipboardArray.addAll(clipboardArray);
    return result;
  }

  SSPClipboardChange._();

  factory SSPClipboardChange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPClipboardChange()..mergeFromBuffer(data, registry);
  factory SSPClipboardChange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPClipboardChange()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPClipboardChange',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPClipboardChange.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_ClipboardChange,
        enumValues: SSPRequestType.values)
    ..pPM<SSPClipboard>(2, _omitFieldNames ? '' : 'clipboardArray',
        protoName: 'clipboardArray', subBuilder: SSPClipboard.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPClipboardChange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPClipboardChange copyWith(void Function(SSPClipboardChange) updates) =>
      super.copyWith((message) => updates(message as SSPClipboardChange))
          as SSPClipboardChange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SSPClipboardChange() / SSPClipboardChange.new instead')
  static SSPClipboardChange create() => SSPClipboardChange._();
  static $pb.GeneratedMessage $_createMessage() => SSPClipboardChange._();
  @$core.override
  SSPClipboardChange createEmptyInstance() => SSPClipboardChange._();
  @$core.pragma('dart2js:noInline')
  static SSPClipboardChange getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPClipboardChange>(
          SSPClipboardChange.$_createMessage);
  static SSPClipboardChange? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<SSPClipboard> get clipboardArray => $_getList(1);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:367
class SSPCancelRequest extends $pb.GeneratedMessage {
  factory SSPCancelRequest({
    SSPRequestType? type,
    $fixnum.Int64? sessionId,
    SSPCancelErrorCode? errorCode,
  }) {
    final result = SSPCancelRequest._();
    if (type != null) result.type = type;
    if (sessionId != null) result.sessionId = sessionId;
    if (errorCode != null) result.errorCode = errorCode;
    return result;
  }

  SSPCancelRequest._();

  factory SSPCancelRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPCancelRequest()..mergeFromBuffer(data, registry);
  factory SSPCancelRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPCancelRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPCancelRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPCancelRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_CancelRequest,
        enumValues: SSPRequestType.values)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'sessionId', $pb.PbFieldType.OU6,
        protoName: 'sessionId', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aE<SSPCancelErrorCode>(3, _omitFieldNames ? '' : 'errorCode',
        protoName: 'errorCode', enumValues: SSPCancelErrorCode.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPCancelRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPCancelRequest copyWith(void Function(SSPCancelRequest) updates) =>
      super.copyWith((message) => updates(message as SSPCancelRequest))
          as SSPCancelRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SSPCancelRequest() / SSPCancelRequest.new instead')
  static SSPCancelRequest create() => SSPCancelRequest._();
  static $pb.GeneratedMessage $_createMessage() => SSPCancelRequest._();
  @$core.override
  SSPCancelRequest createEmptyInstance() => SSPCancelRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPCancelRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SSPCancelRequest>(
          SSPCancelRequest.$_createMessage);
  static SSPCancelRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get sessionId => $_getI64(1);
  @$pb.TagNumber(2)
  set sessionId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => $_clearField(2);

  @$pb.TagNumber(3)
  SSPCancelErrorCode get errorCode => $_getN(2);
  @$pb.TagNumber(3)
  set errorCode(SSPCancelErrorCode value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasErrorCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearErrorCode() => $_clearField(3);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:371
class SSPPhotoSyncRequest extends $pb.GeneratedMessage {
  factory SSPPhotoSyncRequest({
    SSPRequestType? type,
    $core.String? pcId,
    $core.Iterable<SSPFile>? filesArray,
  }) {
    final result = SSPPhotoSyncRequest._();
    if (type != null) result.type = type;
    if (pcId != null) result.pcId = pcId;
    if (filesArray != null) result.filesArray.addAll(filesArray);
    return result;
  }

  SSPPhotoSyncRequest._();

  factory SSPPhotoSyncRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPPhotoSyncRequest()..mergeFromBuffer(data, registry);
  factory SSPPhotoSyncRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPPhotoSyncRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPPhotoSyncRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPPhotoSyncRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_PhotoSyncRequest,
        enumValues: SSPRequestType.values)
    ..aOS(2, _omitFieldNames ? '' : 'pcId', protoName: 'pcId')
    ..pPM<SSPFile>(3, _omitFieldNames ? '' : 'filesArray',
        protoName: 'filesArray', subBuilder: SSPFile.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPPhotoSyncRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPPhotoSyncRequest copyWith(void Function(SSPPhotoSyncRequest) updates) =>
      super.copyWith((message) => updates(message as SSPPhotoSyncRequest))
          as SSPPhotoSyncRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use SSPPhotoSyncRequest() / SSPPhotoSyncRequest.new instead')
  static SSPPhotoSyncRequest create() => SSPPhotoSyncRequest._();
  static $pb.GeneratedMessage $_createMessage() => SSPPhotoSyncRequest._();
  @$core.override
  SSPPhotoSyncRequest createEmptyInstance() => SSPPhotoSyncRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPPhotoSyncRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPPhotoSyncRequest>(
          SSPPhotoSyncRequest.$_createMessage);
  static SSPPhotoSyncRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get pcId => $_getSZ(1);
  @$pb.TagNumber(2)
  set pcId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPcId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPcId() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<SSPFile> get filesArray => $_getList(2);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:375
class SSPPhotoSyncResponse extends $pb.GeneratedMessage {
  factory SSPPhotoSyncResponse({
    SSPRequestType? type,
    $core.bool? isFirst,
    $core.Iterable<SSPFile>? filesArray,
    $core.bool? isSuccess,
  }) {
    final result = SSPPhotoSyncResponse._();
    if (type != null) result.type = type;
    if (isFirst != null) result.isFirst = isFirst;
    if (filesArray != null) result.filesArray.addAll(filesArray);
    if (isSuccess != null) result.isSuccess = isSuccess;
    return result;
  }

  SSPPhotoSyncResponse._();

  factory SSPPhotoSyncResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPPhotoSyncResponse()..mergeFromBuffer(data, registry);
  factory SSPPhotoSyncResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPPhotoSyncResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPPhotoSyncResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPPhotoSyncResponse.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_PhotoSyncRequest,
        enumValues: SSPRequestType.values)
    ..aOB(2, _omitFieldNames ? '' : 'isFirst', protoName: 'isFirst')
    ..pPM<SSPFile>(3, _omitFieldNames ? '' : 'filesArray',
        protoName: 'filesArray', subBuilder: SSPFile.$_createMessage)
    ..aOB(4, _omitFieldNames ? '' : 'isSuccess', protoName: 'isSuccess')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPPhotoSyncResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPPhotoSyncResponse copyWith(void Function(SSPPhotoSyncResponse) updates) =>
      super.copyWith((message) => updates(message as SSPPhotoSyncResponse))
          as SSPPhotoSyncResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPPhotoSyncResponse() / SSPPhotoSyncResponse.new instead')
  static SSPPhotoSyncResponse create() => SSPPhotoSyncResponse._();
  static $pb.GeneratedMessage $_createMessage() => SSPPhotoSyncResponse._();
  @$core.override
  SSPPhotoSyncResponse createEmptyInstance() => SSPPhotoSyncResponse._();
  @$core.pragma('dart2js:noInline')
  static SSPPhotoSyncResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPPhotoSyncResponse>(
          SSPPhotoSyncResponse.$_createMessage);
  static SSPPhotoSyncResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get isFirst => $_getBF(1);
  @$pb.TagNumber(2)
  set isFirst($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIsFirst() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsFirst() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<SSPFile> get filesArray => $_getList(2);

  @$pb.TagNumber(4)
  $core.bool get isSuccess => $_getBF(3);
  @$pb.TagNumber(4)
  set isSuccess($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIsSuccess() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsSuccess() => $_clearField(4);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:380
class SSPFileChange extends $pb.GeneratedMessage {
  factory SSPFileChange({
    SSPRequestType? type,
    $core.Iterable<SSPFileChangeItem>? fileChangeItemsArray,
  }) {
    final result = SSPFileChange._();
    if (type != null) result.type = type;
    if (fileChangeItemsArray != null)
      result.fileChangeItemsArray.addAll(fileChangeItemsArray);
    return result;
  }

  SSPFileChange._();

  factory SSPFileChange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPFileChange()..mergeFromBuffer(data, registry);
  factory SSPFileChange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPFileChange()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPFileChange',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPFileChange.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_FileChange,
        enumValues: SSPRequestType.values)
    ..pPM<SSPFileChangeItem>(2, _omitFieldNames ? '' : 'fileChangeItemsArray',
        protoName: 'fileChangeItemsArray',
        subBuilder: SSPFileChangeItem.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPFileChange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPFileChange copyWith(void Function(SSPFileChange) updates) =>
      super.copyWith((message) => updates(message as SSPFileChange))
          as SSPFileChange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SSPFileChange() / SSPFileChange.new instead')
  static SSPFileChange create() => SSPFileChange._();
  static $pb.GeneratedMessage $_createMessage() => SSPFileChange._();
  @$core.override
  SSPFileChange createEmptyInstance() => SSPFileChange._();
  @$core.pragma('dart2js:noInline')
  static SSPFileChange getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SSPFileChange>(
          SSPFileChange.$_createMessage);
  static SSPFileChange? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<SSPFileChangeItem> get fileChangeItemsArray => $_getList(1);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:383
class SSPFileChangeItem extends $pb.GeneratedMessage {
  factory SSPFileChangeItem({
    SSPFile? file,
    SSPFileChangeStatus? status,
  }) {
    final result = SSPFileChangeItem._();
    if (file != null) result.file = file;
    if (status != null) result.status = status;
    return result;
  }

  SSPFileChangeItem._();

  factory SSPFileChangeItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPFileChangeItem()..mergeFromBuffer(data, registry);
  factory SSPFileChangeItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPFileChangeItem()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPFileChangeItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPFileChangeItem.$_createMessage)
    ..aOM<SSPFile>(1, _omitFieldNames ? '' : 'file',
        subBuilder: SSPFile.$_createMessage)
    ..aE<SSPFileChangeStatus>(2, _omitFieldNames ? '' : 'status',
        enumValues: SSPFileChangeStatus.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPFileChangeItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPFileChangeItem copyWith(void Function(SSPFileChangeItem) updates) =>
      super.copyWith((message) => updates(message as SSPFileChangeItem))
          as SSPFileChangeItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SSPFileChangeItem() / SSPFileChangeItem.new instead')
  static SSPFileChangeItem create() => SSPFileChangeItem._();
  static $pb.GeneratedMessage $_createMessage() => SSPFileChangeItem._();
  @$core.override
  SSPFileChangeItem createEmptyInstance() => SSPFileChangeItem._();
  @$core.pragma('dart2js:noInline')
  static SSPFileChangeItem getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SSPFileChangeItem>(
          SSPFileChangeItem.$_createMessage);
  static SSPFileChangeItem? _defaultInstance;

  @$pb.TagNumber(1)
  SSPFile get file => $_getN(0);
  @$pb.TagNumber(1)
  set file(SSPFile value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasFile() => $_has(0);
  @$pb.TagNumber(1)
  void clearFile() => $_clearField(1);
  @$pb.TagNumber(1)
  SSPFile ensureFile() => $_ensure(0);

  @$pb.TagNumber(2)
  SSPFileChangeStatus get status => $_getN(1);
  @$pb.TagNumber(2)
  set status(SSPFileChangeStatus value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:386
class SSPSyncMonitorRequest extends $pb.GeneratedMessage {
  factory SSPSyncMonitorRequest({
    SSPRequestType? type,
    $core.bool? isSyncMonitor,
  }) {
    final result = SSPSyncMonitorRequest._();
    if (type != null) result.type = type;
    if (isSyncMonitor != null) result.isSyncMonitor = isSyncMonitor;
    return result;
  }

  SSPSyncMonitorRequest._();

  factory SSPSyncMonitorRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPSyncMonitorRequest()..mergeFromBuffer(data, registry);
  factory SSPSyncMonitorRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPSyncMonitorRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPSyncMonitorRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPSyncMonitorRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_SyncMonitorRequest,
        enumValues: SSPRequestType.values)
    ..aOB(2, _omitFieldNames ? '' : 'isSyncMonitor', protoName: 'isSyncMonitor')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPSyncMonitorRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPSyncMonitorRequest copyWith(
          void Function(SSPSyncMonitorRequest) updates) =>
      super.copyWith((message) => updates(message as SSPSyncMonitorRequest))
          as SSPSyncMonitorRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPSyncMonitorRequest() / SSPSyncMonitorRequest.new instead')
  static SSPSyncMonitorRequest create() => SSPSyncMonitorRequest._();
  static $pb.GeneratedMessage $_createMessage() => SSPSyncMonitorRequest._();
  @$core.override
  SSPSyncMonitorRequest createEmptyInstance() => SSPSyncMonitorRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPSyncMonitorRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPSyncMonitorRequest>(
          SSPSyncMonitorRequest.$_createMessage);
  static SSPSyncMonitorRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get isSyncMonitor => $_getBF(1);
  @$pb.TagNumber(2)
  set isSyncMonitor($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIsSyncMonitor() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsSyncMonitor() => $_clearField(2);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:389
class SSPSyncMonitorResponse extends $pb.GeneratedMessage {
  factory SSPSyncMonitorResponse({
    SSPRequestType? type,
    $core.bool? isSuccess,
  }) {
    final result = SSPSyncMonitorResponse._();
    if (type != null) result.type = type;
    if (isSuccess != null) result.isSuccess = isSuccess;
    return result;
  }

  SSPSyncMonitorResponse._();

  factory SSPSyncMonitorResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPSyncMonitorResponse()..mergeFromBuffer(data, registry);
  factory SSPSyncMonitorResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPSyncMonitorResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPSyncMonitorResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPSyncMonitorResponse.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_SyncMonitorRequest,
        enumValues: SSPRequestType.values)
    ..aOB(2, _omitFieldNames ? '' : 'isSuccess', protoName: 'isSuccess')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPSyncMonitorResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPSyncMonitorResponse copyWith(
          void Function(SSPSyncMonitorResponse) updates) =>
      super.copyWith((message) => updates(message as SSPSyncMonitorResponse))
          as SSPSyncMonitorResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPSyncMonitorResponse() / SSPSyncMonitorResponse.new instead')
  static SSPSyncMonitorResponse create() => SSPSyncMonitorResponse._();
  static $pb.GeneratedMessage $_createMessage() => SSPSyncMonitorResponse._();
  @$core.override
  SSPSyncMonitorResponse createEmptyInstance() => SSPSyncMonitorResponse._();
  @$core.pragma('dart2js:noInline')
  static SSPSyncMonitorResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPSyncMonitorResponse>(
          SSPSyncMonitorResponse.$_createMessage);
  static SSPSyncMonitorResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get isSuccess => $_getBF(1);
  @$pb.TagNumber(2)
  set isSuccess($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIsSuccess() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsSuccess() => $_clearField(2);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:392
class SSPUpdateFileRequest extends $pb.GeneratedMessage {
  factory SSPUpdateFileRequest({
    SSPRequestType? type,
    $core.Iterable<SSPFile>? filesArray,
    $core.bool? isSync,
  }) {
    final result = SSPUpdateFileRequest._();
    if (type != null) result.type = type;
    if (filesArray != null) result.filesArray.addAll(filesArray);
    if (isSync != null) result.isSync = isSync;
    return result;
  }

  SSPUpdateFileRequest._();

  factory SSPUpdateFileRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPUpdateFileRequest()..mergeFromBuffer(data, registry);
  factory SSPUpdateFileRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPUpdateFileRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPUpdateFileRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPUpdateFileRequest.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_UpdateFileInfo,
        enumValues: SSPRequestType.values)
    ..pPM<SSPFile>(2, _omitFieldNames ? '' : 'filesArray',
        protoName: 'filesArray', subBuilder: SSPFile.$_createMessage)
    ..aOB(3, _omitFieldNames ? '' : 'isSync', protoName: 'isSync')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPUpdateFileRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPUpdateFileRequest copyWith(void Function(SSPUpdateFileRequest) updates) =>
      super.copyWith((message) => updates(message as SSPUpdateFileRequest))
          as SSPUpdateFileRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPUpdateFileRequest() / SSPUpdateFileRequest.new instead')
  static SSPUpdateFileRequest create() => SSPUpdateFileRequest._();
  static $pb.GeneratedMessage $_createMessage() => SSPUpdateFileRequest._();
  @$core.override
  SSPUpdateFileRequest createEmptyInstance() => SSPUpdateFileRequest._();
  @$core.pragma('dart2js:noInline')
  static SSPUpdateFileRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPUpdateFileRequest>(
          SSPUpdateFileRequest.$_createMessage);
  static SSPUpdateFileRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<SSPFile> get filesArray => $_getList(1);

  @$pb.TagNumber(3)
  $core.bool get isSync => $_getBF(2);
  @$pb.TagNumber(3)
  set isSync($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIsSync() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsSync() => $_clearField(3);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:396
class SSPUpdateFileResponse extends $pb.GeneratedMessage {
  factory SSPUpdateFileResponse({
    SSPRequestType? type,
    $core.bool? isSuccess,
  }) {
    final result = SSPUpdateFileResponse._();
    if (type != null) result.type = type;
    if (isSuccess != null) result.isSuccess = isSuccess;
    return result;
  }

  SSPUpdateFileResponse._();

  factory SSPUpdateFileResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPUpdateFileResponse()..mergeFromBuffer(data, registry);
  factory SSPUpdateFileResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SSPUpdateFileResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SSPUpdateFileResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'recovered.ssp'),
      createEmptyInstance: SSPUpdateFileResponse.$_createMessage)
    ..aE<SSPRequestType>(1, _omitFieldNames ? '' : 'type',
        defaultOrMaker: SSPRequestType.SSPRequestType_UpdateFileInfoResponse,
        enumValues: SSPRequestType.values)
    ..aOB(2, _omitFieldNames ? '' : 'isSuccess', protoName: 'isSuccess')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPUpdateFileResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SSPUpdateFileResponse copyWith(
          void Function(SSPUpdateFileResponse) updates) =>
      super.copyWith((message) => updates(message as SSPUpdateFileResponse))
          as SSPUpdateFileResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SSPUpdateFileResponse() / SSPUpdateFileResponse.new instead')
  static SSPUpdateFileResponse create() => SSPUpdateFileResponse._();
  static $pb.GeneratedMessage $_createMessage() => SSPUpdateFileResponse._();
  @$core.override
  SSPUpdateFileResponse createEmptyInstance() => SSPUpdateFileResponse._();
  @$core.pragma('dart2js:noInline')
  static SSPUpdateFileResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SSPUpdateFileResponse>(
          SSPUpdateFileResponse.$_createMessage);
  static SSPUpdateFileResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SSPRequestType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SSPRequestType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get isSuccess => $_getBF(1);
  @$pb.TagNumber(2)
  set isSuccess($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIsSuccess() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsSuccess() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
