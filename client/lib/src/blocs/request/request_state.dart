import 'package:equatable/equatable.dart';

abstract class RequestState extends Equatable {
  const RequestState();

  @override
  List<Object?> get props => [];
}

class RequestInitial extends RequestState {
  const RequestInitial();
}

class RequestLoading extends RequestState {
  const RequestLoading();
}

class RequestLoaded extends RequestState {
  final List<dynamic> requests; // List<Request>
  final List<dynamic> filteredRequests; // List<Request>
  final String? statusFilter;
  final String? typeFilter;

  const RequestLoaded({
    required this.requests,
    required this.filteredRequests,
    this.statusFilter,
    this.typeFilter,
  });

  @override
  List<Object?> get props => [
        requests,
        filteredRequests,
        statusFilter,
        typeFilter,
      ];

  RequestLoaded copyWith({
    List<dynamic>? requests,
    List<dynamic>? filteredRequests,
    String? statusFilter,
    String? typeFilter,
    bool clearStatusFilter = false,
    bool clearTypeFilter = false,
  }) {
    return RequestLoaded(
      requests: requests ?? this.requests,
      filteredRequests: filteredRequests ?? this.filteredRequests,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
    );
  }
}

class RequestError extends RequestState {
  final String message;

  const RequestError({required this.message});

  @override
  List<Object?> get props => [message];
}

class RequestOperationSuccess extends RequestState {
  final String message;

  const RequestOperationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}
