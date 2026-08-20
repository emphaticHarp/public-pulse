class AppVersionModel {
  final String platform;
  final String versionName;
  final int buildNumber;
  final int minimumSupportedBuild;
  final bool forceUpdate;
  final String updateTitle;
  final String updateMessage;
  final String downloadUrl;
  final String? releaseNotes;
  final bool isActive;
  final String? id;

  const AppVersionModel({
    required this.platform,
    required this.versionName,
    required this.buildNumber,
    required this.minimumSupportedBuild,
    required this.forceUpdate,
    required this.updateTitle,
    required this.updateMessage,
    required this.downloadUrl,
    this.releaseNotes,
    required this.isActive,
    this.id,
  });

  factory AppVersionModel.fromJson(Map<String, dynamic> json) {
    return AppVersionModel(
      platform: json['platform'],
      versionName: json['version_name'],
      buildNumber: json['build_number'],
      minimumSupportedBuild: json['minimum_supported_build'],
      forceUpdate: json['force_update'],
      updateTitle: json['update_title'],
      updateMessage: json['update_message'],
      downloadUrl: json['download_url'],
      releaseNotes: json['release_notes'],
      isActive: json['is_active'],
      id: json['id'],
    );
  }
}
