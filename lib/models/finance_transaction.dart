class FinanceTransaction {
  final String id;
  final String accountId;
  final double amount;
  final String date;
  final String name;
  final String? category;
  final bool pending;

  FinanceTransaction({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.date,
    required this.name,
    this.category,
    this.pending = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountId': accountId,
      'amount': amount,
      'date': date,
      'name': name,
      'category': category,
      'pending': pending ? 1 : 0,
    };
  }

  factory FinanceTransaction.fromMap(Map<String, dynamic> map) {
    return FinanceTransaction(
      id: map['id'],
      accountId: map['accountId'],
      amount: map['amount'],
      date: map['date'],
      name: map['name'],
      category: map['category'],
      pending: map['pending'] == 1,
    );
  }
}
