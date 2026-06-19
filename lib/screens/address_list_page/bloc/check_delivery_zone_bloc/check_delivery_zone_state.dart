part of 'check_delivery_zone_bloc.dart';

abstract class CheckDeliveryZoneState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CheckDeliveryZoneInitial extends CheckDeliveryZoneState {}

class CheckDeliveryZoneProgress extends CheckDeliveryZoneState {}

class CheckDeliveryZoneSuccess extends CheckDeliveryZoneState {
  final String message;
  final String? zoneId;
  final String? zoneName;
  CheckDeliveryZoneSuccess({required this.message, this.zoneId, this.zoneName});
  @override
  List<Object?> get props => [message, zoneId, zoneName];
}

class CheckDeliveryZoneFailure extends CheckDeliveryZoneState {
  final String error;
  CheckDeliveryZoneFailure({required this.error});
  @override
  List<Object?> get props => [error];
}
