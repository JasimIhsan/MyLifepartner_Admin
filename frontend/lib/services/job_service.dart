import 'package:life_partner_again/models/job.dart';
import 'package:life_partner_again/services/api_service.dart';

class JobService {
  static final _client = ApiService.client;

  static Future<List<JobModel>> searchJobs(String query) async {
    try {
      final response = await _client.get(
        '/jobs',
        queryParameters: {if (query.trim().isNotEmpty) 'search': query.trim()},
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => JobModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<JobModel>> getPopularJobs() async {
    try {
      final response = await _client.get('/jobs/popular');

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => JobModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<JobModel> createJob(String name) async {
    try {
      final response = await _client.post('/jobs', data: {'name': name.trim()});

      if (response.data['success'] == true) {
        return JobModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to create job');
      }
    } catch (e) {
      rethrow;
    }
  }
}
