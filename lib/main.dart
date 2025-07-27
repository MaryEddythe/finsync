import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pages/home_page.dart';
import 'pages/calc_page.dart';
import 'pages/wallet_page.dart' as wallet;
import 'pages/history_page.dart' as history;
import 'pages/report_page.dart';
import 'theme/app_theme.dart';
import 'components/modern_bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AppInitializer());
}

class AppInitializer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initHive(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return FinSyncApp();
      },
    );
  }

  Future<void> _initHive() async {
    await Hive.initFlutter();
    await Hive.openBox('transactions');
    await Hive.openBox('balances'); // <-- Add this line
  }
}

class FinSyncApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinSync - Smart Finance Tracker',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: BottomNavPage(),
    );
  }
}

class BottomNavPage extends StatefulWidget {
  @override
  _BottomNavPageState createState() => _BottomNavPageState();
}

class _BottomNavPageState extends State<BottomNavPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),                // Home
    CalcPage(),                // Calc
    wallet.WalletPage(),       // Wallet
    history.HistoryPage(),     // History
    ReportPage(),              // Report
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_selectedIndex],
      bottomNavigationBar: ModernBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
