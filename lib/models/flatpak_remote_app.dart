/// Represents a screenshot for an application sourced from Flathub.
class Screenshot {
  final String imgDesktopUrl;
  final String thumbnailUrl;

  Screenshot({required this.imgDesktopUrl, required this.thumbnailUrl});

  factory Screenshot.fromJson(Map<String, dynamic> json) {
    final url = json['imgDesktopUrl'] ?? '';
    return Screenshot(imgDesktopUrl: url, thumbnailUrl: json['thumbnailUrl'] ?? url);
  }
}

/// Represents a specific release version of an application.
class Release {
  final String? version;
  final DateTime? date;
  final String? description;

  Release({this.version, this.date, this.description});

  factory Release.fromJson(Map<String, dynamic> json) {
    final timestamp = json['timestamp'];
    DateTime? releaseDate;
    if (timestamp is int) {
      releaseDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    }

    return Release(version: json['version'], date: releaseDate, description: json['description']);
  }
}

/// Represents an application available on the remote Flathub repository.
class FlatpakRemoteApp {
  final String flatpakAppId;
  final String name;
  final String summary;
  final String? description;
  final String? developerName;
  final String? projectLicense;
  final String? iconUrl;
  final List<String> categories;
  final List<Screenshot> screenshots;
  final List<Release> releases;
  final String? homepageUrl;
  final String? currentReleaseVersion;
  final DateTime? currentReleaseDate;
  final String? size;
  final bool isInstalled;

  FlatpakRemoteApp({
    required this.flatpakAppId,
    required this.name,
    required this.summary,
    this.description,
    this.developerName,
    this.projectLicense,
    this.iconUrl,
    required this.categories,
    required this.screenshots,
    required this.releases,
    this.homepageUrl,
    this.currentReleaseVersion,
    this.currentReleaseDate,
    this.size,
    this.isInstalled = false,
  });

  factory FlatpakRemoteApp.fromJson(Map<String, dynamic> json) {
    return FlatpakRemoteApp(
      flatpakAppId: json['flatpakAppId'] ?? json['id'] ?? '', // Fallback for older Flathub API responses
      name: json['name'] ?? 'Unknown',
      summary: json['summary'] ?? '',
      description: json['description'],
      developerName: json['developerName'],
      projectLicense: json['projectLicense'],
      iconUrl: json['iconUrl'],
      categories: json['categories'] != null ? List<String>.from(json['categories']) : <String>[],
      screenshots: json['screenshots'] != null
          ? (json['screenshots'] as List).map((s) => Screenshot.fromJson(s as Map<String, dynamic>)).toList()
          : <Screenshot>[],
      releases: json['releases'] != null ? (json['releases'] as List).map((r) => Release.fromJson(r as Map<String, dynamic>)).toList() : <Release>[],
      homepageUrl: json['homepageUrl'],
      currentReleaseVersion: json['currentReleaseVersion'],
      currentReleaseDate: json['currentReleaseDate'] != null ? DateTime.tryParse(json['currentReleaseDate']) : null,
    );
  }

  FlatpakRemoteApp copyWith({String? size, bool? isInstalled}) {
    return FlatpakRemoteApp(
      flatpakAppId: flatpakAppId,
      name: name,
      summary: summary,
      description: description,
      developerName: developerName,
      projectLicense: projectLicense,
      iconUrl: iconUrl,
      categories: categories,
      screenshots: screenshots,
      releases: releases,
      homepageUrl: homepageUrl,
      currentReleaseVersion: currentReleaseVersion,
      currentReleaseDate: currentReleaseDate,
      size: size ?? this.size,
      isInstalled: isInstalled ?? this.isInstalled,
    );
  }
}
