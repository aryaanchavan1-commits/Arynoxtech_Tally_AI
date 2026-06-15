class ApiConstants {
  static const String baseUrl = 'http://localhost:8000';
  static const String login = '$baseUrl/api/auth/login';
  static const String register = '$baseUrl/api/auth/register';
  static const String changePassword = '$baseUrl/api/auth/change-password';
  static const String getMe = '$baseUrl/api/auth/me';

  static const String accounts = '$baseUrl/api/accounts';
  static const String vouchers = '$baseUrl/api/vouchers';

  static const String customers = '$baseUrl/api/customers';
  static const String suppliers = '$baseUrl/api/suppliers';

  static const String inventoryProducts = '$baseUrl/api/inventory/products';
  static const String inventoryCategories = '$baseUrl/api/inventory/categories';
  static const String lowStock = '$baseUrl/api/inventory/products/low-stock/list';

  static const String invoices = '$baseUrl/api/invoices';

  static const String expenses = '$baseUrl/api/expenses';
  static const String expenseCategories = '$baseUrl/api/expenses/categories';

  static const String dashboardSummary = '$baseUrl/api/dashboard/summary';
  static const String dashboardChart = '$baseUrl/api/dashboard/chart';
  static const String topCustomers = '$baseUrl/api/dashboard/top-customers';
  static const String topProducts = '$baseUrl/api/dashboard/top-products';

  static const String reportsTrialBalance = '$baseUrl/api/reports/trial-balance';
  static const String reportsProfitLoss = '$baseUrl/api/reports/profit-loss';
  static const String reportsBalanceSheet = '$baseUrl/api/reports/balance-sheet';
  static const String reportsDayBook = '$baseUrl/api/reports/day-book';
  static const String reportsLedger = '$baseUrl/api/reports/general-ledger';

  static const String aiSettings = '$baseUrl/api/ai/settings';
  static const String aiChat = '$baseUrl/api/ai/chat';
  static const String aiTest = '$baseUrl/api/ai/test';
  static const String aiProviders = '$baseUrl/api/ai/providers';
  static const String aiVoiceInput = '$baseUrl/api/ai/voice-input';
  static const String aiVoiceOutput = '$baseUrl/api/ai/voice-output';
  static const String aiUpload = '$baseUrl/api/ai/upload';
  static const String aiAgent = '$baseUrl/api/ai/agent';
  static const String aiAgentExecute = '$baseUrl/api/ai/agent/execute';

  static const String backupCreate = '$baseUrl/api/backup/create';
  static const String backupList = '$baseUrl/api/backup/list';
  static const String backupRestore = '$baseUrl/api/backup/restore';
  static const String backupExport = '$baseUrl/api/backup/export';

  static const String search = '$baseUrl/api/search';
}
