import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String _selectedPeriod = 'Month';
  final List<String> _periods = ['Week', 'Month', 'Quarter', 'Year', 'All'];
  
  // Summary metrics
  double _gcashIncome = 0.0;
  double _gcashExpense = 0.0;
  double _gcashTopup = 0.0;
  double _loadIncome = 0.0;
  double _loadCommission = 0.0;
  double _loadTopup = 0.0;
  
  // Chart data
  List<FlSpot> _gcashSpots = [];
  List<FlSpot> _loadSpots = [];
  double _maxY = 1000; // Default max value for charts
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
    });
    
    // Reset metrics
    _gcashIncome = 0.0;
    _gcashExpense = 0.0;
    _gcashTopup = 0.0;
    _loadIncome = 0.0;
    _loadCommission = 0.0;
    _loadTopup = 0.0;
    _gcashSpots = [];
    _loadSpots = [];
    
    final transactionsBox = Hive.box('transactions');
    final allTransactions = transactionsBox.values.toList();
    
    // Filter transactions by selected period
    final filteredTransactions = _filterTransactionsByPeriod(allTransactions, _selectedPeriod);
    
    // Process transactions
    for (var tx in filteredTransactions) {
      final txType = tx['type'] as String? ?? '';
      final date = DateTime.parse(tx['date'] as String? ?? DateTime.now().toIso8601String());
      
      if (txType == 'gcash_in') {
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
        _gcashExpense += amount;
        _addToSpots(_gcashSpots, date, amount, false);
        
      } else if (txType == 'gcash_out') {
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
        _gcashIncome += amount;
        _addToSpots(_gcashSpots, date, amount, true);
        
      } else if (txType == 'load') {
        final customerPays = (tx['customerPays'] as num?)?.toDouble() ?? 0.0;
        final profit = (tx['profit'] as num?)?.toDouble() ?? 0.0;
        _loadIncome += customerPays;
        _loadCommission += profit;
        _addToSpots(_loadSpots, date, customerPays, true);
        
      } else if (txType == 'topup') {
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
        if (tx['wallet'] == 'gcash') {
          _gcashTopup += amount;
        } else {
          _loadTopup += amount;
        }
        _addToSpots(tx['wallet'] == 'gcash' ? _gcashSpots : _loadSpots, date, amount, false);
      }
    }
    
    // Calculate max Y for charts
    _calculateMaxY();
    
    setState(() {
      _isLoading = false;
    });
  }
  
  void _addToSpots(List<FlSpot> spots, DateTime date, double amount, bool isIncome) {
    // Convert date to x-axis value
    final x = _getXValue(date);
    
    // Find if there's already a spot for this date
    final existingIndex = spots.indexWhere((spot) => spot.x == x);
    
    if (existingIndex >= 0) {
      // Update existing spot
      final existingSpot = spots[existingIndex];
      spots[existingIndex] = FlSpot(existingSpot.x, existingSpot.y + (isIncome ? amount : -amount));
    } else {
      // Add new spot
      spots.add(FlSpot(x, isIncome ? amount : -amount));
    }
    
    // Sort spots by x
    spots.sort((a, b) => a.x.compareTo(b.x));
  }
  
  double _getXValue(DateTime date) {
    if (_selectedPeriod == 'Week') {
      // Day of week (0-6)
      return date.weekday.toDouble() - 1;
    } else if (_selectedPeriod == 'Month') {
      // Day of month (1-31)
      return date.day.toDouble() - 1;
    } else if (_selectedPeriod == 'Quarter') {
      // Month within quarter (0-2)
      final quarterStartMonth = ((date.month - 1) ~/ 3) * 3 + 1;
      return (date.month - quarterStartMonth).toDouble();
    } else if (_selectedPeriod == 'Year') {
      // Month of year (0-11)
      return date.month.toDouble() - 1;
    } else {
      // All time - use days since epoch
      return date.millisecondsSinceEpoch / (24 * 60 * 60 * 1000);
    }
  }
  
  void _calculateMaxY() {
    // Find max absolute value in both spot lists
    double maxGcash = 0;
    double maxLoad = 0;
    
    for (var spot in _gcashSpots) {
      if (spot.y.abs() > maxGcash) {
        maxGcash = spot.y.abs();
      }
    }
    
    for (var spot in _loadSpots) {
      if (spot.y.abs() > maxLoad) {
        maxLoad = spot.y.abs();
      }
    }
    
    _maxY = [maxGcash, maxLoad, 1000].reduce((a, b) => a > b ? a : b) * 1.2; // Add 20% margin
  }
  
  List<dynamic> _filterTransactionsByPeriod(List<dynamic> transactions, String period) {
    final now = DateTime.now();
    
    return transactions.where((tx) {
      if (tx['date'] == null) return false;
      
      final txDate = DateTime.parse(tx['date'] as String? ?? '');
      
      if (period == 'Week') {
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return txDate.isAfter(weekStart.subtract(Duration(days: 1))) && 
               txDate.isBefore(weekStart.add(Duration(days: 7)));
      } else if (period == 'Month') {
        return txDate.year == now.year && txDate.month == now.month;
      } else if (period == 'Quarter') {
        final quarterStart = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
        final quarterEnd = DateTime(quarterStart.year, quarterStart.month + 3, 0);
        return txDate.isAfter(quarterStart.subtract(Duration(days: 1))) && 
               txDate.isBefore(quarterEnd.add(Duration(days: 1)));
      } else if (period == 'Year') {
        return txDate.year == now.year;
      } else {
        return true; // All time
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.green[700]))
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.green.shade800, Colors.green.shade50],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildPeriodSelector(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummarySection(),
                            SizedBox(height: 24),
                            _buildGCashSection(),
                            SizedBox(height: 24),
                            _buildLoadSection(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Financial Reports',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadReportData,
            tooltip: 'Refresh Reports',
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      height: 40,
      margin: EdgeInsets.symmetric(horizontal: 16),
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
              _loadReportData();
            },
            child: Container(
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  period,
                  style: TextStyle(
                    color: isSelected ? Colors.green.shade800 : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummarySection() {
    final gcashProfit = _gcashIncome - _gcashExpense;
    final loadProfit = _loadIncome - _loadTopup;
    final totalProfit = gcashProfit + loadProfit + _loadCommission;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Overall Summary'),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Revenue',
                      _gcashIncome + _loadIncome,
                      Icons.account_balance_wallet,
                      Colors.green.shade700,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Expenses',
                      _gcashExpense + _gcashTopup + _loadTopup,
                      Icons.money_off,
                      Colors.red.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Load Commission',
                      _loadCommission,
                      Icons.phone_android,
                      Colors.purple.shade700,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Net Profit',
                      totalProfit,
                      Icons.trending_up,
                      Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.insights,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profit Breakdown',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 8),
                          _buildProfitBreakdownBar(gcashProfit, _loadCommission, loadProfit),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfitBreakdownBar(double gcashProfit, double loadCommission, double loadProfit) {
    final total = gcashProfit.abs() + loadCommission.abs() + loadProfit.abs();
    
    if (total == 0) {
      return Text(
        'No profit data available for this period',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      );
    }
    
    final gcashWidth = (gcashProfit / total * 100).abs();
    final commissionWidth = (loadCommission / total * 100).abs();
    final loadWidth = (loadProfit / total * 100).abs();
    
    return Column(
      children: [
        Container(
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: gcashWidth * 0.01 * MediaQuery.of(context).size.width * 0.6,
                decoration: BoxDecoration(
                  color: gcashProfit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
              ),
              Container(
                width: commissionWidth * 0.01 * MediaQuery.of(context).size.width * 0.6,
                color: Colors.purple.shade700,
              ),
              Container(
                width: loadWidth * 0.01 * MediaQuery.of(context).size.width * 0.6,
                decoration: BoxDecoration(
                  color: loadProfit >= 0 ? Colors.blue.shade700 : Colors.orange.shade700,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            _buildLegendItem('GCash', gcashProfit >= 0 ? Colors.green.shade700 : Colors.red.shade700),
            SizedBox(width: 16),
            _buildLegendItem('Commission', Colors.purple.shade700),
            SizedBox(width: 16),
            _buildLegendItem('Load', loadProfit >= 0 ? Colors.blue.shade700 : Colors.orange.shade700),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildGCashSection() {
    final gcashProfit = _gcashIncome - _gcashExpense;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('GCash Performance'),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Cash Out (Revenue)',
                      _gcashIncome,
                      Icons.arrow_downward,
                      Colors.green.shade700,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Cash In (Expense)',
                      _gcashExpense,
                      Icons.arrow_upward,
                      Colors.red.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Top-up Amount',
                      _gcashTopup,
                      Icons.add_circle_outline,
                      Colors.orange.shade700,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Net Profit',
                      gcashProfit,
                      Icons.account_balance_wallet,
                      gcashProfit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildGCashChart(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadSection() {
    final loadProfit = _loadIncome - _loadTopup + _loadCommission;
    final profitMargin = _loadIncome > 0 ? (_loadCommission / _loadIncome * 100) : 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Load Wallet Performance'),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Sales Revenue',
                      _loadIncome,
                      Icons.shopping_cart,
                      Colors.green.shade700,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Commission',
                      _loadCommission,
                      Icons.monetization_on,
                      Colors.purple.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Top-up Amount',
                      _loadTopup,
                      Icons.add_circle_outline,
                      Colors.orange.shade700,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Net Profit',
                      loadProfit,
                      Icons.account_balance_wallet,
                      loadProfit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Colors.purple.shade700,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Commission Rate',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${profitMargin.toStringAsFixed(2)}% of sales',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'For every ₱100 in load sales, you earn ₱${profitMargin.toStringAsFixed(2)} in commission',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              _buildLoadChart(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGCashChart() {
    return Container(
      height: 200,
      child: _gcashSpots.isEmpty
          ? Center(child: Text('No GCash data available for selected period'))
          : LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return Text('0', style: TextStyle(color: Colors.grey.shade600, fontSize: 10));
                        if (value % (_maxY / 3).round() != 0) return Text('');
                        return Text(
                          '₱${value.toInt()}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        String text = '';
                        if (_selectedPeriod == 'Week') {
                          final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          if (value >= 0 && value < weekdays.length) {
                            text = weekdays[value.toInt()];
                          }
                        } else if (_selectedPeriod == 'Month') {
                          if (value % 5 == 0) {
                            text = '${value.toInt() + 1}';
                          }
                        } else if (_selectedPeriod == 'Year') {
                          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                          if (value >= 0 && value < months.length) {
                            text = months[value.toInt()];
                          }
                        } else {
                          if (value % 5 == 0) {
                            text = '${value.toInt()}';
                          }
                        }
                        return Text(
                          text,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: _getMinX(_gcashSpots),
                maxX: _getMaxX(_gcashSpots),
                minY: -_maxY,
                maxY: _maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: _gcashSpots,
                    isCurved: true,
                    color: Colors.green.shade700,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.shade700.withOpacity(0.2),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey.shade800,
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isIncome = spot.y >= 0;
                        return LineTooltipItem(
                          '${isIncome ? "Income" : "Expense"}: ₱${spot.y.abs().toStringAsFixed(2)}',
                          TextStyle(
                            color: isIncome ? Colors.green.shade300 : Colors.red.shade300,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLoadChart() {
    return Container(
      height: 200,
      child: _loadSpots.isEmpty
          ? Center(child: Text('No Load data available for selected period'))
          : LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return Text('0', style: TextStyle(color: Colors.grey.shade600, fontSize: 10));
                        if (value % (_maxY / 3).round() != 0) return Text('');
                        return Text(
                          '₱${value.toInt()}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        String text = '';
                        if (_selectedPeriod == 'Week') {
                          final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          if (value >= 0 && value < weekdays.length) {
                            text = weekdays[value.toInt()];
                          }
                        } else if (_selectedPeriod == 'Month') {
                          if (value % 5 == 0) {
                            text = '${value.toInt() + 1}';
                          }
                        } else if (_selectedPeriod == 'Year') {
                          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                          if (value >= 0 && value < months.length) {
                            text = months[value.toInt()];
                          }
                        } else {
                          if (value % 5 == 0) {
                            text = '${value.toInt()}';
                          }
                        }
                        return Text(
                          text,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: _getMinX(_loadSpots),
                maxX: _getMaxX(_loadSpots),
                minY: -_maxY,
                maxY: _maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: _loadSpots,
                    isCurved: true,
                    color: Colors.purple.shade700,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.purple.shade700.withOpacity(0.2),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey.shade800,
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isIncome = spot.y >= 0;
                        return LineTooltipItem(
                          '${isIncome ? "Income" : "Expense"}: ₱${spot.y.abs().toStringAsFixed(2)}',
                          TextStyle(
                            color: isIncome ? Colors.purple.shade300 : Colors.orange.shade300,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
    );
  }

  double _getMinX(List<FlSpot> spots) {
    if (spots.isEmpty) return 0;
    return spots.map((spot) => spot.x).reduce((a, b) => a < b ? a : b);
  }

  double _getMaxX(List<FlSpot> spots) {
    if (spots.isEmpty) return 6; // Default to a week
    return spots.map((spot) => spot.x).reduce((a, b) => a > b ? a : b);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}