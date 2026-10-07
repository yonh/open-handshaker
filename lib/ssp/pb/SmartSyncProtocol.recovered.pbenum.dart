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

import 'package:protobuf/protobuf.dart' as $pb;

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:399
class SSPRequestType extends $pb.ProtobufEnum {
  static const SSPRequestType SSPRequestType_HeartBeatRequest =
      SSPRequestType._(
          1, _omitEnumNames ? '' : 'SSPRequestType_HeartBeatRequest');
  static const SSPRequestType SSPRequestType_GetDeviceInfoRequest =
      SSPRequestType._(
          2, _omitEnumNames ? '' : 'SSPRequestType_GetDeviceInfoRequest');
  static const SSPRequestType SSPRequestType_GetThumbnailRequest =
      SSPRequestType._(
          3, _omitEnumNames ? '' : 'SSPRequestType_GetThumbnailRequest');
  static const SSPRequestType SSPRequestType_GetPhotoLibRequest =
      SSPRequestType._(
          4, _omitEnumNames ? '' : 'SSPRequestType_GetPhotoLibRequest');
  static const SSPRequestType SSPRequestType_GetVideoLibRequest =
      SSPRequestType._(
          5, _omitEnumNames ? '' : 'SSPRequestType_GetVideoLibRequest');
  static const SSPRequestType SSPRequestType_GetAudioLibRequest =
      SSPRequestType._(
          6, _omitEnumNames ? '' : 'SSPRequestType_GetAudioLibRequest');
  static const SSPRequestType SSPRequestType_GetDirFilesRequest =
      SSPRequestType._(
          7, _omitEnumNames ? '' : 'SSPRequestType_GetDirFilesRequest');
  static const SSPRequestType SSPRequestType_GetFileCountRequest =
      SSPRequestType._(
          8, _omitEnumNames ? '' : 'SSPRequestType_GetFileCountRequest');
  static const SSPRequestType SSPRequestType_GetFileExistRequest =
      SSPRequestType._(
          9, _omitEnumNames ? '' : 'SSPRequestType_GetFileExistRequest');
  static const SSPRequestType SSPRequestType_GetCreateFolderRequest =
      SSPRequestType._(
          10, _omitEnumNames ? '' : 'SSPRequestType_GetCreateFolderRequest');
  static const SSPRequestType SSPRequestType_GetRenameFileRequest =
      SSPRequestType._(
          11, _omitEnumNames ? '' : 'SSPRequestType_GetRenameFileRequest');
  static const SSPRequestType SSPRequestType_GetDownloadFileRequest =
      SSPRequestType._(
          12, _omitEnumNames ? '' : 'SSPRequestType_GetDownloadFileRequest');
  static const SSPRequestType SSPRequestType_GetDownloadFileResponseHeader =
      SSPRequestType._(13,
          _omitEnumNames ? '' : 'SSPRequestType_GetDownloadFileResponseHeader');
  static const SSPRequestType SSPRequestType_GetDownloadFileResponseBody =
      SSPRequestType._(14,
          _omitEnumNames ? '' : 'SSPRequestType_GetDownloadFileResponseBody');
  static const SSPRequestType SSPRequestType_GetUploadFileRequestHeader =
      SSPRequestType._(15,
          _omitEnumNames ? '' : 'SSPRequestType_GetUploadFileRequestHeader');
  static const SSPRequestType SSPRequestType_GetUploadFileResponseHeader =
      SSPRequestType._(16,
          _omitEnumNames ? '' : 'SSPRequestType_GetUploadFileResponseHeader');
  static const SSPRequestType SSPRequestType_GetUploadFileRequestBody =
      SSPRequestType._(
          17, _omitEnumNames ? '' : 'SSPRequestType_GetUploadFileRequestBody');
  static const SSPRequestType SSPRequestType_GetUploadFileResponse =
      SSPRequestType._(
          18, _omitEnumNames ? '' : 'SSPRequestType_GetUploadFileResponse');
  static const SSPRequestType SSPRequestType_GetDeleteFileRequest =
      SSPRequestType._(
          19, _omitEnumNames ? '' : 'SSPRequestType_GetDeleteFileRequest');
  static const SSPRequestType SSPRequestType_PhotoLibChange = SSPRequestType._(
      20, _omitEnumNames ? '' : 'SSPRequestType_PhotoLibChange');
  static const SSPRequestType SSPRequestType_AudioLibChange = SSPRequestType._(
      21, _omitEnumNames ? '' : 'SSPRequestType_AudioLibChange');
  static const SSPRequestType SSPRequestType_VideoLibChange = SSPRequestType._(
      22, _omitEnumNames ? '' : 'SSPRequestType_VideoLibChange');
  static const SSPRequestType SSPRequestType_MonitorFolderRequest =
      SSPRequestType._(
          23, _omitEnumNames ? '' : 'SSPRequestType_MonitorFolderRequest');
  static const SSPRequestType SSPRequestType_MonitorFolderResponseHeader =
      SSPRequestType._(24,
          _omitEnumNames ? '' : 'SSPRequestType_MonitorFolderResponseHeader');
  static const SSPRequestType SSPRequestType_MonitorFolderResponse =
      SSPRequestType._(
          25, _omitEnumNames ? '' : 'SSPRequestType_MonitorFolderResponse');
  static const SSPRequestType SSPRequestType_GetClipboardRequest =
      SSPRequestType._(
          26, _omitEnumNames ? '' : 'SSPRequestType_GetClipboardRequest');
  static const SSPRequestType SSPRequestType_PostClipboardRequest =
      SSPRequestType._(
          27, _omitEnumNames ? '' : 'SSPRequestType_PostClipboardRequest');
  static const SSPRequestType SSPRequestType_ClearClipboardRequest =
      SSPRequestType._(
          28, _omitEnumNames ? '' : 'SSPRequestType_ClearClipboardRequest');
  static const SSPRequestType SSPRequestType_DeleteClipboardRequest =
      SSPRequestType._(
          29, _omitEnumNames ? '' : 'SSPRequestType_DeleteClipboardRequest');
  static const SSPRequestType SSPRequestType_ClipboardChange = SSPRequestType._(
      30, _omitEnumNames ? '' : 'SSPRequestType_ClipboardChange');
  static const SSPRequestType SSPRequestType_HandshakeRequest01 =
      SSPRequestType._(
          31, _omitEnumNames ? '' : 'SSPRequestType_HandshakeRequest01');
  static const SSPRequestType SSPRequestType_HandshakeResponse01 =
      SSPRequestType._(
          32, _omitEnumNames ? '' : 'SSPRequestType_HandshakeResponse01');
  static const SSPRequestType SSPRequestType_HandshakeRequest02 =
      SSPRequestType._(
          33, _omitEnumNames ? '' : 'SSPRequestType_HandshakeRequest02');
  static const SSPRequestType SSPRequestType_HandshakeResponse02 =
      SSPRequestType._(
          34, _omitEnumNames ? '' : 'SSPRequestType_HandshakeResponse02');
  static const SSPRequestType SSPRequestType_QuitRequest =
      SSPRequestType._(35, _omitEnumNames ? '' : 'SSPRequestType_QuitRequest');
  static const SSPRequestType SSPRequestType_CancelRequest = SSPRequestType._(
      36, _omitEnumNames ? '' : 'SSPRequestType_CancelRequest');
  static const SSPRequestType SSPRequestType_PhotoSyncRequest =
      SSPRequestType._(
          37, _omitEnumNames ? '' : 'SSPRequestType_PhotoSyncRequest');
  static const SSPRequestType SSPRequestType_FileChange =
      SSPRequestType._(38, _omitEnumNames ? '' : 'SSPRequestType_FileChange');
  static const SSPRequestType SSPRequestType_SyncMonitorRequest =
      SSPRequestType._(
          39, _omitEnumNames ? '' : 'SSPRequestType_SyncMonitorRequest');
  static const SSPRequestType SSPRequestType_UpdateFileInfo = SSPRequestType._(
      40, _omitEnumNames ? '' : 'SSPRequestType_UpdateFileInfo');
  static const SSPRequestType SSPRequestType_UpdateFileInfoResponse =
      SSPRequestType._(
          41, _omitEnumNames ? '' : 'SSPRequestType_UpdateFileInfoResponse');

  static const $core.List<SSPRequestType> values = <SSPRequestType>[
    SSPRequestType_HeartBeatRequest,
    SSPRequestType_GetDeviceInfoRequest,
    SSPRequestType_GetThumbnailRequest,
    SSPRequestType_GetPhotoLibRequest,
    SSPRequestType_GetVideoLibRequest,
    SSPRequestType_GetAudioLibRequest,
    SSPRequestType_GetDirFilesRequest,
    SSPRequestType_GetFileCountRequest,
    SSPRequestType_GetFileExistRequest,
    SSPRequestType_GetCreateFolderRequest,
    SSPRequestType_GetRenameFileRequest,
    SSPRequestType_GetDownloadFileRequest,
    SSPRequestType_GetDownloadFileResponseHeader,
    SSPRequestType_GetDownloadFileResponseBody,
    SSPRequestType_GetUploadFileRequestHeader,
    SSPRequestType_GetUploadFileResponseHeader,
    SSPRequestType_GetUploadFileRequestBody,
    SSPRequestType_GetUploadFileResponse,
    SSPRequestType_GetDeleteFileRequest,
    SSPRequestType_PhotoLibChange,
    SSPRequestType_AudioLibChange,
    SSPRequestType_VideoLibChange,
    SSPRequestType_MonitorFolderRequest,
    SSPRequestType_MonitorFolderResponseHeader,
    SSPRequestType_MonitorFolderResponse,
    SSPRequestType_GetClipboardRequest,
    SSPRequestType_PostClipboardRequest,
    SSPRequestType_ClearClipboardRequest,
    SSPRequestType_DeleteClipboardRequest,
    SSPRequestType_ClipboardChange,
    SSPRequestType_HandshakeRequest01,
    SSPRequestType_HandshakeResponse01,
    SSPRequestType_HandshakeRequest02,
    SSPRequestType_HandshakeResponse02,
    SSPRequestType_QuitRequest,
    SSPRequestType_CancelRequest,
    SSPRequestType_PhotoSyncRequest,
    SSPRequestType_FileChange,
    SSPRequestType_SyncMonitorRequest,
    SSPRequestType_UpdateFileInfo,
    SSPRequestType_UpdateFileInfoResponse,
  ];

  static final $core.List<SSPRequestType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 41);
  static SSPRequestType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SSPRequestType._(super.value, super.name);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:441
class SSPFileEventType extends $pb.ProtobufEnum {
  static const SSPFileEventType SSPFileEventType_FileEventCreate =
      SSPFileEventType._(
          1, _omitEnumNames ? '' : 'SSPFileEventType_FileEventCreate');
  static const SSPFileEventType SSPFileEventType_FileEventDelete =
      SSPFileEventType._(
          2, _omitEnumNames ? '' : 'SSPFileEventType_FileEventDelete');
  static const SSPFileEventType SSPFileEventType_FileEventCloseWrite =
      SSPFileEventType._(
          3, _omitEnumNames ? '' : 'SSPFileEventType_FileEventCloseWrite');
  static const SSPFileEventType SSPFileEventType_FileEventMovedFrom =
      SSPFileEventType._(
          4, _omitEnumNames ? '' : 'SSPFileEventType_FileEventMovedFrom');
  static const SSPFileEventType SSPFileEventType_FileEventMovedTo =
      SSPFileEventType._(
          5, _omitEnumNames ? '' : 'SSPFileEventType_FileEventMovedTo');
  static const SSPFileEventType SSPFileEventType_FileEventDeleteSelf =
      SSPFileEventType._(
          6, _omitEnumNames ? '' : 'SSPFileEventType_FileEventDeleteSelf');
  static const SSPFileEventType SSPFileEventType_FileEventMoveSelf =
      SSPFileEventType._(
          7, _omitEnumNames ? '' : 'SSPFileEventType_FileEventMoveSelf');
  static const SSPFileEventType SSPFileEventType_FileEventDirChanged =
      SSPFileEventType._(
          8, _omitEnumNames ? '' : 'SSPFileEventType_FileEventDirChanged');

  static const $core.List<SSPFileEventType> values = <SSPFileEventType>[
    SSPFileEventType_FileEventCreate,
    SSPFileEventType_FileEventDelete,
    SSPFileEventType_FileEventCloseWrite,
    SSPFileEventType_FileEventMovedFrom,
    SSPFileEventType_FileEventMovedTo,
    SSPFileEventType_FileEventDeleteSelf,
    SSPFileEventType_FileEventMoveSelf,
    SSPFileEventType_FileEventDirChanged,
  ];

  static final $core.List<SSPFileEventType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 8);
  static SSPFileEventType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SSPFileEventType._(super.value, super.name);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:450
class SSPFileIOError extends $pb.ProtobufEnum {
  static const SSPFileIOError SSPFileIOError_FileIoUnknowError =
      SSPFileIOError._(
          1, _omitEnumNames ? '' : 'SSPFileIOError_FileIoUnknowError');
  static const SSPFileIOError SSPFileIOError_FileIoInvalidName =
      SSPFileIOError._(
          2, _omitEnumNames ? '' : 'SSPFileIOError_FileIoInvalidName');
  static const SSPFileIOError SSPFileIOError_FileIoInvalidSource =
      SSPFileIOError._(
          3, _omitEnumNames ? '' : 'SSPFileIOError_FileIoInvalidSource');
  static const SSPFileIOError SSPFileIOError_FileIoTargetAlreadyExist =
      SSPFileIOError._(
          4, _omitEnumNames ? '' : 'SSPFileIOError_FileIoTargetAlreadyExist');
  static const SSPFileIOError SSPFileIOError_FileIoPermissionError =
      SSPFileIOError._(
          5, _omitEnumNames ? '' : 'SSPFileIOError_FileIoPermissionError');
  static const SSPFileIOError SSPFileIOError_FileIoInsufficientDiskSpaceError =
      SSPFileIOError._(
          6,
          _omitEnumNames
              ? ''
              : 'SSPFileIOError_FileIoInsufficientDiskSpaceError');
  static const SSPFileIOError SSPFileIOError_FileIoMd5CheckError =
      SSPFileIOError._(
          7, _omitEnumNames ? '' : 'SSPFileIOError_FileIoMd5CheckError');
  static const SSPFileIOError SSPFileIOError_FileIoSystemFile =
      SSPFileIOError._(
          8, _omitEnumNames ? '' : 'SSPFileIOError_FileIoSystemFile');
  static const SSPFileIOError SSPFileIOError_FileIoSdcardRemoved =
      SSPFileIOError._(
          9, _omitEnumNames ? '' : 'SSPFileIOError_FileIoSdcardRemoved');
  static const SSPFileIOError SSPFileIOError_FileIoSdcardNoPermission =
      SSPFileIOError._(
          10, _omitEnumNames ? '' : 'SSPFileIOError_FileIoSdcardNoPermission');

  static const $core.List<SSPFileIOError> values = <SSPFileIOError>[
    SSPFileIOError_FileIoUnknowError,
    SSPFileIOError_FileIoInvalidName,
    SSPFileIOError_FileIoInvalidSource,
    SSPFileIOError_FileIoTargetAlreadyExist,
    SSPFileIOError_FileIoPermissionError,
    SSPFileIOError_FileIoInsufficientDiskSpaceError,
    SSPFileIOError_FileIoMd5CheckError,
    SSPFileIOError_FileIoSystemFile,
    SSPFileIOError_FileIoSdcardRemoved,
    SSPFileIOError_FileIoSdcardNoPermission,
  ];

  static final $core.List<SSPFileIOError?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 10);
  static SSPFileIOError? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SSPFileIOError._(super.value, super.name);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:461
class SSPFileIOPermission extends $pb.ProtobufEnum {
  static const SSPFileIOPermission SSPFileIOPermission_AllowNone =
      SSPFileIOPermission._(
          0, _omitEnumNames ? '' : 'SSPFileIOPermission_AllowNone');
  static const SSPFileIOPermission SSPFileIOPermission_AllowRead =
      SSPFileIOPermission._(
          1, _omitEnumNames ? '' : 'SSPFileIOPermission_AllowRead');
  static const SSPFileIOPermission SSPFileIOPermission_AllowWrite =
      SSPFileIOPermission._(
          2, _omitEnumNames ? '' : 'SSPFileIOPermission_AllowWrite');
  static const SSPFileIOPermission SSPFileIOPermission_AllowReadWrite =
      SSPFileIOPermission._(
          3, _omitEnumNames ? '' : 'SSPFileIOPermission_AllowReadWrite');

  static const $core.List<SSPFileIOPermission> values = <SSPFileIOPermission>[
    SSPFileIOPermission_AllowNone,
    SSPFileIOPermission_AllowRead,
    SSPFileIOPermission_AllowWrite,
    SSPFileIOPermission_AllowReadWrite,
  ];

  static final $core.List<SSPFileIOPermission?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static SSPFileIOPermission? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SSPFileIOPermission._(super.value, super.name);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:466
class SSPHandShakeTrustType extends $pb.ProtobufEnum {
  static const SSPHandShakeTrustType SSPHandShakeTrustType_TrustWaiting =
      SSPHandShakeTrustType._(
          1, _omitEnumNames ? '' : 'SSPHandShakeTrustType_TrustWaiting');
  static const SSPHandShakeTrustType SSPHandShakeTrustType_TrustUnknow =
      SSPHandShakeTrustType._(
          2, _omitEnumNames ? '' : 'SSPHandShakeTrustType_TrustUnknow');
  static const SSPHandShakeTrustType SSPHandShakeTrustType_TrustNo =
      SSPHandShakeTrustType._(
          3, _omitEnumNames ? '' : 'SSPHandShakeTrustType_TrustNo');
  static const SSPHandShakeTrustType SSPHandShakeTrustType_TrustOnce =
      SSPHandShakeTrustType._(
          4, _omitEnumNames ? '' : 'SSPHandShakeTrustType_TrustOnce');
  static const SSPHandShakeTrustType SSPHandShakeTrustType_TrustAlways =
      SSPHandShakeTrustType._(
          5, _omitEnumNames ? '' : 'SSPHandShakeTrustType_TrustAlways');
  static const SSPHandShakeTrustType SSPHandShakeTrustType_TrustRemove =
      SSPHandShakeTrustType._(
          6, _omitEnumNames ? '' : 'SSPHandShakeTrustType_TrustRemove');

  static const $core.List<SSPHandShakeTrustType> values =
      <SSPHandShakeTrustType>[
    SSPHandShakeTrustType_TrustWaiting,
    SSPHandShakeTrustType_TrustUnknow,
    SSPHandShakeTrustType_TrustNo,
    SSPHandShakeTrustType_TrustOnce,
    SSPHandShakeTrustType_TrustAlways,
    SSPHandShakeTrustType_TrustRemove,
  ];

  static final $core.List<SSPHandShakeTrustType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static SSPHandShakeTrustType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SSPHandShakeTrustType._(super.value, super.name);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:473
class SSPCancelErrorCode extends $pb.ProtobufEnum {
  static const SSPCancelErrorCode SSPCancelErrorCode_ErrorCodeUnknown =
      SSPCancelErrorCode._(
          1, _omitEnumNames ? '' : 'SSPCancelErrorCode_ErrorCodeUnknown');
  static const SSPCancelErrorCode SSPCancelErrorCode_ErrorCodeSdcardRemoved =
      SSPCancelErrorCode._(
          2, _omitEnumNames ? '' : 'SSPCancelErrorCode_ErrorCodeSdcardRemoved');

  static const $core.List<SSPCancelErrorCode> values = <SSPCancelErrorCode>[
    SSPCancelErrorCode_ErrorCodeUnknown,
    SSPCancelErrorCode_ErrorCodeSdcardRemoved,
  ];

  static final $core.Map<$core.int, SSPCancelErrorCode> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static SSPCancelErrorCode? valueOf($core.int value) => _byValue[value];

  const SSPCancelErrorCode._(super.value, super.name);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:476
class SSPFileType extends $pb.ProtobufEnum {
  static const SSPFileType SSPFileType_Normal =
      SSPFileType._(0, _omitEnumNames ? '' : 'SSPFileType_Normal');
  static const SSPFileType SSPFileType_Data =
      SSPFileType._(1, _omitEnumNames ? '' : 'SSPFileType_Data');

  static const $core.List<SSPFileType> values = <SSPFileType>[
    SSPFileType_Normal,
    SSPFileType_Data,
  ];

  static final $core.List<SSPFileType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static SSPFileType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SSPFileType._(super.value, super.name);
}

/// Source: handshaker_analysis/dumps/ssp_descriptors.raw.txt:479
class SSPFileChangeStatus extends $pb.ProtobufEnum {
  static const SSPFileChangeStatus SSPFileChangeStatus_None =
      SSPFileChangeStatus._(
          0, _omitEnumNames ? '' : 'SSPFileChangeStatus_None');
  static const SSPFileChangeStatus SSPFileChangeStatus_Added =
      SSPFileChangeStatus._(
          1, _omitEnumNames ? '' : 'SSPFileChangeStatus_Added');
  static const SSPFileChangeStatus SSPFileChangeStatus_Deleted =
      SSPFileChangeStatus._(
          2, _omitEnumNames ? '' : 'SSPFileChangeStatus_Deleted');
  static const SSPFileChangeStatus SSPFileChangeStatus_Modified =
      SSPFileChangeStatus._(
          3, _omitEnumNames ? '' : 'SSPFileChangeStatus_Modified');
  static const SSPFileChangeStatus SSPFileChangeStatus_InfoModified =
      SSPFileChangeStatus._(
          4, _omitEnumNames ? '' : 'SSPFileChangeStatus_InfoModified');
  static const SSPFileChangeStatus SSPFileChangeStatus_FileAndInfoModified =
      SSPFileChangeStatus._(
          5, _omitEnumNames ? '' : 'SSPFileChangeStatus_FileAndInfoModified');

  static const $core.List<SSPFileChangeStatus> values = <SSPFileChangeStatus>[
    SSPFileChangeStatus_None,
    SSPFileChangeStatus_Added,
    SSPFileChangeStatus_Deleted,
    SSPFileChangeStatus_Modified,
    SSPFileChangeStatus_InfoModified,
    SSPFileChangeStatus_FileAndInfoModified,
  ];

  static final $core.List<SSPFileChangeStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static SSPFileChangeStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SSPFileChangeStatus._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
