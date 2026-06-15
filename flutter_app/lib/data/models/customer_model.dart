class CustomerModel {
  final int id;
  final String name;
  final String? companyName;
  final String? email;
  final String? phone;
  final String? mobile;
  final String? gstin;
  final String? city;
  final String? state;
  final double creditLimit;
  final double currentBalance;
  final double outstandingAmount;

  CustomerModel({
    required this.id,
    required this.name,
    this.companyName,
    this.email,
    this.phone,
    this.mobile,
    this.gstin,
    this.city,
    this.state,
    required this.creditLimit,
    required this.currentBalance,
    required this.outstandingAmount,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'],
      name: json['name'],
      companyName: json['company_name'],
      email: json['email'],
      phone: json['phone'],
      mobile: json['mobile'],
      gstin: json['gstin'],
      city: json['city'],
      state: json['state'],
      creditLimit: (json['credit_limit'] ?? 0).toDouble(),
      currentBalance: (json['current_balance'] ?? 0).toDouble(),
      outstandingAmount: (json['outstanding_amount'] ?? 0).toDouble(),
    );
  }
}
