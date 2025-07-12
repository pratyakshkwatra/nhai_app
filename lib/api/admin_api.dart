import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

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

  Future<void> createOfficer(
    String username,
    String password, {
    File? image,
    Uint8List? imageBytes,
    String? filename,
  }) async {
    try {
      final formData = FormData();

      formData.fields
        ..add(MapEntry('username', username))
        ..add(MapEntry('password', password));

      if (image != null) {
        final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(
            image.path,
            filename: basename(image.path),
            contentType: MediaType.parse(mimeType),
          ),
        ));
      } else if (imageBytes != null && filename != null) {
        final mimeType = lookupMimeType(filename) ?? 'image/jpeg';
        formData.files.add(MapEntry(
          'image',
          MultipartFile.fromBytes(
            imageBytes,
            filename: filename,
            contentType: MediaType.parse(mimeType),
          ),
        ));
      }

      await _dio.post('/admin/officers', data: formData);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];
      throw APIException(
          detail is String ? detail : 'Failed to create officer');
    } catch (_) {
      throw APIException('Failed to create officer');
    }
  }

  Future<void> updateOfficer(
    int id,
    String? username,
    String? password, {
    File? file,
    Uint8List? bytes,
    String? filename,
  }) async {
    try {
      final formData = FormData.fromMap({
        if (username != null) 'username': username,
        if (password != null) 'password': password,
        if (file != null)
          'image': await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
            contentType: MediaType('image', 'jpeg'),
          ),
        if (bytes != null && filename != null)
          'image': MultipartFile.fromBytes(
            bytes,
            filename: filename,
            contentType: MediaType('image', 'jpeg'),
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
    String roadwayId,
    String name,
    Uint8List imageBytes,
    String filename,
  ) async {
    try {
      final formData = FormData.fromMap({
        'roadway_id': roadwayId,
        'name': name,
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: filename,
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
    Uint8List? imageBytes,
    String? filename,
  }) async {
    final Map<String, dynamic> fields = {
      'name': name,
      'roadway_id': roadwayId,
    };

    if (imageFile != null) {
      fields['image'] = await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.path.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      );
    } else if (imageBytes != null && filename != null) {
      fields['image'] = MultipartFile.fromBytes(
        imageBytes,
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      );
    }

    final formData = FormData.fromMap(fields);

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
    required Uint8List videoBytes,
    required String videoName,
    required Uint8List excelBytes,
    required String excelName,
    void Function(double progress)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'lane_id': laneId,
      'direction': direction,
      'video': MultipartFile.fromBytes(
        videoBytes,
        filename: videoName,
        contentType: MediaType('video', 'mp4'),
      ),
      'excel': MultipartFile.fromBytes(
        excelBytes,
        filename: excelName,
        contentType: MediaType('application',
            'vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
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
      log('Access update error: $e');
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
