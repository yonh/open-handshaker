// This is a generated file - do not edit.
//
// Generated from SmartSyncProtocol.recovered.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use sSPRequestTypeDescriptor instead')
const SSPRequestType$json = {
  '1': 'SSPRequestType',
  '2': [
    {'1': 'SSPRequestType_HeartBeatRequest', '2': 1},
    {'1': 'SSPRequestType_GetDeviceInfoRequest', '2': 2},
    {'1': 'SSPRequestType_GetThumbnailRequest', '2': 3},
    {'1': 'SSPRequestType_GetPhotoLibRequest', '2': 4},
    {'1': 'SSPRequestType_GetVideoLibRequest', '2': 5},
    {'1': 'SSPRequestType_GetAudioLibRequest', '2': 6},
    {'1': 'SSPRequestType_GetDirFilesRequest', '2': 7},
    {'1': 'SSPRequestType_GetFileCountRequest', '2': 8},
    {'1': 'SSPRequestType_GetFileExistRequest', '2': 9},
    {'1': 'SSPRequestType_GetCreateFolderRequest', '2': 10},
    {'1': 'SSPRequestType_GetRenameFileRequest', '2': 11},
    {'1': 'SSPRequestType_GetDownloadFileRequest', '2': 12},
    {'1': 'SSPRequestType_GetDownloadFileResponseHeader', '2': 13},
    {'1': 'SSPRequestType_GetDownloadFileResponseBody', '2': 14},
    {'1': 'SSPRequestType_GetUploadFileRequestHeader', '2': 15},
    {'1': 'SSPRequestType_GetUploadFileResponseHeader', '2': 16},
    {'1': 'SSPRequestType_GetUploadFileRequestBody', '2': 17},
    {'1': 'SSPRequestType_GetUploadFileResponse', '2': 18},
    {'1': 'SSPRequestType_GetDeleteFileRequest', '2': 19},
    {'1': 'SSPRequestType_PhotoLibChange', '2': 20},
    {'1': 'SSPRequestType_AudioLibChange', '2': 21},
    {'1': 'SSPRequestType_VideoLibChange', '2': 22},
    {'1': 'SSPRequestType_MonitorFolderRequest', '2': 23},
    {'1': 'SSPRequestType_MonitorFolderResponseHeader', '2': 24},
    {'1': 'SSPRequestType_MonitorFolderResponse', '2': 25},
    {'1': 'SSPRequestType_GetClipboardRequest', '2': 26},
    {'1': 'SSPRequestType_PostClipboardRequest', '2': 27},
    {'1': 'SSPRequestType_ClearClipboardRequest', '2': 28},
    {'1': 'SSPRequestType_DeleteClipboardRequest', '2': 29},
    {'1': 'SSPRequestType_ClipboardChange', '2': 30},
    {'1': 'SSPRequestType_HandshakeRequest01', '2': 31},
    {'1': 'SSPRequestType_HandshakeResponse01', '2': 32},
    {'1': 'SSPRequestType_HandshakeRequest02', '2': 33},
    {'1': 'SSPRequestType_HandshakeResponse02', '2': 34},
    {'1': 'SSPRequestType_QuitRequest', '2': 35},
    {'1': 'SSPRequestType_CancelRequest', '2': 36},
    {'1': 'SSPRequestType_PhotoSyncRequest', '2': 37},
    {'1': 'SSPRequestType_FileChange', '2': 38},
    {'1': 'SSPRequestType_SyncMonitorRequest', '2': 39},
    {'1': 'SSPRequestType_UpdateFileInfo', '2': 40},
    {'1': 'SSPRequestType_UpdateFileInfoResponse', '2': 41},
  ],
};

/// Descriptor for `SSPRequestType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sSPRequestTypeDescriptor = $convert.base64Decode(
    'Cg5TU1BSZXF1ZXN0VHlwZRIjCh9TU1BSZXF1ZXN0VHlwZV9IZWFydEJlYXRSZXF1ZXN0EAESJw'
    'ojU1NQUmVxdWVzdFR5cGVfR2V0RGV2aWNlSW5mb1JlcXVlc3QQAhImCiJTU1BSZXF1ZXN0VHlw'
    'ZV9HZXRUaHVtYm5haWxSZXF1ZXN0EAMSJQohU1NQUmVxdWVzdFR5cGVfR2V0UGhvdG9MaWJSZX'
    'F1ZXN0EAQSJQohU1NQUmVxdWVzdFR5cGVfR2V0VmlkZW9MaWJSZXF1ZXN0EAUSJQohU1NQUmVx'
    'dWVzdFR5cGVfR2V0QXVkaW9MaWJSZXF1ZXN0EAYSJQohU1NQUmVxdWVzdFR5cGVfR2V0RGlyRm'
    'lsZXNSZXF1ZXN0EAcSJgoiU1NQUmVxdWVzdFR5cGVfR2V0RmlsZUNvdW50UmVxdWVzdBAIEiYK'
    'IlNTUFJlcXVlc3RUeXBlX0dldEZpbGVFeGlzdFJlcXVlc3QQCRIpCiVTU1BSZXF1ZXN0VHlwZV'
    '9HZXRDcmVhdGVGb2xkZXJSZXF1ZXN0EAoSJwojU1NQUmVxdWVzdFR5cGVfR2V0UmVuYW1lRmls'
    'ZVJlcXVlc3QQCxIpCiVTU1BSZXF1ZXN0VHlwZV9HZXREb3dubG9hZEZpbGVSZXF1ZXN0EAwSMA'
    'osU1NQUmVxdWVzdFR5cGVfR2V0RG93bmxvYWRGaWxlUmVzcG9uc2VIZWFkZXIQDRIuCipTU1BS'
    'ZXF1ZXN0VHlwZV9HZXREb3dubG9hZEZpbGVSZXNwb25zZUJvZHkQDhItCilTU1BSZXF1ZXN0VH'
    'lwZV9HZXRVcGxvYWRGaWxlUmVxdWVzdEhlYWRlchAPEi4KKlNTUFJlcXVlc3RUeXBlX0dldFVw'
    'bG9hZEZpbGVSZXNwb25zZUhlYWRlchAQEisKJ1NTUFJlcXVlc3RUeXBlX0dldFVwbG9hZEZpbG'
    'VSZXF1ZXN0Qm9keRAREigKJFNTUFJlcXVlc3RUeXBlX0dldFVwbG9hZEZpbGVSZXNwb25zZRAS'
    'EicKI1NTUFJlcXVlc3RUeXBlX0dldERlbGV0ZUZpbGVSZXF1ZXN0EBMSIQodU1NQUmVxdWVzdF'
    'R5cGVfUGhvdG9MaWJDaGFuZ2UQFBIhCh1TU1BSZXF1ZXN0VHlwZV9BdWRpb0xpYkNoYW5nZRAV'
    'EiEKHVNTUFJlcXVlc3RUeXBlX1ZpZGVvTGliQ2hhbmdlEBYSJwojU1NQUmVxdWVzdFR5cGVfTW'
    '9uaXRvckZvbGRlclJlcXVlc3QQFxIuCipTU1BSZXF1ZXN0VHlwZV9Nb25pdG9yRm9sZGVyUmVz'
    'cG9uc2VIZWFkZXIQGBIoCiRTU1BSZXF1ZXN0VHlwZV9Nb25pdG9yRm9sZGVyUmVzcG9uc2UQGR'
    'ImCiJTU1BSZXF1ZXN0VHlwZV9HZXRDbGlwYm9hcmRSZXF1ZXN0EBoSJwojU1NQUmVxdWVzdFR5'
    'cGVfUG9zdENsaXBib2FyZFJlcXVlc3QQGxIoCiRTU1BSZXF1ZXN0VHlwZV9DbGVhckNsaXBib2'
    'FyZFJlcXVlc3QQHBIpCiVTU1BSZXF1ZXN0VHlwZV9EZWxldGVDbGlwYm9hcmRSZXF1ZXN0EB0S'
    'IgoeU1NQUmVxdWVzdFR5cGVfQ2xpcGJvYXJkQ2hhbmdlEB4SJQohU1NQUmVxdWVzdFR5cGVfSG'
    'FuZHNoYWtlUmVxdWVzdDAxEB8SJgoiU1NQUmVxdWVzdFR5cGVfSGFuZHNoYWtlUmVzcG9uc2Uw'
    'MRAgEiUKIVNTUFJlcXVlc3RUeXBlX0hhbmRzaGFrZVJlcXVlc3QwMhAhEiYKIlNTUFJlcXVlc3'
    'RUeXBlX0hhbmRzaGFrZVJlc3BvbnNlMDIQIhIeChpTU1BSZXF1ZXN0VHlwZV9RdWl0UmVxdWVz'
    'dBAjEiAKHFNTUFJlcXVlc3RUeXBlX0NhbmNlbFJlcXVlc3QQJBIjCh9TU1BSZXF1ZXN0VHlwZV'
    '9QaG90b1N5bmNSZXF1ZXN0ECUSHQoZU1NQUmVxdWVzdFR5cGVfRmlsZUNoYW5nZRAmEiUKIVNT'
    'UFJlcXVlc3RUeXBlX1N5bmNNb25pdG9yUmVxdWVzdBAnEiEKHVNTUFJlcXVlc3RUeXBlX1VwZG'
    'F0ZUZpbGVJbmZvECgSKQolU1NQUmVxdWVzdFR5cGVfVXBkYXRlRmlsZUluZm9SZXNwb25zZRAp');

@$core.Deprecated('Use sSPFileEventTypeDescriptor instead')
const SSPFileEventType$json = {
  '1': 'SSPFileEventType',
  '2': [
    {'1': 'SSPFileEventType_FileEventCreate', '2': 1},
    {'1': 'SSPFileEventType_FileEventDelete', '2': 2},
    {'1': 'SSPFileEventType_FileEventCloseWrite', '2': 3},
    {'1': 'SSPFileEventType_FileEventMovedFrom', '2': 4},
    {'1': 'SSPFileEventType_FileEventMovedTo', '2': 5},
    {'1': 'SSPFileEventType_FileEventDeleteSelf', '2': 6},
    {'1': 'SSPFileEventType_FileEventMoveSelf', '2': 7},
    {'1': 'SSPFileEventType_FileEventDirChanged', '2': 8},
  ],
};

/// Descriptor for `SSPFileEventType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sSPFileEventTypeDescriptor = $convert.base64Decode(
    'ChBTU1BGaWxlRXZlbnRUeXBlEiQKIFNTUEZpbGVFdmVudFR5cGVfRmlsZUV2ZW50Q3JlYXRlEA'
    'ESJAogU1NQRmlsZUV2ZW50VHlwZV9GaWxlRXZlbnREZWxldGUQAhIoCiRTU1BGaWxlRXZlbnRU'
    'eXBlX0ZpbGVFdmVudENsb3NlV3JpdGUQAxInCiNTU1BGaWxlRXZlbnRUeXBlX0ZpbGVFdmVudE'
    '1vdmVkRnJvbRAEEiUKIVNTUEZpbGVFdmVudFR5cGVfRmlsZUV2ZW50TW92ZWRUbxAFEigKJFNT'
    'UEZpbGVFdmVudFR5cGVfRmlsZUV2ZW50RGVsZXRlU2VsZhAGEiYKIlNTUEZpbGVFdmVudFR5cG'
    'VfRmlsZUV2ZW50TW92ZVNlbGYQBxIoCiRTU1BGaWxlRXZlbnRUeXBlX0ZpbGVFdmVudERpckNo'
    'YW5nZWQQCA==');

@$core.Deprecated('Use sSPFileIOErrorDescriptor instead')
const SSPFileIOError$json = {
  '1': 'SSPFileIOError',
  '2': [
    {'1': 'SSPFileIOError_FileIoUnknowError', '2': 1},
    {'1': 'SSPFileIOError_FileIoInvalidName', '2': 2},
    {'1': 'SSPFileIOError_FileIoInvalidSource', '2': 3},
    {'1': 'SSPFileIOError_FileIoTargetAlreadyExist', '2': 4},
    {'1': 'SSPFileIOError_FileIoPermissionError', '2': 5},
    {'1': 'SSPFileIOError_FileIoInsufficientDiskSpaceError', '2': 6},
    {'1': 'SSPFileIOError_FileIoMd5CheckError', '2': 7},
    {'1': 'SSPFileIOError_FileIoSystemFile', '2': 8},
    {'1': 'SSPFileIOError_FileIoSdcardRemoved', '2': 9},
    {'1': 'SSPFileIOError_FileIoSdcardNoPermission', '2': 10},
  ],
};

/// Descriptor for `SSPFileIOError`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sSPFileIOErrorDescriptor = $convert.base64Decode(
    'Cg5TU1BGaWxlSU9FcnJvchIkCiBTU1BGaWxlSU9FcnJvcl9GaWxlSW9Vbmtub3dFcnJvchABEi'
    'QKIFNTUEZpbGVJT0Vycm9yX0ZpbGVJb0ludmFsaWROYW1lEAISJgoiU1NQRmlsZUlPRXJyb3Jf'
    'RmlsZUlvSW52YWxpZFNvdXJjZRADEisKJ1NTUEZpbGVJT0Vycm9yX0ZpbGVJb1RhcmdldEFscm'
    'VhZHlFeGlzdBAEEigKJFNTUEZpbGVJT0Vycm9yX0ZpbGVJb1Blcm1pc3Npb25FcnJvchAFEjMK'
    'L1NTUEZpbGVJT0Vycm9yX0ZpbGVJb0luc3VmZmljaWVudERpc2tTcGFjZUVycm9yEAYSJgoiU1'
    'NQRmlsZUlPRXJyb3JfRmlsZUlvTWQ1Q2hlY2tFcnJvchAHEiMKH1NTUEZpbGVJT0Vycm9yX0Zp'
    'bGVJb1N5c3RlbUZpbGUQCBImCiJTU1BGaWxlSU9FcnJvcl9GaWxlSW9TZGNhcmRSZW1vdmVkEA'
    'kSKwonU1NQRmlsZUlPRXJyb3JfRmlsZUlvU2RjYXJkTm9QZXJtaXNzaW9uEAo=');

@$core.Deprecated('Use sSPFileIOPermissionDescriptor instead')
const SSPFileIOPermission$json = {
  '1': 'SSPFileIOPermission',
  '2': [
    {'1': 'SSPFileIOPermission_AllowNone', '2': 0},
    {'1': 'SSPFileIOPermission_AllowRead', '2': 1},
    {'1': 'SSPFileIOPermission_AllowWrite', '2': 2},
    {'1': 'SSPFileIOPermission_AllowReadWrite', '2': 3},
  ],
};

/// Descriptor for `SSPFileIOPermission`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sSPFileIOPermissionDescriptor = $convert.base64Decode(
    'ChNTU1BGaWxlSU9QZXJtaXNzaW9uEiEKHVNTUEZpbGVJT1Blcm1pc3Npb25fQWxsb3dOb25lEA'
    'ASIQodU1NQRmlsZUlPUGVybWlzc2lvbl9BbGxvd1JlYWQQARIiCh5TU1BGaWxlSU9QZXJtaXNz'
    'aW9uX0FsbG93V3JpdGUQAhImCiJTU1BGaWxlSU9QZXJtaXNzaW9uX0FsbG93UmVhZFdyaXRlEA'
    'M=');

@$core.Deprecated('Use sSPHandShakeTrustTypeDescriptor instead')
const SSPHandShakeTrustType$json = {
  '1': 'SSPHandShakeTrustType',
  '2': [
    {'1': 'SSPHandShakeTrustType_TrustWaiting', '2': 1},
    {'1': 'SSPHandShakeTrustType_TrustUnknow', '2': 2},
    {'1': 'SSPHandShakeTrustType_TrustNo', '2': 3},
    {'1': 'SSPHandShakeTrustType_TrustOnce', '2': 4},
    {'1': 'SSPHandShakeTrustType_TrustAlways', '2': 5},
    {'1': 'SSPHandShakeTrustType_TrustRemove', '2': 6},
  ],
};

/// Descriptor for `SSPHandShakeTrustType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sSPHandShakeTrustTypeDescriptor = $convert.base64Decode(
    'ChVTU1BIYW5kU2hha2VUcnVzdFR5cGUSJgoiU1NQSGFuZFNoYWtlVHJ1c3RUeXBlX1RydXN0V2'
    'FpdGluZxABEiUKIVNTUEhhbmRTaGFrZVRydXN0VHlwZV9UcnVzdFVua25vdxACEiEKHVNTUEhh'
    'bmRTaGFrZVRydXN0VHlwZV9UcnVzdE5vEAMSIwofU1NQSGFuZFNoYWtlVHJ1c3RUeXBlX1RydX'
    'N0T25jZRAEEiUKIVNTUEhhbmRTaGFrZVRydXN0VHlwZV9UcnVzdEFsd2F5cxAFEiUKIVNTUEhh'
    'bmRTaGFrZVRydXN0VHlwZV9UcnVzdFJlbW92ZRAG');

@$core.Deprecated('Use sSPCancelErrorCodeDescriptor instead')
const SSPCancelErrorCode$json = {
  '1': 'SSPCancelErrorCode',
  '2': [
    {'1': 'SSPCancelErrorCode_ErrorCodeUnknown', '2': 1},
    {'1': 'SSPCancelErrorCode_ErrorCodeSdcardRemoved', '2': 2},
  ],
};

/// Descriptor for `SSPCancelErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sSPCancelErrorCodeDescriptor = $convert.base64Decode(
    'ChJTU1BDYW5jZWxFcnJvckNvZGUSJwojU1NQQ2FuY2VsRXJyb3JDb2RlX0Vycm9yQ29kZVVua2'
    '5vd24QARItCilTU1BDYW5jZWxFcnJvckNvZGVfRXJyb3JDb2RlU2RjYXJkUmVtb3ZlZBAC');

@$core.Deprecated('Use sSPFileTypeDescriptor instead')
const SSPFileType$json = {
  '1': 'SSPFileType',
  '2': [
    {'1': 'SSPFileType_Normal', '2': 0},
    {'1': 'SSPFileType_Data', '2': 1},
  ],
};

/// Descriptor for `SSPFileType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sSPFileTypeDescriptor = $convert.base64Decode(
    'CgtTU1BGaWxlVHlwZRIWChJTU1BGaWxlVHlwZV9Ob3JtYWwQABIUChBTU1BGaWxlVHlwZV9EYX'
    'RhEAE=');

@$core.Deprecated('Use sSPFileChangeStatusDescriptor instead')
const SSPFileChangeStatus$json = {
  '1': 'SSPFileChangeStatus',
  '2': [
    {'1': 'SSPFileChangeStatus_None', '2': 0},
    {'1': 'SSPFileChangeStatus_Added', '2': 1},
    {'1': 'SSPFileChangeStatus_Deleted', '2': 2},
    {'1': 'SSPFileChangeStatus_Modified', '2': 3},
    {'1': 'SSPFileChangeStatus_InfoModified', '2': 4},
    {'1': 'SSPFileChangeStatus_FileAndInfoModified', '2': 5},
  ],
};

/// Descriptor for `SSPFileChangeStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sSPFileChangeStatusDescriptor = $convert.base64Decode(
    'ChNTU1BGaWxlQ2hhbmdlU3RhdHVzEhwKGFNTUEZpbGVDaGFuZ2VTdGF0dXNfTm9uZRAAEh0KGV'
    'NTUEZpbGVDaGFuZ2VTdGF0dXNfQWRkZWQQARIfChtTU1BGaWxlQ2hhbmdlU3RhdHVzX0RlbGV0'
    'ZWQQAhIgChxTU1BGaWxlQ2hhbmdlU3RhdHVzX01vZGlmaWVkEAMSJAogU1NQRmlsZUNoYW5nZV'
    'N0YXR1c19JbmZvTW9kaWZpZWQQBBIrCidTU1BGaWxlQ2hhbmdlU3RhdHVzX0ZpbGVBbmRJbmZv'
    'TW9kaWZpZWQQBQ==');

@$core.Deprecated('Use sSPFileDescriptor instead')
const SSPFile$json = {
  '1': 'SSPFile',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'fileSize', '3': 2, '4': 1, '5': 4, '10': 'fileSize'},
    {'1': 'createdTimestamp', '3': 3, '4': 1, '5': 4, '10': 'createdTimestamp'},
    {
      '1': 'modifiedTimestamp',
      '3': 4,
      '4': 1,
      '5': 4,
      '10': 'modifiedTimestamp'
    },
    {'1': 'isDirectory', '3': 6, '4': 1, '5': 8, '10': 'isDirectory'},
    {'1': 'checksum', '3': 7, '4': 1, '5': 9, '10': 'checksum'},
    {
      '1': 'fileType',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPFileType',
      '10': 'fileType'
    },
    {'1': 'prefixMd5', '3': 9, '4': 1, '5': 9, '10': 'prefixMd5'},
    {'1': 'extData', '3': 10, '4': 1, '5': 9, '10': 'extData'},
  ],
};

/// Descriptor for `SSPFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPFileDescriptor = $convert.base64Decode(
    'CgdTU1BGaWxlEhIKBHBhdGgYASABKAlSBHBhdGgSGgoIZmlsZVNpemUYAiABKARSCGZpbGVTaX'
    'plEioKEGNyZWF0ZWRUaW1lc3RhbXAYAyABKARSEGNyZWF0ZWRUaW1lc3RhbXASLAoRbW9kaWZp'
    'ZWRUaW1lc3RhbXAYBCABKARSEW1vZGlmaWVkVGltZXN0YW1wEiAKC2lzRGlyZWN0b3J5GAYgAS'
    'gIUgtpc0RpcmVjdG9yeRIaCghjaGVja3N1bRgHIAEoCVIIY2hlY2tzdW0SNgoIZmlsZVR5cGUY'
    'CCABKA4yGi5yZWNvdmVyZWQuc3NwLlNTUEZpbGVUeXBlUghmaWxlVHlwZRIcCglwcmVmaXhNZD'
    'UYCSABKAlSCXByZWZpeE1kNRIYCgdleHREYXRhGAogASgJUgdleHREYXRh');

@$core.Deprecated('Use sSPImageFileDescriptor instead')
const SSPImageFile$json = {
  '1': 'SSPImageFile',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'fileSize', '3': 2, '4': 1, '5': 4, '10': 'fileSize'},
    {'1': 'createdTimestamp', '3': 3, '4': 1, '5': 4, '10': 'createdTimestamp'},
    {
      '1': 'modifiedTimestamp',
      '3': 4,
      '4': 1,
      '5': 4,
      '10': 'modifiedTimestamp'
    },
    {'1': 'width', '3': 5, '4': 1, '5': 13, '10': 'width'},
    {'1': 'height', '3': 6, '4': 1, '5': 13, '10': 'height'},
    {'1': 'orientation', '3': 7, '4': 1, '5': 13, '10': 'orientation'},
    {'1': 'mediaId', '3': 8, '4': 1, '5': 4, '10': 'mediaId'},
    {'1': 'albumId', '3': 9, '4': 1, '5': 4, '10': 'albumId'},
    {'1': 'mimeType', '3': 10, '4': 1, '5': 9, '10': 'mimeType'},
    {'1': 'thumbnail', '3': 11, '4': 1, '5': 12, '10': 'thumbnail'},
    {'1': 'albumName', '3': 12, '4': 1, '5': 9, '10': 'albumName'},
    {'1': 'dateTaken', '3': 13, '4': 1, '5': 4, '10': 'dateTaken'},
    {'1': 'latitude', '3': 14, '4': 1, '5': 9, '10': 'latitude'},
    {'1': 'longitude', '3': 15, '4': 1, '5': 9, '10': 'longitude'},
    {'1': 'miniThumbMagic', '3': 16, '4': 1, '5': 9, '10': 'miniThumbMagic'},
    {'1': 'title', '3': 17, '4': 1, '5': 9, '10': 'title'},
    {
      '1': 'getThumbnailError',
      '3': 18,
      '4': 1,
      '5': 8,
      '10': 'getThumbnailError'
    },
    {'1': 'starred', '3': 19, '4': 1, '5': 8, '10': 'starred'},
  ],
};

/// Descriptor for `SSPImageFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPImageFileDescriptor = $convert.base64Decode(
    'CgxTU1BJbWFnZUZpbGUSEgoEcGF0aBgBIAEoCVIEcGF0aBIaCghmaWxlU2l6ZRgCIAEoBFIIZm'
    'lsZVNpemUSKgoQY3JlYXRlZFRpbWVzdGFtcBgDIAEoBFIQY3JlYXRlZFRpbWVzdGFtcBIsChFt'
    'b2RpZmllZFRpbWVzdGFtcBgEIAEoBFIRbW9kaWZpZWRUaW1lc3RhbXASFAoFd2lkdGgYBSABKA'
    '1SBXdpZHRoEhYKBmhlaWdodBgGIAEoDVIGaGVpZ2h0EiAKC29yaWVudGF0aW9uGAcgASgNUgtv'
    'cmllbnRhdGlvbhIYCgdtZWRpYUlkGAggASgEUgdtZWRpYUlkEhgKB2FsYnVtSWQYCSABKARSB2'
    'FsYnVtSWQSGgoIbWltZVR5cGUYCiABKAlSCG1pbWVUeXBlEhwKCXRodW1ibmFpbBgLIAEoDFIJ'
    'dGh1bWJuYWlsEhwKCWFsYnVtTmFtZRgMIAEoCVIJYWxidW1OYW1lEhwKCWRhdGVUYWtlbhgNIA'
    'EoBFIJZGF0ZVRha2VuEhoKCGxhdGl0dWRlGA4gASgJUghsYXRpdHVkZRIcCglsb25naXR1ZGUY'
    'DyABKAlSCWxvbmdpdHVkZRImCg5taW5pVGh1bWJNYWdpYxgQIAEoCVIObWluaVRodW1iTWFnaW'
    'MSFAoFdGl0bGUYESABKAlSBXRpdGxlEiwKEWdldFRodW1ibmFpbEVycm9yGBIgASgIUhFnZXRU'
    'aHVtYm5haWxFcnJvchIYCgdzdGFycmVkGBMgASgIUgdzdGFycmVk');

@$core.Deprecated('Use sSPImageAlbumDescriptor instead')
const SSPImageAlbum$json = {
  '1': 'SSPImageAlbum',
  '2': [
    {'1': 'albumPath', '3': 1, '4': 1, '5': 9, '10': 'albumPath'},
    {'1': 'albumId', '3': 2, '4': 1, '5': 4, '10': 'albumId'},
    {'1': 'albumName', '3': 3, '4': 1, '5': 9, '10': 'albumName'},
    {
      '1': 'coverImage',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPImageFile',
      '10': 'coverImage'
    },
  ],
};

/// Descriptor for `SSPImageAlbum`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPImageAlbumDescriptor = $convert.base64Decode(
    'Cg1TU1BJbWFnZUFsYnVtEhwKCWFsYnVtUGF0aBgBIAEoCVIJYWxidW1QYXRoEhgKB2FsYnVtSW'
    'QYAiABKARSB2FsYnVtSWQSHAoJYWxidW1OYW1lGAMgASgJUglhbGJ1bU5hbWUSOwoKY292ZXJJ'
    'bWFnZRgEIAEoCzIbLnJlY292ZXJlZC5zc3AuU1NQSW1hZ2VGaWxlUgpjb3ZlckltYWdl');

@$core.Deprecated('Use sSPAudioFileDescriptor instead')
const SSPAudioFile$json = {
  '1': 'SSPAudioFile',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'fileSize', '3': 2, '4': 1, '5': 4, '10': 'fileSize'},
    {'1': 'createdTimestamp', '3': 3, '4': 1, '5': 4, '10': 'createdTimestamp'},
    {
      '1': 'modifiedTimestamp',
      '3': 4,
      '4': 1,
      '5': 4,
      '10': 'modifiedTimestamp'
    },
    {'1': 'mediaId', '3': 5, '4': 1, '5': 4, '10': 'mediaId'},
    {'1': 'albumId', '3': 6, '4': 1, '5': 4, '10': 'albumId'},
    {'1': 'title', '3': 7, '4': 1, '5': 9, '10': 'title'},
    {'1': 'mimeType', '3': 8, '4': 1, '5': 9, '10': 'mimeType'},
    {'1': 'artistId', '3': 9, '4': 1, '5': 4, '10': 'artistId'},
    {'1': 'artist', '3': 10, '4': 1, '5': 9, '10': 'artist'},
    {'1': 'composer', '3': 11, '4': 1, '5': 9, '10': 'composer'},
    {'1': 'genre', '3': 12, '4': 1, '5': 13, '10': 'genre'},
    {'1': 'comment', '3': 13, '4': 1, '5': 9, '10': 'comment'},
    {'1': 'copyright', '3': 14, '4': 1, '5': 9, '10': 'copyright'},
    {'1': 'audioCodec', '3': 15, '4': 1, '5': 9, '10': 'audioCodec'},
    {'1': 'track', '3': 16, '4': 1, '5': 13, '10': 'track'},
    {'1': 'duration', '3': 17, '4': 1, '5': 1, '10': 'duration'},
    {'1': 'startOffset', '3': 18, '4': 1, '5': 1, '10': 'startOffset'},
    {'1': 'year', '3': 19, '4': 1, '5': 13, '10': 'year'},
    {'1': 'bitrate', '3': 20, '4': 1, '5': 13, '10': 'bitrate'},
    {'1': 'sampleRate', '3': 21, '4': 1, '5': 1, '10': 'sampleRate'},
    {'1': 'playCount', '3': 22, '4': 1, '5': 13, '10': 'playCount'},
    {'1': 'rating', '3': 23, '4': 1, '5': 1, '10': 'rating'},
    {'1': 'totalFrames', '3': 24, '4': 1, '5': 13, '10': 'totalFrames'},
    {'1': 'bitspersample', '3': 25, '4': 1, '5': 13, '10': 'bitspersample'},
    {'1': 'channels', '3': 26, '4': 1, '5': 13, '10': 'channels'},
    {'1': 'genreName', '3': 27, '4': 1, '5': 9, '10': 'genreName'},
  ],
};

/// Descriptor for `SSPAudioFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPAudioFileDescriptor = $convert.base64Decode(
    'CgxTU1BBdWRpb0ZpbGUSEgoEcGF0aBgBIAEoCVIEcGF0aBIaCghmaWxlU2l6ZRgCIAEoBFIIZm'
    'lsZVNpemUSKgoQY3JlYXRlZFRpbWVzdGFtcBgDIAEoBFIQY3JlYXRlZFRpbWVzdGFtcBIsChFt'
    'b2RpZmllZFRpbWVzdGFtcBgEIAEoBFIRbW9kaWZpZWRUaW1lc3RhbXASGAoHbWVkaWFJZBgFIA'
    'EoBFIHbWVkaWFJZBIYCgdhbGJ1bUlkGAYgASgEUgdhbGJ1bUlkEhQKBXRpdGxlGAcgASgJUgV0'
    'aXRsZRIaCghtaW1lVHlwZRgIIAEoCVIIbWltZVR5cGUSGgoIYXJ0aXN0SWQYCSABKARSCGFydG'
    'lzdElkEhYKBmFydGlzdBgKIAEoCVIGYXJ0aXN0EhoKCGNvbXBvc2VyGAsgASgJUghjb21wb3Nl'
    'chIUCgVnZW5yZRgMIAEoDVIFZ2VucmUSGAoHY29tbWVudBgNIAEoCVIHY29tbWVudBIcCgljb3'
    'B5cmlnaHQYDiABKAlSCWNvcHlyaWdodBIeCgphdWRpb0NvZGVjGA8gASgJUgphdWRpb0NvZGVj'
    'EhQKBXRyYWNrGBAgASgNUgV0cmFjaxIaCghkdXJhdGlvbhgRIAEoAVIIZHVyYXRpb24SIAoLc3'
    'RhcnRPZmZzZXQYEiABKAFSC3N0YXJ0T2Zmc2V0EhIKBHllYXIYEyABKA1SBHllYXISGAoHYml0'
    'cmF0ZRgUIAEoDVIHYml0cmF0ZRIeCgpzYW1wbGVSYXRlGBUgASgBUgpzYW1wbGVSYXRlEhwKCX'
    'BsYXlDb3VudBgWIAEoDVIJcGxheUNvdW50EhYKBnJhdGluZxgXIAEoAVIGcmF0aW5nEiAKC3Rv'
    'dGFsRnJhbWVzGBggASgNUgt0b3RhbEZyYW1lcxIkCg1iaXRzcGVyc2FtcGxlGBkgASgNUg1iaX'
    'RzcGVyc2FtcGxlEhoKCGNoYW5uZWxzGBogASgNUghjaGFubmVscxIcCglnZW5yZU5hbWUYGyAB'
    'KAlSCWdlbnJlTmFtZQ==');

@$core.Deprecated('Use sSPAudioAlbumDescriptor instead')
const SSPAudioAlbum$json = {
  '1': 'SSPAudioAlbum',
  '2': [
    {'1': 'albumPath', '3': 1, '4': 1, '5': 9, '10': 'albumPath'},
    {'1': 'albumId', '3': 2, '4': 1, '5': 4, '10': 'albumId'},
    {'1': 'albumName', '3': 3, '4': 1, '5': 9, '10': 'albumName'},
    {'1': 'artistId', '3': 4, '4': 1, '5': 4, '10': 'artistId'},
    {'1': 'artist', '3': 5, '4': 1, '5': 9, '10': 'artist'},
    {'1': 'year', '3': 6, '4': 1, '5': 13, '10': 'year'},
    {'1': 'thumbnail', '3': 7, '4': 1, '5': 12, '10': 'thumbnail'},
    {
      '1': 'getThumbnailError',
      '3': 8,
      '4': 1,
      '5': 8,
      '10': 'getThumbnailError'
    },
  ],
};

/// Descriptor for `SSPAudioAlbum`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPAudioAlbumDescriptor = $convert.base64Decode(
    'Cg1TU1BBdWRpb0FsYnVtEhwKCWFsYnVtUGF0aBgBIAEoCVIJYWxidW1QYXRoEhgKB2FsYnVtSW'
    'QYAiABKARSB2FsYnVtSWQSHAoJYWxidW1OYW1lGAMgASgJUglhbGJ1bU5hbWUSGgoIYXJ0aXN0'
    'SWQYBCABKARSCGFydGlzdElkEhYKBmFydGlzdBgFIAEoCVIGYXJ0aXN0EhIKBHllYXIYBiABKA'
    '1SBHllYXISHAoJdGh1bWJuYWlsGAcgASgMUgl0aHVtYm5haWwSLAoRZ2V0VGh1bWJuYWlsRXJy'
    'b3IYCCABKAhSEWdldFRodW1ibmFpbEVycm9y');

@$core.Deprecated('Use sSPVideoFileDescriptor instead')
const SSPVideoFile$json = {
  '1': 'SSPVideoFile',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'fileSize', '3': 2, '4': 1, '5': 4, '10': 'fileSize'},
    {
      '1': 'createdTimestamp',
      '3': 3,
      '4': 1,
      '5': 13,
      '10': 'createdTimestamp'
    },
    {
      '1': 'modifiedTimestamp',
      '3': 4,
      '4': 1,
      '5': 13,
      '10': 'modifiedTimestamp'
    },
    {'1': 'width', '3': 5, '4': 1, '5': 13, '10': 'width'},
    {'1': 'height', '3': 6, '4': 1, '5': 13, '10': 'height'},
    {'1': 'orientation', '3': 7, '4': 1, '5': 13, '10': 'orientation'},
    {'1': 'mediaId', '3': 8, '4': 1, '5': 4, '10': 'mediaId'},
    {'1': 'albumId', '3': 9, '4': 1, '5': 4, '10': 'albumId'},
    {'1': 'mimeType', '3': 10, '4': 1, '5': 9, '10': 'mimeType'},
    {'1': 'thumbnail', '3': 11, '4': 1, '5': 12, '10': 'thumbnail'},
    {
      '1': 'getThumbnailError',
      '3': 12,
      '4': 1,
      '5': 8,
      '10': 'getThumbnailError'
    },
    {'1': 'duration', '3': 13, '4': 1, '5': 1, '10': 'duration'},
  ],
};

/// Descriptor for `SSPVideoFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPVideoFileDescriptor = $convert.base64Decode(
    'CgxTU1BWaWRlb0ZpbGUSEgoEcGF0aBgBIAEoCVIEcGF0aBIaCghmaWxlU2l6ZRgCIAEoBFIIZm'
    'lsZVNpemUSKgoQY3JlYXRlZFRpbWVzdGFtcBgDIAEoDVIQY3JlYXRlZFRpbWVzdGFtcBIsChFt'
    'b2RpZmllZFRpbWVzdGFtcBgEIAEoDVIRbW9kaWZpZWRUaW1lc3RhbXASFAoFd2lkdGgYBSABKA'
    '1SBXdpZHRoEhYKBmhlaWdodBgGIAEoDVIGaGVpZ2h0EiAKC29yaWVudGF0aW9uGAcgASgNUgtv'
    'cmllbnRhdGlvbhIYCgdtZWRpYUlkGAggASgEUgdtZWRpYUlkEhgKB2FsYnVtSWQYCSABKARSB2'
    'FsYnVtSWQSGgoIbWltZVR5cGUYCiABKAlSCG1pbWVUeXBlEhwKCXRodW1ibmFpbBgLIAEoDFIJ'
    'dGh1bWJuYWlsEiwKEWdldFRodW1ibmFpbEVycm9yGAwgASgIUhFnZXRUaHVtYm5haWxFcnJvch'
    'IaCghkdXJhdGlvbhgNIAEoAVIIZHVyYXRpb24=');

@$core.Deprecated('Use sSPVideoAlbumDescriptor instead')
const SSPVideoAlbum$json = {
  '1': 'SSPVideoAlbum',
  '2': [
    {'1': 'albumPath', '3': 1, '4': 1, '5': 9, '10': 'albumPath'},
    {'1': 'albumId', '3': 2, '4': 1, '5': 4, '10': 'albumId'},
    {'1': 'albumName', '3': 3, '4': 1, '5': 9, '10': 'albumName'},
  ],
};

/// Descriptor for `SSPVideoAlbum`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPVideoAlbumDescriptor = $convert.base64Decode(
    'Cg1TU1BWaWRlb0FsYnVtEhwKCWFsYnVtUGF0aBgBIAEoCVIJYWxidW1QYXRoEhgKB2FsYnVtSW'
    'QYAiABKARSB2FsYnVtSWQSHAoJYWxidW1OYW1lGAMgASgJUglhbGJ1bU5hbWU=');

@$core.Deprecated('Use sSPDataRangeDescriptor instead')
const SSPDataRange$json = {
  '1': 'SSPDataRange',
  '2': [
    {'1': 'offset', '3': 1, '4': 1, '5': 4, '10': 'offset'},
    {'1': 'length', '3': 2, '4': 1, '5': 4, '10': 'length'},
  ],
};

/// Descriptor for `SSPDataRange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPDataRangeDescriptor = $convert.base64Decode(
    'CgxTU1BEYXRhUmFuZ2USFgoGb2Zmc2V0GAEgASgEUgZvZmZzZXQSFgoGbGVuZ3RoGAIgASgEUg'
    'ZsZW5ndGg=');

@$core.Deprecated('Use sSPFileEventDescriptor instead')
const SSPFileEvent$json = {
  '1': 'SSPFileEvent',
  '2': [
    {
      '1': 'file',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'file'
    },
    {
      '1': 'event',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPFileEventType',
      '10': 'event'
    },
  ],
};

/// Descriptor for `SSPFileEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPFileEventDescriptor = $convert.base64Decode(
    'CgxTU1BGaWxlRXZlbnQSKgoEZmlsZRgBIAEoCzIWLnJlY292ZXJlZC5zc3AuU1NQRmlsZVIEZm'
    'lsZRI1CgVldmVudBgCIAEoDjIfLnJlY292ZXJlZC5zc3AuU1NQRmlsZUV2ZW50VHlwZVIFZXZl'
    'bnQ=');

@$core.Deprecated('Use sSPRequestDescriptor instead')
const SSPRequest$json = {
  '1': 'SSPRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '10': 'type'
    },
  ],
};

/// Descriptor for `SSPRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPRequestDescriptor = $convert.base64Decode(
    'CgpTU1BSZXF1ZXN0EjEKBHR5cGUYASABKA4yHS5yZWNvdmVyZWQuc3NwLlNTUFJlcXVlc3RUeX'
    'BlUgR0eXBl');

@$core.Deprecated('Use sSPHandShakeRequest01Descriptor instead')
const SSPHandShakeRequest01$json = {
  '1': 'SSPHandShakeRequest01',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_HandshakeRequest01',
      '10': 'type'
    },
    {'1': 'hostUuid', '3': 2, '4': 1, '5': 9, '10': 'hostUuid'},
    {'1': 'hostName', '3': 3, '4': 1, '5': 9, '10': 'hostName'},
    {'1': 'hostTimestamp', '3': 4, '4': 1, '5': 4, '10': 'hostTimestamp'},
    {
      '1': 'hostSmartSyncProtocolVersion',
      '3': 5,
      '4': 1,
      '5': 9,
      '10': 'hostSmartSyncProtocolVersion'
    },
    {'1': 'hostAppVersion', '3': 6, '4': 1, '5': 9, '10': 'hostAppVersion'},
    {
      '1': 'hostMinClientVersion',
      '3': 7,
      '4': 1,
      '5': 9,
      '10': 'hostMinClientVersion'
    },
    {'1': 'md5', '3': 8, '4': 1, '5': 12, '10': 'md5'},
    {'1': 'enckey', '3': 9, '4': 1, '5': 12, '10': 'enckey'},
    {'1': 'hostModel', '3': 10, '4': 1, '5': 9, '10': 'hostModel'},
    {
      '1': 'heartbeatTimeoutSecond',
      '3': 11,
      '4': 1,
      '5': 4,
      '10': 'heartbeatTimeoutSecond'
    },
  ],
};

/// Descriptor for `SSPHandShakeRequest01`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPHandShakeRequest01Descriptor = $convert.base64Decode(
    'ChVTU1BIYW5kU2hha2VSZXF1ZXN0MDESVAoEdHlwZRgBIAEoDjIdLnJlY292ZXJlZC5zc3AuU1'
    'NQUmVxdWVzdFR5cGU6IVNTUFJlcXVlc3RUeXBlX0hhbmRzaGFrZVJlcXVlc3QwMVIEdHlwZRIa'
    'Cghob3N0VXVpZBgCIAEoCVIIaG9zdFV1aWQSGgoIaG9zdE5hbWUYAyABKAlSCGhvc3ROYW1lEi'
    'QKDWhvc3RUaW1lc3RhbXAYBCABKARSDWhvc3RUaW1lc3RhbXASQgocaG9zdFNtYXJ0U3luY1By'
    'b3RvY29sVmVyc2lvbhgFIAEoCVIcaG9zdFNtYXJ0U3luY1Byb3RvY29sVmVyc2lvbhImCg5ob3'
    'N0QXBwVmVyc2lvbhgGIAEoCVIOaG9zdEFwcFZlcnNpb24SMgoUaG9zdE1pbkNsaWVudFZlcnNp'
    'b24YByABKAlSFGhvc3RNaW5DbGllbnRWZXJzaW9uEhAKA21kNRgIIAEoDFIDbWQ1EhYKBmVuY2'
    'tleRgJIAEoDFIGZW5ja2V5EhwKCWhvc3RNb2RlbBgKIAEoCVIJaG9zdE1vZGVsEjYKFmhlYXJ0'
    'YmVhdFRpbWVvdXRTZWNvbmQYCyABKARSFmhlYXJ0YmVhdFRpbWVvdXRTZWNvbmQ=');

@$core.Deprecated('Use sSPHandShakeResponse01Descriptor instead')
const SSPHandShakeResponse01$json = {
  '1': 'SSPHandShakeResponse01',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_HandshakeResponse01',
      '10': 'type'
    },
    {'1': 'apkVersion', '3': 2, '4': 1, '5': 9, '10': 'apkVersion'},
    {'1': 'apkVersionName', '3': 3, '4': 1, '5': 9, '10': 'apkVersionName'},
    {'1': 'clientTimestamp', '3': 4, '4': 1, '5': 4, '10': 'clientTimestamp'},
    {
      '1': 'clientSmartSyncProtocolVersion',
      '3': 5,
      '4': 1,
      '5': 9,
      '10': 'clientSmartSyncProtocolVersion'
    },
    {
      '1': 'clientMinHostVersion',
      '3': 6,
      '4': 1,
      '5': 9,
      '10': 'clientMinHostVersion'
    },
    {'1': 'deviceUuid', '3': 7, '4': 1, '5': 9, '10': 'deviceUuid'},
    {'1': 'deviceName', '3': 8, '4': 1, '5': 9, '10': 'deviceName'},
    {'1': 'usbSerial', '3': 9, '4': 1, '5': 9, '10': 'usbSerial'},
    {
      '1': 'isSmartisanDevice',
      '3': 10,
      '4': 1,
      '5': 8,
      '10': 'isSmartisanDevice'
    },
    {
      '1': 'clientMinHostVersionCode',
      '3': 11,
      '4': 1,
      '5': 4,
      '10': 'clientMinHostVersionCode'
    },
  ],
};

/// Descriptor for `SSPHandShakeResponse01`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPHandShakeResponse01Descriptor = $convert.base64Decode(
    'ChZTU1BIYW5kU2hha2VSZXNwb25zZTAxElUKBHR5cGUYASABKA4yHS5yZWNvdmVyZWQuc3NwLl'
    'NTUFJlcXVlc3RUeXBlOiJTU1BSZXF1ZXN0VHlwZV9IYW5kc2hha2VSZXNwb25zZTAxUgR0eXBl'
    'Eh4KCmFwa1ZlcnNpb24YAiABKAlSCmFwa1ZlcnNpb24SJgoOYXBrVmVyc2lvbk5hbWUYAyABKA'
    'lSDmFwa1ZlcnNpb25OYW1lEigKD2NsaWVudFRpbWVzdGFtcBgEIAEoBFIPY2xpZW50VGltZXN0'
    'YW1wEkYKHmNsaWVudFNtYXJ0U3luY1Byb3RvY29sVmVyc2lvbhgFIAEoCVIeY2xpZW50U21hcn'
    'RTeW5jUHJvdG9jb2xWZXJzaW9uEjIKFGNsaWVudE1pbkhvc3RWZXJzaW9uGAYgASgJUhRjbGll'
    'bnRNaW5Ib3N0VmVyc2lvbhIeCgpkZXZpY2VVdWlkGAcgASgJUgpkZXZpY2VVdWlkEh4KCmRldm'
    'ljZU5hbWUYCCABKAlSCmRldmljZU5hbWUSHAoJdXNiU2VyaWFsGAkgASgJUgl1c2JTZXJpYWwS'
    'LAoRaXNTbWFydGlzYW5EZXZpY2UYCiABKAhSEWlzU21hcnRpc2FuRGV2aWNlEjoKGGNsaWVudE'
    '1pbkhvc3RWZXJzaW9uQ29kZRgLIAEoBFIYY2xpZW50TWluSG9zdFZlcnNpb25Db2Rl');

@$core.Deprecated('Use sSPHandShakeRequest02Descriptor instead')
const SSPHandShakeRequest02$json = {
  '1': 'SSPHandShakeRequest02',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_HandshakeRequest02',
      '10': 'type'
    },
    {'1': 'hostUuid', '3': 2, '4': 1, '5': 9, '10': 'hostUuid'},
    {'1': 'derivedKey', '3': 3, '4': 1, '5': 12, '10': 'derivedKey'},
    {
      '1': 'trustType',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPHandShakeTrustType',
      '10': 'trustType'
    },
  ],
};

/// Descriptor for `SSPHandShakeRequest02`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPHandShakeRequest02Descriptor = $convert.base64Decode(
    'ChVTU1BIYW5kU2hha2VSZXF1ZXN0MDISVAoEdHlwZRgBIAEoDjIdLnJlY292ZXJlZC5zc3AuU1'
    'NQUmVxdWVzdFR5cGU6IVNTUFJlcXVlc3RUeXBlX0hhbmRzaGFrZVJlcXVlc3QwMlIEdHlwZRIa'
    'Cghob3N0VXVpZBgCIAEoCVIIaG9zdFV1aWQSHgoKZGVyaXZlZEtleRgDIAEoDFIKZGVyaXZlZE'
    'tleRJCCgl0cnVzdFR5cGUYBCABKA4yJC5yZWNvdmVyZWQuc3NwLlNTUEhhbmRTaGFrZVRydXN0'
    'VHlwZVIJdHJ1c3RUeXBl');

@$core.Deprecated('Use sSPHandShakeResponse02Descriptor instead')
const SSPHandShakeResponse02$json = {
  '1': 'SSPHandShakeResponse02',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_HandshakeResponse02',
      '10': 'type'
    },
    {
      '1': 'trustType',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPHandShakeTrustType',
      '10': 'trustType'
    },
    {'1': 'deviceUuid', '3': 3, '4': 1, '5': 9, '10': 'deviceUuid'},
    {'1': 'deviceName', '3': 4, '4': 1, '5': 9, '10': 'deviceName'},
    {'1': 'derivedKey', '3': 5, '4': 1, '5': 12, '10': 'derivedKey'},
    {'1': 'result', '3': 6, '4': 1, '5': 9, '10': 'result'},
  ],
};

/// Descriptor for `SSPHandShakeResponse02`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPHandShakeResponse02Descriptor = $convert.base64Decode(
    'ChZTU1BIYW5kU2hha2VSZXNwb25zZTAyElUKBHR5cGUYASABKA4yHS5yZWNvdmVyZWQuc3NwLl'
    'NTUFJlcXVlc3RUeXBlOiJTU1BSZXF1ZXN0VHlwZV9IYW5kc2hha2VSZXNwb25zZTAyUgR0eXBl'
    'EkIKCXRydXN0VHlwZRgCIAEoDjIkLnJlY292ZXJlZC5zc3AuU1NQSGFuZFNoYWtlVHJ1c3RUeX'
    'BlUgl0cnVzdFR5cGUSHgoKZGV2aWNlVXVpZBgDIAEoCVIKZGV2aWNlVXVpZBIeCgpkZXZpY2VO'
    'YW1lGAQgASgJUgpkZXZpY2VOYW1lEh4KCmRlcml2ZWRLZXkYBSABKAxSCmRlcml2ZWRLZXkSFg'
    'oGcmVzdWx0GAYgASgJUgZyZXN1bHQ=');

@$core.Deprecated('Use sSPHeartBeatRequestDescriptor instead')
const SSPHeartBeatRequest$json = {
  '1': 'SSPHeartBeatRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_HeartBeatRequest',
      '10': 'type'
    },
    {'1': 'hostTimestamp', '3': 2, '4': 1, '5': 4, '10': 'hostTimestamp'},
  ],
};

/// Descriptor for `SSPHeartBeatRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPHeartBeatRequestDescriptor = $convert.base64Decode(
    'ChNTU1BIZWFydEJlYXRSZXF1ZXN0ElIKBHR5cGUYASABKA4yHS5yZWNvdmVyZWQuc3NwLlNTUF'
    'JlcXVlc3RUeXBlOh9TU1BSZXF1ZXN0VHlwZV9IZWFydEJlYXRSZXF1ZXN0UgR0eXBlEiQKDWhv'
    'c3RUaW1lc3RhbXAYAiABKARSDWhvc3RUaW1lc3RhbXA=');

@$core.Deprecated('Use sSPHeartBeatResponseDescriptor instead')
const SSPHeartBeatResponse$json = {
  '1': 'SSPHeartBeatResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_HeartBeatRequest',
      '10': 'type'
    },
    {'1': 'hostTimestamp', '3': 2, '4': 1, '5': 4, '10': 'hostTimestamp'},
    {'1': 'clientTimestamp', '3': 3, '4': 1, '5': 4, '10': 'clientTimestamp'},
  ],
};

/// Descriptor for `SSPHeartBeatResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPHeartBeatResponseDescriptor = $convert.base64Decode(
    'ChRTU1BIZWFydEJlYXRSZXNwb25zZRJSCgR0eXBlGAEgASgOMh0ucmVjb3ZlcmVkLnNzcC5TU1'
    'BSZXF1ZXN0VHlwZTofU1NQUmVxdWVzdFR5cGVfSGVhcnRCZWF0UmVxdWVzdFIEdHlwZRIkCg1o'
    'b3N0VGltZXN0YW1wGAIgASgEUg1ob3N0VGltZXN0YW1wEigKD2NsaWVudFRpbWVzdGFtcBgDIA'
    'EoBFIPY2xpZW50VGltZXN0YW1w');

@$core.Deprecated('Use sSPQuitRequestDescriptor instead')
const SSPQuitRequest$json = {
  '1': 'SSPQuitRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_QuitRequest',
      '10': 'type'
    },
  ],
};

/// Descriptor for `SSPQuitRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPQuitRequestDescriptor = $convert.base64Decode(
    'Cg5TU1BRdWl0UmVxdWVzdBJNCgR0eXBlGAEgASgOMh0ucmVjb3ZlcmVkLnNzcC5TU1BSZXF1ZX'
    'N0VHlwZToaU1NQUmVxdWVzdFR5cGVfUXVpdFJlcXVlc3RSBHR5cGU=');

@$core.Deprecated('Use sSPGetDeviceInfoRequestDescriptor instead')
const SSPGetDeviceInfoRequest$json = {
  '1': 'SSPGetDeviceInfoRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetDeviceInfoRequest',
      '10': 'type'
    },
    {'1': 'hostTimestamp', '3': 2, '4': 1, '5': 4, '10': 'hostTimestamp'},
    {
      '1': 'hostSmartSyncProtocolVersion',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'hostSmartSyncProtocolVersion'
    },
    {
      '1': 'needDeviceInfoCallback',
      '3': 4,
      '4': 1,
      '5': 8,
      '10': 'needDeviceInfoCallback'
    },
    {
      '1': 'needPhotoLibraryCallback',
      '3': 5,
      '4': 1,
      '5': 8,
      '10': 'needPhotoLibraryCallback'
    },
    {
      '1': 'needAudioLibraryCallback',
      '3': 6,
      '4': 1,
      '5': 8,
      '10': 'needAudioLibraryCallback'
    },
    {
      '1': 'needVideoLibraryCallback',
      '3': 7,
      '4': 1,
      '5': 8,
      '10': 'needVideoLibraryCallback'
    },
    {'1': 'hostAppVersion', '3': 8, '4': 1, '5': 9, '10': 'hostAppVersion'},
    {
      '1': 'hostMinClientVersion',
      '3': 9,
      '4': 1,
      '5': 9,
      '10': 'hostMinClientVersion'
    },
    {'1': 'hostType', '3': 10, '4': 1, '5': 13, '7': '1', '10': 'hostType'},
    {
      '1': 'hostAppVersionCode',
      '3': 11,
      '4': 1,
      '5': 13,
      '10': 'hostAppVersionCode'
    },
  ],
};

/// Descriptor for `SSPGetDeviceInfoRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPGetDeviceInfoRequestDescriptor = $convert.base64Decode(
    'ChdTU1BHZXREZXZpY2VJbmZvUmVxdWVzdBJWCgR0eXBlGAEgASgOMh0ucmVjb3ZlcmVkLnNzcC'
    '5TU1BSZXF1ZXN0VHlwZTojU1NQUmVxdWVzdFR5cGVfR2V0RGV2aWNlSW5mb1JlcXVlc3RSBHR5'
    'cGUSJAoNaG9zdFRpbWVzdGFtcBgCIAEoBFINaG9zdFRpbWVzdGFtcBJCChxob3N0U21hcnRTeW'
    '5jUHJvdG9jb2xWZXJzaW9uGAMgASgJUhxob3N0U21hcnRTeW5jUHJvdG9jb2xWZXJzaW9uEjYK'
    'Fm5lZWREZXZpY2VJbmZvQ2FsbGJhY2sYBCABKAhSFm5lZWREZXZpY2VJbmZvQ2FsbGJhY2sSOg'
    'oYbmVlZFBob3RvTGlicmFyeUNhbGxiYWNrGAUgASgIUhhuZWVkUGhvdG9MaWJyYXJ5Q2FsbGJh'
    'Y2sSOgoYbmVlZEF1ZGlvTGlicmFyeUNhbGxiYWNrGAYgASgIUhhuZWVkQXVkaW9MaWJyYXJ5Q2'
    'FsbGJhY2sSOgoYbmVlZFZpZGVvTGlicmFyeUNhbGxiYWNrGAcgASgIUhhuZWVkVmlkZW9MaWJy'
    'YXJ5Q2FsbGJhY2sSJgoOaG9zdEFwcFZlcnNpb24YCCABKAlSDmhvc3RBcHBWZXJzaW9uEjIKFG'
    'hvc3RNaW5DbGllbnRWZXJzaW9uGAkgASgJUhRob3N0TWluQ2xpZW50VmVyc2lvbhIdCghob3N0'
    'VHlwZRgKIAEoDToBMVIIaG9zdFR5cGUSLgoSaG9zdEFwcFZlcnNpb25Db2RlGAsgASgNUhJob3'
    'N0QXBwVmVyc2lvbkNvZGU=');

@$core.Deprecated('Use sSPGetDeviceInfoResponseDescriptor instead')
const SSPGetDeviceInfoResponse$json = {
  '1': 'SSPGetDeviceInfoResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetDeviceInfoRequest',
      '10': 'type'
    },
    {'1': 'hostTimestamp', '3': 2, '4': 1, '5': 4, '10': 'hostTimestamp'},
    {
      '1': 'hostSmartSyncProtocolVersion',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'hostSmartSyncProtocolVersion'
    },
    {'1': 'apkVersion', '3': 4, '4': 1, '5': 9, '10': 'apkVersion'},
    {'1': 'clientTimestamp', '3': 5, '4': 1, '5': 4, '10': 'clientTimestamp'},
    {
      '1': 'clientSmartSyncProtocolVersion',
      '3': 6,
      '4': 1,
      '5': 9,
      '10': 'clientSmartSyncProtocolVersion'
    },
    {'1': 'hostAppVersion', '3': 7, '4': 1, '5': 9, '10': 'hostAppVersion'},
    {
      '1': 'hostMinClientVersion',
      '3': 8,
      '4': 1,
      '5': 9,
      '10': 'hostMinClientVersion'
    },
    {'1': 'phoneModel', '3': 9, '4': 1, '5': 9, '10': 'phoneModel'},
    {'1': 'phoneColor', '3': 10, '4': 1, '5': 9, '10': 'phoneColor'},
    {'1': 'diskSize', '3': 11, '4': 1, '5': 4, '10': 'diskSize'},
    {'1': 'ramSize', '3': 12, '4': 1, '5': 4, '10': 'ramSize'},
    {'1': 'batteryCapacity', '3': 13, '4': 1, '5': 1, '10': 'batteryCapacity'},
    {
      '1': 'batteryPercentage',
      '3': 14,
      '4': 1,
      '5': 13,
      '10': 'batteryPercentage'
    },
    {'1': 'phoneName', '3': 15, '4': 1, '5': 9, '10': 'phoneName'},
    {'1': 'usedDiskSize', '3': 16, '4': 1, '5': 4, '10': 'usedDiskSize'},
    {'1': 'rootPath', '3': 17, '4': 1, '5': 9, '10': 'rootPath'},
    {'1': 'productBrand', '3': 18, '4': 1, '5': 9, '10': 'productBrand'},
    {
      '1': 'productManufacturer',
      '3': 19,
      '4': 1,
      '5': 9,
      '10': 'productManufacturer'
    },
    {
      '1': 'smartisanVersion',
      '3': 20,
      '4': 1,
      '5': 9,
      '10': 'smartisanVersion'
    },
    {'1': 'phoneLocked', '3': 21, '4': 1, '5': 8, '10': 'phoneLocked'},
    {
      '1': 'clientMinHostVersion',
      '3': 22,
      '4': 1,
      '5': 9,
      '10': 'clientMinHostVersion'
    },
    {'1': 'apkVersionName', '3': 23, '4': 1, '5': 9, '10': 'apkVersionName'},
    {
      '1': 'externalStoragePath',
      '3': 24,
      '4': 1,
      '5': 9,
      '10': 'externalStoragePath'
    },
    {
      '1': 'externalStoragePermission',
      '3': 25,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPFileIOPermission',
      '10': 'externalStoragePermission'
    },
    {'1': 'extDiskSize', '3': 26, '4': 1, '5': 4, '10': 'extDiskSize'},
    {'1': 'extUsedDiskSize', '3': 27, '4': 1, '5': 4, '10': 'extUsedDiskSize'},
    {'1': 'phoneId', '3': 28, '4': 1, '5': 9, '10': 'phoneId'},
    {'1': 'audioSize', '3': 29, '4': 1, '5': 3, '10': 'audioSize'},
    {'1': 'picVideoSize', '3': 30, '4': 1, '5': 3, '10': 'picVideoSize'},
    {'1': 'downloadSize', '3': 31, '4': 1, '5': 3, '10': 'downloadSize'},
    {'1': 'otherSize', '3': 32, '4': 1, '5': 3, '10': 'otherSize'},
    {'1': 'appSize', '3': 33, '4': 1, '5': 3, '10': 'appSize'},
    {'1': 'cacheSize', '3': 34, '4': 1, '5': 3, '10': 'cacheSize'},
    {'1': 'debugBuildTime', '3': 35, '4': 1, '5': 9, '10': 'debugBuildTime'},
    {
      '1': 'clientMinHostVersionCode',
      '3': 36,
      '4': 1,
      '5': 3,
      '10': 'clientMinHostVersionCode'
    },
  ],
};

/// Descriptor for `SSPGetDeviceInfoResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPGetDeviceInfoResponseDescriptor = $convert.base64Decode(
    'ChhTU1BHZXREZXZpY2VJbmZvUmVzcG9uc2USVgoEdHlwZRgBIAEoDjIdLnJlY292ZXJlZC5zc3'
    'AuU1NQUmVxdWVzdFR5cGU6I1NTUFJlcXVlc3RUeXBlX0dldERldmljZUluZm9SZXF1ZXN0UgR0'
    'eXBlEiQKDWhvc3RUaW1lc3RhbXAYAiABKARSDWhvc3RUaW1lc3RhbXASQgocaG9zdFNtYXJ0U3'
    'luY1Byb3RvY29sVmVyc2lvbhgDIAEoCVIcaG9zdFNtYXJ0U3luY1Byb3RvY29sVmVyc2lvbhIe'
    'CgphcGtWZXJzaW9uGAQgASgJUgphcGtWZXJzaW9uEigKD2NsaWVudFRpbWVzdGFtcBgFIAEoBF'
    'IPY2xpZW50VGltZXN0YW1wEkYKHmNsaWVudFNtYXJ0U3luY1Byb3RvY29sVmVyc2lvbhgGIAEo'
    'CVIeY2xpZW50U21hcnRTeW5jUHJvdG9jb2xWZXJzaW9uEiYKDmhvc3RBcHBWZXJzaW9uGAcgAS'
    'gJUg5ob3N0QXBwVmVyc2lvbhIyChRob3N0TWluQ2xpZW50VmVyc2lvbhgIIAEoCVIUaG9zdE1p'
    'bkNsaWVudFZlcnNpb24SHgoKcGhvbmVNb2RlbBgJIAEoCVIKcGhvbmVNb2RlbBIeCgpwaG9uZU'
    'NvbG9yGAogASgJUgpwaG9uZUNvbG9yEhoKCGRpc2tTaXplGAsgASgEUghkaXNrU2l6ZRIYCgdy'
    'YW1TaXplGAwgASgEUgdyYW1TaXplEigKD2JhdHRlcnlDYXBhY2l0eRgNIAEoAVIPYmF0dGVyeU'
    'NhcGFjaXR5EiwKEWJhdHRlcnlQZXJjZW50YWdlGA4gASgNUhFiYXR0ZXJ5UGVyY2VudGFnZRIc'
    'CglwaG9uZU5hbWUYDyABKAlSCXBob25lTmFtZRIiCgx1c2VkRGlza1NpemUYECABKARSDHVzZW'
    'REaXNrU2l6ZRIaCghyb290UGF0aBgRIAEoCVIIcm9vdFBhdGgSIgoMcHJvZHVjdEJyYW5kGBIg'
    'ASgJUgxwcm9kdWN0QnJhbmQSMAoTcHJvZHVjdE1hbnVmYWN0dXJlchgTIAEoCVITcHJvZHVjdE'
    '1hbnVmYWN0dXJlchIqChBzbWFydGlzYW5WZXJzaW9uGBQgASgJUhBzbWFydGlzYW5WZXJzaW9u'
    'EiAKC3Bob25lTG9ja2VkGBUgASgIUgtwaG9uZUxvY2tlZBIyChRjbGllbnRNaW5Ib3N0VmVyc2'
    'lvbhgWIAEoCVIUY2xpZW50TWluSG9zdFZlcnNpb24SJgoOYXBrVmVyc2lvbk5hbWUYFyABKAlS'
    'DmFwa1ZlcnNpb25OYW1lEjAKE2V4dGVybmFsU3RvcmFnZVBhdGgYGCABKAlSE2V4dGVybmFsU3'
    'RvcmFnZVBhdGgSYAoZZXh0ZXJuYWxTdG9yYWdlUGVybWlzc2lvbhgZIAEoDjIiLnJlY292ZXJl'
    'ZC5zc3AuU1NQRmlsZUlPUGVybWlzc2lvblIZZXh0ZXJuYWxTdG9yYWdlUGVybWlzc2lvbhIgCg'
    'tleHREaXNrU2l6ZRgaIAEoBFILZXh0RGlza1NpemUSKAoPZXh0VXNlZERpc2tTaXplGBsgASgE'
    'Ug9leHRVc2VkRGlza1NpemUSGAoHcGhvbmVJZBgcIAEoCVIHcGhvbmVJZBIcCglhdWRpb1Npem'
    'UYHSABKANSCWF1ZGlvU2l6ZRIiCgxwaWNWaWRlb1NpemUYHiABKANSDHBpY1ZpZGVvU2l6ZRIi'
    'Cgxkb3dubG9hZFNpemUYHyABKANSDGRvd25sb2FkU2l6ZRIcCglvdGhlclNpemUYICABKANSCW'
    '90aGVyU2l6ZRIYCgdhcHBTaXplGCEgASgDUgdhcHBTaXplEhwKCWNhY2hlU2l6ZRgiIAEoA1IJ'
    'Y2FjaGVTaXplEiYKDmRlYnVnQnVpbGRUaW1lGCMgASgJUg5kZWJ1Z0J1aWxkVGltZRI6ChhjbG'
    'llbnRNaW5Ib3N0VmVyc2lvbkNvZGUYJCABKANSGGNsaWVudE1pbkhvc3RWZXJzaW9uQ29kZQ==');

@$core.Deprecated('Use sSPGetDirFilesRequestDescriptor instead')
const SSPGetDirFilesRequest$json = {
  '1': 'SSPGetDirFilesRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetDirFilesRequest',
      '10': 'type'
    },
    {
      '1': 'dir',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'dir'
    },
    {'1': 'maxdepth', '3': 3, '4': 1, '5': 13, '10': 'maxdepth'},
  ],
};

/// Descriptor for `SSPGetDirFilesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPGetDirFilesRequestDescriptor = $convert.base64Decode(
    'ChVTU1BHZXREaXJGaWxlc1JlcXVlc3QSVAoEdHlwZRgBIAEoDjIdLnJlY292ZXJlZC5zc3AuU1'
    'NQUmVxdWVzdFR5cGU6IVNTUFJlcXVlc3RUeXBlX0dldERpckZpbGVzUmVxdWVzdFIEdHlwZRIo'
    'CgNkaXIYAiABKAsyFi5yZWNvdmVyZWQuc3NwLlNTUEZpbGVSA2RpchIaCghtYXhkZXB0aBgDIA'
    'EoDVIIbWF4ZGVwdGg=');

@$core.Deprecated('Use sSPGetDirFilesResponseDescriptor instead')
const SSPGetDirFilesResponse$json = {
  '1': 'SSPGetDirFilesResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetDirFilesRequest',
      '10': 'type'
    },
    {
      '1': 'dir',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'dir'
    },
    {'1': 'maxdepth', '3': 3, '4': 1, '5': 13, '10': 'maxdepth'},
    {'1': 'timecost', '3': 4, '4': 1, '5': 13, '10': 'timecost'},
    {
      '1': 'fileArray',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'fileArray'
    },
  ],
};

/// Descriptor for `SSPGetDirFilesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPGetDirFilesResponseDescriptor = $convert.base64Decode(
    'ChZTU1BHZXREaXJGaWxlc1Jlc3BvbnNlElQKBHR5cGUYASABKA4yHS5yZWNvdmVyZWQuc3NwLl'
    'NTUFJlcXVlc3RUeXBlOiFTU1BSZXF1ZXN0VHlwZV9HZXREaXJGaWxlc1JlcXVlc3RSBHR5cGUS'
    'KAoDZGlyGAIgASgLMhYucmVjb3ZlcmVkLnNzcC5TU1BGaWxlUgNkaXISGgoIbWF4ZGVwdGgYAy'
    'ABKA1SCG1heGRlcHRoEhoKCHRpbWVjb3N0GAQgASgNUgh0aW1lY29zdBI0CglmaWxlQXJyYXkY'
    'BSADKAsyFi5yZWNvdmVyZWQuc3NwLlNTUEZpbGVSCWZpbGVBcnJheQ==');

@$core.Deprecated('Use sSPGetFileCountRequestDescriptor instead')
const SSPGetFileCountRequest$json = {
  '1': 'SSPGetFileCountRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetFileCountRequest',
      '10': 'type'
    },
    {
      '1': 'dir',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'dir'
    },
    {'1': 'maxdepth', '3': 3, '4': 1, '5': 13, '10': 'maxdepth'},
    {
      '1': 'exclusionPatternArray',
      '3': 4,
      '4': 3,
      '5': 9,
      '10': 'exclusionPatternArray'
    },
  ],
};

/// Descriptor for `SSPGetFileCountRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPGetFileCountRequestDescriptor = $convert.base64Decode(
    'ChZTU1BHZXRGaWxlQ291bnRSZXF1ZXN0ElUKBHR5cGUYASABKA4yHS5yZWNvdmVyZWQuc3NwLl'
    'NTUFJlcXVlc3RUeXBlOiJTU1BSZXF1ZXN0VHlwZV9HZXRGaWxlQ291bnRSZXF1ZXN0UgR0eXBl'
    'EigKA2RpchgCIAEoCzIWLnJlY292ZXJlZC5zc3AuU1NQRmlsZVIDZGlyEhoKCG1heGRlcHRoGA'
    'MgASgNUghtYXhkZXB0aBI0ChVleGNsdXNpb25QYXR0ZXJuQXJyYXkYBCADKAlSFWV4Y2x1c2lv'
    'blBhdHRlcm5BcnJheQ==');

@$core.Deprecated('Use sSPGetFileCountResponseDescriptor instead')
const SSPGetFileCountResponse$json = {
  '1': 'SSPGetFileCountResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetFileCountRequest',
      '10': 'type'
    },
    {
      '1': 'dir',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'dir'
    },
    {'1': 'maxdepth', '3': 3, '4': 1, '5': 13, '10': 'maxdepth'},
    {
      '1': 'exclusionPatternArray',
      '3': 4,
      '4': 3,
      '5': 9,
      '10': 'exclusionPatternArray'
    },
    {'1': 'count', '3': 5, '4': 1, '5': 4, '10': 'count'},
  ],
};

/// Descriptor for `SSPGetFileCountResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPGetFileCountResponseDescriptor = $convert.base64Decode(
    'ChdTU1BHZXRGaWxlQ291bnRSZXNwb25zZRJVCgR0eXBlGAEgASgOMh0ucmVjb3ZlcmVkLnNzcC'
    '5TU1BSZXF1ZXN0VHlwZToiU1NQUmVxdWVzdFR5cGVfR2V0RmlsZUNvdW50UmVxdWVzdFIEdHlw'
    'ZRIoCgNkaXIYAiABKAsyFi5yZWNvdmVyZWQuc3NwLlNTUEZpbGVSA2RpchIaCghtYXhkZXB0aB'
    'gDIAEoDVIIbWF4ZGVwdGgSNAoVZXhjbHVzaW9uUGF0dGVybkFycmF5GAQgAygJUhVleGNsdXNp'
    'b25QYXR0ZXJuQXJyYXkSFAoFY291bnQYBSABKARSBWNvdW50');

@$core.Deprecated('Use sSPFileExistRequestDescriptor instead')
const SSPFileExistRequest$json = {
  '1': 'SSPFileExistRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetFileExistRequest',
      '10': 'type'
    },
    {
      '1': 'file',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'file'
    },
  ],
};

/// Descriptor for `SSPFileExistRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPFileExistRequestDescriptor = $convert.base64Decode(
    'ChNTU1BGaWxlRXhpc3RSZXF1ZXN0ElUKBHR5cGUYASABKA4yHS5yZWNvdmVyZWQuc3NwLlNTUF'
    'JlcXVlc3RUeXBlOiJTU1BSZXF1ZXN0VHlwZV9HZXRGaWxlRXhpc3RSZXF1ZXN0UgR0eXBlEioK'
    'BGZpbGUYAiABKAsyFi5yZWNvdmVyZWQuc3NwLlNTUEZpbGVSBGZpbGU=');

@$core.Deprecated('Use sSPFileExistResponseDescriptor instead')
const SSPFileExistResponse$json = {
  '1': 'SSPFileExistResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetFileExistRequest',
      '10': 'type'
    },
    {
      '1': 'file',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'file'
    },
    {'1': 'exist', '3': 3, '4': 1, '5': 8, '10': 'exist'},
  ],
};

/// Descriptor for `SSPFileExistResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPFileExistResponseDescriptor = $convert.base64Decode(
    'ChRTU1BGaWxlRXhpc3RSZXNwb25zZRJVCgR0eXBlGAEgASgOMh0ucmVjb3ZlcmVkLnNzcC5TU1'
    'BSZXF1ZXN0VHlwZToiU1NQUmVxdWVzdFR5cGVfR2V0RmlsZUV4aXN0UmVxdWVzdFIEdHlwZRIq'
    'CgRmaWxlGAIgASgLMhYucmVjb3ZlcmVkLnNzcC5TU1BGaWxlUgRmaWxlEhQKBWV4aXN0GAMgAS'
    'gIUgVleGlzdA==');

@$core.Deprecated('Use sSPCreateFolderRequestDescriptor instead')
const SSPCreateFolderRequest$json = {
  '1': 'SSPCreateFolderRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetCreateFolderRequest',
      '10': 'type'
    },
    {
      '1': 'file',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'file'
    },
  ],
};

/// Descriptor for `SSPCreateFolderRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPCreateFolderRequestDescriptor = $convert.base64Decode(
    'ChZTU1BDcmVhdGVGb2xkZXJSZXF1ZXN0ElgKBHR5cGUYASABKA4yHS5yZWNvdmVyZWQuc3NwLl'
    'NTUFJlcXVlc3RUeXBlOiVTU1BSZXF1ZXN0VHlwZV9HZXRDcmVhdGVGb2xkZXJSZXF1ZXN0UgR0'
    'eXBlEioKBGZpbGUYAiABKAsyFi5yZWNvdmVyZWQuc3NwLlNTUEZpbGVSBGZpbGU=');

@$core.Deprecated('Use sSPCreateFolderResponseDescriptor instead')
const SSPCreateFolderResponse$json = {
  '1': 'SSPCreateFolderResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetCreateFolderRequest',
      '10': 'type'
    },
    {
      '1': 'file',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'file'
    },
    {'1': 'succeed', '3': 3, '4': 1, '5': 8, '10': 'succeed'},
    {
      '1': 'errorCode',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPFileIOError',
      '10': 'errorCode'
    },
    {'1': 'errorMessage', '3': 5, '4': 1, '5': 9, '10': 'errorMessage'},
  ],
};

/// Descriptor for `SSPCreateFolderResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPCreateFolderResponseDescriptor = $convert.base64Decode(
    'ChdTU1BDcmVhdGVGb2xkZXJSZXNwb25zZRJYCgR0eXBlGAEgASgOMh0ucmVjb3ZlcmVkLnNzcC'
    '5TU1BSZXF1ZXN0VHlwZTolU1NQUmVxdWVzdFR5cGVfR2V0Q3JlYXRlRm9sZGVyUmVxdWVzdFIE'
    'dHlwZRIqCgRmaWxlGAIgASgLMhYucmVjb3ZlcmVkLnNzcC5TU1BGaWxlUgRmaWxlEhgKB3N1Y2'
    'NlZWQYAyABKAhSB3N1Y2NlZWQSOwoJZXJyb3JDb2RlGAQgASgOMh0ucmVjb3ZlcmVkLnNzcC5T'
    'U1BGaWxlSU9FcnJvclIJZXJyb3JDb2RlEiIKDGVycm9yTWVzc2FnZRgFIAEoCVIMZXJyb3JNZX'
    'NzYWdl');

@$core.Deprecated('Use sSPRenameFileRequestDescriptor instead')
const SSPRenameFileRequest$json = {
  '1': 'SSPRenameFileRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetRenameFileRequest',
      '10': 'type'
    },
    {
      '1': 'sourceFile',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'sourceFile'
    },
    {
      '1': 'targetFile',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'targetFile'
    },
  ],
};

/// Descriptor for `SSPRenameFileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPRenameFileRequestDescriptor = $convert.base64Decode(
    'ChRTU1BSZW5hbWVGaWxlUmVxdWVzdBJWCgR0eXBlGAEgASgOMh0ucmVjb3ZlcmVkLnNzcC5TU1'
    'BSZXF1ZXN0VHlwZTojU1NQUmVxdWVzdFR5cGVfR2V0UmVuYW1lRmlsZVJlcXVlc3RSBHR5cGUS'
    'NgoKc291cmNlRmlsZRgCIAEoCzIWLnJlY292ZXJlZC5zc3AuU1NQRmlsZVIKc291cmNlRmlsZR'
    'I2Cgp0YXJnZXRGaWxlGAMgASgLMhYucmVjb3ZlcmVkLnNzcC5TU1BGaWxlUgp0YXJnZXRGaWxl');

@$core.Deprecated('Use sSPRenameFileResponseDescriptor instead')
const SSPRenameFileResponse$json = {
  '1': 'SSPRenameFileResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetRenameFileRequest',
      '10': 'type'
    },
    {
      '1': 'sourceFile',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'sourceFile'
    },
    {
      '1': 'targetFile',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'targetFile'
    },
    {'1': 'succeed', '3': 4, '4': 1, '5': 8, '10': 'succeed'},
    {
      '1': 'errorCode',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPFileIOError',
      '10': 'errorCode'
    },
    {'1': 'errorMessage', '3': 6, '4': 1, '5': 9, '10': 'errorMessage'},
  ],
};

/// Descriptor for `SSPRenameFileResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPRenameFileResponseDescriptor = $convert.base64Decode(
    'ChVTU1BSZW5hbWVGaWxlUmVzcG9uc2USVgoEdHlwZRgBIAEoDjIdLnJlY292ZXJlZC5zc3AuU1'
    'NQUmVxdWVzdFR5cGU6I1NTUFJlcXVlc3RUeXBlX0dldFJlbmFtZUZpbGVSZXF1ZXN0UgR0eXBl'
    'EjYKCnNvdXJjZUZpbGUYAiABKAsyFi5yZWNvdmVyZWQuc3NwLlNTUEZpbGVSCnNvdXJjZUZpbG'
    'USNgoKdGFyZ2V0RmlsZRgDIAEoCzIWLnJlY292ZXJlZC5zc3AuU1NQRmlsZVIKdGFyZ2V0Rmls'
    'ZRIYCgdzdWNjZWVkGAQgASgIUgdzdWNjZWVkEjsKCWVycm9yQ29kZRgFIAEoDjIdLnJlY292ZX'
    'JlZC5zc3AuU1NQRmlsZUlPRXJyb3JSCWVycm9yQ29kZRIiCgxlcnJvck1lc3NhZ2UYBiABKAlS'
    'DGVycm9yTWVzc2FnZQ==');

@$core.Deprecated('Use sSPDeleteFileRequestDescriptor instead')
const SSPDeleteFileRequest$json = {
  '1': 'SSPDeleteFileRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetDeleteFileRequest',
      '10': 'type'
    },
    {
      '1': 'file',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'file'
    },
    {'1': 'isSync', '3': 3, '4': 1, '5': 8, '10': 'isSync'},
    {'1': 'isTrash', '3': 4, '4': 1, '5': 8, '10': 'isTrash'},
  ],
};

/// Descriptor for `SSPDeleteFileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPDeleteFileRequestDescriptor = $convert.base64Decode(
    'ChRTU1BEZWxldGVGaWxlUmVxdWVzdBJWCgR0eXBlGAEgASgOMh0ucmVjb3ZlcmVkLnNzcC5TU1'
    'BSZXF1ZXN0VHlwZTojU1NQUmVxdWVzdFR5cGVfR2V0RGVsZXRlRmlsZVJlcXVlc3RSBHR5cGUS'
    'KgoEZmlsZRgCIAEoCzIWLnJlY292ZXJlZC5zc3AuU1NQRmlsZVIEZmlsZRIWCgZpc1N5bmMYAy'
    'ABKAhSBmlzU3luYxIYCgdpc1RyYXNoGAQgASgIUgdpc1RyYXNo');

@$core.Deprecated('Use sSPDeleteFileResponseDescriptor instead')
const SSPDeleteFileResponse$json = {
  '1': 'SSPDeleteFileResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetDeleteFileRequest',
      '10': 'type'
    },
    {
      '1': 'file',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'file'
    },
    {'1': 'succeed', '3': 4, '4': 1, '5': 8, '10': 'succeed'},
    {
      '1': 'errorCode',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPFileIOError',
      '10': 'errorCode'
    },
    {'1': 'errorMessage', '3': 6, '4': 1, '5': 9, '10': 'errorMessage'},
  ],
};

/// Descriptor for `SSPDeleteFileResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPDeleteFileResponseDescriptor = $convert.base64Decode(
    'ChVTU1BEZWxldGVGaWxlUmVzcG9uc2USVgoEdHlwZRgBIAEoDjIdLnJlY292ZXJlZC5zc3AuU1'
    'NQUmVxdWVzdFR5cGU6I1NTUFJlcXVlc3RUeXBlX0dldERlbGV0ZUZpbGVSZXF1ZXN0UgR0eXBl'
    'EioKBGZpbGUYAiABKAsyFi5yZWNvdmVyZWQuc3NwLlNTUEZpbGVSBGZpbGUSGAoHc3VjY2VlZB'
    'gEIAEoCFIHc3VjY2VlZBI7CgllcnJvckNvZGUYBSABKA4yHS5yZWNvdmVyZWQuc3NwLlNTUEZp'
    'bGVJT0Vycm9yUgllcnJvckNvZGUSIgoMZXJyb3JNZXNzYWdlGAYgASgJUgxlcnJvck1lc3NhZ2'
    'U=');

@$core.Deprecated('Use sSPMonitorFolderRequestDescriptor instead')
const SSPMonitorFolderRequest$json = {
  '1': 'SSPMonitorFolderRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_MonitorFolderRequest',
      '10': 'type'
    },
    {
      '1': 'file',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'file'
    },
    {'1': 'register_p', '3': 3, '4': 1, '5': 8, '10': 'registerP'},
  ],
};

/// Descriptor for `SSPMonitorFolderRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPMonitorFolderRequestDescriptor = $convert.base64Decode(
    'ChdTU1BNb25pdG9yRm9sZGVyUmVxdWVzdBJWCgR0eXBlGAEgASgOMh0ucmVjb3ZlcmVkLnNzcC'
    '5TU1BSZXF1ZXN0VHlwZTojU1NQUmVxdWVzdFR5cGVfTW9uaXRvckZvbGRlclJlcXVlc3RSBHR5'
    'cGUSKgoEZmlsZRgCIAEoCzIWLnJlY292ZXJlZC5zc3AuU1NQRmlsZVIEZmlsZRIdCgpyZWdpc3'
    'Rlcl9wGAMgASgIUglyZWdpc3RlclA=');

@$core.Deprecated('Use sSPMonitorFolderResponseHeaderDescriptor instead')
const SSPMonitorFolderResponseHeader$json = {
  '1': 'SSPMonitorFolderResponseHeader',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_MonitorFolderResponseHeader',
      '10': 'type'
    },
    {'1': 'succeed', '3': 2, '4': 1, '5': 8, '10': 'succeed'},
    {'1': 'errorMessage', '3': 3, '4': 1, '5': 9, '10': 'errorMessage'},
  ],
};

/// Descriptor for `SSPMonitorFolderResponseHeader`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPMonitorFolderResponseHeaderDescriptor =
    $convert.base64Decode(
        'Ch5TU1BNb25pdG9yRm9sZGVyUmVzcG9uc2VIZWFkZXISXQoEdHlwZRgBIAEoDjIdLnJlY292ZX'
        'JlZC5zc3AuU1NQUmVxdWVzdFR5cGU6KlNTUFJlcXVlc3RUeXBlX01vbml0b3JGb2xkZXJSZXNw'
        'b25zZUhlYWRlclIEdHlwZRIYCgdzdWNjZWVkGAIgASgIUgdzdWNjZWVkEiIKDGVycm9yTWVzc2'
        'FnZRgDIAEoCVIMZXJyb3JNZXNzYWdl');

@$core.Deprecated('Use sSPMonitorFolderResponseDescriptor instead')
const SSPMonitorFolderResponse$json = {
  '1': 'SSPMonitorFolderResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_MonitorFolderResponse',
      '10': 'type'
    },
    {
      '1': 'eventArray',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPFileEvent',
      '10': 'eventArray'
    },
  ],
};

/// Descriptor for `SSPMonitorFolderResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPMonitorFolderResponseDescriptor = $convert.base64Decode(
    'ChhTU1BNb25pdG9yRm9sZGVyUmVzcG9uc2USVwoEdHlwZRgBIAEoDjIdLnJlY292ZXJlZC5zc3'
    'AuU1NQUmVxdWVzdFR5cGU6JFNTUFJlcXVlc3RUeXBlX01vbml0b3JGb2xkZXJSZXNwb25zZVIE'
    'dHlwZRI7CgpldmVudEFycmF5GAIgAygLMhsucmVjb3ZlcmVkLnNzcC5TU1BGaWxlRXZlbnRSCm'
    'V2ZW50QXJyYXk=');

@$core.Deprecated('Use sSPDownloadFileRequestDescriptor instead')
const SSPDownloadFileRequest$json = {
  '1': 'SSPDownloadFileRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetDownloadFileRequest',
      '10': 'type'
    },
    {
      '1': 'file',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'file'
    },
    {
      '1': 'range',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPDataRange',
      '10': 'range'
    },
    {'1': 'needMd5', '3': 4, '4': 1, '5': 8, '10': 'needMd5'},
    {'1': 'gzip', '3': 5, '4': 1, '5': 8, '10': 'gzip'},
    {'1': 'isSync', '3': 6, '4': 1, '5': 8, '10': 'isSync'},
  ],
};

/// Descriptor for `SSPDownloadFileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPDownloadFileRequestDescriptor = $convert.base64Decode(
    'ChZTU1BEb3dubG9hZEZpbGVSZXF1ZXN0ElgKBHR5cGUYASABKA4yHS5yZWNvdmVyZWQuc3NwLl'
    'NTUFJlcXVlc3RUeXBlOiVTU1BSZXF1ZXN0VHlwZV9HZXREb3dubG9hZEZpbGVSZXF1ZXN0UgR0'
    'eXBlEioKBGZpbGUYAiABKAsyFi5yZWNvdmVyZWQuc3NwLlNTUEZpbGVSBGZpbGUSMQoFcmFuZ2'
    'UYAyABKAsyGy5yZWNvdmVyZWQuc3NwLlNTUERhdGFSYW5nZVIFcmFuZ2USGAoHbmVlZE1kNRgE'
    'IAEoCFIHbmVlZE1kNRISCgRnemlwGAUgASgIUgRnemlwEhYKBmlzU3luYxgGIAEoCFIGaXNTeW'
    '5j');

@$core.Deprecated('Use sSPDownloadFileResponseHeaderDescriptor instead')
const SSPDownloadFileResponseHeader$json = {
  '1': 'SSPDownloadFileResponseHeader',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetDownloadFileResponseHeader',
      '10': 'type'
    },
    {
      '1': 'file',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'file'
    },
    {
      '1': 'range',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPDataRange',
      '10': 'range'
    },
    {'1': 'needMd5', '3': 4, '4': 1, '5': 8, '10': 'needMd5'},
    {'1': 'dataMd5', '3': 5, '4': 1, '5': 9, '10': 'dataMd5'},
    {'1': 'ready', '3': 6, '4': 1, '5': 8, '10': 'ready'},
    {
      '1': 'errorCode',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPFileIOError',
      '10': 'errorCode'
    },
  ],
};

/// Descriptor for `SSPDownloadFileResponseHeader`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPDownloadFileResponseHeaderDescriptor = $convert.base64Decode(
    'Ch1TU1BEb3dubG9hZEZpbGVSZXNwb25zZUhlYWRlchJfCgR0eXBlGAEgASgOMh0ucmVjb3Zlcm'
    'VkLnNzcC5TU1BSZXF1ZXN0VHlwZTosU1NQUmVxdWVzdFR5cGVfR2V0RG93bmxvYWRGaWxlUmVz'
    'cG9uc2VIZWFkZXJSBHR5cGUSKgoEZmlsZRgCIAEoCzIWLnJlY292ZXJlZC5zc3AuU1NQRmlsZV'
    'IEZmlsZRIxCgVyYW5nZRgDIAEoCzIbLnJlY292ZXJlZC5zc3AuU1NQRGF0YVJhbmdlUgVyYW5n'
    'ZRIYCgduZWVkTWQ1GAQgASgIUgduZWVkTWQ1EhgKB2RhdGFNZDUYBSABKAlSB2RhdGFNZDUSFA'
    'oFcmVhZHkYBiABKAhSBXJlYWR5EjsKCWVycm9yQ29kZRgHIAEoDjIdLnJlY292ZXJlZC5zc3Au'
    'U1NQRmlsZUlPRXJyb3JSCWVycm9yQ29kZQ==');

@$core.Deprecated('Use sSPUploadFileRequestDescriptor instead')
const SSPUploadFileRequest$json = {
  '1': 'SSPUploadFileRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetUploadFileRequestHeader',
      '10': 'type'
    },
    {
      '1': 'file',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'file'
    },
    {'1': 'dataMd5', '3': 3, '4': 1, '5': 9, '10': 'dataMd5'},
    {'1': 'gzip', '3': 4, '4': 1, '5': 8, '10': 'gzip'},
    {'1': 'isSync', '3': 5, '4': 1, '5': 8, '10': 'isSync'},
  ],
};

/// Descriptor for `SSPUploadFileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPUploadFileRequestDescriptor = $convert.base64Decode(
    'ChRTU1BVcGxvYWRGaWxlUmVxdWVzdBJcCgR0eXBlGAEgASgOMh0ucmVjb3ZlcmVkLnNzcC5TU1'
    'BSZXF1ZXN0VHlwZTopU1NQUmVxdWVzdFR5cGVfR2V0VXBsb2FkRmlsZVJlcXVlc3RIZWFkZXJS'
    'BHR5cGUSKgoEZmlsZRgCIAEoCzIWLnJlY292ZXJlZC5zc3AuU1NQRmlsZVIEZmlsZRIYCgdkYX'
    'RhTWQ1GAMgASgJUgdkYXRhTWQ1EhIKBGd6aXAYBCABKAhSBGd6aXASFgoGaXNTeW5jGAUgASgI'
    'UgZpc1N5bmM=');

@$core.Deprecated('Use sSPUploadFileResponseHeaderDescriptor instead')
const SSPUploadFileResponseHeader$json = {
  '1': 'SSPUploadFileResponseHeader',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetUploadFileResponse',
      '10': 'type'
    },
    {
      '1': 'file',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'file'
    },
    {'1': 'ready', '3': 3, '4': 1, '5': 8, '10': 'ready'},
    {
      '1': 'errorCode',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPFileIOError',
      '10': 'errorCode'
    },
  ],
};

/// Descriptor for `SSPUploadFileResponseHeader`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPUploadFileResponseHeaderDescriptor = $convert.base64Decode(
    'ChtTU1BVcGxvYWRGaWxlUmVzcG9uc2VIZWFkZXISVwoEdHlwZRgBIAEoDjIdLnJlY292ZXJlZC'
    '5zc3AuU1NQUmVxdWVzdFR5cGU6JFNTUFJlcXVlc3RUeXBlX0dldFVwbG9hZEZpbGVSZXNwb25z'
    'ZVIEdHlwZRIqCgRmaWxlGAIgASgLMhYucmVjb3ZlcmVkLnNzcC5TU1BGaWxlUgRmaWxlEhQKBX'
    'JlYWR5GAMgASgIUgVyZWFkeRI7CgllcnJvckNvZGUYBCABKA4yHS5yZWNvdmVyZWQuc3NwLlNT'
    'UEZpbGVJT0Vycm9yUgllcnJvckNvZGU=');

@$core.Deprecated('Use sSPUploadFileResponseDescriptor instead')
const SSPUploadFileResponse$json = {
  '1': 'SSPUploadFileResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetUploadFileResponse',
      '10': 'type'
    },
    {
      '1': 'file',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'file'
    },
    {'1': 'canceled', '3': 3, '4': 1, '5': 8, '10': 'canceled'},
    {'1': 'succeed', '3': 4, '4': 1, '5': 8, '10': 'succeed'},
    {
      '1': 'errorCode',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPFileIOError',
      '10': 'errorCode'
    },
  ],
};

/// Descriptor for `SSPUploadFileResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPUploadFileResponseDescriptor = $convert.base64Decode(
    'ChVTU1BVcGxvYWRGaWxlUmVzcG9uc2USVwoEdHlwZRgBIAEoDjIdLnJlY292ZXJlZC5zc3AuU1'
    'NQUmVxdWVzdFR5cGU6JFNTUFJlcXVlc3RUeXBlX0dldFVwbG9hZEZpbGVSZXNwb25zZVIEdHlw'
    'ZRIqCgRmaWxlGAIgASgLMhYucmVjb3ZlcmVkLnNzcC5TU1BGaWxlUgRmaWxlEhoKCGNhbmNlbG'
    'VkGAMgASgIUghjYW5jZWxlZBIYCgdzdWNjZWVkGAQgASgIUgdzdWNjZWVkEjsKCWVycm9yQ29k'
    'ZRgFIAEoDjIdLnJlY292ZXJlZC5zc3AuU1NQRmlsZUlPRXJyb3JSCWVycm9yQ29kZQ==');

@$core.Deprecated('Use sSPGetThumbnailRequestDescriptor instead')
const SSPGetThumbnailRequest$json = {
  '1': 'SSPGetThumbnailRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetThumbnailRequest',
      '10': 'type'
    },
    {
      '1': 'imageArray',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPImageFile',
      '10': 'imageArray'
    },
    {
      '1': 'videoArray',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPVideoFile',
      '10': 'videoArray'
    },
    {
      '1': 'audioAlbumArray',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPAudioAlbum',
      '10': 'audioAlbumArray'
    },
  ],
};

/// Descriptor for `SSPGetThumbnailRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPGetThumbnailRequestDescriptor = $convert.base64Decode(
    'ChZTU1BHZXRUaHVtYm5haWxSZXF1ZXN0ElUKBHR5cGUYASABKA4yHS5yZWNvdmVyZWQuc3NwLl'
    'NTUFJlcXVlc3RUeXBlOiJTU1BSZXF1ZXN0VHlwZV9HZXRUaHVtYm5haWxSZXF1ZXN0UgR0eXBl'
    'EjsKCmltYWdlQXJyYXkYAiADKAsyGy5yZWNvdmVyZWQuc3NwLlNTUEltYWdlRmlsZVIKaW1hZ2'
    'VBcnJheRI7Cgp2aWRlb0FycmF5GAMgAygLMhsucmVjb3ZlcmVkLnNzcC5TU1BWaWRlb0ZpbGVS'
    'CnZpZGVvQXJyYXkSRgoPYXVkaW9BbGJ1bUFycmF5GAQgAygLMhwucmVjb3ZlcmVkLnNzcC5TU1'
    'BBdWRpb0FsYnVtUg9hdWRpb0FsYnVtQXJyYXk=');

@$core.Deprecated('Use sSPGetThumbnailResponseDescriptor instead')
const SSPGetThumbnailResponse$json = {
  '1': 'SSPGetThumbnailResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetThumbnailRequest',
      '10': 'type'
    },
    {
      '1': 'imageArray',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPImageFile',
      '10': 'imageArray'
    },
    {
      '1': 'videoArray',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPVideoFile',
      '10': 'videoArray'
    },
    {
      '1': 'audioAlbumArray',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPAudioAlbum',
      '10': 'audioAlbumArray'
    },
  ],
};

/// Descriptor for `SSPGetThumbnailResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPGetThumbnailResponseDescriptor = $convert.base64Decode(
    'ChdTU1BHZXRUaHVtYm5haWxSZXNwb25zZRJVCgR0eXBlGAEgASgOMh0ucmVjb3ZlcmVkLnNzcC'
    '5TU1BSZXF1ZXN0VHlwZToiU1NQUmVxdWVzdFR5cGVfR2V0VGh1bWJuYWlsUmVxdWVzdFIEdHlw'
    'ZRI7CgppbWFnZUFycmF5GAIgAygLMhsucmVjb3ZlcmVkLnNzcC5TU1BJbWFnZUZpbGVSCmltYW'
    'dlQXJyYXkSOwoKdmlkZW9BcnJheRgDIAMoCzIbLnJlY292ZXJlZC5zc3AuU1NQVmlkZW9GaWxl'
    'Ugp2aWRlb0FycmF5EkYKD2F1ZGlvQWxidW1BcnJheRgEIAMoCzIcLnJlY292ZXJlZC5zc3AuU1'
    'NQQXVkaW9BbGJ1bVIPYXVkaW9BbGJ1bUFycmF5');

@$core.Deprecated('Use sSPGetPhotoLibraryRequestDescriptor instead')
const SSPGetPhotoLibraryRequest$json = {
  '1': 'SSPGetPhotoLibraryRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetPhotoLibRequest',
      '10': 'type'
    },
  ],
};

/// Descriptor for `SSPGetPhotoLibraryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPGetPhotoLibraryRequestDescriptor = $convert.base64Decode(
    'ChlTU1BHZXRQaG90b0xpYnJhcnlSZXF1ZXN0ElQKBHR5cGUYASABKA4yHS5yZWNvdmVyZWQuc3'
    'NwLlNTUFJlcXVlc3RUeXBlOiFTU1BSZXF1ZXN0VHlwZV9HZXRQaG90b0xpYlJlcXVlc3RSBHR5'
    'cGU=');

@$core.Deprecated('Use sSPGetPhotoLibraryResponseDescriptor instead')
const SSPGetPhotoLibraryResponse$json = {
  '1': 'SSPGetPhotoLibraryResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetPhotoLibRequest',
      '10': 'type'
    },
    {
      '1': 'imageArray',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPImageFile',
      '10': 'imageArray'
    },
    {
      '1': 'albumArray',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPImageAlbum',
      '10': 'albumArray'
    },
    {'1': 'cameraAlbumId', '3': 4, '4': 1, '5': 4, '10': 'cameraAlbumId'},
  ],
};

/// Descriptor for `SSPGetPhotoLibraryResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPGetPhotoLibraryResponseDescriptor = $convert.base64Decode(
    'ChpTU1BHZXRQaG90b0xpYnJhcnlSZXNwb25zZRJUCgR0eXBlGAEgASgOMh0ucmVjb3ZlcmVkLn'
    'NzcC5TU1BSZXF1ZXN0VHlwZTohU1NQUmVxdWVzdFR5cGVfR2V0UGhvdG9MaWJSZXF1ZXN0UgR0'
    'eXBlEjsKCmltYWdlQXJyYXkYAiADKAsyGy5yZWNvdmVyZWQuc3NwLlNTUEltYWdlRmlsZVIKaW'
    '1hZ2VBcnJheRI8CgphbGJ1bUFycmF5GAMgAygLMhwucmVjb3ZlcmVkLnNzcC5TU1BJbWFnZUFs'
    'YnVtUgphbGJ1bUFycmF5EiQKDWNhbWVyYUFsYnVtSWQYBCABKARSDWNhbWVyYUFsYnVtSWQ=');

@$core.Deprecated('Use sSPGetVideoLibraryRequestDescriptor instead')
const SSPGetVideoLibraryRequest$json = {
  '1': 'SSPGetVideoLibraryRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetVideoLibRequest',
      '10': 'type'
    },
  ],
};

/// Descriptor for `SSPGetVideoLibraryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPGetVideoLibraryRequestDescriptor = $convert.base64Decode(
    'ChlTU1BHZXRWaWRlb0xpYnJhcnlSZXF1ZXN0ElQKBHR5cGUYASABKA4yHS5yZWNvdmVyZWQuc3'
    'NwLlNTUFJlcXVlc3RUeXBlOiFTU1BSZXF1ZXN0VHlwZV9HZXRWaWRlb0xpYlJlcXVlc3RSBHR5'
    'cGU=');

@$core.Deprecated('Use sSPGetVideoLibraryResponseDescriptor instead')
const SSPGetVideoLibraryResponse$json = {
  '1': 'SSPGetVideoLibraryResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetVideoLibRequest',
      '10': 'type'
    },
    {
      '1': 'videoArray',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPVideoFile',
      '10': 'videoArray'
    },
    {
      '1': 'albumArray',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPVideoAlbum',
      '10': 'albumArray'
    },
  ],
};

/// Descriptor for `SSPGetVideoLibraryResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPGetVideoLibraryResponseDescriptor = $convert.base64Decode(
    'ChpTU1BHZXRWaWRlb0xpYnJhcnlSZXNwb25zZRJUCgR0eXBlGAEgASgOMh0ucmVjb3ZlcmVkLn'
    'NzcC5TU1BSZXF1ZXN0VHlwZTohU1NQUmVxdWVzdFR5cGVfR2V0VmlkZW9MaWJSZXF1ZXN0UgR0'
    'eXBlEjsKCnZpZGVvQXJyYXkYAiADKAsyGy5yZWNvdmVyZWQuc3NwLlNTUFZpZGVvRmlsZVIKdm'
    'lkZW9BcnJheRI8CgphbGJ1bUFycmF5GAMgAygLMhwucmVjb3ZlcmVkLnNzcC5TU1BWaWRlb0Fs'
    'YnVtUgphbGJ1bUFycmF5');

@$core.Deprecated('Use sSPGetAudioLibraryRequestDescriptor instead')
const SSPGetAudioLibraryRequest$json = {
  '1': 'SSPGetAudioLibraryRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetAudioLibRequest',
      '10': 'type'
    },
  ],
};

/// Descriptor for `SSPGetAudioLibraryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPGetAudioLibraryRequestDescriptor = $convert.base64Decode(
    'ChlTU1BHZXRBdWRpb0xpYnJhcnlSZXF1ZXN0ElQKBHR5cGUYASABKA4yHS5yZWNvdmVyZWQuc3'
    'NwLlNTUFJlcXVlc3RUeXBlOiFTU1BSZXF1ZXN0VHlwZV9HZXRBdWRpb0xpYlJlcXVlc3RSBHR5'
    'cGU=');

@$core.Deprecated('Use sSPGetAudioLibraryResponseDescriptor instead')
const SSPGetAudioLibraryResponse$json = {
  '1': 'SSPGetAudioLibraryResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetAudioLibRequest',
      '10': 'type'
    },
    {
      '1': 'audioArray',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPAudioFile',
      '10': 'audioArray'
    },
    {
      '1': 'albumArray',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPAudioAlbum',
      '10': 'albumArray'
    },
  ],
};

/// Descriptor for `SSPGetAudioLibraryResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPGetAudioLibraryResponseDescriptor = $convert.base64Decode(
    'ChpTU1BHZXRBdWRpb0xpYnJhcnlSZXNwb25zZRJUCgR0eXBlGAEgASgOMh0ucmVjb3ZlcmVkLn'
    'NzcC5TU1BSZXF1ZXN0VHlwZTohU1NQUmVxdWVzdFR5cGVfR2V0QXVkaW9MaWJSZXF1ZXN0UgR0'
    'eXBlEjsKCmF1ZGlvQXJyYXkYAiADKAsyGy5yZWNvdmVyZWQuc3NwLlNTUEF1ZGlvRmlsZVIKYX'
    'VkaW9BcnJheRI8CgphbGJ1bUFycmF5GAMgAygLMhwucmVjb3ZlcmVkLnNzcC5TU1BBdWRpb0Fs'
    'YnVtUgphbGJ1bUFycmF5');

@$core.Deprecated('Use sSPPhotoLibraryChangeDescriptor instead')
const SSPPhotoLibraryChange$json = {
  '1': 'SSPPhotoLibraryChange',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_PhotoLibChange',
      '10': 'type'
    },
    {
      '1': 'addedImageArray',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPImageFile',
      '10': 'addedImageArray'
    },
    {
      '1': 'deletedImageArray',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPImageFile',
      '10': 'deletedImageArray'
    },
  ],
};

/// Descriptor for `SSPPhotoLibraryChange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPPhotoLibraryChangeDescriptor = $convert.base64Decode(
    'ChVTU1BQaG90b0xpYnJhcnlDaGFuZ2USUAoEdHlwZRgBIAEoDjIdLnJlY292ZXJlZC5zc3AuU1'
    'NQUmVxdWVzdFR5cGU6HVNTUFJlcXVlc3RUeXBlX1Bob3RvTGliQ2hhbmdlUgR0eXBlEkUKD2Fk'
    'ZGVkSW1hZ2VBcnJheRgCIAMoCzIbLnJlY292ZXJlZC5zc3AuU1NQSW1hZ2VGaWxlUg9hZGRlZE'
    'ltYWdlQXJyYXkSSQoRZGVsZXRlZEltYWdlQXJyYXkYAyADKAsyGy5yZWNvdmVyZWQuc3NwLlNT'
    'UEltYWdlRmlsZVIRZGVsZXRlZEltYWdlQXJyYXk=');

@$core.Deprecated('Use sSPVideoLibraryChangeDescriptor instead')
const SSPVideoLibraryChange$json = {
  '1': 'SSPVideoLibraryChange',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_VideoLibChange',
      '10': 'type'
    },
    {
      '1': 'addedVideoArray',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPVideoFile',
      '10': 'addedVideoArray'
    },
    {
      '1': 'deletedVideoArray',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPVideoFile',
      '10': 'deletedVideoArray'
    },
    {
      '1': 'updatedVideoArray',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPVideoFile',
      '10': 'updatedVideoArray'
    },
  ],
};

/// Descriptor for `SSPVideoLibraryChange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPVideoLibraryChangeDescriptor = $convert.base64Decode(
    'ChVTU1BWaWRlb0xpYnJhcnlDaGFuZ2USUAoEdHlwZRgBIAEoDjIdLnJlY292ZXJlZC5zc3AuU1'
    'NQUmVxdWVzdFR5cGU6HVNTUFJlcXVlc3RUeXBlX1ZpZGVvTGliQ2hhbmdlUgR0eXBlEkUKD2Fk'
    'ZGVkVmlkZW9BcnJheRgCIAMoCzIbLnJlY292ZXJlZC5zc3AuU1NQVmlkZW9GaWxlUg9hZGRlZF'
    'ZpZGVvQXJyYXkSSQoRZGVsZXRlZFZpZGVvQXJyYXkYAyADKAsyGy5yZWNvdmVyZWQuc3NwLlNT'
    'UFZpZGVvRmlsZVIRZGVsZXRlZFZpZGVvQXJyYXkSSQoRdXBkYXRlZFZpZGVvQXJyYXkYBCADKA'
    'syGy5yZWNvdmVyZWQuc3NwLlNTUFZpZGVvRmlsZVIRdXBkYXRlZFZpZGVvQXJyYXk=');

@$core.Deprecated('Use sSPAudioLibraryChangeDescriptor instead')
const SSPAudioLibraryChange$json = {
  '1': 'SSPAudioLibraryChange',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_AudioLibChange',
      '10': 'type'
    },
    {
      '1': 'addedAudioArray',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPAudioFile',
      '10': 'addedAudioArray'
    },
    {
      '1': 'deletedAudioArray',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPAudioFile',
      '10': 'deletedAudioArray'
    },
    {
      '1': 'addedAlbumArray',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPAudioAlbum',
      '10': 'addedAlbumArray'
    },
  ],
};

/// Descriptor for `SSPAudioLibraryChange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPAudioLibraryChangeDescriptor = $convert.base64Decode(
    'ChVTU1BBdWRpb0xpYnJhcnlDaGFuZ2USUAoEdHlwZRgBIAEoDjIdLnJlY292ZXJlZC5zc3AuU1'
    'NQUmVxdWVzdFR5cGU6HVNTUFJlcXVlc3RUeXBlX0F1ZGlvTGliQ2hhbmdlUgR0eXBlEkUKD2Fk'
    'ZGVkQXVkaW9BcnJheRgCIAMoCzIbLnJlY292ZXJlZC5zc3AuU1NQQXVkaW9GaWxlUg9hZGRlZE'
    'F1ZGlvQXJyYXkSSQoRZGVsZXRlZEF1ZGlvQXJyYXkYAyADKAsyGy5yZWNvdmVyZWQuc3NwLlNT'
    'UEF1ZGlvRmlsZVIRZGVsZXRlZEF1ZGlvQXJyYXkSRgoPYWRkZWRBbGJ1bUFycmF5GAQgAygLMh'
    'wucmVjb3ZlcmVkLnNzcC5TU1BBdWRpb0FsYnVtUg9hZGRlZEFsYnVtQXJyYXk=');

@$core.Deprecated('Use sSPClipboardDescriptor instead')
const SSPClipboard$json = {
  '1': 'SSPClipboard',
  '2': [
    {'1': 'content', '3': 1, '4': 1, '5': 12, '10': 'content'},
    {'1': 'mstimestamp', '3': 2, '4': 1, '5': 3, '10': 'mstimestamp'},
  ],
};

/// Descriptor for `SSPClipboard`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPClipboardDescriptor = $convert.base64Decode(
    'CgxTU1BDbGlwYm9hcmQSGAoHY29udGVudBgBIAEoDFIHY29udGVudBIgCgttc3RpbWVzdGFtcB'
    'gCIAEoA1ILbXN0aW1lc3RhbXA=');

@$core.Deprecated('Use sSPGetClipboardRequestDescriptor instead')
const SSPGetClipboardRequest$json = {
  '1': 'SSPGetClipboardRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetClipboardRequest',
      '10': 'type'
    },
  ],
};

/// Descriptor for `SSPGetClipboardRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPGetClipboardRequestDescriptor = $convert.base64Decode(
    'ChZTU1BHZXRDbGlwYm9hcmRSZXF1ZXN0ElUKBHR5cGUYASABKA4yHS5yZWNvdmVyZWQuc3NwLl'
    'NTUFJlcXVlc3RUeXBlOiJTU1BSZXF1ZXN0VHlwZV9HZXRDbGlwYm9hcmRSZXF1ZXN0UgR0eXBl');

@$core.Deprecated('Use sSPGetClipboardResponseDescriptor instead')
const SSPGetClipboardResponse$json = {
  '1': 'SSPGetClipboardResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_GetClipboardRequest',
      '10': 'type'
    },
    {
      '1': 'clipboardArray',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPClipboard',
      '10': 'clipboardArray'
    },
  ],
};

/// Descriptor for `SSPGetClipboardResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPGetClipboardResponseDescriptor = $convert.base64Decode(
    'ChdTU1BHZXRDbGlwYm9hcmRSZXNwb25zZRJVCgR0eXBlGAEgASgOMh0ucmVjb3ZlcmVkLnNzcC'
    '5TU1BSZXF1ZXN0VHlwZToiU1NQUmVxdWVzdFR5cGVfR2V0Q2xpcGJvYXJkUmVxdWVzdFIEdHlw'
    'ZRJDCg5jbGlwYm9hcmRBcnJheRgCIAMoCzIbLnJlY292ZXJlZC5zc3AuU1NQQ2xpcGJvYXJkUg'
    '5jbGlwYm9hcmRBcnJheQ==');

@$core.Deprecated('Use sSPPostClipboardRequestDescriptor instead')
const SSPPostClipboardRequest$json = {
  '1': 'SSPPostClipboardRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_PostClipboardRequest',
      '10': 'type'
    },
    {
      '1': 'clipboard',
      '3': 2,
      '4': 2,
      '5': 11,
      '6': '.recovered.ssp.SSPClipboard',
      '10': 'clipboard'
    },
  ],
};

/// Descriptor for `SSPPostClipboardRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPPostClipboardRequestDescriptor = $convert.base64Decode(
    'ChdTU1BQb3N0Q2xpcGJvYXJkUmVxdWVzdBJWCgR0eXBlGAEgASgOMh0ucmVjb3ZlcmVkLnNzcC'
    '5TU1BSZXF1ZXN0VHlwZTojU1NQUmVxdWVzdFR5cGVfUG9zdENsaXBib2FyZFJlcXVlc3RSBHR5'
    'cGUSOQoJY2xpcGJvYXJkGAIgAigLMhsucmVjb3ZlcmVkLnNzcC5TU1BDbGlwYm9hcmRSCWNsaX'
    'Bib2FyZA==');

@$core.Deprecated('Use sSPPostClipboardResponseDescriptor instead')
const SSPPostClipboardResponse$json = {
  '1': 'SSPPostClipboardResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_PostClipboardRequest',
      '10': 'type'
    },
    {'1': 'succeed', '3': 2, '4': 1, '5': 8, '10': 'succeed'},
  ],
};

/// Descriptor for `SSPPostClipboardResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPPostClipboardResponseDescriptor = $convert.base64Decode(
    'ChhTU1BQb3N0Q2xpcGJvYXJkUmVzcG9uc2USVgoEdHlwZRgBIAEoDjIdLnJlY292ZXJlZC5zc3'
    'AuU1NQUmVxdWVzdFR5cGU6I1NTUFJlcXVlc3RUeXBlX1Bvc3RDbGlwYm9hcmRSZXF1ZXN0UgR0'
    'eXBlEhgKB3N1Y2NlZWQYAiABKAhSB3N1Y2NlZWQ=');

@$core.Deprecated('Use sSPClearClipboardRequestDescriptor instead')
const SSPClearClipboardRequest$json = {
  '1': 'SSPClearClipboardRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_ClearClipboardRequest',
      '10': 'type'
    },
  ],
};

/// Descriptor for `SSPClearClipboardRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPClearClipboardRequestDescriptor = $convert.base64Decode(
    'ChhTU1BDbGVhckNsaXBib2FyZFJlcXVlc3QSVwoEdHlwZRgBIAEoDjIdLnJlY292ZXJlZC5zc3'
    'AuU1NQUmVxdWVzdFR5cGU6JFNTUFJlcXVlc3RUeXBlX0NsZWFyQ2xpcGJvYXJkUmVxdWVzdFIE'
    'dHlwZQ==');

@$core.Deprecated('Use sSPClearClipboardResponseDescriptor instead')
const SSPClearClipboardResponse$json = {
  '1': 'SSPClearClipboardResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_ClearClipboardRequest',
      '10': 'type'
    },
    {'1': 'succeed', '3': 2, '4': 1, '5': 8, '10': 'succeed'},
  ],
};

/// Descriptor for `SSPClearClipboardResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPClearClipboardResponseDescriptor = $convert.base64Decode(
    'ChlTU1BDbGVhckNsaXBib2FyZFJlc3BvbnNlElcKBHR5cGUYASABKA4yHS5yZWNvdmVyZWQuc3'
    'NwLlNTUFJlcXVlc3RUeXBlOiRTU1BSZXF1ZXN0VHlwZV9DbGVhckNsaXBib2FyZFJlcXVlc3RS'
    'BHR5cGUSGAoHc3VjY2VlZBgCIAEoCFIHc3VjY2VlZA==');

@$core.Deprecated('Use sSPDeleteClipboardRequestDescriptor instead')
const SSPDeleteClipboardRequest$json = {
  '1': 'SSPDeleteClipboardRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_DeleteClipboardRequest',
      '10': 'type'
    },
    {
      '1': 'clipboard',
      '3': 2,
      '4': 2,
      '5': 11,
      '6': '.recovered.ssp.SSPClipboard',
      '10': 'clipboard'
    },
  ],
};

/// Descriptor for `SSPDeleteClipboardRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPDeleteClipboardRequestDescriptor = $convert.base64Decode(
    'ChlTU1BEZWxldGVDbGlwYm9hcmRSZXF1ZXN0ElgKBHR5cGUYASABKA4yHS5yZWNvdmVyZWQuc3'
    'NwLlNTUFJlcXVlc3RUeXBlOiVTU1BSZXF1ZXN0VHlwZV9EZWxldGVDbGlwYm9hcmRSZXF1ZXN0'
    'UgR0eXBlEjkKCWNsaXBib2FyZBgCIAIoCzIbLnJlY292ZXJlZC5zc3AuU1NQQ2xpcGJvYXJkUg'
    'ljbGlwYm9hcmQ=');

@$core.Deprecated('Use sSPDeleteClipboardResponseDescriptor instead')
const SSPDeleteClipboardResponse$json = {
  '1': 'SSPDeleteClipboardResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_DeleteClipboardRequest',
      '10': 'type'
    },
    {'1': 'succeed', '3': 2, '4': 1, '5': 8, '10': 'succeed'},
  ],
};

/// Descriptor for `SSPDeleteClipboardResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPDeleteClipboardResponseDescriptor =
    $convert.base64Decode(
        'ChpTU1BEZWxldGVDbGlwYm9hcmRSZXNwb25zZRJYCgR0eXBlGAEgASgOMh0ucmVjb3ZlcmVkLn'
        'NzcC5TU1BSZXF1ZXN0VHlwZTolU1NQUmVxdWVzdFR5cGVfRGVsZXRlQ2xpcGJvYXJkUmVxdWVz'
        'dFIEdHlwZRIYCgdzdWNjZWVkGAIgASgIUgdzdWNjZWVk');

@$core.Deprecated('Use sSPClipboardChangeDescriptor instead')
const SSPClipboardChange$json = {
  '1': 'SSPClipboardChange',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_ClipboardChange',
      '10': 'type'
    },
    {
      '1': 'clipboardArray',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPClipboard',
      '10': 'clipboardArray'
    },
  ],
};

/// Descriptor for `SSPClipboardChange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPClipboardChangeDescriptor = $convert.base64Decode(
    'ChJTU1BDbGlwYm9hcmRDaGFuZ2USUQoEdHlwZRgBIAEoDjIdLnJlY292ZXJlZC5zc3AuU1NQUm'
    'VxdWVzdFR5cGU6HlNTUFJlcXVlc3RUeXBlX0NsaXBib2FyZENoYW5nZVIEdHlwZRJDCg5jbGlw'
    'Ym9hcmRBcnJheRgCIAMoCzIbLnJlY292ZXJlZC5zc3AuU1NQQ2xpcGJvYXJkUg5jbGlwYm9hcm'
    'RBcnJheQ==');

@$core.Deprecated('Use sSPCancelRequestDescriptor instead')
const SSPCancelRequest$json = {
  '1': 'SSPCancelRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_CancelRequest',
      '10': 'type'
    },
    {'1': 'sessionId', '3': 2, '4': 1, '5': 4, '10': 'sessionId'},
    {
      '1': 'errorCode',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPCancelErrorCode',
      '10': 'errorCode'
    },
  ],
};

/// Descriptor for `SSPCancelRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPCancelRequestDescriptor = $convert.base64Decode(
    'ChBTU1BDYW5jZWxSZXF1ZXN0Ek8KBHR5cGUYASABKA4yHS5yZWNvdmVyZWQuc3NwLlNTUFJlcX'
    'Vlc3RUeXBlOhxTU1BSZXF1ZXN0VHlwZV9DYW5jZWxSZXF1ZXN0UgR0eXBlEhwKCXNlc3Npb25J'
    'ZBgCIAEoBFIJc2Vzc2lvbklkEj8KCWVycm9yQ29kZRgDIAEoDjIhLnJlY292ZXJlZC5zc3AuU1'
    'NQQ2FuY2VsRXJyb3JDb2RlUgllcnJvckNvZGU=');

@$core.Deprecated('Use sSPPhotoSyncRequestDescriptor instead')
const SSPPhotoSyncRequest$json = {
  '1': 'SSPPhotoSyncRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_PhotoSyncRequest',
      '10': 'type'
    },
    {'1': 'pcId', '3': 2, '4': 1, '5': 9, '10': 'pcId'},
    {
      '1': 'filesArray',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'filesArray'
    },
  ],
};

/// Descriptor for `SSPPhotoSyncRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPPhotoSyncRequestDescriptor = $convert.base64Decode(
    'ChNTU1BQaG90b1N5bmNSZXF1ZXN0ElIKBHR5cGUYASABKA4yHS5yZWNvdmVyZWQuc3NwLlNTUF'
    'JlcXVlc3RUeXBlOh9TU1BSZXF1ZXN0VHlwZV9QaG90b1N5bmNSZXF1ZXN0UgR0eXBlEhIKBHBj'
    'SWQYAiABKAlSBHBjSWQSNgoKZmlsZXNBcnJheRgDIAMoCzIWLnJlY292ZXJlZC5zc3AuU1NQRm'
    'lsZVIKZmlsZXNBcnJheQ==');

@$core.Deprecated('Use sSPPhotoSyncResponseDescriptor instead')
const SSPPhotoSyncResponse$json = {
  '1': 'SSPPhotoSyncResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_PhotoSyncRequest',
      '10': 'type'
    },
    {'1': 'isFirst', '3': 2, '4': 1, '5': 8, '10': 'isFirst'},
    {
      '1': 'filesArray',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'filesArray'
    },
    {'1': 'isSuccess', '3': 4, '4': 1, '5': 8, '10': 'isSuccess'},
  ],
};

/// Descriptor for `SSPPhotoSyncResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPPhotoSyncResponseDescriptor = $convert.base64Decode(
    'ChRTU1BQaG90b1N5bmNSZXNwb25zZRJSCgR0eXBlGAEgASgOMh0ucmVjb3ZlcmVkLnNzcC5TU1'
    'BSZXF1ZXN0VHlwZTofU1NQUmVxdWVzdFR5cGVfUGhvdG9TeW5jUmVxdWVzdFIEdHlwZRIYCgdp'
    'c0ZpcnN0GAIgASgIUgdpc0ZpcnN0EjYKCmZpbGVzQXJyYXkYAyADKAsyFi5yZWNvdmVyZWQuc3'
    'NwLlNTUEZpbGVSCmZpbGVzQXJyYXkSHAoJaXNTdWNjZXNzGAQgASgIUglpc1N1Y2Nlc3M=');

@$core.Deprecated('Use sSPFileChangeDescriptor instead')
const SSPFileChange$json = {
  '1': 'SSPFileChange',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_FileChange',
      '10': 'type'
    },
    {
      '1': 'fileChangeItemsArray',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPFileChangeItem',
      '10': 'fileChangeItemsArray'
    },
  ],
};

/// Descriptor for `SSPFileChange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPFileChangeDescriptor = $convert.base64Decode(
    'Cg1TU1BGaWxlQ2hhbmdlEkwKBHR5cGUYASABKA4yHS5yZWNvdmVyZWQuc3NwLlNTUFJlcXVlc3'
    'RUeXBlOhlTU1BSZXF1ZXN0VHlwZV9GaWxlQ2hhbmdlUgR0eXBlElQKFGZpbGVDaGFuZ2VJdGVt'
    'c0FycmF5GAIgAygLMiAucmVjb3ZlcmVkLnNzcC5TU1BGaWxlQ2hhbmdlSXRlbVIUZmlsZUNoYW'
    '5nZUl0ZW1zQXJyYXk=');

@$core.Deprecated('Use sSPFileChangeItemDescriptor instead')
const SSPFileChangeItem$json = {
  '1': 'SSPFileChangeItem',
  '2': [
    {
      '1': 'file',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'file'
    },
    {
      '1': 'status',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPFileChangeStatus',
      '10': 'status'
    },
  ],
};

/// Descriptor for `SSPFileChangeItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPFileChangeItemDescriptor = $convert.base64Decode(
    'ChFTU1BGaWxlQ2hhbmdlSXRlbRIqCgRmaWxlGAEgASgLMhYucmVjb3ZlcmVkLnNzcC5TU1BGaW'
    'xlUgRmaWxlEjoKBnN0YXR1cxgCIAEoDjIiLnJlY292ZXJlZC5zc3AuU1NQRmlsZUNoYW5nZVN0'
    'YXR1c1IGc3RhdHVz');

@$core.Deprecated('Use sSPSyncMonitorRequestDescriptor instead')
const SSPSyncMonitorRequest$json = {
  '1': 'SSPSyncMonitorRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_SyncMonitorRequest',
      '10': 'type'
    },
    {'1': 'isSyncMonitor', '3': 2, '4': 1, '5': 8, '10': 'isSyncMonitor'},
  ],
};

/// Descriptor for `SSPSyncMonitorRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPSyncMonitorRequestDescriptor = $convert.base64Decode(
    'ChVTU1BTeW5jTW9uaXRvclJlcXVlc3QSVAoEdHlwZRgBIAEoDjIdLnJlY292ZXJlZC5zc3AuU1'
    'NQUmVxdWVzdFR5cGU6IVNTUFJlcXVlc3RUeXBlX1N5bmNNb25pdG9yUmVxdWVzdFIEdHlwZRIk'
    'Cg1pc1N5bmNNb25pdG9yGAIgASgIUg1pc1N5bmNNb25pdG9y');

@$core.Deprecated('Use sSPSyncMonitorResponseDescriptor instead')
const SSPSyncMonitorResponse$json = {
  '1': 'SSPSyncMonitorResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_SyncMonitorRequest',
      '10': 'type'
    },
    {'1': 'isSuccess', '3': 2, '4': 1, '5': 8, '10': 'isSuccess'},
  ],
};

/// Descriptor for `SSPSyncMonitorResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPSyncMonitorResponseDescriptor = $convert.base64Decode(
    'ChZTU1BTeW5jTW9uaXRvclJlc3BvbnNlElQKBHR5cGUYASABKA4yHS5yZWNvdmVyZWQuc3NwLl'
    'NTUFJlcXVlc3RUeXBlOiFTU1BSZXF1ZXN0VHlwZV9TeW5jTW9uaXRvclJlcXVlc3RSBHR5cGUS'
    'HAoJaXNTdWNjZXNzGAIgASgIUglpc1N1Y2Nlc3M=');

@$core.Deprecated('Use sSPUpdateFileRequestDescriptor instead')
const SSPUpdateFileRequest$json = {
  '1': 'SSPUpdateFileRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_UpdateFileInfo',
      '10': 'type'
    },
    {
      '1': 'filesArray',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.recovered.ssp.SSPFile',
      '10': 'filesArray'
    },
    {'1': 'isSync', '3': 3, '4': 1, '5': 8, '10': 'isSync'},
  ],
};

/// Descriptor for `SSPUpdateFileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPUpdateFileRequestDescriptor = $convert.base64Decode(
    'ChRTU1BVcGRhdGVGaWxlUmVxdWVzdBJQCgR0eXBlGAEgASgOMh0ucmVjb3ZlcmVkLnNzcC5TU1'
    'BSZXF1ZXN0VHlwZTodU1NQUmVxdWVzdFR5cGVfVXBkYXRlRmlsZUluZm9SBHR5cGUSNgoKZmls'
    'ZXNBcnJheRgCIAMoCzIWLnJlY292ZXJlZC5zc3AuU1NQRmlsZVIKZmlsZXNBcnJheRIWCgZpc1'
    'N5bmMYAyABKAhSBmlzU3luYw==');

@$core.Deprecated('Use sSPUpdateFileResponseDescriptor instead')
const SSPUpdateFileResponse$json = {
  '1': 'SSPUpdateFileResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.recovered.ssp.SSPRequestType',
      '7': 'SSPRequestType_UpdateFileInfoResponse',
      '10': 'type'
    },
    {'1': 'isSuccess', '3': 2, '4': 1, '5': 8, '10': 'isSuccess'},
  ],
};

/// Descriptor for `SSPUpdateFileResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sSPUpdateFileResponseDescriptor = $convert.base64Decode(
    'ChVTU1BVcGRhdGVGaWxlUmVzcG9uc2USWAoEdHlwZRgBIAEoDjIdLnJlY292ZXJlZC5zc3AuU1'
    'NQUmVxdWVzdFR5cGU6JVNTUFJlcXVlc3RUeXBlX1VwZGF0ZUZpbGVJbmZvUmVzcG9uc2VSBHR5'
    'cGUSHAoJaXNTdWNjZXNzGAIgASgIUglpc1N1Y2Nlc3M=');
