import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';

import 'package:nhai_app/api/models/inspection_officer.dart';
import 'package:mime/mime.dart';
import './models/lane.dart';
import './models/roadway.dart';
import 'api_client.dart';
import 'exceptions.dart';

class AdminApi {
  final Dio _dio = ApiClient().dio;

  Future<List<InspectionOfficer>> listOfficers() async {
    try {
      final response = await _dio.get('/admin/officers');
      return (response.data as List)
          .map((e) => InspectionOfficer.fromJson(e))
          .toList();
    } catch (e) {
      throw APIException('Failed to fetch officers');
    }
  }

  Future<void> createOfficer(String username, String password,
      {File? image}) async {
    try {
      final formData = FormData.fromMap({
        'username': username,
        'password': password,
        if (image != null)
          'image': await MultipartFile.fromFile(
            image.path,
            filename: basename(image.path),
            contentType: MediaType(
                'image', lookupMimeType(image.path)?.split('/')[1] ?? 'jpeg'),
          ),
      });

      await _dio.post('/admin/officers', data: formData);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final detail = e.response?.data['detail'];
        if (detail != null && detail is String) {
          throw APIException(detail);
        }
      }
      throw APIException('Failed to create officer');
    } catch (e) {
      throw APIException('Failed to create officer');
    }
  }

  Future<void> updateOfficer(
      int id, String? username, String? password, File? file) async {
    try {
      final formData = FormData.fromMap({
        if (username != null) 'username': username,
        if (password != null) 'password': password,
        if (file != null)
          'image': await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
      });

      await _dio.put(
        '/admin/officers/$id',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } catch (e) {
      throw APIException('Failed to update officer');
    }
  }

  Future<void> deleteOfficer(int id) async {
    try {
      await _dio.delete('/admin/officers/$id');
    } catch (e) {
      throw APIException('Failed to delete officer');
    }
  }

  Future<List<Roadway>> listRoadways() async {
    try {
      final response = await _dio.get('/admin/roadways');
      return (response.data as List).map((e) => Roadway.fromJson(e)).toList();
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Failed to fetch roadways';
      throw APIException(message.toString());
    } catch (e) {
      throw APIException('Something went wrong while fetching roadways');
    }
  }

  Future<Roadway> createRoadway(
      String roadwayId, String name, File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'roadway_id': roadwayId,
        'name': name,
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/admin/roadways',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return Roadway.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Failed to create roadway';
      throw APIException(message.toString());
    } catch (e) {
      throw APIException('Something went wrong while creating roadway');
    }
  }

  Future<Roadway> updateRoadway(
    int id,
    String name,
    String roadwayId, {
    File? imageFile,
  }) async {
    final formData = FormData.fromMap({
      'name': name,
      'roadway_id': roadwayId,
      if (imageFile != null)
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
          contentType: MediaType('image', 'jpeg'),
        ),
    });

    final response = await _dio.put(
      '/admin/roadways/$id',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return Roadway.fromJson(response.data);
  }

  Future<void> deleteRoadway(int id) async {
    await _dio.delete('/admin/roadways/$id');
  }

  Future<List<Lane>> getLanes(int roadwayId) async {
    final response = await _dio.get('/admin/roadways/$roadwayId/lanes');
    return (response.data as List).map((e) => Lane.fromJson(e)).toList();
  }

  Future<Lane> addLane({
    required int roadwayId,
    required String laneId,
    required String direction,
    required File videoFile,
    required File excelFile,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'lane_id': laneId,
        'direction': direction,
        'video': MultipartFile.fromStream(
          videoFile.openRead,
          await videoFile.length(),
          filename: 'video.mp4',
          contentType: MediaType('video', 'mp4'),
        ),
        'excel': await MultipartFile.fromFile(
          excelFile.path,
          filename: excelFile.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/admin/roadways/$roadwayId/lanes',
        data: formData,
        onSendProgress: (int sent, int total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      return Lane.fromJson(response.data);
    } on DioException catch (exception) {
      throw APIException(
          exception.response?.data['detail'] ?? 'Failed to add lane');
    } catch (e) {
      throw APIException('Failed to add lane');
    }
  }

  Future<void> deleteLane(int laneId) async {
    await _dio.delete('/admin/lanes/$laneId');
  }

  Future<void> updateAccess(Map<int, bool> accessMap, int roadwayId) async {
    try {
      final body = {
        'access_map':
            accessMap.map((key, value) => MapEntry(key.toString(), value)),
        'roadway_id': roadwayId,
      };

      await _dio.post(
        '/admin/access',
        data: body,
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );
    } catch (e) {
      throw APIException('Failed to update access');
    }
  }

  Future<List<InspectionOfficer>> getOfficersWithAccess(int roadwayId) async {
    try {
      final response = await _dio.get('/admin/roadways/$roadwayId/officers');
      return (response.data as List)
          .map((e) => InspectionOfficer.fromJson(e))
          .toList();
    } catch (e) {
      throw APIException('Failed to fetch assigned officers');
    }
  }

  Future<void> uploadLaneData(
      int laneId, MultipartFile video, MultipartFile xlsx) async {
    final form = FormData.fromMap({
      'video': video,
      'xlsx': xlsx,
    });
    await _dio.post('/admin/lanes/$laneId/upload', data: form);
  }

  Future<Map<String, dynamic>> getLaneProcessingProgress(int laneDataId) async {
    final response = await _dio.get('/admin/lane-data/$laneDataId/progress');
    return response.data;
  }
}
