class AccountModel {
  final int id;
  final String name;
  final String groupName;
  final String accountType;
  final double openingBalance;
  final double currentBalance;
  final bool isActive;

  AccountModel({
    required this.id,
    required this.name,
    required this.groupName,
    required this.accountType,
    required this.openingBalance,
    required this.currentBalance,
    required this.isActive,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'],
      name: json['name'],
      groupName: json['group_name'],
      accountType: json['account_type'],
      openingBalance: (json['opening_balance'] ?? 0).toDouble(),
      currentBalance: (json['current_balance'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
    );
  }
}
