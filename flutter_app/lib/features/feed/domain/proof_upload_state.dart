enum ProofUploadStatus { idle, uploading, uploaded, failed }

class ProofUploadState {
  const ProofUploadState({
    required this.status,
    this.localPath,
    this.remoteUrl,
    this.errorMessage,
  });

  const ProofUploadState.idle({String? localPath})
      : this(status: ProofUploadStatus.idle, localPath: localPath);

  const ProofUploadState.uploading({String? localPath})
      : this(status: ProofUploadStatus.uploading, localPath: localPath);

  const ProofUploadState.uploaded({String? localPath, String? remoteUrl})
      : this(status: ProofUploadStatus.uploaded, localPath: localPath, remoteUrl: remoteUrl);

  const ProofUploadState.failed({String? localPath, String? errorMessage})
      : this(status: ProofUploadStatus.failed, localPath: localPath, errorMessage: errorMessage);

  final ProofUploadStatus status;
  final String? localPath;
  final String? remoteUrl;
  final String? errorMessage;

  bool get isUploading => status == ProofUploadStatus.uploading;
  bool get isUploaded => status == ProofUploadStatus.uploaded;
  bool get isFailed => status == ProofUploadStatus.failed;
}
