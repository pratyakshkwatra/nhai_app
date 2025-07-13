import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
    Uint8List? webBytes,
    String? fileName,
    void Function(int, int)? onProgress,
  }) async {
    try {
      MultipartFile? multipartFile;

      if (image != null) {
        final mime = lookupMimeType(image.path) ?? 'image/jpeg';
        multipartFile = await MultipartFile.fromFile(
          image.path,
          filename: basename(image.path),
          contentType: MediaType.parse(mime),
        );
      } else if (kIsWeb && webBytes != null && fileName != null) {
        final mime = lookupMimeType(fileName) ?? 'image/jpeg';
        multipartFile = MultipartFile.fromBytes(
          webBytes,
          filename: fileName,
          contentType: MediaType.parse(mime),
        );
      }

      final formData = FormData.fromMap({
        'username': username,
        'password': password,
        if (multipartFile != null) 'image': multipartFile,
      });

      await _dio.post(
        '/admin/officers',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onProgress,
      );
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
    int id,
    String? username,
    String? password,
    dynamic fileOrBytes, {
    String? fileName,
    ProgressCallback? onProgress,
  }) async {
    try {
      final formMap = <String, dynamic>{};

      if (username != null) formMap['username'] = username;
      if (password != null) formMap['password'] = password;

      if (fileOrBytes != null) {
        if (fileOrBytes is File) {
          formMap['image'] = await MultipartFile.fromFile(
            fileOrBytes.path,
            filename: fileOrBytes.path.split('/').last,
          );
        } else if (fileOrBytes is Uint8List) {
          formMap['image'] = MultipartFile.fromBytes(
            fileOrBytes,
            filename: fileName ?? 'upload.jpg',
            contentType: MediaType('image', 'jpeg'),
          );
        }
      }

      final formData = FormData.fromMap(formMap);

      await _dio.put(
        '/admin/officers/$id',
        data: formData,
        onSendProgress: onProgress,
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
    String name, {
    File? imageFile,
    Uint8List? webBytes,
    String? webFileName,
    void Function(int, int)? onProgress,
  }) async {
    try {
      MultipartFile? multipartFile;

      if (imageFile != null) {
        final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
        multipartFile = await MultipartFile.fromFile(
          imageFile.path,
          filename: basename(imageFile.path),
          contentType: MediaType.parse(mimeType),
        );
      } else if (kIsWeb && webBytes != null && webFileName != null) {
        final mimeType = lookupMimeType(webFileName) ?? 'image/jpeg';
        multipartFile = MultipartFile.fromBytes(
          webBytes,
          filename: webFileName,
          contentType: MediaType.parse(mimeType),
        );
      }

      final formData = FormData.fromMap({
        'roadway_id': roadwayId,
        'name': name,
        if (multipartFile != null) 'image': multipartFile,
      });

      final response = await _dio.post(
        '/admin/roadways',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onProgress,
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
    MultipartFile? imageFile,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'name': name,
      'roadway_id': roadwayId,
      if (imageFile != null) 'image': imageFile,
    });

    final response = await _dio.put(
      '/admin/roadways/$id',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: onSendProgress,
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
    required MultipartFile videoFile,
    required MultipartFile excelFile,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'lane_id': laneId,
        'direction': direction,
        'video': videoFile,
        'excel': excelFile,
      });

      final response = await _dio.post(
        '/admin/roadways/$roadwayId/lanes',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: (int sent, int total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      return Lane.fromJson(response.data);
    } on DioException catch (exception) {
      throw APIException(
        exception.response?.data['detail'] ?? 'Failed to add lane',
      );
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
