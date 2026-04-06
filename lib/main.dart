import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/database_service.dart';
import 'theme/refugio_theme.dart';
import 'screens/centro_de_mando_screen.dart';
import 'screens/suministros_screen.dart';
import 'screens/frentes_de_batalla_screen.dart';
import 'screens/asistente_tactico_screen.dart';
import 'screens/fondos_screen.dart';
import 'screens/info_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: RefugioTheme.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await initializeDateFormatting('es', null);
  await DatabaseService.initialize();

  runApp(const RefugioApp());
}

class RefugioApp extends StatelessWidget {
  const RefugioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Refugio',
      debugShowCheckedModeBanner: false,
      theme: RefugioTheme.darkTheme,
      home: const RefugioShell(),
    );
  }
}

class RefugioShell extends StatefulWidget {
  const RefugioShell({super.key});

  @override
  State<RefugioShell> createState() => _RefugioShellState();
}

class _RefugioShellState extends State<RefugioShell> {
  int _currentIndex = 0;

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: RefugioTheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: RefugioTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Text('Refugio'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'v1.0',
                style: TextStyle(
                  fontFamily: RefugioTheme.fontFamily,
                  fontSize: 12,
                  color: RefugioTheme.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const CentroDeMandoScreen(),
          SuministrosScreen(onIncomeRegistered: _refresh),
          FrentesDeBatallaScreen(onPaymentMade: _refresh),
          const AsistenteTacticoScreen(),
          const FondosScreen(),
          const InfoScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: RefugioTheme.cardBorder, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Panel',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Ingresos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Pasivos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology_outlined),
              activeIcon: Icon(Icons.psychology),
              label: 'Asesor',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.savings_outlined),
              activeIcon: Icon(Icons.savings_rounded),
              label: 'Fondos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.info_outline_rounded),
              activeIcon: Icon(Icons.info_rounded),
              label: 'Info',
            ),
          ],
        ),
      ),
    );
  }
}
