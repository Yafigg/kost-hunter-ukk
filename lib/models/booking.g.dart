// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Booking _$BookingFromJson(Map<String, dynamic> json) => Booking(
  id: (json['id'] as num).toInt(),
  kosId: (json['kosId'] as num).toInt(),
  roomId: (json['roomId'] as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  bookingCode: json['bookingCode'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  totalPrice: (json['totalPrice'] as num).toInt(),
  status: json['status'] as String,
  rejectedReason: json['rejectedReason'] as String?,
);

Map<String, dynamic> _$BookingToJson(Booking instance) => <String, dynamic>{
  'id': instance.id,
  'kosId': instance.kosId,
  'roomId': instance.roomId,
  'userId': instance.userId,
  'bookingCode': instance.bookingCode,
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate.toIso8601String(),
  'totalPrice': instance.totalPrice,
  'status': instance.status,
  'rejectedReason': instance.rejectedReason,
};
