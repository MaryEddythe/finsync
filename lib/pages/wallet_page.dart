import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

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

  // For transaction filtering
  String _selectedPeriod = 'All';
  final List<String> _periods = ['Today', 'Week', 'Month', 'All'];

  // For responsive design
  late double screenWidth;
  late double screenHeight;
  late bool isTablet;
  late bool isLargeScreen;
  late Orientation orientation;
  late double textScaleFactor;
  late EdgeInsets systemPadding;

  double _adaptiveFontSize(double value) {
    // Adjust font size based on textScaleFactor for accessibility
    return value * (textScaleFactor.clamp(0.8, 1.5));
  }

  double _adaptiveSpacing(double value) {
    // You can adjust the scaling logic as needed for your app
    return value * (textScaleFactor.clamp(0.8, 1.2));
  }

  double _adaptiveRadius(double value) {
    // Adjust border radius based on textScaleFactor or screen size
    return value * (textScaleFactor.clamp(0.8, 1.2));
  }

  double _adaptiveHeight(double value) {
    return value * (screenHeight / 800); // Base height of 800
  }

  double _adaptiveSize(double value) {
    return value * (screenWidth / 400); // Base width of 400
  }

  double _adaptiveIconSize(double value) {
    return value * (screenWidth / 400); // Base width of 400
  }

  double _adaptivePadding(double value) {
    return value * (screenWidth / 400); // Base width of 400
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

  // Set up responsive values based on screen size and orientation
  void _setResponsiveValues(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    screenWidth = mediaQuery.size.width;
    screenHeight = mediaQuery.size.height;
    orientation = mediaQuery.orientation;
    textScaleFactor = mediaQuery.textScaleFactor;
    systemPadding = mediaQuery.padding;

    // Adjust breakpoints based on orientation
    if (orientation == Orientation.portrait) {
      isTablet = screenWidth > 600;
      isLargeScreen = screenWidth > 900;
    } else {
      // In landscape, use height as the primary factor
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

    // For chart data
    Map<int, double> revenueByDay = {};
    Map<int, double> profitByDay = {};

    // Get current date for filtering
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
        // Update profit calculation - it's simply customer pays minus deducted amount
        double txProfit = customerPays - deducted;

        revenue += customerPays;
        profit += txProfit;

        // Add to chart data
        revenueByDay[daysSinceEpoch] =
            (revenueByDay[daysSinceEpoch] ?? 0) + customerPays;
        profitByDay[daysSinceEpoch] =
            (profitByDay[daysSinceEpoch] ?? 0) + txProfit;
      } else if (tx['type'] == 'gcash_in' || tx['type'] == 'gcash_out') {
        double amount = (tx['amount'] ?? 0.0).toDouble();
        double serviceFee = (tx['serviceFee'] ?? 0.0).toDouble();
        revenue += amount;
        profit += serviceFee; // Add service fee to total profit

        // Add to chart data
        revenueByDay[daysSinceEpoch] = (revenueByDay[daysSinceEpoch] ?? 0) + amount;
        profitByDay[daysSinceEpoch] = (profitByDay[daysSinceEpoch] ?? 0) + serviceFee;
      }
    }

    // Convert map to list of FlSpots for chart
    List<int> sortedDays = revenueByDay.keys.toList()..sort();
    _revenueSpots = [];
    _profitSpots = [];

    if (sortedDays.isNotEmpty) {
      for (int i = 0; i < 7; i++) {
        int day =
            sortedDays.length > i ? sortedDays[sortedDays.length - 1 - i] : 0;
        double dayRevenue = revenueByDay[day] ?? 0;
        double dayProfit = profitByDay[day] ?? 0;

        // Add in reverse order (oldest first)
        _revenueSpots.insert(0, FlSpot(i.toDouble(), dayRevenue));
        _profitSpots.insert(0, FlSpot(i.toDouble(), dayProfit));
      }
    } else {
      // Add dummy data if no transactions
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
      body: _isLoading
          ? _buildLoadingView()
          : OrientationBuilder(
              builder: (context, orientation) {
                return _buildMainView(orientation);
              },
            ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6B48FF), Color(0xFF8A72FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: _adaptiveSpacing(16)),
            Text(
              'Loading wallet data...',
              style: TextStyle(
                color: Colors.white,
                fontSize: _adaptiveFontSize(16),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainView(Orientation currentOrientation) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
      ),
      child: SafeArea(
        child: currentOrientation == Orientation.portrait
            ? _buildPortraitLayout()
            : _buildLandscapeLayout(),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: _adaptiveHeight(280),
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(),
            ),
          ),
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: Color(0xFF6B48FF),
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Color(0xFF6B48FF),
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'ANALYTICS'),
                  Tab(text: 'TRANSACTIONS'),
                ],
              ),
            ),
            pinned: true,
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          // Make analytics tab scrollable
          // Apply primary: false and ClampingScrollPhysics for better coordination
          // with NestedScrollView.
          SingleChildScrollView(
            primary: false,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.zero,
            child: _buildAnalyticsTab(),
          ),
          // Transactions tab: filter chips pinned, list scrolls
          Column(
            children: [
              _buildFilterChips(),
              Expanded(
                child: _buildTransactionList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Left panel with header
        Container(
          width: screenWidth * 0.35,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6B48FF), Color(0xFF8A72FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(_adaptiveRadius(30)),
              bottomRight: Radius.circular(_adaptiveRadius(30)),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(_adaptivePadding(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Wallet',
                        style: TextStyle(
                          fontSize: _adaptiveFontSize(24),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadWalletData,
                        tooltip: 'Refresh Data',
                        iconSize: _adaptiveIconSize(20),
                      ),
                    ],
                  ),
                  SizedBox(height: _adaptiveSpacing(20)),
                  Text(
                    'Total Balance',
                    style: TextStyle(
                      fontSize: _adaptiveFontSize(14),
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(height: _adaptiveSpacing(8)),
                  Text(
                    'PHP ${(_gcashBalance + _loadWalletBalance).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: _adaptiveFontSize(28),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: _adaptiveSpacing(20)),
                  _buildBalanceCard(
                    'GCash',
                    _gcashBalance,
                    Icons.account_balance_wallet,
                  ),
                  SizedBox(height: _adaptiveSpacing(12)),
                  _buildBalanceCard(
                    'Load Wallet',
                    _loadWalletBalance,
                    Icons.phone_android,
                  ),
                  Expanded(child: SizedBox()),
                  // Navigation buttons for landscape mode
                ],
              ),
            ),
          ),
        ),
        // Right panel with content
        Expanded(
          child: Column(
            children: [
              // Tab bar for landscape mode
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Color(0xFF6B48FF),
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Color(0xFF6B48FF),
                  indicatorWeight: 3,
                  tabs: [
                    Tab(text: 'ANALYTICS'),
                    Tab(text: 'TRANSACTIONS'),
                  ],
                ),
              ),
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAnalyticsTab(),
                    _buildTransactionsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6B48FF), Color(0xFF8A72FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(_adaptiveRadius(30)),
          bottomRight: Radius.circular(_adaptiveRadius(30)),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(_adaptivePadding(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Wallet',
                  style: TextStyle(
                    fontSize: _adaptiveFontSize(28),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadWalletData,
                  tooltip: 'Refresh Data',
                  iconSize: _adaptiveIconSize(24),
                ),
              ],
            ),
            SizedBox(height: _adaptiveSpacing(20)),
            Text(
              'Total Balance',
              style: TextStyle(
                fontSize: _adaptiveFontSize(16),
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            SizedBox(height: _adaptiveSpacing(8)),
            Text(
              'PHP ${(_gcashBalance + _loadWalletBalance).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: _adaptiveFontSize(32),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: _adaptiveSpacing(20)),
            // Use Flex for better responsiveness on different screen sizes
            Flex(
              direction: Axis.horizontal,
              children: [
                Expanded(
                  child: _buildBalanceCard(
                    'GCash',
                    _gcashBalance,
                    Icons.account_balance_wallet,
                  ),
                ),
                SizedBox(width: _adaptiveSpacing(16)),
                Expanded(
                  child: _buildBalanceCard(
                    'Load Wallet',
                    _loadWalletBalance,
                    Icons.phone_android,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(String title, double amount, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: _adaptivePadding(16), vertical: _adaptivePadding(12)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(_adaptiveRadius(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(_adaptivePadding(8)),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(_adaptiveRadius(12)),
            ),
            child: Icon(icon, color: Colors.white, size: _adaptiveIconSize(20)),
          ),
          SizedBox(width: _adaptiveSpacing(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _adaptiveFontSize(14),
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: _adaptiveSpacing(4)),
                Text(
                  'PHP ${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: _adaptiveFontSize(16),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Padding(
      padding: EdgeInsets.all(_adaptivePadding(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(MediaQuery.of(context).size.width > 600),
          SizedBox(height: _adaptiveSpacing(24)),
          _buildChartSection(),
          SizedBox(height: _adaptiveSpacing(24)),
          _buildRecentTransactionsSection(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(bool isWideLayout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: TextStyle(
            fontSize: _adaptiveFontSize(18),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: _adaptiveSpacing(16)),
        isWideLayout
            ? _buildWideLayoutSummaryCards()
            : _buildNarrowLayoutSummaryCards(),
      ],
    );
  }

  Widget _buildWideLayoutSummaryCards() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Revenue',
            _totalRevenue,
            Icons.trending_up,
            Color(0xFF6B48FF),
          ),
        ),
        SizedBox(width: _adaptiveSpacing(16)),
        Expanded(
          child: _buildSummaryCard(
            'Total Profit',
            _totalProfit,
            Icons.attach_money,
            Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayoutSummaryCards() {
    return Column(
      children: [
        _buildSummaryCard(
          'Total Revenue',
          _totalRevenue,
          Icons.trending_up,
          Color(0xFF6B48FF),
        ),
        SizedBox(height: _adaptiveSpacing(16)),
        _buildSummaryCard(
          'Total Profit',
          _totalProfit,
          Icons.attach_money,
          Color(0xFF4CAF50),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, double amount, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(_adaptivePadding(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_adaptiveRadius(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(_adaptivePadding(8)),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(_adaptiveRadius(8)),
                ),
                child: Icon(icon, color: color, size: _adaptiveIconSize(16)),
              ),
              SizedBox(width: _adaptiveSpacing(8)),
              Text(
                title,
                style: TextStyle(
                  fontSize: _adaptiveFontSize(14),
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: _adaptiveSpacing(12)),
          Text(
            'PHP ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: _adaptiveFontSize(20),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      padding: EdgeInsets.all(_adaptivePadding(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_adaptiveRadius(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue & Profit Trend',
                style: TextStyle(
                  fontSize: _adaptiveFontSize(16),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: _adaptivePadding(12),
                    vertical: _adaptivePadding(6)),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(_adaptiveRadius(20)),
                ),
                child: Text(
                  'Last 7 Days',
                  style: TextStyle(
                    fontSize: _adaptiveFontSize(12),
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _adaptiveSpacing(24)),
          // Use LayoutBuilder to make chart responsive
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                height: _adaptiveHeight(200),
                width: constraints.maxWidth,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1000,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey[200],
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          getTitlesWidget: (value, meta) {
                            final style = TextStyle(
                              color: Color(0xff72719b),
                              fontWeight: FontWeight.normal,
                              fontSize: _adaptiveFontSize(10),
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
                                color: Color(0xff75729e),
                                fontWeight: FontWeight.normal,
                                fontSize: _adaptiveFontSize(10),
                              ),
                            );
                          },
                          reservedSize: 40,
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    minX: 0,
                    maxX: 6,
                    minY: 0,
                    lineBarsData: [
                      LineChartBarData(
                        spots: _revenueSpots,
                        isCurved: true,
                        color: Color(0xFF6B48FF),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Color(0xFF6B48FF).withOpacity(0.2),
                        ),
                      ),
                      LineChartBarData(
                        spots: _profitSpots,
                        isCurved: true,
                        color: Color(0xFF4CAF50),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Color(0xFF4CAF50).withOpacity(0.2),
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
                                color: spot.barIndex == 0
                                    ? Colors.purple.shade100
                                    : Colors.green.shade100,
                                fontWeight: FontWeight.bold,
                                fontSize: _adaptiveFontSize(12),
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
                );
            },
          ),
          SizedBox(height: _adaptiveSpacing(16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Revenue', Color(0xFF6B48FF)),
              SizedBox(width: _adaptiveSpacing(24)),
              _buildLegendItem('Profit', Color(0xFF4CAF50)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(
          width: _adaptiveSize(12),
          height: _adaptiveSize(12),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: _adaptiveSpacing(8)),
        Text(
          title,
          style: TextStyle(
            fontSize: _adaptiveFontSize(12),
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: _adaptiveFontSize(18),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {
                _tabController.animateTo(1);
              },
              child: Text(
                'See All',
                style: TextStyle(
                  color: Color(0xFF6B48FF),
                  fontWeight: FontWeight.w600,
                  fontSize: _adaptiveFontSize(14),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: _adaptiveSpacing(16)),
        _buildRecentTransactionsList(),
      ],
    );
  }

  Widget _buildRecentTransactionsList() {
    final transactionsBox = Hive.box('transactions');
    final transactions =
        transactionsBox.values.toList().reversed.take(3).toList();

    if (transactions.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: _adaptivePadding(32)),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              Icons.receipt_long,
              size: _adaptiveIconSize(48),
              color: Colors.grey[400],
            ),
            SizedBox(height: _adaptiveSpacing(16)),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: _adaptiveFontSize(16),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideLayout = constraints.maxWidth > 600;

        if (isWideLayout) {
          // Grid layout for wider screens
          return GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth > 900 ? 3 : 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: _adaptiveSpacing(12),
              mainAxisSpacing: _adaptiveSpacing(12),
            ),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              return _buildTransactionItem(transactions[index]);
            },
          );
        } else {
          // List layout for narrower screens
          return Column(
            children:
                transactions.map((tx) => _buildTransactionItem(tx)).toList(),
          );
        }
      },
    );
  }

  Widget _buildTransactionsTab() {
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
      height: _adaptiveHeight(50),
      padding: EdgeInsets.symmetric(horizontal: _adaptivePadding(16)),
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
              margin: EdgeInsets.only(
                  right: _adaptiveSpacing(8), top: _adaptiveSpacing(8)),
              padding: EdgeInsets.symmetric(
                  horizontal: _adaptivePadding(16),
                  vertical: _adaptivePadding(8)),
              decoration: BoxDecoration(
                color: isSelected ? Color(0xFF6B48FF) : Colors.white,
                borderRadius: BorderRadius.circular(_adaptiveRadius(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                period,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: _adaptiveFontSize(14),
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

    // Filter transactions based on selected period
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
            Icon(
              Icons.receipt_long,
              size: _adaptiveIconSize(64),
              color: Colors.grey[400],
            ),
            SizedBox(height: _adaptiveSpacing(16)),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: _adaptiveFontSize(18),
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: _adaptiveSpacing(8)),
            Text(
              _selectedPeriod == 'All'
                  ? 'Start by adding a transaction'
                  : 'Try a different time period',
              style: TextStyle(
                fontSize: _adaptiveFontSize(14),
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideLayout = constraints.maxWidth > 600;

        if (isWideLayout) {
          // Grid layout for wider screens
          return GridView.builder(
            padding: EdgeInsets.all(_adaptivePadding(16)),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth > 900 ? 3 : 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: _adaptiveSpacing(12),
              mainAxisSpacing: _adaptiveSpacing(12),
            ),
            itemCount: filteredTransactions.length,
            itemBuilder: (context, index) {
              return _buildTransactionItem(filteredTransactions[index]);
            },
          );
        } else {
          // List layout for narrower screens
          return ListView.builder(
            padding: EdgeInsets.all(_adaptivePadding(16)),
            itemCount: filteredTransactions.length,
            itemBuilder: (context, index) {
              return _buildTransactionItem(filteredTransactions[index]);
            },
          );
        }
      },
    );
  }

  Widget _buildTransactionItem(dynamic tx) {
    String type = tx['type'] ?? '';
    String title = '';
    String subtitle = '';
    Color amountColor = Colors.black;
    double amount = 0.0;
    bool isIncome = false;
    IconData icon;
    Color iconBgColor;
    
    // Format date
    String formattedDate = '';
    if (tx['date'] != null) {
      DateTime txDate = DateTime.parse(tx['date']);
      formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(txDate);
    }

    if (type == 'load') {
      title = 'Load Sale';
      double customerPays = tx['customerPays'] ?? 0.0;
      double deducted = tx['deducted'] ?? 0.0;
      double profit = customerPays - deducted;
      subtitle = 'Profit: PHP ${profit.toStringAsFixed(2)}';
      amount = customerPays;
      amountColor = Color(0xFF4CAF50);
      isIncome = true;
      icon = Icons.phone_android;
      iconBgColor = Colors.blue[50]!;
      
      // Return the Load Sale transaction card
      return Container(
        margin: EdgeInsets.only(bottom: _adaptiveSpacing(12)),
        padding: EdgeInsets.all(_adaptivePadding(12)),
        decoration: BoxDecoration(
          color: Color(0xFFF8E7FF), // Light purple/pink background
          borderRadius: BorderRadius.circular(_adaptiveRadius(12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(_adaptivePadding(10)),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phone_android,
                    color: Colors.purple[700],
                    size: _adaptiveIconSize(20),
                  ),
                ),
                SizedBox(width: _adaptiveSpacing(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Load Sale',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: _adaptiveFontSize(16), 
                          color: Colors.grey[800]
                        ),
                      ),
                      SizedBox(height: _adaptiveSpacing(4)),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colors.grey[600], 
                          fontSize: _adaptiveFontSize(12)
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+PHP ${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: _adaptiveFontSize(16),
                        color: Colors.green[700],
                      ),
                    ),
                    SizedBox(height: _adaptiveSpacing(4)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _adaptivePadding(8), 
                        vertical: _adaptivePadding(2)
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(_adaptiveRadius(10)),
                      ),
                      child: Text(
                        'Profit: PHP ${profit.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: _adaptiveFontSize(12),
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: _adaptiveSpacing(8)),
            Divider(height: 1, color: Colors.purple[200]),
            SizedBox(height: _adaptiveSpacing(8)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Wallet Deducted:',
                  style: TextStyle(
                    fontSize: _adaptiveFontSize(12), 
                    color: Colors.grey[700]
                  ),
                ),
                Text(
                  '-PHP ${deducted.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: _adaptiveFontSize(12), 
                    fontWeight: FontWeight.bold, 
                    color: Colors.red[700]
                  ),
                ),
              ],
            ),
            SizedBox(height: _adaptiveSpacing(4)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Commission:',
                  style: TextStyle(
                    fontSize: _adaptiveFontSize(12), 
                    color: Colors.grey[700]
                  ),
                ),
                Text(
                  '-PHP ${(tx['commission'] ?? 0).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: _adaptiveFontSize(12), 
                    color: Colors.grey[700]
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (type == 'gcash_in') {
      title = 'GCash Cash In';
      amount = tx['amount'] ?? 0.0;
      double serviceFee = tx['serviceFee'] ?? 0.0;
      subtitle = 'Profit (Fee): PHP ${serviceFee.toStringAsFixed(2)}';
      amountColor = Colors.red[700]!;
      isIncome = false;
      icon = Icons.arrow_upward;
      iconBgColor = Colors.green[50]!;
      
      return Container(
        margin: EdgeInsets.only(bottom: _adaptiveSpacing(12)),
        padding: EdgeInsets.all(_adaptivePadding(12)),
        decoration: BoxDecoration(
          color: Color(0xFFE8F5E9), // Light green background
          borderRadius: BorderRadius.circular(_adaptiveRadius(12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(_adaptivePadding(10)),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_upward,
                    color: Colors.green[700],
                    size: _adaptiveIconSize(20),
                  ),
                ),
                SizedBox(width: _adaptiveSpacing(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: _adaptiveFontSize(16), 
                          color: Colors.grey[800]
                        ),
                      ),
                      SizedBox(height: _adaptiveSpacing(4)),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colors.grey[600], 
                          fontSize: _adaptiveFontSize(12)
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '-PHP ${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: _adaptiveFontSize(16),
                        color: Colors.red[700],
                      ),
                    ),
                    SizedBox(height: _adaptiveSpacing(4)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _adaptivePadding(8), 
                        vertical: _adaptivePadding(2)
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(_adaptiveRadius(10)),
                      ),
                      child: Text(
                        'Fee: PHP ${serviceFee.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: _adaptiveFontSize(12),
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    } else if (type == 'gcash_out') {
      title = 'GCash Cash Out';
      amount = tx['amount'] ?? 0.0;
      double serviceFee = tx['serviceFee'] ?? 0.0;
      subtitle = 'Profit (Fee): PHP ${serviceFee.toStringAsFixed(2)}';  
      amountColor = Colors.green[700]!;
      isIncome = true;
      icon = Icons.arrow_downward;
      iconBgColor = Colors.red[50]!;
      
      return Container(
        margin: EdgeInsets.only(bottom: _adaptiveSpacing(12)),
        padding: EdgeInsets.all(_adaptivePadding(12)),
        decoration: BoxDecoration(
          color: Color(0xFFFFEBEE), // Light red background
          borderRadius: BorderRadius.circular(_adaptiveRadius(12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(_adaptivePadding(10)),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_downward,
                    color: Colors.red[700],
                    size: _adaptiveIconSize(20),
                  ),
                ),
                SizedBox(width: _adaptiveSpacing(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: _adaptiveFontSize(16), 
                          color: Colors.grey[800]
                        ),
                      ),
                      SizedBox(height: _adaptiveSpacing(4)),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colors.grey[600], 
                          fontSize: _adaptiveFontSize(12)
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+PHP ${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: _adaptiveFontSize(16),
                        color: Colors.green[700],
                      ),
                    ),
                    SizedBox(height: _adaptiveSpacing(4)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _adaptivePadding(8), 
                        vertical: _adaptivePadding(2)
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(_adaptiveRadius(10)),
                      ),
                      child: Text(
                        'Fee: PHP ${serviceFee.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: _adaptiveFontSize(12),
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      title = type;
      amount = tx['amount'] ?? 0.0;
      subtitle = '';
      amountColor = Colors.black;
      icon = Icons.help_outline;
      iconBgColor = Colors.grey[200]!;
    }

    return Container(
      margin: EdgeInsets.only(bottom: _adaptiveSpacing(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_adaptiveRadius(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_adaptiveRadius(16)),
          onTap: () {
            _showTransactionDetails(tx);
          },
          child: Padding(
            padding: EdgeInsets.all(_adaptivePadding(16)),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(_adaptivePadding(10)),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(_adaptiveRadius(12)),
                  ),
                  child: Icon(
                    icon,
                    color: amountColor,
                    size: _adaptiveIconSize(24),
                  ),
                ),
                SizedBox(width: _adaptiveSpacing(16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: _adaptiveFontSize(16),
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: _adaptiveSpacing(4)),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: _adaptiveFontSize(12),
                          color: Colors.grey[600],
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        SizedBox(height: _adaptiveSpacing(4)),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: _adaptiveFontSize(12),
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  '${isIncome ? '+' : '-'}PHP ${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                    fontSize: _adaptiveFontSize(16),
                  ),
                ),
              ],
            ),
          ),
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

    // Format date
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

    // Determine if we should use a full-screen dialog or bottom sheet based on screen size
    if (isLargeScreen) {
      _showTransactionDetailsDialog(
          transaction, title, icon, iconColor, formattedDate, formattedTime);
    } else {
      _showTransactionDetailsBottomSheet(
          transaction, title, icon, iconColor, formattedDate, formattedTime);
    }
  }

  void _showTransactionDetailsDialog(
      dynamic transaction,
      String title,
      IconData icon,
      Color iconColor,
      String formattedDate,
      String formattedTime) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_adaptiveRadius(24)),
        ),
        child: Container(
          width: screenWidth * 0.8,
          padding: EdgeInsets.all(_adaptivePadding(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(_adaptivePadding(12)),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(_adaptiveRadius(16)),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: _adaptiveIconSize(28),
                    ),
                  ),
                  SizedBox(width: _adaptiveSpacing(16)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: _adaptiveFontSize(20),
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: _adaptiveSpacing(4)),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: _adaptivePadding(8),
                            vertical: _adaptivePadding(4)),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius:
                              BorderRadius.circular(_adaptiveRadius(8)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: _adaptiveIconSize(12),
                              color: Colors.green[700],
                            ),
                            SizedBox(width: _adaptiveSpacing(4)),
                            Text(
                              'Completed',
                              style: TextStyle(
                                fontSize: _adaptiveFontSize(10),
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: _adaptiveSpacing(24)),
              Container(
                padding: EdgeInsets.all(_adaptivePadding(16)),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(_adaptiveRadius(16)),
                ),
                child: Column(
                  children: [
                    _buildDetailItem(
                        'Date', formattedDate, Icons.calendar_today_rounded),
                    Divider(
                        height: _adaptiveSpacing(24), color: Colors.grey[200]),
                    _buildDetailItem(
                        'Time', formattedTime, Icons.access_time_rounded),
                    Divider(
                        height: _adaptiveSpacing(24), color: Colors.grey[200]),
                    _buildDetailItem('Transaction ID', '#${transaction.key}',
                        Icons.tag_rounded),
                  ],
                ),
              ),
              SizedBox(height: _adaptiveSpacing(24)),
              Text(
                'Transaction Details',
                style: TextStyle(
                  fontSize: _adaptiveFontSize(18),
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: _adaptiveSpacing(16)),
              Container(
                padding: EdgeInsets.all(_adaptivePadding(16)),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(_adaptiveRadius(16)),
                ),
                child: Column(
                  children: _buildTransactionDetailItems(transaction,
                      type: transaction['type'] ?? ''),
                ),
              ),
              SizedBox(height: _adaptiveSpacing(24)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon:
                        Icon(Icons.share_rounded, size: _adaptiveIconSize(18)),
                    label: Text(
                      'Share',
                      style: TextStyle(fontSize: _adaptiveFontSize(14)),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: EdgeInsets.symmetric(
                          horizontal: _adaptivePadding(16),
                          vertical: _adaptivePadding(12)),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(_adaptiveRadius(12)),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.delete_outline_rounded,
                        size: _adaptiveIconSize(18)),
                    label: Text(
                      'Delete',
                      style: TextStyle(fontSize: _adaptiveFontSize(14)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red[700],
                      padding: EdgeInsets.symmetric(
                          horizontal: _adaptivePadding(16),
                          vertical: _adaptivePadding(12)),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(_adaptiveRadius(12)),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
                top: Radius.circular(_adaptiveRadius(24))),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: _adaptiveSpacing(12)),
                height: 4,
                width: _adaptiveSize(40),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(_adaptivePadding(20)),
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(_adaptivePadding(12)),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(_adaptiveRadius(16)),
                          ),
                          child: Icon(
                            icon,
                            color: iconColor,
                            size: _adaptiveIconSize(28),
                          ),
                        ),
                        SizedBox(width: _adaptiveSpacing(16)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: _adaptiveFontSize(20),
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: _adaptiveSpacing(4)),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: _adaptivePadding(8),
                                  vertical: _adaptivePadding(4)),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius:
                                    BorderRadius.circular(_adaptiveRadius(8)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: _adaptiveIconSize(12),
                                    color: Colors.green[700],
                                  ),
                                  SizedBox(width: _adaptiveSpacing(4)),
                                  Text(
                                    'Completed',
                                    style: TextStyle(
                                      fontSize: _adaptiveFontSize(10),
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: _adaptiveSpacing(24)),
                    Container(
                      padding: EdgeInsets.all(_adaptivePadding(16)),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius:
                            BorderRadius.circular(_adaptiveRadius(16)),
                      ),
                      child: Column(
                        children: [
                          _buildDetailItem('Date', formattedDate,
                              Icons.calendar_today_rounded),
                          Divider(
                              height: _adaptiveSpacing(24),
                              color: Colors.grey[200]),
                          _buildDetailItem(
                              'Time', formattedTime, Icons.access_time_rounded),
                          Divider(
                              height: _adaptiveSpacing(24),
                              color: Colors.grey[200]),
                          _buildDetailItem('Transaction ID',
                              '#${transaction.key}', Icons.tag_rounded),
                        ],
                      ),
                    ),
                    SizedBox(height: _adaptiveSpacing(24)),
                    Text(
                      'Transaction Details',
                      style: TextStyle(
                        fontSize: _adaptiveFontSize(18),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: _adaptiveSpacing(16)),
                    Container(
                      padding: EdgeInsets.all(_adaptivePadding(16)),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius:
                            BorderRadius.circular(_adaptiveRadius(16)),
                      ),
                      child: Column(
                        children: _buildTransactionDetailItems(transaction,
                            type: transaction['type'] ?? ''),
                      ),
                    ),
                    SizedBox(height: _adaptiveSpacing(24)),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.share_rounded,
                                size: _adaptiveIconSize(18)),
                            label: Text(
                              'Share',
                              style: TextStyle(fontSize: _adaptiveFontSize(14)),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: EdgeInsets.symmetric(
                                  vertical: _adaptivePadding(16)),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(_adaptiveRadius(12)),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: _adaptiveSpacing(12)),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.delete_outline_rounded,
                                size: _adaptiveIconSize(18)),
                            label: Text(
                              'Delete',
                              style: TextStyle(fontSize: _adaptiveFontSize(14)),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[50],
                              foregroundColor: Colors.red[700],
                              padding: EdgeInsets.symmetric(
                                  vertical: _adaptivePadding(16)),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(_adaptiveRadius(12)),
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
          padding: EdgeInsets.all(_adaptivePadding(8)),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(_adaptiveRadius(8)),
          ),
          child: Icon(
            icon,
            size: _adaptiveIconSize(16),
            color: Colors.grey[700],
          ),
        ),
        SizedBox(width: _adaptiveSpacing(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: _adaptiveFontSize(12),
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: _adaptiveSpacing(4)),
              Text(
                value,
                style: TextStyle(
                  fontSize: _adaptiveFontSize(14),
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
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
          Icons.payments_outlined,
        ),
        Divider(height: _adaptiveSpacing(24)),
        _buildDetailItem(
          'Wallet Deducted',
          'PHP ${(transaction['deducted'] ?? 0.0).toStringAsFixed(2)}',
          Icons.account_balance_wallet_outlined,
        ),
        if (transaction['commission'] != null) ...[
          Divider(height: _adaptiveSpacing(24)),
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
          Icons.payments_outlined,
        ),
        if (transaction['serviceFee'] != null) ...[
          Divider(height: _adaptiveSpacing(24)),
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
          Icons.payments_outlined,
        ),
      ];
    }
    
    return items;
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
