/// Represents a locally installed Flatpak application.
class FlatpakApp {
  final String name;
  final String description;
  final String application;
  final String version;
  final String branch;
  final String arch;
  final String runtime;
  final String origin;
  final String installation;
  final String ref;
  final String active;
  final String latest;
  final String size;
  final DateTime? installDate;
  final String? iconPath;
  final List<String> permissions;
  final List<String> categories;
  final List<String> keywords;
  final String? eolMessage;
  final String? eolRebaseId;

  /// Combines fields to guarantee a unique identifier: e.g., "system_org.videolan.VLC_3.0.20_stable"
  String get uniqueId => '${installation}_${application}_${version}_$branch';

  FlatpakApp({
    required this.name,
    required this.description,
    required this.application,
    required this.version,
    required this.branch,
    required this.arch,
    required this.runtime,
    required this.origin,
    required this.installation,
    required this.ref,
    required this.active,
    required this.latest,
    required this.size,
    this.installDate,
    this.iconPath,
    required this.permissions,
    required this.categories,
    required this.keywords,
    this.eolMessage,
    this.eolRebaseId,
  });

  FlatpakApp copyWith({
    String? name,
    String? description,
    String? application,
    String? version,
    String? branch,
    String? arch,
    String? runtime,
    String? origin,
    String? installation,
    String? ref,
    String? active,
    String? latest,
    String? size,
    DateTime? installDate,
    String? iconPath,
    List<String>? permissions,
    List<String>? categories,
    List<String>? keywords,
    String? eolMessage,
    String? eolRebaseId,
  }) {
    return FlatpakApp(
      name: name ?? this.name,
      description: description ?? this.description,
      application: application ?? this.application,
      version: version ?? this.version,
      branch: branch ?? this.branch,
      arch: arch ?? this.arch,
      runtime: runtime ?? this.runtime,
      origin: origin ?? this.origin,
      installation: installation ?? this.installation,
      ref: ref ?? this.ref,
      active: active ?? this.active,
      latest: latest ?? this.latest,
      size: size ?? this.size,
      installDate: installDate ?? this.installDate,
      iconPath: iconPath ?? this.iconPath,
      permissions: permissions ?? this.permissions,
      categories: categories ?? this.categories,
      keywords: keywords ?? this.keywords,
      eolMessage: eolMessage ?? this.eolMessage,
      eolRebaseId: eolRebaseId ?? this.eolRebaseId,
    );
  }
}

/// Holds basic metadata extracted from a local .desktop file.
class DesktopInfo {
  final List<String> categories;
  final List<String> keywords;
  final String? iconName;

  DesktopInfo(this.categories, this.keywords, this.iconName);
}
