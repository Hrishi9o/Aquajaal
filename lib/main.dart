import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/app_theme.dart';
import 'data/services/cloud_sync_service.dart';
import 'data/services/local_db_service.dart';
import 'providers/theme_provider.dart';
import 'providers/stock_provider.dart';
import 'providers/pos_provider.dart';
import 'providers/sales_provider.dart';
import 'presentation/navigation/app_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline-first Hive storage engine
  await LocalDbService.instance.init();

  // Initialize cloud synchronization bridge
  await CloudSyncService.instance.init();

  runApp(const AquajaalPosApp());
}

class AquajaalPosApp extends StatelessWidget {
  const AquajaalPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => StockProvider()),
        ChangeNotifierProvider(create: (_) => PosProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: themeProvider.themeMode,
            home: const AppScaffold(),
          );
        },
      ),
    );
  }
}
