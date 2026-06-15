import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';

class VoucherScreen extends StatelessWidget {
  const VoucherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vouchers'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () => Navigator.pushNamed(context, AppRoutes.createVoucher)),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _voucherCard(context, 'Payment', Icons.payment, Colors.red),
          _voucherCard(context, 'Receipt', Icons.receipt, Colors.green),
          _voucherCard(context, 'Sales', Icons.shopping_cart, Colors.blue),
          _voucherCard(context, 'Purchase', Icons.shopping_bag, Colors.orange),
          _voucherCard(context, 'Contra', Icons.swap_horiz, Colors.purple),
          _voucherCard(context, 'Journal', Icons.description, Colors.indigo),
          _voucherCard(context, 'Debit Note', Icons.arrow_downward, Colors.amber),
          _voucherCard(context, 'Credit Note', Icons.arrow_upward, Colors.teal),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createVoucher),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _voucherCard(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Create $title voucher'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(context, AppRoutes.createVoucher, arguments: title),
      ),
    );
  }
}
