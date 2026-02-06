import 'package:json_annotation/json_annotation.dart';

part 'dto.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class Version {
  late String version;

  Version({required this.version});

  factory Version.fromJson(Map<String, dynamic> json) => _$VersionFromJson(json);

  Map<String, dynamic> toJson() => _$VersionToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class RootInfo {
  String name;
  String version;
  String description;
  String baseUrl;
  Map<String, String> endpoints;

  RootInfo({
    required this.name,
    required this.version,
    required this.description,
    required this.baseUrl,
    required this.endpoints,
  });

  factory RootInfo.fromJson(Map<String, dynamic> json) =>
      _$RootInfoFromJson(json);

  Map<String, dynamic> toJson() => _$RootInfoToJson(this);
}
