import 'package:json_annotation/json_annotation.dart';

part 'dto.g.dart';

class ContentType {
  static final String text = "text";
  static final String imageUrl = "imageUrl";
}


@JsonSerializable(explicitToJson: true, includeIfNull: false)
class Content {
  String type;
  String message;

  Content({required this.type, required this.message});

  factory Content.fromJson(Map<String, dynamic> json) => _$ContentFromJson(json);

  Map<String, dynamic> toJson() => _$ContentToJson(this);
}

