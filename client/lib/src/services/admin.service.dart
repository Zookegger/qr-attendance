import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:qr_attendance_frontend/src/consts/api_endpoints.dart';
import 'package:qr_attendance_frontend/src/models/user.dart';
import '../utils/api_client.dart';

class AdminService {
  final Dio _dio = ApiClient().client;

  Future<List<User>> getUsers() async {
    try {
      final response = await _dio.get(ApiEndpoints.adminUsers);

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is List) {
          return data
              .map((e) => User.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        throw Exception('Unexpected response format for users');
      }

      throw Exception('Failed to fetch users: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Network error while fetching users: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createUser(Map<String, dynamic> data) async {
    try {
      debugPrint(data.toString());

      await _dio.post(
        ApiEndpoints.adminUsers,
        data: data,
      ); // POST /api/admin/users
    } on DioException catch (e) {
      throw Exception('Network error while fetching users: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    try {
      await _dio.put(
        ApiEndpoints.adminUser(id),
        data: data,
      ); // PUT /api/admin/users/:id
    } on DioException catch (e) {
      throw Exception('Network error while fetching users: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _dio.delete(
        ApiEndpoints.adminUser(id),
      ); // DELETE /api/admin/users/:id
    } on DioException catch (e) {
      throw Exception('Network error while fetching users: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unbindDevice(String userId) async {
    try {
      await _dio.post(ApiEndpoints.unbindDevice, data: {'userId': userId});
    } on DioException catch (e) {
      throw Exception('Network error while fetching users: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  Future<User> getUserById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.adminUser(id));

      if (response.statusCode == 200) {
        final userData = response.data['user'] ?? response.data;
        return User.fromJson(userData as Map<String, dynamic>);
      }

      throw Exception('Failed to fetch user: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Network error while fetching user: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }
}
