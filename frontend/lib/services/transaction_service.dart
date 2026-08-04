import 'package:dio/dio.dart';
import 'package:life_partner_again/models/transaction_history.dart';
import 'package:life_partner_again/services/api_service.dart';

class TransactionService {
  static final _client = ApiService.client;
  Future<List<TransactionHistory>> getUserTransactions() async {
    try {
      final response = await _client.get('/transactions');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((e) => TransactionHistory.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch transaction history',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }
}
