class AppConstants {
  static const String appName = 'Arynoxtech Tally';
  static const String owner = 'Aryan Chavan';
  static const String company = 'Arynoxtech';
  static const String tagline = 'AI-Powered Smart Accounting for Small Businesses';
  static const String version = '1.0.0';

  static const List<String> accountGroups = [
    'Current Assets', 'Fixed Assets', 'Current Liabilities',
    'Long Term Liabilities', 'Equity', 'Revenue', 'Expenses',
    'Cost of Goods Sold', 'Bank Accounts', 'Cash in Hand',
    'Receivables', 'Payables', 'Duties & Taxes',
    'Direct Income', 'Indirect Income', 'Direct Expenses', 'Indirect Expenses',
  ];

  static const List<String> voucherTypes = [
    'Payment', 'Receipt', 'Sales', 'Purchase',
    'Contra', 'Journal', 'Debit Note', 'Credit Note',
  ];

  static const List<String> invoiceStatuses = [
    'Unpaid', 'Partial', 'Paid', 'Overdue', 'Cancelled',
  ];

  static const List<String> units = [
    'Pieces', 'Kilogram', 'Gram', 'Litre', 'Millilitre',
    'Meter', 'Box', 'Pack', 'Dozen', 'Bag', 'Bottle', 'Pair', 'Set', 'Roll', 'Other',
  ];
}
