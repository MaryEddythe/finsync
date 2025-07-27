import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../components/modern_card.dart';
import '../utils/animations.dart';

class WalletPage extends StatefulWidget {
  @override
  _WalletPageState createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  double _gcashBalance = 0.0;
  double _loadWalletBalance = 0.0;
  double _totalRevenue = 0.0;
  double _totalProfit = 0.0;
  double _mayaCommissionRate = 0.03;
  double _fixedMarkup = 3.0;

  late TabController _tabController;
  bool _isLoading = true;
  List<FlSpot> _revenueSpots = [];
  List<FlSpot> _profitSpots = [];

  String _selectedPeriod = 'All';
  final List<String> _periods = ['Today', 'Week', 'Month', 'All'];

  late double screenWidth;
  late double screenHeight;
  late bool isTablet;
  late bool isLargeScreen;
  late Orientation orientation;
  late double textScaleFactor;
  late EdgeInsets systemPadding;

  double _adaptiveFontSize(double value) {
    return value * (textScaleFactor.clamp(0.8, 1.5));
  }

  double _adaptiveSpacing(double value) {
    return value * (textScaleFactor.clamp(0.8, 1.2));
  }

  double _adaptiveRadius(double value) {
    return value * (textScaleFactor.clamp(0.8, 1.2));
  }

  double _adaptiveHeight(double value) {
    return value * (screenHeight / 800);
  }

  double _adaptiveSize(double value) {
    return value * (screenWidth / 400);
  }

  double _adaptiveIconSize(double value) {
    return value * (screenWidth / 400);
  }

  double _adaptivePadding(double value) {
    return value * (screenWidth / 400);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWalletData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setResponsiveValues(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    screenWidth = mediaQuery.size.width;
    screenHeight = mediaQuery.size.height;
    orientation = mediaQuery.orientation;
    textScaleFactor = mediaQuery.textScaleFactor;
    systemPadding = mediaQuery.padding;

    if (orientation == Orientation.portrait) {
      isTablet = screenWidth > 600;
      isLargeScreen = screenWidth > 900;
    } else {
      isTablet = screenHeight > 480;
      isLargeScreen = screenHeight > 700;
    }
  }

  Future<void> _loadWalletData() async {
    setState(() {
      _isLoading = true;
    });

    final balancesBox = Hive.box('balances');
    final transactionsBox = Hive.box('transactions');

    double gcashBalance = balancesBox.get('gcash', defaultValue: 0.0);
    double loadWalletBalance = balancesBox.get('load', defaultValue: 0.0);
    double revenue = 0.0;
    double profit = 0.0;

    Map<int, double> revenueByDay = {};
    Map<int, double> profitByDay = {};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var tx in transactionsBox.values) {
      if (tx['date'] == null) continue;

      DateTime? txDate;
      try {
        txDate = DateTime.tryParse(tx['date']);
      } catch (_) {
        continue;
      }
      if (txDate == null) continue;

      int daysSinceEpoch = txDate.difference(DateTime(2023, 1, 1)).inDays;

      if (tx['type'] == 'load') {
        double customerPays = (tx['customerPays'] ?? 0.0).toDouble();
        double deducted = (tx['deducted'] ?? 0.0).toDouble();
        double txProfit = customerPays - deducted;

        revenue += customerPays;
        profit += txProfit;

        revenueByDay[daysSinceEpoch] =
            (revenueByDay[daysSinceEpoch] ?? 0) + customerPays;
        profitByDay[daysSinceEpoch] =
            (profitByDay[daysSinceEpoch] ?? 0) + txProfit;
      } else if (tx['type'] == 'gcash_in' || tx['type'] == 'gcash_out') {
        double amount = (tx['amount'] ?? 0.0).toDouble();
        double serviceFee = (tx['serviceFee'] ?? 0.0).toDouble();
        revenue += amount;
        profit += serviceFee;

        revenueByDay[daysSinceEpoch] = (revenueByDay[daysSinceEpoch] ?? 0) + amount;
        profitByDay[daysSinceEpoch] = (profitByDay[daysSinceEpoch] ?? 0) + serviceFee;
      }
    }

    List<int> sortedDays = revenueByDay.keys.toList()..sort();
    _revenueSpots = [];
    _profitSpots = [];

    if (sortedDays.isNotEmpty) {
      for (int i = 0; i < 7; i++) {
        int day =
            sortedDays.length > i ? sortedDays[sortedDays.length - 1 - i] : 0;
        double dayRevenue = revenueByDay[day] ?? 0;
        double dayProfit = profitByDay[day] ?? 0;

        _revenueSpots.insert(0, FlSpot(i.toDouble(), dayRevenue));
        _profitSpots.insert(0, FlSpot(i.toDouble(), dayProfit));
      }
    } else {
      for (int i = 0; i < 7; i++) {
        _revenueSpots.add(FlSpot(i.toDouble(), 0));
        _profitSpots.add(FlSpot(i.toDouble(), 0));
      }
    }

    setState(() {
      _gcashBalance = gcashBalance;
      _loadWalletBalance = loadWalletBalance;
      _totalRevenue = revenue;
      _totalProfit = profit;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    _setResponsiveValues(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: _isLoading
          ? _buildLoadingView()
          : CustomScrollView(
              slivers: [
                _buildModernAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildBalanceOverview(),
                      _buildQuickStats(),
                      _buildTabSection(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Loading your wallet...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait while we fetch your data',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryDark,
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          title: Text(
            'My Wallet',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: false,
          titlePadding: EdgeInsets.only(left: 20, bottom: 16),
          background: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good ${_getGreeting()}!',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Track your financial progress',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.refresh_rounded, color: Colors.white),
                          onPressed: _loadWalletData,
                          tooltip: 'Refresh Data',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildBalanceOverview() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Balance',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'PHP ${(_gcashBalance + _loadWalletBalance).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildBalanceItem(
                  'GCash Wallet',
                  _gcashBalance,
                  Icons.payment,
                  AppTheme.accentColor,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildBalanceItem(
                  'Load Wallet',
                  _loadWalletBalance,
                  Icons.phone_android,
                  AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            'PHP ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Revenue',
              _totalRevenue,
              Icons.trending_up,
              AppTheme.successColor,
              'Total earnings',
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Profit',
              _totalProfit,
              Icons.monetization_on,
              AppTheme.warningColor,
              'Net profit',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, double amount, IconData icon, Color color, String subtitle) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              Spacer(),
              Icon(
                Icons.more_horiz,
                color: AppTheme.textTertiary,
                size: 20,
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'PHP ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      margin: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.softShadow,
              ),
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'Analytics'),
                Tab(text: 'Transactions'),
              ],
            ),
          ),
          Container(
            height: 600,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAnalyticsView(),
                _buildTransactionsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsView() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue & Profit Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Track your earnings over the last 7 days',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 24),
          Container(
            height: 250,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade300,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final style = TextStyle(
                          color: AppTheme.textTertiary,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        );
                        Widget text;
                        switch (value.toInt()) {
                          case 0:
                            text = Text('Day 1', style: style);
                            break;
                          case 2:
                            text = Text('Day 3', style: style);
                            break;
                          case 4:
                            text = Text('Day 5', style: style);
                            break;
                          case 6:
                            text = Text('Day 7', style: style);
                            break;
                          default:
                            text = Text('', style: style);
                            break;
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: text,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return const Text('');
                        }
                        return Text(
                          'PHP ${value.toInt()}',
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 50,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: _revenueSpots,
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppTheme.primaryColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: _profitSpots,
                    isCurved: true,
                    color: AppTheme.successColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppTheme.successColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.successColor.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          'PHP ${spot.y.toStringAsFixed(2)}',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Revenue', AppTheme.primaryColor),
              SizedBox(width: 32),
              _buildLegendItem('Profit', AppTheme.successColor),
            ],
          ),
          SizedBox(height: 24),
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: _buildRecentTransactionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsView() {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: _buildTransactionList(),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _periods.length,
        itemBuilder: (context, index) {
          final period = _periods[index];
          final isSelected = period == _selectedPeriod;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPeriod = period;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Text(
                period,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionList() {
    final transactionsBox = Hive.box('transactions');
    final allTransactions = transactionsBox.values.toList().reversed.toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final filteredTransactions = allTransactions.where((tx) {
      if (_selectedPeriod == 'All') return true;

      if (tx['date'] == null) return false;

      final txDate = DateTime.parse(tx['date']);

      if (_selectedPeriod == 'Today') {
        return txDate.year == today.year &&
            txDate.month == today.month &&
            txDate.day == today.day;
      } else if (_selectedPeriod == 'Week') {
        final weekAgo = today.subtract(Duration(days: 7));
        return txDate.isAfter(weekAgo);
      } else if (_selectedPeriod == 'Month') {
        final monthAgo = today.subtract(Duration(days: 30));
        return txDate.isAfter(monthAgo);
      }

      return false;
    }).toList();

    if (filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: AppTheme.textTertiary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _selectedPeriod == 'All'
                  ? 'Start by adding a transaction'
                  : 'Try a different time period',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(24),
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        return _buildTransactionItem(filteredTransactions[index]);
      },
    );
  }

  Widget _buildRecentTransactionsList() {
    final transactionsBox = Hive.box('transactions');
    final transactions = transactionsBox.values.toList().reversed.take(3).toList();

    if (transactions.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 32,
              color: AppTheme.textTertiary,
            ),
            SizedBox(height: 12),
            Text(
              'No recent transactions',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: transactions.map((tx) => _buildTransactionItem(tx, isCompact: true)).toList(),
    );
  }

  Widget _buildTransactionItem(dynamic tx, {bool isCompact = false}) {
    String type = tx['type'] ?? '';
    String title = '';
    String subtitle = '';
    Color amountColor = Colors.black;
    double amount = 0.0;
    bool isIncome = false;
    IconData icon;
    Color iconBgColor;
    Color iconColor;

    String formattedDate = '';
    if (tx['date'] != null) {
      DateTime txDate = DateTime.parse(tx['date']);
      formattedDate = isCompact 
          ? DateFormat('MMM dd').format(txDate)
          : DateFormat('MMM dd, yyyy • hh:mm a').format(txDate);
    }

    if (type == 'load') {
      title = 'Load Sale';
      double customerPays = tx['customerPays'] ?? 0.0;
      double deducted = tx['deducted'] ?? 0.0;
      double profit = customerPays - deducted;
      subtitle = 'Profit: PHP ${profit.toStringAsFixed(2)}';
      amount = customerPays;
      amountColor = AppTheme.successColor;
      isIncome = true;
      icon = Icons.phone_android;
      iconColor = Colors.blue[700]!;
      iconBgColor = Colors.blue[50]!;
    } else if (type == 'gcash_in') {
      title = 'GCash Cash In';
      amount = tx['amount'] ?? 0.0;
      double serviceFee = tx['serviceFee'] ?? 0.0;
      subtitle = 'Fee: PHP ${serviceFee.toStringAsFixed(2)}';
      amountColor = AppTheme.errorColor;
      isIncome = false;
      icon = Icons.arrow_upward;
      iconColor = Colors.green[700]!;
      iconBgColor = Colors.green[50]!;
    } else if (type == 'gcash_out') {
      title = 'GCash Cash Out';
      amount = tx['amount'] ?? 0.0;
      double serviceFee = tx['serviceFee'] ?? 0.0;
      subtitle = 'Fee: PHP ${serviceFee.toStringAsFixed(2)}';
      amountColor = AppTheme.successColor;
      isIncome = true;
      icon = Icons.arrow_downward;
      iconColor = Colors.red[700]!;
      iconBgColor = Colors.red[50]!;
    } else {
      title = type;
      amount = tx['amount'] ?? 0.0;
      subtitle = '';
      amountColor = AppTheme.textPrimary;
      icon = Icons.help_outline;
      iconColor = AppTheme.textSecondary;
      iconBgColor = Colors.grey[100]!;
    }

    return Container(
      margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isCompact ? null : () => _showTransactionDetails(tx),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isCompact ? 14 : 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  if (subtitle.isNotEmpty && !isCompact) ...[
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}PHP ${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                    fontSize: isCompact ? 14 : 16,
                  ),
                ),
                if (subtitle.isNotEmpty && isCompact) ...[
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(dynamic transaction) {
    String type = transaction['type'] ?? '';
    String title = '';
    IconData icon;
    Color iconColor;

    if (type == 'load') {
      title = 'Load Sale';
      icon = Icons.phone_android;
      iconColor = Colors.blue;
    } else if (type == 'gcash_in') {
      title = 'GCash Cash In';
      icon = Icons.arrow_upward;
      iconColor = Colors.green;
    } else if (type == 'gcash_out') {
      title = 'GCash Cash Out';
      icon = Icons.arrow_downward;
      iconColor = Colors.red;
    } else if (type == 'topup') {
      title = 'Load Wallet Top-up';
      icon = Icons.add_circle_outline;
      iconColor = Colors.orange;
    } else if (type == 'gcash_topup') {
      title = 'GCash Top-up';
      icon = Icons.account_balance_wallet;
      iconColor = Colors.purple;
    } else {
      title = type;
      icon = Icons.help_outline;
      iconColor = Colors.grey;
    }

    String formattedDate = '';
    String formattedTime = '';
    if (transaction['date'] != null) {
      DateTime? txDate;
      try {
        txDate = DateTime.tryParse(transaction['date']);
      } catch (_) {
        txDate = null;
      }
      if (txDate != null) {
        formattedDate = DateFormat('MMMM dd, yyyy').format(txDate);
        formattedTime = DateFormat('hh:mm a').format(txDate);
      }
    }

    _showTransactionDetailsBottomSheet(
        transaction, title, icon, iconColor, formattedDate, formattedTime);
  }

  void _showTransactionDetailsBottomSheet(
      dynamic transaction,
      String title,
      IconData icon,
      Color iconColor,
      String formattedDate,
      String formattedTime) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(24),
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            icon,
                            color: iconColor,
                            size: 32,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: AppTheme.successColor,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Completed',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.successColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildDetailItem('Date', formattedDate, Icons.calendar_today),
                          Divider(height: 32, color: Colors.grey[300]),
                          _buildDetailItem('Time', formattedTime, Icons.access_time),
                          Divider(height: 32, color: Colors.grey[300]),
                          _buildDetailItem('Transaction ID', '#${transaction.key}', Icons.tag),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Transaction Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: _buildTransactionDetailItems(transaction,
                            type: transaction['type'] ?? ''),
                      ),
                    ),
                    SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.share, size: 18),
                            label: Text('Share'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.delete_outline, size: 18),
                            label: Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                              foregroundColor: AppTheme.errorColor,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppTheme.textSecondary,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTransactionDetailItems(dynamic transaction, {required String type}) {
    List<Widget> items = [];

    if (type == 'load') {
      items = [
        _buildDetailItem(
          'Customer Pays',
          'PHP ${(transaction['customerPays'] ?? 0.0).toStringAsFixed(2)}',
          Icons.payments,
        ),
        Divider(height: 32),
        _buildDetailItem(
          'Wallet Deducted',
          'PHP ${(transaction['deducted'] ?? 0.0).toStringAsFixed(2)}',
          Icons.account_balance_wallet,
        ),
        if (transaction['commission'] != null) ...[
          Divider(height: 32),
          _buildDetailItem(
            'Commission',
            'PHP ${(transaction['commission'] ?? 0.0).toStringAsFixed(2)}',
            Icons.currency_exchange,
          ),
        ],
      ];
    } else if (type == 'gcash_in' || type == 'gcash_out') {
      items = [
        _buildDetailItem(
          'Amount',
          'PHP ${(transaction['amount'] ?? 0.0).toStringAsFixed(2)}',
          Icons.payments,
        ),
        if (transaction['serviceFee'] != null) ...[
          Divider(height: 32),
          _buildDetailItem(
            'Service Fee',
            'PHP ${(transaction['serviceFee'] ?? 0.0).toStringAsFixed(2)}',
            Icons.currency_exchange,
          ),
        ],
      ];
    } else {
      items = [
        _buildDetailItem(
          'Amount',
          'PHP ${(transaction['amount'] ?? 0.0).toStringAsFixed(2)}',
          Icons.payments,
        ),
      ];
    }

    return items;
  }
}
