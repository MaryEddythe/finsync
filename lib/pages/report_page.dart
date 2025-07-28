import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  // Animation Controllers
  late AnimationController _mainController;
  late AnimationController _cardController;
  late AnimationController _chartController;
  late AnimationController _fabController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _chartAnimation;
  
  // Page and Tab Controllers
  late PageController _pageController;
  late TabController _tabController;
  
  // State Variables
  String _selectedPeriod = 'Month';
  final List<String> _periods = ['Today', 'Week', 'Month', 'Quarter', 'All'];
  int _selectedTabIndex = 0;
  bool _isLoading = true;
  bool _isFilterApplied = false;
  
  // Filter Variables
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedTransactionType = 'All';
  final List<String> _transactionTypes = [
    'All', 'GCash In', 'GCash Out', 'Load Sale', 'GCash Topup', 'Load Topup'
  ];
  
  // Financial Data
  double _netProfit = 0.0;
  double _totalExpenses = 0.0;
  double _loadCommission = 0.0;
  double _gcashCashIn = 0.0;
  double _gcashCashOut = 0.0;
  double _gcashTopup = 0.0;
  double _gcashServiceFeeTotal = 0.0;
  double _loadIncome = 0.0;
  double _loadTopup = 0.0;
  double _loadNetProfit = 0.0;
  double _commissionSalesRate = 0.0;
  
  // Chart Data
  List<FlSpot> _overallSpots = [];
  List<FlSpot> _gcashSpots = [];
  List<FlSpot> _loadSpots = [];
  List<FlSpot> _topupSpots = [];
  double _maxY = 1000;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeControllers();
    _loadReportData();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _chartController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.bounceOut,
    ));

    _chartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeInOutCubic,
    ));
  }

  void _initializeControllers() {
    _pageController = PageController();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
        _pageController.animateToPage(
          _tabController.index,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _cardController.dispose();
    _chartController.dispose();
    _fabController.dispose();
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
    });

    // Reset animations
    _mainController.reset();
    _cardController.reset();
    _chartController.reset();
    _fabController.reset();

    // Reset all metrics
    _resetMetrics();

    try {
      final transactionsBox = Hive.box('transactions');
      final allTransactions = transactionsBox.values.toList();

      final filteredTransactions = _isFilterApplied 
          ? _filterTransactionsByCustomFilters(allTransactions)
          : _filterTransactionsByPeriod(allTransactions, _selectedPeriod);

      _processTransactions(filteredTransactions);
      _calculateDerivedMetrics();
      _generateChartData(filteredTransactions);

    } catch (e) {
      print('Error loading report data: $e');
    }

    setState(() {
      _isLoading = false;
    });

    // Start animation sequence
    await _startAnimationSequence();
  }

  void _resetMetrics() {
    _netProfit = 0.0;
    _totalExpenses = 0.0;
    _loadCommission = 0.0;
    _gcashCashIn = 0.0;
    _gcashCashOut = 0.0;
    _gcashTopup = 0.0;
    _gcashServiceFeeTotal = 0.0;
    _loadIncome = 0.0;
    _loadTopup = 0.0;
    _loadNetProfit = 0.0;
    _commissionSalesRate = 0.0;
    _overallSpots.clear();
    _gcashSpots.clear();
    _loadSpots.clear();
    _topupSpots.clear();
  }

  void _processTransactions(List<dynamic> transactions) {
    for (var tx in transactions) {
      final txType = tx['type'] as String? ?? '';
      final date = DateTime.parse(tx['date'] as String? ?? DateTime.now().toIso8601String());

      switch (txType) {
        case 'gcash_in':
          final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
          final serviceFee = (tx['serviceFee'] as num?)?.toDouble() ?? 0.0;
          
          _gcashCashIn += amount;
          _gcashServiceFeeTotal += serviceFee;
          _totalExpenses += amount + serviceFee;
          _addToSpots(_gcashSpots, date, amount, true);
          break;

        case 'gcash_out':
          final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
          final serviceFee = (tx['serviceFee'] as num?)?.toDouble() ?? 0.0;
          
          _gcashCashOut += amount;
          _gcashServiceFeeTotal += serviceFee;
          _addToSpots(_gcashSpots, date, amount, false);
          break;

        case 'load':
          final customerPays = (tx['customerPays'] as num?)?.toDouble() ?? 0.0;
          final commission = (tx['commission'] as num?)?.toDouble() ?? 0.0;
          
          _loadIncome += customerPays;
          _loadCommission += commission;
          _addToSpots(_loadSpots, date, customerPays, true);
          break;

        case 'topup':
          final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
          final wallet = tx['wallet'] as String? ?? 'load';
          
          if (wallet == 'gcash') {
            _gcashTopup += amount;
          } else {
            _loadTopup += amount;
          }
          _addToSpots(_topupSpots, date, amount, true);
          break;

        case 'gcash_topup':
          final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
          _gcashTopup += amount;
          _addToSpots(_topupSpots, date, amount, true);
          break;
      }
    }
  }

  void _calculateDerivedMetrics() {
    // Calculate net profits
    _loadNetProfit = _loadCommission - _loadTopup;
    _netProfit = _gcashServiceFeeTotal + _loadCommission - _totalExpenses;
    
    // Calculate commission sales rate
    _commissionSalesRate = _loadIncome > 0 ? (_loadCommission / _loadIncome) * 100 : 0.0;
    
    // Calculate max Y for charts
    _calculateMaxY();
  }

  void _addToSpots(List<FlSpot> spots, DateTime date, double amount, bool isIncome) {
    final x = _getXValue(date);
    final existingIndex = spots.indexWhere((spot) => spot.x == x);

    if (existingIndex >= 0) {
      final existingSpot = spots[existingIndex];
      spots[existingIndex] = FlSpot(
          existingSpot.x, existingSpot.y + (isIncome ? amount : -amount));
    } else {
      spots.add(FlSpot(x, isIncome ? amount : -amount));
    }

    spots.sort((a, b) => a.x.compareTo(b.x));
  }

  double _getXValue(DateTime date) {
    switch (_selectedPeriod) {
      case 'Today':
        return date.hour.toDouble();
      case 'Week':
        return date.weekday.toDouble() - 1;
      case 'Month':
        return date.day.toDouble() - 1;
      case 'Quarter':
        final quarterStartMonth = ((date.month - 1) ~/ 3) * 3 + 1;
        return (date.month - quarterStartMonth).toDouble();
      default:
        return date.millisecondsSinceEpoch / (24 * 60 * 60 * 1000);
    }
  }

  void _calculateMaxY() {
    double maxValue = 0;
    
    for (var spots in [_overallSpots, _gcashSpots, _loadSpots, _topupSpots]) {
      for (var spot in spots) {
        if (spot.y.abs() > maxValue) {
          maxValue = spot.y.abs();
        }
      }
    }
    
    _maxY = math.max(maxValue * 1.2, 1000);
  }

  void _generateChartData(List<dynamic> transactions) {
    // Generate overall performance spots
    _overallSpots.clear();
    
    final groupedData = <double, double>{};
    for (var tx in transactions) {
      final date = DateTime.parse(tx['date'] as String? ?? DateTime.now().toIso8601String());
      final x = _getXValue(date);
      final txType = tx['type'] as String? ?? '';
      
      double value = 0.0;
      if (txType == 'load') {
        value = (tx['commission'] as num?)?.toDouble() ?? 0.0;
      } else if (txType.contains('gcash')) {
        value = (tx['serviceFee'] as num?)?.toDouble() ?? 0.0;
      }
      
      groupedData[x] = (groupedData[x] ?? 0.0) + value;
    }
    
    groupedData.forEach((x, y) {
      _overallSpots.add(FlSpot(x, y));
    });
    
    _overallSpots.sort((a, b) => a.x.compareTo(b.x));
  }

  Future<void> _startAnimationSequence() async {
    _mainController.forward();
    await Future.delayed(Duration(milliseconds: 200));
    _cardController.forward();
    await Future.delayed(Duration(milliseconds: 300));
    _fabController.forward();
    await Future.delayed(Duration(milliseconds: 200));
    _chartController.forward();
  }

  List<dynamic> _filterTransactionsByPeriod(List<dynamic> transactions, String period) {
    final now = DateTime.now();

    return transactions.where((tx) {
      if (tx['date'] == null) return false;

      final txDate = DateTime.parse(tx['date'] as String? ?? '');

      switch (period) {
        case 'Today':
          return txDate.year == now.year &&
              txDate.month == now.month &&
              txDate.day == now.day;
        case 'Week':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          return txDate.isAfter(weekStart.subtract(Duration(days: 1))) &&
              txDate.isBefore(weekStart.add(Duration(days: 7)));
        case 'Month':
          return txDate.year == now.year && txDate.month == now.month;
        case 'Quarter':
          final quarterStart = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
          final quarterEnd = DateTime(quarterStart.year, quarterStart.month + 3, 0);
          return txDate.isAfter(quarterStart.subtract(Duration(days: 1))) &&
              txDate.isBefore(quarterEnd.add(Duration(days: 1)));
        default:
          return true;
      }
    }).toList();
  }

  List<dynamic> _filterTransactionsByCustomFilters(List<dynamic> transactions) {
    return transactions.where((tx) {
      if (tx['date'] == null) return false;

      final txDate = DateTime.parse(tx['date'] as String? ?? '');
      final txType = tx['type'] as String? ?? '';
      
      if (_startDate != null && txDate.isBefore(_startDate!)) return false;
      if (_endDate != null && txDate.isAfter(_endDate!.add(Duration(days: 1)))) return false;
      
      if (_selectedTransactionType != 'All') {
        final typeMap = {
          'GCash In': 'gcash_in',
          'GCash Out': 'gcash_out',
          'Load Sale': 'load',
          'GCash Topup': 'gcash_topup',
          'Load Topup': 'topup',
        };
        
        if (typeMap[_selectedTransactionType] != txType) return false;
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
              Color(0xFFf5576c),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: _isLoading ? _buildLoadingState() : _buildMainContent(),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                strokeWidth: 6,
              ),
            ),
            SizedBox(height: 30),
            Text(
              'Analyzing Financial Data',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Preparing comprehensive insights...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF718096),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildPeriodSelector(),
            _buildTabBar(),
            Expanded(child: _buildPageView()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.white.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.analytics_rounded,
              color: Color(0xFF667eea),
              size: 32,
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Analytics',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                Text(
                  'Comprehensive Performance Dashboard',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_isFilterApplied)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isFilterApplied = false;
                  _startDate = null;
                  _endDate = null;
                  _selectedTransactionType = 'All';
                });
                _loadReportData();
              },
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: Icon(
                  Icons.filter_list_off_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _periods.length,
        itemBuilder: (context, index) {
          final period = _periods[index];
          final isSelected = period == _selectedPeriod && !_isFilterApplied;

          return Container(
            margin: EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                  _isFilterApplied = false;
                });
                _loadReportData();
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected 
                      ? LinearGradient(
                          colors: [Colors.white, Colors.white.withOpacity(0.9)],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ] : [],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(
                        Icons.access_time_rounded,
                        color: Color(0xFF667eea),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                    ],
                    Text(
                      period,
                      style: TextStyle(
                        color: isSelected ? Color(0xFF667eea) : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white.withOpacity(0.9)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        indicatorPadding: EdgeInsets.all(5),
        labelColor: Color(0xFF667eea),
        unselectedLabelColor: Colors.white,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.dashboard_rounded, size: 16),
                SizedBox(width: 4),
                Text('Summary'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_wallet_rounded, size: 16),
                SizedBox(width: 4),
                Text('GCash'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone_android_rounded, size: 16),
                SizedBox(width: 4),
                Text('Load'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_rounded, size: 16),
                SizedBox(width: 4),
                Text('Topup'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return SlideTransition(
      position: _slideAnimation,
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          _tabController.animateTo(index);
        },
        children: [
          _buildOverallSummary(),
          _buildGCashPerformance(),
          _buildLoadWalletAnalysis(),
          _buildTopupAnalysis(),
        ],
      ),
    );
  }

  Widget _buildOverallSummary() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          // Main Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Net Profit',
                  _netProfit,
                  Icons.trending_up_rounded,
                  Colors.green,
                  'Total earnings after expenses',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Total Expenses',
                  _totalExpenses,
                  Icons.trending_down_rounded,
                  Colors.red,
                  'All operational costs',
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Load Commission Card
          _buildMetricCard(
            'Load Commission',
            _loadCommission,
            Icons.phone_android_rounded,
            Color(0xFF8B5CF6),
            'Commission from load sales',
            isFullWidth: true,
          ),
          
          SizedBox(height: 24),
          
          // Performance Chart
          _buildChartCard(
            'Overall Performance Trends',
            'Combined revenue and profit analysis',
            _overallSpots,
            Color(0xFF667eea),
          ),
        ],
      ),
    );
  }

  Widget _buildGCashPerformance() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          // GCash Metrics Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Cash In',
                  _gcashCashIn,
                  Icons.arrow_downward_rounded,
                  Colors.blue,
                  'Money received',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Cash Out',
                  _gcashCashOut,
                  Icons.arrow_upward_rounded,
                  Colors.orange,
                  'Money sent',
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'GCash Topup',
                  _gcashTopup,
                  Icons.add_circle_outline_rounded,
                  Colors.purple,
                  'Balance added',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Service Fee Total',
                  _gcashServiceFeeTotal,
                  Icons.star_rounded,
                  Colors.amber,
                  'Net profit from fees',
                ),
              ),
            ],
          ),
          
          SizedBox(height: 24),
          
          // GCash Chart
          _buildChartCard(
            'GCash Transaction Trends',
            'Daily GCash activity overview',
            _gcashSpots,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadWalletAnalysis() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          // Load Metrics Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Income',
                  _loadIncome,
                  Icons.monetization_on_rounded,
                  Colors.green,
                  'Total load sales',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Commission',
                  _loadCommission,
                  Icons.percent_rounded,
                  Color(0xFF8B5CF6),
                  'Commission earned',
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Load Topup',
                  _loadTopup,
                  Icons.add_circle_outline_rounded,
                  Colors.orange,
                  'Wallet funding',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Net Profit',
                  _loadNetProfit,
                  Icons.trending_up_rounded,
                  _loadNetProfit >= 0 ? Colors.green : Colors.red,
                  'Final load profit',
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Commission Sales Rate
          _buildMetricCard(
            'Commission Sales Rate',
            _commissionSalesRate,
            Icons.analytics_rounded,
            Colors.indigo,
            'Commission percentage of sales',
            isFullWidth: true,
            isPercentage: true,
          ),
          
          SizedBox(height: 24),
          
          // Load Chart
          _buildChartCard(
            'Load Wallet Performance',
            'Load sales and commission trends',
            _loadSpots,
            Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _buildTopupAnalysis() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          // Topup Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'GCash Topup',
                  _gcashTopup,
                  Icons.account_balance_wallet_rounded,
                  Colors.blue,
                  'Digital wallet funding',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Load Topup',
                  _loadTopup,
                  Icons.phone_android_rounded,
                  Colors.orange,
                  'Mobile load funding',
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Total Topup
          _buildMetricCard(
            'Total Topup',
            _gcashTopup + _loadTopup,
            Icons.add_circle_rounded,
            Colors.teal,
            'Combined wallet funding',
            isFullWidth: true,
          ),
          
          SizedBox(height: 24),
          
          // Topup Distribution Chart
          _buildTopupDistributionChart(),
          
          SizedBox(height: 24),
          
          // Topup Trends Chart
          _buildChartCard(
            'Topup Transaction Trends',
            'Wallet funding activity over time',
            _topupSpots,
            Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    double value,
    IconData icon,
    Color color,
    String description, {
    bool isFullWidth = false,
    bool isPercentage = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: color,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '0.0%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A5568),
            ),
          ),
          SizedBox(height: 8),
          AnimatedBuilder(
            animation: _chartAnimation,
            builder: (context, child) {
              final animatedValue = value * _chartAnimation.value;
              return Text(
                isPercentage 
                    ? '${animatedValue.toStringAsFixed(1)}%'
                    : '₱${NumberFormat('#,##0.00').format(animatedValue)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              );
            },
          ),
          SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, String subtitle, List<FlSpot> spots, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
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
                child: Icon(Icons.show_chart_rounded, color: color, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            height: 250,
            child: spots.isEmpty
                ? _buildEmptyChart()
                : AnimatedBuilder(
                    animation: _chartAnimation,
                    builder: (context, child) {
                      return LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            drawHorizontalLine: true,
                            horizontalInterval: _maxY / 4,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: color.withOpacity(0.1),
                                strokeWidth: 1,
                                dashArray: [8, 4],
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) return Text('0', style: TextStyle(fontSize: 10, color: Color(0xFF718096)));
                                  if (value % (_maxY / 3).round() != 0) return Text('');
                                  return Text(
                                    '₱${(value / 1000).toStringAsFixed(0)}k',
                                    style: TextStyle(fontSize: 10, color: Color(0xFF718096)),
                                  );
                                },
                                reservedSize: 50,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    _getBottomTitleText(value),
                                    style: TextStyle(fontSize: 10, color: Color(0xFF718096)),
                                  );
                                },
                                reservedSize: 32,
                              ),
                            ),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: _getMinX(spots),
                          maxX: _getMaxX(spots),
                          minY: -_maxY,
                          maxY: _maxY,
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots.map((spot) => FlSpot(
                                spot.x, 
                                spot.y * _chartAnimation.value
                              )).toList(),
                              isCurved: true,
                              curveSmoothness: 0.4,
                              color: color,
                              barWidth: 4,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 6,
                                    color: color,
                                    strokeWidth: 3,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    color.withOpacity(0.4),
                                    color.withOpacity(0.1),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                return touchedSpots.map((spot) {
                                  final isIncome = spot.y >= 0;
                                  return LineTooltipItem(
                                    '${isIncome ? "Income" : "Expense"}\n₱${spot.y.abs().toStringAsFixed(2)}',
                                    TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  );
                                }).toList();
                              },
                              tooltipMargin: 12,
                              tooltipRoundedRadius: 12,
                            ),
                            touchSpotThreshold: 20,
                            handleBuiltInTouches: true,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up_rounded, size: 48, color: Color(0xFF718096)),
            SizedBox(height: 12),
            Text(
              'No chart data available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A5568),
              ),
            ),
            Text(
              'Data will appear as transactions are made',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF718096),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopupDistributionChart() {
    final total = _gcashTopup + _loadTopup;
    
    if (total == 0) {
      return Container(
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.donut_large_outlined, size: 48, color: Color(0xFF718096)),
            SizedBox(height: 12),
            Text(
              'No topup distribution data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A5568),
              ),
            ),
          ],
        ),
      );
    }

    final gcashPercentage = (_gcashTopup / total * 100);
    final loadPercentage = (_loadTopup / total * 100);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.donut_large_rounded, color: Colors.teal, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Topup Distribution',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // Distribution bars
          Container(
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  if (gcashPercentage > 0)
                    Expanded(
                      flex: gcashPercentage.round(),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.blue.withOpacity(0.8)],
                          ),
                        ),
                      ),
                    ),
                  if (loadPercentage > 0)
                    Expanded(
                      flex: loadPercentage.round(),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange, Colors.orange.withOpacity(0.8)],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 20),
          
          // Distribution details
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.withOpacity(0.1), Colors.blue.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue, Colors.blue.withOpacity(0.8)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'GCash Topup',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${gcashPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        '₱${NumberFormat('#,##0.00').format(_gcashTopup)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.withOpacity(0.1), Colors.orange.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange, Colors.orange.withOpacity(0.8)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Load Topup',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${loadPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        '₱${NumberFormat('#,##0.00').format(_loadTopup)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FloatingActionButton.extended(
        onPressed: _showAdvancedFilters,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF667eea),
        elevation: 10,
        icon: Icon(Icons.tune_rounded, size: 24),
        label: Text(
          'Filters',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    );
  }

  void _showAdvancedFilters() {
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  offset: Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: 16),
                  height: 6,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Color(0xFF718096).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                
                // Header
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF667eea).withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Advanced Filters',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            Text(
                              'Customize your financial insights',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF718096),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Date Range Section
                        _buildFilterSection(
                          'Date Range',
                          Icons.calendar_today_rounded,
                          Colors.blue,
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDateField(
                                      _startDate == null 
                                        ? 'Select start date' 
                                        : DateFormat('MMM dd, yyyy').format(_startDate!),
                                      Icons.calendar_today_rounded,
                                      () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: _startDate ?? DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime.now(),
                                        );
                                        if (picked != null) {
                                          setModalState(() {
                                            _startDate = picked;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _buildDateField(
                                      _endDate == null 
                                        ? 'Select end date' 
                                        : DateFormat('MMM dd, yyyy').format(_endDate!),
                                      Icons.event_rounded,
                                      () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: _endDate ?? DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime.now(),
                                        );
                                        if (picked != null) {
                                          setModalState(() {
                                            _endDate = picked;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 32),
                        
                        // Transaction Type Section
                        _buildFilterSection(
                          'Transaction Types',
                          Icons.category_rounded,
                          Color(0xFF8B5CF6),
                          _buildTransactionTypeSelector(setModalState),
                        ),
                        
                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                
                // Action Buttons
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setModalState(() {
                                  _startDate = null;
                                  _endDate = null;
                                  _selectedTransactionType = 'All';
                                });
                              },
                              icon: Icon(Icons.refresh_rounded),
                              label: Text('Reset All'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Color(0xFF718096),
                                side: BorderSide(color: Colors.grey.shade300, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF667eea).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isFilterApplied = true;
                                });
                                Navigator.pop(context);
                                _loadReportData();
                              },
                              icon: Icon(Icons.check_circle_rounded),
                              label: Text('Apply Filters'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection(String title, IconData icon, Color color, Widget content) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.05),
            color.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          content,
        ],
      ),
    );
  }

  Widget _buildDateField(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white.withOpacity(0.95)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: Colors.blue),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: label.contains('Select') ? Color(0xFF718096) : Color(0xFF2D3748),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTypeSelector(StateSetter setModalState) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _transactionTypes.map((type) {
        final isSelected = type == _selectedTransactionType;
        return GestureDetector(
          onTap: () {
            setModalState(() {
              _selectedTransactionType = type;
            });
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                    )
                  : LinearGradient(
                      colors: [Colors.white, Colors.white.withOpacity(0.9)],
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Color(0xFF8B5CF6) : Colors.grey.shade300,
                width: 1.5,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ] : [],
            ),
            child: Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : Color(0xFF4A5568),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getBottomTitleText(double value) {
    switch (_selectedPeriod) {
      case 'Today':
        if (value % 3 == 0) {
          final hour = value.toInt();
          final amPm = hour >= 12 ? 'PM' : 'AM';
          final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
          return '$hour12$amPm';
        }
        break;
      case 'Week':
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        if (value >= 0 && value < weekdays.length) {
          return weekdays[value.toInt()];
        }
        break;
      case 'Month':
        if (value % 5 == 0) {
          return '${value.toInt() + 1}';
        }
        break;
      case 'Quarter':
        if (value.toInt() == 0) return 'M1';
        if (value.toInt() == 1) return 'M2';
        if (value.toInt() == 2) return 'M3';
        break;
      default:
        if (value % 5 == 0) {
          return '${value.toInt()}';
        }
    }
    return '';
  }

  double _getMinX(List<FlSpot> spots) {
    if (spots.isEmpty) return 0;
    return spots.map((spot) => spot.x).reduce((a, b) => a < b ? a : b);
  }

  double _getMaxX(List<FlSpot> spots) {
    if (spots.isEmpty) {
      switch (_selectedPeriod) {
        case 'Today':
          return 23;
        case 'Week':
          return 6;
        case 'Month':
          return 30;
        case 'Quarter':
          return 2;
        default:
          return 30;
      }
    }
    return spots.map((spot) => spot.x).reduce((a, b) => a > b ? a : b);
  }
}
