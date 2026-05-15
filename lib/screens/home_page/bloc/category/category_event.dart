import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class CategoryEvent extends Equatable {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class FetchCategory extends CategoryEvent {
  final bool isHome;
  FetchCategory({this.isHome = false});
  @override
  // TODO: implement props
  List<Object?> get props => [isHome];
}

class FetchMoreCategory extends CategoryEvent {}