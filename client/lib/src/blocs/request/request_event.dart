import 'package:equatable/equatable.dart';
import 'dart:io';

abstract class RequestEvent extends Equatable {
  const RequestEvent();

  @override
  List<Object?> get props => [];
}

class RequestsFetchAll extends RequestEvent {
  const RequestsFetchAll();
}

class RequestsFetchByUser extends RequestEvent {
  final String userId;

  const RequestsFetchByUser({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class RequestCreate extends RequestEvent {
  final dynamic request; // Request model
  final List<File> files;

  const RequestCreate({
    required this.request,
    this.files = const [],
  });

  @override
  List<Object?> get props => [request, files];
}

class RequestUpdate extends RequestEvent {
  final dynamic request; // Request model

  const RequestUpdate({required this.request});

  @override
  List<Object?> get props => [request];
}

class RequestDelete extends RequestEvent {
  final String requestId;

  const RequestDelete({required this.requestId});

  @override
  List<Object?> get props => [requestId];
}

class RequestApprove extends RequestEvent {
  final String requestId;

  const RequestApprove({required this.requestId});

  @override
  List<Object?> get props => [requestId];
}

class RequestReject extends RequestEvent {
  final String requestId;
  final String? reason;

  const RequestReject({
    required this.requestId,
    this.reason,
  });

  @override
  List<Object?> get props => [requestId, reason];
}

class RequestFilterChanged extends RequestEvent {
  final String? status;
  final String? type;

  const RequestFilterChanged({
    this.status,
    this.type,
  });

  @override
  List<Object?> get props => [status, type];
}
