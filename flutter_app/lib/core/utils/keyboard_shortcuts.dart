import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/routes/app_routes.dart';

class TallyKeyboardShortcuts extends StatelessWidget {
  final Widget child;
  final BuildContext Function() getContext;

  const TallyKeyboardShortcuts({
    super.key,
    required this.child,
    required this.getContext,
  });

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.f2): () => _navigate(AppRoutes.chartOfAccounts),
        SingleActivator(LogicalKeyboardKey.f3): () => _navigate(AppRoutes.customers),
        SingleActivator(LogicalKeyboardKey.f4): () => _navigate(AppRoutes.suppliers),
        SingleActivator(LogicalKeyboardKey.f5): () => _navigate(AppRoutes.products),
        SingleActivator(LogicalKeyboardKey.f6): () => _navigate(AppRoutes.invoices),
        SingleActivator(LogicalKeyboardKey.f7): () => _navigate(AppRoutes.vouchers),
        SingleActivator(LogicalKeyboardKey.f8): () => _navigate(AppRoutes.pos),
        SingleActivator(LogicalKeyboardKey.f9): () => _navigate(AppRoutes.expenses),
        SingleActivator(LogicalKeyboardKey.f10): () => _navigate(AppRoutes.trialBalance),
        SingleActivator(LogicalKeyboardKey.f11): () => _navigate(AppRoutes.profitLoss),
        SingleActivator(LogicalKeyboardKey.f12): () => _navigate(AppRoutes.balanceSheet),
        SingleActivator(LogicalKeyboardKey.keyA, control: true): () => _navigate(AppRoutes.chartOfAccounts),
        SingleActivator(LogicalKeyboardKey.keyC, control: true): () => _navigate(AppRoutes.customers),
        SingleActivator(LogicalKeyboardKey.keyI, control: true): () => _navigate(AppRoutes.invoices),
        SingleActivator(LogicalKeyboardKey.keyP, control: true): () => _navigate(AppRoutes.products),
        SingleActivator(LogicalKeyboardKey.keyS, control: true): () => _navigate(AppRoutes.settings),
        SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(getContext()).pop(),
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }

  void _navigate(String route) {
    final ctx = getContext();
    if (ctx.mounted) {
      Navigator.of(ctx).pushNamed(route);
    }
  }
}
