part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {}

class FetchSettingsData extends SettingsEvent {
  FetchSettingsData();
  @override
  List<Object?> get props => [];
}