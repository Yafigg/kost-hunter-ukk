import 'package:json_annotation/json_annotation.dart';

part 'kos.g.dart';

@JsonSerializable()
class Kos {
  final int id;
  final String name;
  final String address;
  final String? description;
  final String? image;
  final double? price;
  final List<String>? facilities;
  final List<String>? paymentMethods;
  final List<Map<String, dynamic>>? rooms;
  final String? gender;

  Kos({
    required this.id,
    required this.name,
    required this.address,
    this.description,
    this.image,
    this.price,
    this.facilities,
    this.paymentMethods,
    this.rooms,
    this.gender,
  });

  factory Kos.fromJson(Map<String, dynamic> json) => _$KosFromJson(json);
  Map<String, dynamic> toJson() => _$KosToJson(this);
}
