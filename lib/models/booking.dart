import 'package:json_annotation/json_annotation.dart';

part 'booking.g.dart';

@JsonSerializable()
class Booking {
  final int id;
  final int kosId;
  final int roomId;
  final int userId;
  final String bookingCode;
  final DateTime startDate;
  final DateTime endDate;
  final int totalPrice;
  final String status;
  final String? rejectedReason;

  Booking({
    required this.id,
    required this.kosId,
    required this.roomId,
    required this.userId,
    required this.bookingCode,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    this.rejectedReason,
  });

  factory Booking.fromJson(Map<String, dynamic> json) =>
      _$BookingFromJson(json);
  Map<String, dynamic> toJson() => _$BookingToJson(this);
}
