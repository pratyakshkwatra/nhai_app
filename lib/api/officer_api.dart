import 'package:dio/dio.dart';
import './models/roadway.dart';
import './models/lane.dart';
import 'api_client.dart';

class OfficerApi {
  final Dio _dio = ApiClient().dio;

  Future<List<Roadway>> getMyRoadways() async {
    final response = await _dio.get('/officer/roadways');
    return (response.data as List).map((e) => Roadway.fromJson(e)).toList();
  }

  Future<List<Lane>> getLanes(int roadwayId) async {
    final response = await _dio.get('/officer/roadways/$roadwayId/lanes');
    return (response.data as List).map((e) => Lane.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getLaneData(int laneId) async {
    final response = await _dio.get('/officer/lanes/$laneId/data');
    return response.data;
  }
}
