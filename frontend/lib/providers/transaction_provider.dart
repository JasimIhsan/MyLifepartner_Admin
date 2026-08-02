import 'package:flutter/foundation.dart';
import 'package:life_partner_again/models/transaction_history.dart';
import 'package:life_partner_again/services/transaction_service.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionService _transactionService = TransactionService();

  List<TransactionHistory> transactions = [];
  bool isLoading = false;
  String? error;

  Future<void> loadTransactions() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      transactions = await _transactionService.getUserTransactions();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
