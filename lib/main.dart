import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';

import 'pages/home_page.dart';
import 'pages/calc_page.dart';
import 'pages/wallet_page.dart' as wallet;
import 'pages/history_page.dart' as history;
import 'pages/report_page.dart'; // Make sure this file exists and contains a ReportPage widget

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

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
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        color: Colors.deepPurple,
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Loading your data...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.deepPurple),
          titleTextStyle: TextStyle(
            color: Colors.deepPurple,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: BottomNavPage(),
    );
  }
}

class BottomNavPage extends StatefulWidget {
  @override
  _BottomNavPageState createState() => _BottomNavPageState();
}

class _BottomNavPageState extends State<BottomNavPage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(), // Home
    CalcPage(), // Calc
    wallet.WalletPage(), // Wallet
    history.HistoryPage(), // History
    ReportPage(), // Report
  ];

  final List<String> _titles = [
    'Home',
    'Calculator',
    'Wallet',
    'History',
    'Reports'
  ];

  final List<IconData> _icons = [
    Icons.home_rounded,
    Icons.calculate_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.history_rounded,
    Icons.bar_chart_rounded,
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page content
          _pages[_selectedIndex],

          // Bottom navigation bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavigationBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 70,
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _pages.length,
              (index) => _buildNavItem(index, screenWidth),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, double screenWidth) {
    final isSelected = _selectedIndex == index;

    // Calculate item width based on screen size
    final itemWidth = (screenWidth - 32) / _pages.length;
    final labelWidth = itemWidth * 0.8;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        width: itemWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with animated container for selected state
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.deepPurple
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  _icons[index],
                  color: isSelected
                      ? Colors.white
                      : Colors.grey[600],
                  size: 24,
                ),
              ),
            ),

            // Label with animation
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: 20,
              width: labelWidth,
              alignment: Alignment.center,
              child: Text(
                _titles[index],
                style: TextStyle(
                  color: isSelected
                      ? Colors.deepPurple
                      : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),

            // Indicator dot for selected item
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: 4,
              width: isSelected ? 20 : 0,
              margin: EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.deepPurple : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
