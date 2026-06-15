import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'core/utils/keyboard_shortcuts.dart';
import 'core/services/voice_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/dashboard_provider.dart';
import 'presentation/providers/account_provider.dart';
import 'presentation/providers/customer_provider.dart';
import 'presentation/providers/supplier_provider.dart';
import 'presentation/providers/inventory_provider.dart';
import 'presentation/providers/invoice_provider.dart';
import 'presentation/providers/expense_provider.dart';
import 'presentation/providers/ai_provider.dart';
import 'presentation/providers/backup_provider.dart';
import 'presentation/providers/search_provider.dart';
import 'presentation/providers/enterprise_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ArynoxtechTallyApp());
}

class ArynoxtechTallyApp extends StatelessWidget {
  const ArynoxtechTallyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => AIProvider()),
        ChangeNotifierProvider(create: (_) => BackupProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => EnterpriseProvider()),
        ChangeNotifierProvider(create: (_) => VoiceService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return TallyKeyboardShortcuts(
            getContext: () => navigatorKey.currentContext!,
            child: MaterialApp(
              navigatorKey: navigatorKey,
              title: 'Arynoxtech Tally',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              initialRoute: AppRoutes.splash,
              onGenerateRoute: AppRoutes.generateRoute,
            ),
          );
        },
      ),
    );
  }
}
