enum TransactionType {
  expense,
  income,
  transfer;

  static TransactionType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'transfer':
        return TransactionType.transfer;
      case 'expense':
      default:
        return TransactionType.expense;
    }
  }

  String toApiString() {
    switch (this) {
      case TransactionType.income:
        return 'income';
      case TransactionType.transfer:
        return 'transfer';
      case TransactionType.expense:
        return 'expense';
    }
  }

  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.transfer:
        return 'Transfer';
      case TransactionType.expense:
        return 'Expense';
    }
  }
}

class TransactionEntity {
  final String id;
  final String userId;
  final String accountId;
  final String? destinationAccountId;
  final String? categoryId;
  final TransactionType type;
  final double amount;
  final double feeAmount;
  final DateTime transactionDate;
  final String? description;
  final List<String> tags;
  final String? receiptUrl;
  final bool isRecurring;
  final DateTime createdAt;

  // Joined presentation data
  final String? accountName;
  final String? destinationAccountName;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColorHex;

  const TransactionEntity({
    required this.id,
    required this.userId,
    required this.accountId,
    this.destinationAccountId,
    this.categoryId,
    required this.type,
    required this.amount,
    this.feeAmount = 0.0,
    required this.transactionDate,
    this.description,
    this.tags = const [],
    this.receiptUrl,
    this.isRecurring = false,
    required this.createdAt,
    this.accountName,
    this.destinationAccountName,
    this.categoryName,
    this.categoryIcon,
    this.categoryColorHex,
  });

  factory TransactionEntity.fromJson(Map<String, dynamic> json) {
    return TransactionEntity(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      accountId: json['accountId'] ?? json['account_id'] ?? '',
      destinationAccountId: json['destinationAccountId'] ?? json['destination_account_id'],
      categoryId: json['categoryId'] ?? json['category_id'],
      type: TransactionType.fromString(json['type'] ?? 'expense'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      feeAmount: (json['feeAmount'] ?? json['fee_amount'] as num?)?.toDouble() ?? 0.0,
      transactionDate: json['transactionDate'] != null
          ? DateTime.tryParse(json['transactionDate']) ?? DateTime.now()
          : (json['transaction_date'] != null ? DateTime.tryParse(json['transaction_date']) ?? DateTime.now() : DateTime.now()),
      description: json['description'],
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      receiptUrl: json['receiptUrl'] ?? json['receipt_url'],
      isRecurring: json['isRecurring'] ?? json['is_recurring'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at']) ?? DateTime.now() : DateTime.now()),
      accountName: json['accountName'] ?? json['accounts']?['name'],
      destinationAccountName: json['destinationAccountName'] ?? json['destination_account']?['name'],
      categoryName: json['categoryName'] ?? json['categories']?['name'],
      categoryIcon: json['categoryIcon'] ?? json['categories']?['icon'],
      categoryColorHex: json['categoryColorHex'] ?? json['categories']?['color_hex'],
    );
  }
}
