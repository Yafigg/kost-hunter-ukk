// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Kos _$KosFromJson(Map<String, dynamic> json) => Kos(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  address: json['address'] as String,
  description: json['description'] as String?,
  image: json['image'] as String?,
);

Map<String, dynamic> _$KosToJson(Kos instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'address': instance.address,
  'description': instance.description,
  'image': instance.image,
};
