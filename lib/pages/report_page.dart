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
  late AnimationController _mainController;
  late AnimationController _cardController;
  late AnimationController _chartController;
  late AnimationController _fabController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _chartAnimation;
  late PageController _pageController;
  late TabController _tabController;
  String _selectedPeriod = 'Month';
  final List<String> _periods = ['Today', 'Week', 'Month', 'Quarter', 'All'];
  int _selectedTabIndex = 0;
  bool _isLoading = true;
  bool _isFilterApplied = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedTransactionType = 'All';
  final List<String> _transactionTypes = [
    'All', 'GCash In', 'GCash Out', 'Load Sale', 'GCash Topup', 'Load Topup'
  ];
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
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeOut),
    );
    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chartController, curve: Curves.easeOut),
    );
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
    _mainController.reset();
    _cardController.reset();
    _chartController.reset();
    _fabController.reset();
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
          final deducted = (tx['deducted'] as num?)?.toDouble() ?? 0.0;
          final commission = (tx['commission'] as num?)?.toDouble() ?? 0.0;
          final profit = (tx['profit'] as num?)?.toDouble() ?? (customerPays - deducted);
          _loadIncome += customerPays;
          _loadCommission += commission;
          _loadNetProfit += profit;
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
    _netProfit = _gcashServiceFeeTotal + _loadNetProfit - _totalExpenses;
    _commissionSalesRate = _loadIncome > 0 ? (_loadCommission / _loadIncome) * 100 : 0.0;
    _calculateMaxY();
  }

  void _addToSpots(List<FlSpot> spots, DateTime date, double amount, bool isIncome) {
    final x = _getXValue(date);
    final existingIndex = spots.indexWhere((spot) => spot.x == x);
    if (existingIndex >= 0) {
      final existingSpot = spots[existingIndex];
      spots[existingIndex] = FlSpot(existingSpot.x, existingSpot.y + (isIncome ? amount : -amount));
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
    _overallSpots.clear();
    final groupedData = <double, double>{};
    for (var tx in transactions) {
      final date = DateTime.parse(tx['date'] as String? ?? DateTime.now().toIso8601String());
      final x = _getXValue(date);
      final txType = tx['type'] as String? ?? '';
      double value = 0.0;
      if (txType == 'load') {
        value = (tx['profit'] as num?)?.toDouble() ?? ((tx['customerPays'] as num?)?.toDouble() ?? 0.0) - ((tx['deducted'] as num?)?.toDouble() ?? 0.0);
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
    await Future.delayed(Duration(milliseconds: 100));
    _cardController.forward();
    await Future.delayed(Duration(milliseconds: 150));
    _fabController.forward();
    await Future.delayed(Duration(milliseconds: 100));
    _chartController.forward();
  }

  List<dynamic> _filterTransactionsByPeriod(List<dynamic> transactions, String period) {
    final now = DateTime.now();
    return transactions.where((tx) {
      if (tx['date'] == null) return false;
      final txDate = DateTime.parse(tx['date'] as String? ?? '');
      switch (period) {
        case 'Today':
          return txDate.year == now.year && txDate.month == now.month && txDate.day == now.day;
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
      backgroundColor: Colors.grey[100],
      body: _isLoading ? _buildLoadingState() : _buildMainContent(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                strokeWidth: 4,
              ),
              SizedBox(height: 16),
              Text(
                'Loading Reports',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                'Fetching financial data...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Icon(Icons.analytics, color: Colors.blue[600], size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reports',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'Your financial overview',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (_isFilterApplied)
            IconButton(
              icon: Icon(Icons.filter_list_off, color: Colors.red[400], size: 24),
              onPressed: () {
                setState(() {
                  _isFilterApplied = false;
                  _startDate = null;
                  _endDate = null;
                  _selectedTransactionType = 'All';
                });
                _loadReportData();
              },
              tooltip: 'Clear filters',
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      height: 48,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _periods.length,
        itemBuilder: (context, index) {
          final period = _periods[index];
          final isSelected = period == _selectedPeriod && !_isFilterApplied;
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                  _isFilterApplied = false;
                });
                _loadReportData();
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[600] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? Colors.blue[600]! : Colors.grey[300]!),
                ),
                child: Center(
                  child: Text(
                    period,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
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
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildTabItem(0, 'Summary', Icons.dashboard),
          SizedBox(width: 8),
          _buildTabItem(1, 'GCash', Icons.account_balance_wallet),
          SizedBox(width: 8),
          _buildTabItem(2, 'Load', Icons.phone_android),
          SizedBox(width: 8),
          _buildTabItem(3, 'Topup', Icons.add_circle),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[600] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
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
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Net Profit',
                  _netProfit,
                  Icons.trending_up,
                  Colors.green,
                  'Total earnings after expenses',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Total Expenses',
                  _totalExpenses,
                  Icons.trending_down,
                  Colors.red,
                  'All operational costs',
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildMetricCard(
            'Load Profit',
            _loadNetProfit,
            Icons.phone_android,
            Colors.purple,
            'Profit from load sales',
            isFullWidth: true,
          ),
          SizedBox(height: 16),
          _buildChartCard(
            'Overall Performance Trends',
            'Combined revenue and profit analysis',
            _overallSpots,
            Colors.blue[600]!,
          ),
        ],
      ),
    );
  }

  Widget _buildGCashPerformance() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Cash In',
                  _gcashCashIn,
                  Icons.arrow_downward,
                  Colors.blue,
                  'Money received',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Cash Out',
                  _gcashCashOut,
                  Icons.arrow_upward,
                  Colors.orange,
                  'Money sent',
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'GCash Topup',
                  _gcashTopup,
                  Icons.add_circle_outline,
                  Colors.purple,
                  'Balance added',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Service Fee Total',
                  _gcashServiceFeeTotal,
                  Icons.star,
                  Colors.amber,
                  'Net profit from fees',
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildChartCard(
            'GCash Transaction Trends',
            'Daily GCash activity overview',
            _gcashSpots,
            Colors.blue[600]!,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadWalletAnalysis() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Income',
                  _loadIncome,
                  Icons.monetization_on,
                  Colors.green,
                  'Total load sales',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Commission',
                  _loadCommission,
                  Icons.percent,
                  Colors.purple,
                  'Commission earned',
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Load Topup',
                  _loadTopup,
                  Icons.add_circle_outline,
                  Colors.orange,
                  'Wallet funding',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Net Profit',
                  _loadNetProfit,
                  Icons.trending_up,
                  _loadNetProfit >= 0 ? Colors.green : Colors.red,
                  'Profit from load sales',
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildMetricCard(
            'Commission Sales Rate',
            _commissionSalesRate,
            Icons.analytics,
            Colors.indigo,
            'Commission percentage of sales',
            isFullWidth: true,
            isPercentage: true,
          ),
          SizedBox(height: 16),
          _buildChartCard(
            'Load Wallet Performance',
            'Load sales and profit trends',
            _loadSpots,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildTopupAnalysis() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'GCash Topup',
                  _gcashTopup,
                  Icons.account_balance_wallet,
                  Colors.blue,
                  'Digital wallet funding',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Load Topup',
                  _loadTopup,
                  Icons.phone_android,
                  Colors.orange,
                  'Mobile load funding',
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildMetricCard(
            'Total Topup',
            _gcashTopup + _loadTopup,
            Icons.add_circle,
            Colors.teal,
            'Combined wallet funding',
            isFullWidth: true,
          ),
          SizedBox(height: 16),
          _buildTopupDistributionChart(),
          SizedBox(height: 16),
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, color: color, size: 20),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, color: color, size: 12),
                      SizedBox(width: 4),
                      Text(
                        '0.0%',
                        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            SizedBox(height: 4),
            AnimatedBuilder(
              animation: _chartAnimation,
              builder: (context, child) {
                final animatedValue = value * _chartAnimation.value;
                return Text(
                  isPercentage
                      ? '${animatedValue.toStringAsFixed(1)}%'
                      : '₱${NumberFormat('#,##0.00').format(animatedValue)}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                );
              },
            ),
            Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, String subtitle, List<FlSpot> spots, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(Icons.show_chart, color: color, size: 20),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              height: 200,
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
                                    if (value == 0) return Text('0', style: TextStyle(fontSize: 10, color: Colors.grey[600]));
                                    if (value % (_maxY / 3).round() != 0) return Text('');
                                    return Text(
                                      '₱${(value / 1000).toStringAsFixed(0)}k',
                                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                    );
                                  },
                                  reservedSize: 40,
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      _getBottomTitleText(value),
                                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                    );
                                  },
                                  reservedSize: 24,
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
                                spots: spots
                                    .map((spot) => FlSpot(spot.x, spot.y * _chartAnimation.value))
                                    .toList(),
                                isCurved: true,
                                curveSmoothness: 0.4,
                                color: color,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: 4,
                                      color: color,
                                      strokeWidth: 2,
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
                                      color.withOpacity(0.3),
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
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    );
                                  }).toList();
                                },
                                tooltipMargin: 8,
                                tooltipRoundedRadius: 8,
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
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 40, color: Colors.grey[600]),
            SizedBox(height: 8),
            Text(
              'No chart data available',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800]),
            ),
            Text(
              'Add transactions to see trends',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopupDistributionChart() {
    final total = _gcashTopup + _loadTopup;
    if (total == 0) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.donut_large, size: 40, color: Colors.grey[600]),
              SizedBox(height: 8),
              Text(
                'No topup data available',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800]),
              ),
            ],
          ),
        ),
      );
    }
    final gcashPercentage = (_gcashTopup / total * 100);
    final loadPercentage = (_loadTopup / total * 100);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal.withOpacity(0.1),
                  child: Icon(Icons.donut_large, color: Colors.teal, size: 20),
                ),
                SizedBox(width: 8),
                Text(
                  'Topup Distribution',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                ),
              ],
            ),
            SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  if (gcashPercentage > 0)
                    Expanded(
                      flex: gcashPercentage.round(),
                      child: Container(
                        height: 24,
                        color: Colors.blue,
                      ),
                    ),
                  if (loadPercentage > 0)
                    Expanded(
                      flex: loadPercentage.round(),
                      child: Container(
                        height: 24,
                        color: Colors.orange,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'GCash Topup',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey[800]),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${gcashPercentage.toStringAsFixed(1)}%',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          Text(
                            '₱${NumberFormat('#,##0.00').format(_gcashTopup)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Load Topup',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey[800]),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${loadPercentage.toStringAsFixed(1)}%',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                          Text(
                            '₱${NumberFormat('#,##0.00').format(_loadTopup)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FloatingActionButton(
        onPressed: _showAdvancedFilters,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.tune, size: 24),
      ),
    );
  }

  void _showAdvancedFilters() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          padding: EdgeInsets.all(16),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.tune, color: Colors.blue[600], size: 24),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Advanced Filters',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                      ),
                      Text(
                        'Customize your report',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildFilterSection(
                'Date Range',
                Icons.calendar_today,
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
                            Icons.calendar_today,
                            () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _startDate = picked;
                                });
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildDateField(
                            _endDate == null
                                ? 'Select end date'
                                : DateFormat('MMM dd, yyyy').format(_endDate!),
                            Icons.event,
                            () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
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
              SizedBox(height: 16),
              _buildFilterSection(
                'Transaction Types',
                Icons.category,
                Colors.purple,
                _buildTransactionTypeSelector(setState),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                          _selectedTransactionType = 'All';
                        });
                      },
                      child: Text('Reset'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isFilterApplied = true;
                        });
                        Navigator.pop(context);
                        _loadReportData();
                      },
                      child: Text('Apply Filters'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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

  Widget _buildFilterSection(String title, IconData icon, Color color, Widget content) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, color: color, size: 20),
                ),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                ),
              ],
            ),
            SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.blue[600]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: label.contains('Select') ? Colors.grey[600] : Colors.grey[800],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTypeSelector(StateSetter setModalState) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
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
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[600] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? Colors.blue[600]! : Colors.grey[300]!),
            ),
            child: Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 12,
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