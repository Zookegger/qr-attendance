import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_attendance_frontend/src/blocs/request/request_event.dart';
import 'package:qr_attendance_frontend/src/blocs/request/request_state.dart';
import 'package:qr_attendance_frontend/src/services/request.service.dart';

class RequestBloc extends Bloc<RequestEvent, RequestState> {
  final RequestService _requestService;

  RequestBloc({
    RequestService? requestService,
  })  : _requestService = requestService ?? RequestService(),
        super(const RequestInitial()) {
    on<RequestsFetchAll>(_onRequestsFetchAll);
    on<RequestsFetchByUser>(_onRequestsFetchByUser);
    on<RequestCreate>(_onRequestCreate);
    on<RequestUpdate>(_onRequestUpdate);
    on<RequestDelete>(_onRequestDelete);
    on<RequestApprove>(_onRequestApprove);
    on<RequestReject>(_onRequestReject);
    on<RequestFilterChanged>(_onRequestFilterChanged);
  }

  Future<void> _onRequestsFetchAll(
    RequestsFetchAll event,
    Emitter<RequestState> emit,
  ) async {
    emit(const RequestLoading());
    try {
      final requests = await _requestService.listRequests();
      emit(RequestLoaded(
        requests: requests,
        filteredRequests: requests,
      ));
    } catch (e) {
      emit(RequestError(message: 'Error loading requests: $e'));
    }
  }

  Future<void> _onRequestsFetchByUser(
    RequestsFetchByUser event,
    Emitter<RequestState> emit,
  ) async {
    emit(const RequestLoading());
    try {
      final requests = await _requestService.listRequests(
        userId: event.userId,
      );
      emit(RequestLoaded(
        requests: requests,
        filteredRequests: requests,
      ));
    } catch (e) {
      emit(RequestError(message: 'Error loading requests: $e'));
    }
  }

  Future<void> _onRequestCreate(
    RequestCreate event,
    Emitter<RequestState> emit,
  ) async {
    try {
      await _requestService.createRequest(event.request, event.files);
      emit(const RequestOperationSuccess(message: 'Request created successfully'));
      
      // Reload the data
      add(const RequestsFetchAll());
    } catch (e) {
      emit(RequestError(message: 'Error creating request: $e'));
    }
  }

  Future<void> _onRequestUpdate(
    RequestUpdate event,
    Emitter<RequestState> emit,
  ) async {
    try {
      await _requestService.updateRequest(event.request, const []);
      emit(const RequestOperationSuccess(message: 'Request updated successfully'));
      
      // Reload the data
      add(const RequestsFetchAll());
    } catch (e) {
      emit(RequestError(message: 'Error updating request: $e'));
    }
  }

  Future<void> _onRequestDelete(
    RequestDelete event,
    Emitter<RequestState> emit,
  ) async {
    try {
      await _requestService.cancelRequest(event.requestId);
      emit(const RequestOperationSuccess(message: 'Request deleted successfully'));
      
      // Reload the data
      add(const RequestsFetchAll());
    } catch (e) {
      emit(RequestError(message: 'Error deleting request: $e'));
    }
  }

  Future<void> _onRequestApprove(
    RequestApprove event,
    Emitter<RequestState> emit,
  ) async {
    try {
      await _requestService.reviewRequest(
        event.requestId,
        'approved',
      );
      emit(const RequestOperationSuccess(message: 'Request approved successfully'));
      
      // Reload the data
      add(const RequestsFetchAll());
    } catch (e) {
      emit(RequestError(message: 'Error approving request: $e'));
    }
  }

  Future<void> _onRequestReject(
    RequestReject event,
    Emitter<RequestState> emit,
  ) async {
    try {
      await _requestService.reviewRequest(
        event.requestId,
        'rejected',
        reviewNote: event.reason,
      );
      emit(const RequestOperationSuccess(message: 'Request rejected'));
      
      // Reload the data
      add(const RequestsFetchAll());
    } catch (e) {
      emit(RequestError(message: 'Error rejecting request: $e'));
    }
  }

  void _onRequestFilterChanged(
    RequestFilterChanged event,
    Emitter<RequestState> emit,
  ) {
    if (state is! RequestLoaded) return;
    
    final currentState = state as RequestLoaded;
    final allRequests = currentState.requests;
    
    // Apply filters
    var filtered = allRequests;
    
    if (event.status != null) {
      filtered = filtered.where((r) => r.status.name == event.status).toList();
    }
    
    if (event.type != null) {
      filtered = filtered.where((r) => r.type.name == event.type).toList();
    }
    
    emit(currentState.copyWith(
      filteredRequests: filtered,
      statusFilter: event.status,
      typeFilter: event.type,
    ));
  }
}
