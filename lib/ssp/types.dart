import 'pb/SmartSyncProtocol.recovered.pbenum.dart' as pbe;

/// Short aliases for the generated enum constants (whose names repeat the
/// enum class prefix).
abstract final class Req {
  static const heartBeat = pbe.SSPRequestType.SSPRequestType_HeartBeatRequest;
  static const getDeviceInfo =
      pbe.SSPRequestType.SSPRequestType_GetDeviceInfoRequest;
  static const getThumbnail =
      pbe.SSPRequestType.SSPRequestType_GetThumbnailRequest;
  static const getPhotoLib =
      pbe.SSPRequestType.SSPRequestType_GetPhotoLibRequest;
  static const getVideoLib =
      pbe.SSPRequestType.SSPRequestType_GetVideoLibRequest;
  static const getAudioLib =
      pbe.SSPRequestType.SSPRequestType_GetAudioLibRequest;
  static const getDirFiles =
      pbe.SSPRequestType.SSPRequestType_GetDirFilesRequest;
  static const getFileCount =
      pbe.SSPRequestType.SSPRequestType_GetFileCountRequest;
  static const getFileExist =
      pbe.SSPRequestType.SSPRequestType_GetFileExistRequest;
  static const createFolder =
      pbe.SSPRequestType.SSPRequestType_GetCreateFolderRequest;
  static const renameFile =
      pbe.SSPRequestType.SSPRequestType_GetRenameFileRequest;
  static const downloadFile =
      pbe.SSPRequestType.SSPRequestType_GetDownloadFileRequest;
  static const downloadFileRespHeader =
      pbe.SSPRequestType.SSPRequestType_GetDownloadFileResponseHeader;
  static const downloadFileRespBody =
      pbe.SSPRequestType.SSPRequestType_GetDownloadFileResponseBody;
  static const uploadFileReqHeader =
      pbe.SSPRequestType.SSPRequestType_GetUploadFileRequestHeader;
  static const uploadFileRespHeader =
      pbe.SSPRequestType.SSPRequestType_GetUploadFileResponseHeader;
  static const uploadFileReqBody =
      pbe.SSPRequestType.SSPRequestType_GetUploadFileRequestBody;
  static const uploadFileResp =
      pbe.SSPRequestType.SSPRequestType_GetUploadFileResponse;
  static const deleteFile =
      pbe.SSPRequestType.SSPRequestType_GetDeleteFileRequest;
  static const photoLibChange =
      pbe.SSPRequestType.SSPRequestType_PhotoLibChange;
  static const audioLibChange =
      pbe.SSPRequestType.SSPRequestType_AudioLibChange;
  static const videoLibChange =
      pbe.SSPRequestType.SSPRequestType_VideoLibChange;
  static const monitorFolder =
      pbe.SSPRequestType.SSPRequestType_MonitorFolderRequest;
  static const monitorFolderHeader =
      pbe.SSPRequestType.SSPRequestType_MonitorFolderResponseHeader;
  static const monitorFolderResp =
      pbe.SSPRequestType.SSPRequestType_MonitorFolderResponse;
  static const getClipboard =
      pbe.SSPRequestType.SSPRequestType_GetClipboardRequest;
  static const postClipboard =
      pbe.SSPRequestType.SSPRequestType_PostClipboardRequest;
  static const clearClipboard =
      pbe.SSPRequestType.SSPRequestType_ClearClipboardRequest;
  static const deleteClipboard =
      pbe.SSPRequestType.SSPRequestType_DeleteClipboardRequest;
  static const clipboardChange =
      pbe.SSPRequestType.SSPRequestType_ClipboardChange;
  static const handshakeReq01 =
      pbe.SSPRequestType.SSPRequestType_HandshakeRequest01;
  static const handshakeResp01 =
      pbe.SSPRequestType.SSPRequestType_HandshakeResponse01;
  static const handshakeReq02 =
      pbe.SSPRequestType.SSPRequestType_HandshakeRequest02;
  static const handshakeResp02 =
      pbe.SSPRequestType.SSPRequestType_HandshakeResponse02;
  static const quit = pbe.SSPRequestType.SSPRequestType_QuitRequest;
  static const cancel = pbe.SSPRequestType.SSPRequestType_CancelRequest;
  static const photoSync = pbe.SSPRequestType.SSPRequestType_PhotoSyncRequest;
  static const fileChange = pbe.SSPRequestType.SSPRequestType_FileChange;
  static const syncMonitor =
      pbe.SSPRequestType.SSPRequestType_SyncMonitorRequest;
  static const updateFileInfo =
      pbe.SSPRequestType.SSPRequestType_UpdateFileInfo;
  static const updateFileInfoResp =
      pbe.SSPRequestType.SSPRequestType_UpdateFileInfoResponse;
}

abstract final class Trust {
  static const waiting =
      pbe.SSPHandShakeTrustType.SSPHandShakeTrustType_TrustWaiting;
  static const unknow =
      pbe.SSPHandShakeTrustType.SSPHandShakeTrustType_TrustUnknow;
  static const no = pbe.SSPHandShakeTrustType.SSPHandShakeTrustType_TrustNo;
  static const once =
      pbe.SSPHandShakeTrustType.SSPHandShakeTrustType_TrustOnce;
  static const always =
      pbe.SSPHandShakeTrustType.SSPHandShakeTrustType_TrustAlways;
  static const remove =
      pbe.SSPHandShakeTrustType.SSPHandShakeTrustType_TrustRemove;
}

abstract final class FileErr {
  static const unknow = pbe.SSPFileIOError.SSPFileIOError_FileIoUnknowError;
  static const invalidName =
      pbe.SSPFileIOError.SSPFileIOError_FileIoInvalidName;
  static const invalidSource =
      pbe.SSPFileIOError.SSPFileIOError_FileIoInvalidSource;
  static const targetExists =
      pbe.SSPFileIOError.SSPFileIOError_FileIoTargetAlreadyExist;
  static const permission =
      pbe.SSPFileIOError.SSPFileIOError_FileIoPermissionError;
  static const insufficientSpace =
      pbe.SSPFileIOError.SSPFileIOError_FileIoInsufficientDiskSpaceError;
  static const md5Check =
      pbe.SSPFileIOError.SSPFileIOError_FileIoMd5CheckError;
  static const systemFile =
      pbe.SSPFileIOError.SSPFileIOError_FileIoSystemFile;
  static const sdcardRemoved =
      pbe.SSPFileIOError.SSPFileIOError_FileIoSdcardRemoved;
  static const sdcardNoPermission =
      pbe.SSPFileIOError.SSPFileIOError_FileIoSdcardNoPermission;
}

abstract final class FileEventType {
  static const create =
      pbe.SSPFileEventType.SSPFileEventType_FileEventCreate;
  static const delete =
      pbe.SSPFileEventType.SSPFileEventType_FileEventDelete;
  static const closeWrite =
      pbe.SSPFileEventType.SSPFileEventType_FileEventCloseWrite;
  static const movedFrom =
      pbe.SSPFileEventType.SSPFileEventType_FileEventMovedFrom;
  static const movedTo =
      pbe.SSPFileEventType.SSPFileEventType_FileEventMovedTo;
  static const deleteSelf =
      pbe.SSPFileEventType.SSPFileEventType_FileEventDeleteSelf;
  static const moveSelf =
      pbe.SSPFileEventType.SSPFileEventType_FileEventMoveSelf;
  static const dirChanged =
      pbe.SSPFileEventType.SSPFileEventType_FileEventDirChanged;
}

abstract final class CancelErr {
  static const unknown =
      pbe.SSPCancelErrorCode.SSPCancelErrorCode_ErrorCodeUnknown;
  static const sdcardRemoved =
      pbe.SSPCancelErrorCode.SSPCancelErrorCode_ErrorCodeSdcardRemoved;
}

abstract final class FilePerm {
  static const none = pbe.SSPFileIOPermission.SSPFileIOPermission_AllowNone;
  static const read = pbe.SSPFileIOPermission.SSPFileIOPermission_AllowRead;
  static const write = pbe.SSPFileIOPermission.SSPFileIOPermission_AllowWrite;
  static const readWrite =
      pbe.SSPFileIOPermission.SSPFileIOPermission_AllowReadWrite;
}

abstract final class ChangeStatus {
  static const none =
      pbe.SSPFileChangeStatus.SSPFileChangeStatus_None;
  static const added =
      pbe.SSPFileChangeStatus.SSPFileChangeStatus_Added;
  static const deleted =
      pbe.SSPFileChangeStatus.SSPFileChangeStatus_Deleted;
  static const modified =
      pbe.SSPFileChangeStatus.SSPFileChangeStatus_Modified;
  static const infoModified =
      pbe.SSPFileChangeStatus.SSPFileChangeStatus_InfoModified;
  static const fileAndInfoModified =
      pbe.SSPFileChangeStatus.SSPFileChangeStatus_FileAndInfoModified;
}
