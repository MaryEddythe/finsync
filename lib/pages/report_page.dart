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
  final List<String> _periods = ['Today', 'Week', 'Month', 'Quarter', 'All'];
  
  // Filter variables
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedTransactionType = 'All';
  final List<String> _transactionTypes = ['All', 'GCash In', 'GCash Out', 'Load Sale', 'GCash Topup', 'Load Topup'];
  double _minAmount = 0.0;
  double _maxAmount = 10000.0;
  bool _isFilterApplied = false;

  // Summary metrics
  double _gcashIncome = 0.0;
  double _gcashExpense = 0.0;
  double _gcashTopup = 0.0; // GCash topup (adding to GCash balance)
  double _loadIncome = 0.0;
  double _loadCommission = 0.0;
  double _loadTopup = 0.0; // Load wallet topup
  double _gcashLoadTopup = 0.0; // Load topup from GCash balance

  // Revenue and profit tracking
  double _totalRevenue = 0.0;
  double _totalProfit = 0.0;

  // Commission rates
  double _mayaCommissionRate = 0.03;
  double _fixedMarkup = 3.0;

  // Chart data
  List<FlSpot> _gcashSpots = [];
  List<FlSpot> _loadSpots = [];
  List<FlSpot> _topupSpots = [];
  double _maxY = 1000; // Default max value for charts

  bool _isLoading = true;

  // For responsive design
  late double screenWidth;
  late double screenHeight;
  late bool isTablet;
  late bool isLargeScreen;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  // Set up responsive values based on screen size
  void _setResponsiveValues(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    isTablet = screenWidth > 600;
    isLargeScreen = screenWidth > 900;
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
    _gcashLoadTopup = 0.0;
    _totalRevenue = 0.0;
    _totalProfit = 0.0;
    _gcashSpots = [];
    _loadSpots = [];
    _topupSpots = [];

    final transactionsBox = Hive.box('transactions');
    final allTransactions = transactionsBox.values.toList();

    // Filter transactions by selected period or custom filter
    final filteredTransactions = _isFilterApplied 
        ? _filterTransactionsByCustomFilters(allTransactions)
        : _filterTransactionsByPeriod(allTransactions, _selectedPeriod);

    // Process transactions
    for (var tx in filteredTransactions) {
      final txType = tx['type'] as String? ?? '';
      final date = DateTime.parse(
          tx['date'] as String? ?? DateTime.now().toIso8601String());

      if (txType == 'gcash_in') {
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
        final serviceFee = (tx['serviceFee'] as num?)?.toDouble() ?? 0.0;

        // For GCash, only count service fee as revenue/profit
        _totalRevenue += serviceFee;
        _totalProfit += serviceFee;

        _gcashExpense += amount; // Track the cash in amount as expense
        _addToSpots(_gcashSpots, date, amount, false); // Show as negative in chart

      } else if (txType == 'gcash_out') {
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
        final serviceFee = (tx['serviceFee'] as num?)?.toDouble() ?? 0.0;

        // For GCash, only count service fee as revenue/profit
        _totalRevenue += serviceFee;
        _totalProfit += serviceFee;

        _gcashIncome += amount; // Track the cash out amount as income
        _addToSpots(_gcashSpots, date, amount, true); // Show as positive in chart
      } else if (txType == 'load') {
        final customerPays = (tx['customerPays'] as num?)?.toDouble() ?? 0.0;
        final deducted = (tx['deducted'] as num?)?.toDouble() ?? 0.0;

        // Calculate Maya commission
        final mayaCommission = deducted * _mayaCommissionRate;

        // Calculate profit as Maya commission + fixed markup
        final profit = _fixedMarkup + mayaCommission;

        _loadIncome += customerPays;
        _loadCommission += profit;

        // Revenue for Load is Maya commission + fixed markup
        _totalRevenue += profit;
        _totalProfit += profit;

        _addToSpots(_loadSpots, date, customerPays, true);
      } else if (txType == 'topup') {
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
        final wallet = tx['wallet'] as String? ?? 'load';

        if (wallet == 'gcash') {
          // GCash topup (adding to GCash balance)
          _gcashTopup += amount;
          _addToSpots(_topupSpots, date, amount, true);
        } else {
          // Load wallet topup
          _loadTopup += amount;
          _gcashLoadTopup += amount; // This is deducted from GCash balance
          _addToSpots(_topupSpots, date, amount, false);
        }
      } else if (txType == 'gcash_topup') {
        // Specific GCash topup transaction
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
        _gcashTopup += amount;
        _addToSpots(_topupSpots, date, amount, true);
      }
    }

    // Calculate max Y for charts
    _calculateMaxY();

    setState(() {
      _isLoading = false;
    });
  }

  void _addToSpots(
      List<FlSpot> spots, DateTime date, double amount, bool isIncome) {
    // Convert date to x-axis value
    final x = _getXValue(date);

    // Find if there's already a spot for this date
    final existingIndex = spots.indexWhere((spot) => spot.x == x);

    if (existingIndex >= 0) {
      // Update existing spot
      final existingSpot = spots[existingIndex];
      spots[existingIndex] = FlSpot(
          existingSpot.x, existingSpot.y + (isIncome ? amount : -amount));
    } else {
      // Add new spot
      spots.add(FlSpot(x, isIncome ? amount : -amount));
    }

    // Sort spots by x
    spots.sort((a, b) => a.x.compareTo(b.x));
  }

  double _getXValue(DateTime date) {
    if (_selectedPeriod == 'Today') {
      // Hour of day (0-23)
      return date.hour.toDouble();
    } else if (_selectedPeriod == 'Week') {
      // Day of week (0-6)
      return date.weekday.toDouble() - 1;
    } else if (_selectedPeriod == 'Month') {
      // Day of month (1-31)
      return date.day.toDouble() - 1;
    } else if (_selectedPeriod == 'Quarter') {
      // Month within quarter (0-2)
      final quarterStartMonth = ((date.month - 1) ~/ 3) * 3 + 1;
      return (date.month - quarterStartMonth).toDouble();
    } else {
      // All time - use days since epoch
      return date.millisecondsSinceEpoch / (24 * 60 * 60 * 1000);
    }
  }

  void _calculateMaxY() {
    // Find max absolute value in all spot lists
    double maxGcash = 0;
    double maxLoad = 0;
    double maxTopup = 0;

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

    for (var spot in _topupSpots) {
      if (spot.y.abs() > maxTopup) {
        maxTopup = spot.y.abs();
      }
    }

    _maxY =
        [maxGcash, maxLoad, maxTopup, 1000].reduce((a, b) => a > b ? a : b) *
            1.2; // Add 20% margin
  }

  List<dynamic> _filterTransactionsByPeriod(
      List<dynamic> transactions, String period) {
    final now = DateTime.now();

    return transactions.where((tx) {
      if (tx['date'] == null) return false;

      final txDate = DateTime.parse(tx['date'] as String? ?? '');

      if (period == 'Today') {
        // Only transactions from today
        return txDate.year == now.year &&
            txDate.month == now.month &&
            txDate.day == now.day;
      } else if (period == 'Week') {
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return txDate.isAfter(weekStart.subtract(Duration(days: 1))) &&
            txDate.isBefore(weekStart.add(Duration(days: 7)));
      } else if (period == 'Month') {
        return txDate.year == now.year && txDate.month == now.month;
      } else if (period == 'Quarter') {
        final quarterStart =
            DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
        final quarterEnd =
            DateTime(quarterStart.year, quarterStart.month + 3, 0);
        return txDate.isAfter(quarterStart.subtract(Duration(days: 1))) &&
            txDate.isBefore(quarterEnd.add(Duration(days: 1)));
      } else {
        return true; // All time
      }
    }).toList();
  }
  
  List<dynamic> _filterTransactionsByCustomFilters(List<dynamic> transactions) {
    return transactions.where((tx) {
      if (tx['date'] == null) return false;

      final txDate = DateTime.parse(tx['date'] as String? ?? '');
      final txType = tx['type'] as String? ?? '';
      
      // Filter by date range
      if (_startDate != null && txDate.isBefore(_startDate!)) {
        return false;
      }
      
      if (_endDate != null) {
        // Add one day to include the end date fully
        final endDatePlusOne = _endDate!.add(Duration(days: 1));
        if (txDate.isAfter(endDatePlusOne)) {
          return false;
        }
      }
      
      // Filter by transaction type
      if (_selectedTransactionType != 'All') {
        if (_selectedTransactionType == 'GCash In' && txType != 'gcash_in') {
          return false;
        } else if (_selectedTransactionType == 'GCash Out' && txType != 'gcash_out') {
          return false;
        } else if (_selectedTransactionType == 'Load Sale' && txType != 'load') {
          return false;
        } else if (_selectedTransactionType == 'GCash Topup' && txType != 'gcash_topup') {
          return false;
        } else if (_selectedTransactionType == 'Load Topup' && txType != 'topup') {
          return false;
        }
      }
      
      // Filter by amount range
      double amount = 0.0;
      if (txType == 'load') {
        amount = (tx['customerPays'] as num?)?.toDouble() ?? 0.0;
      } else {
        amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
      }
      
      if (amount < _minAmount || amount > _maxAmount) {
        return false;
      }
      
      return true;
    }).toList();
  }

  void _showFilterOptions() {
    // Set initial values for the filter
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;
    String tempTransactionType = _selectedTransactionType;
    double tempMinAmount = _minAmount;
    double tempMaxAmount = _maxAmount;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filter Transactions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Date Range',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: tempStartDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setModalState(() {
                                        tempStartDate = picked;
                                      });
                                    }
                                  },
                                  child: _buildDateField(
                                    tempStartDate == null 
                                      ? 'Start Date' 
                                      : DateFormat('MMM dd, yyyy').format(tempStartDate!),
                                    Icons.calendar_today_rounded,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: tempEndDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setModalState(() {
                                        tempEndDate = picked;
                                      });
                                    }
                                  },
                                  child: _buildDateField(
                                    tempEndDate == null 
                                      ? 'End Date' 
                                      : DateFormat('MMM dd, yyyy').format(tempEndDate!),
                                    Icons.calendar_today_rounded,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Transaction Type',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _transactionTypes.map((type) {
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    tempTransactionType = type;
                                  });
                                },
                                child: _buildFilterChip(type, type == tempTransactionType),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Amount Range',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildAmountField('Min: ₱${tempMinAmount.toStringAsFixed(0)}'),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildAmountField('Max: ₱${tempMaxAmount.toStringAsFixed(0)}'),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          RangeSlider(
                            values: RangeValues(tempMinAmount, tempMaxAmount),
                            min: 0,
                            max: 10000,
                            divisions: 100,
                            labels: RangeLabels(
                              '₱${tempMinAmount.toStringAsFixed(0)}',
                              '₱${tempMaxAmount.toStringAsFixed(0)}',
                            ),
                            onChanged: (RangeValues values) {
                              setModalState(() {
                                tempMinAmount = values.start;
                                tempMaxAmount = values.end;
                              });
                            },
                            activeColor: Colors.green[700],
                            inactiveColor: Colors.grey[300],
                          ),
                          SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setModalState(() {
                                      tempStartDate = null;
                                      tempEndDate = null;
                                      tempTransactionType = 'All';
                                      tempMinAmount = 0.0;
                                      tempMaxAmount = 10000.0;
                                    });
                                  },
                                  child: Text('Reset'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey[700],
                                    side: BorderSide(color: Colors.grey[300]!),
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _startDate = tempStartDate;
                                      _endDate = tempEndDate;
                                      _selectedTransactionType = tempTransactionType;
                                      _minAmount = tempMinAmount;
                                      _maxAmount = tempMaxAmount;
                                      _isFilterApplied = true;
                                    });
                                    Navigator.pop(context);
                                    _loadReportData();
                                  },
                                  child: Text('Apply Filters'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[700],
                                    foregroundColor: Colors.white,
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
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateField(String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green[700] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.green[700]! : Colors.grey[300]!,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _setResponsiveValues(context);

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
                    _buildFilterBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(_adaptivePadding(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummarySection(),
                            SizedBox(height: _adaptiveSpacing(24)),
                            _buildGCashSection(),
                            SizedBox(height: _adaptiveSpacing(24)),
                            _buildLoadSection(),
                            SizedBox(height: _adaptiveSpacing(24)),
                            _buildTopupSection(),
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
      padding: EdgeInsets.all(_adaptivePadding(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Financial Reports',
            style: TextStyle(
              fontSize: _adaptiveFontSize(24),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              if (_isFilterApplied)
                IconButton(
                  icon: Icon(Icons.filter_list_off, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _isFilterApplied = false;
                      _startDate = null;
                      _endDate = null;
                      _selectedTransactionType = 'All';
                      _minAmount = 0.0;
                      _maxAmount = 10000.0;
                    });
                    _loadReportData();
                  },
                  tooltip: 'Clear Filters',
                  iconSize: _adaptiveIconSize(24),
                ),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadReportData,
                tooltip: 'Refresh Reports',
                iconSize: _adaptiveIconSize(24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: _adaptivePadding(16), vertical: _adaptivePadding(8)),
      child: Row(
        children: [
          if (!_isFilterApplied) ...[
            Expanded(
              child: Container(
                height: _adaptiveHeight(40),
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
                        margin: EdgeInsets.only(right: _adaptiveSpacing(8)),
                        padding: EdgeInsets.symmetric(horizontal: _adaptivePadding(16)),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(_adaptiveRadius(20)),
                        ),
                        child: Center(
                          child: Text(
                            period,
                            style: TextStyle(
                              color: isSelected ? Colors.green.shade800 : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: _adaptiveFontSize(14),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: Container(
                height: _adaptiveHeight(40),
                padding: EdgeInsets.symmetric(horizontal: _adaptivePadding(12), vertical: _adaptivePadding(8)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_adaptiveRadius(20)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: Colors.green[700], size: _adaptiveIconSize(18)),
                    SizedBox(width: _adaptiveSpacing(8)),
                    Expanded(
                      child: Text(
                        _getFilterSummary(),
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: _adaptiveFontSize(12),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(width: _adaptiveSpacing(8)),
          GestureDetector(
            onTap: _showFilterOptions,
            child: Container(
              height: _adaptiveHeight(40),
              width: _adaptiveHeight(40),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.filter_alt,
                color: Colors.green[700],
                size: _adaptiveIconSize(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getFilterSummary() {
    if (!_isFilterApplied) return "No filters applied";
    
    List<String> filterParts = [];
    
    if (_startDate != null && _endDate != null) {
      filterParts.add("${DateFormat('MM/dd').format(_startDate!)} - ${DateFormat('MM/dd').format(_endDate!)}");
    } else if (_startDate != null) {
      filterParts.add("From ${DateFormat('MM/dd').format(_startDate!)}");
    } else if (_endDate != null) {
      filterParts.add("Until ${DateFormat('MM/dd').format(_endDate!)}");
    }
    
    if (_selectedTransactionType != 'All') {
      filterParts.add(_selectedTransactionType);
    }
    
    if (_minAmount > 0 || _maxAmount < 10000) {
      filterParts.add("₱${_minAmount.toInt()}-₱${_maxAmount.toInt()}");
    }
    
    return filterParts.join(" • ");
  }

  Widget _buildSummarySection() {
    final gcashProfit = _gcashIncome - _gcashExpense;
    final loadProfit = _loadIncome - _loadTopup;
    final totalProfit = _totalProfit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Overall Summary'),
        SizedBox(height: _adaptiveSpacing(16)),
        Container(
          padding: EdgeInsets.all(_adaptivePadding(20)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_adaptiveRadius(16)),
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
              _buildResponsiveRow(
                first: _buildSummaryCard(
                  'Total Revenue',
                  _totalRevenue,
                  Icons.account_balance_wallet,
                  Colors.green.shade700,
                ),
                second: _buildSummaryCard(
                  'Total Expenses',
                  _gcashExpense + _gcashTopup + _loadTopup,
                  Icons.money_off,
                  Colors.red.shade700,
                ),
                spacing: _adaptiveSpacing(16),
              ),
              SizedBox(height: _adaptiveSpacing(16)),
              _buildResponsiveRow(
                first: _buildSummaryCard(
                  'Load Commission',
                  _loadCommission,
                  Icons.phone_android,
                  Colors.purple.shade700,
                ),
                second: _buildSummaryCard(
                  'Net Profit',
                  totalProfit,
                  Icons.trending_up,
                  Colors.blue.shade700,
                ),
                spacing: _adaptiveSpacing(16),
              ),
              SizedBox(height: _adaptiveSpacing(20)),
              Container(
                padding: EdgeInsets.all(_adaptivePadding(16)),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(_adaptiveRadius(12)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.insights,
                      color: Colors.blue.shade700,
                      size: _adaptiveIconSize(24),
                    ),
                    SizedBox(width: _adaptiveSpacing(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profit Breakdown',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                              fontSize: _adaptiveFontSize(14),
                            ),
                          ),
                          SizedBox(height: _adaptiveSpacing(8)),
                          _buildProfitBreakdownBar(
                              gcashProfit, _loadCommission, loadProfit),
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

  Widget _buildProfitBreakdownBar(
      double gcashProfit, double loadCommission, double loadProfit) {
    final total = gcashProfit.abs() + loadCommission.abs() + loadProfit.abs();

    if (total == 0) {
      return Text(
        'No profit data available for this period',
        style: TextStyle(
          fontSize: _adaptiveFontSize(12),
          color: Colors.grey.shade600,
        ),
      );
    }

    final gcashWidth = (gcashProfit / total * 100).abs();
    final commissionWidth = (loadCommission / total * 100).abs();
    final loadWidth = (loadProfit / total * 100).abs();

    // Calculate responsive widths based on available space
    final availableWidth =
        screenWidth - _adaptivePadding(80); // Accounting for padding
    final barWidth = isTablet ? availableWidth * 0.7 : availableWidth * 0.6;

    return Column(
      children: [
        Container(
          height: _adaptiveHeight(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_adaptiveRadius(10)),
          ),
          child: Row(
            children: [
              Container(
                width: gcashWidth * 0.01 * barWidth,
                decoration: BoxDecoration(
                  color: gcashProfit >= 0
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(_adaptiveRadius(10)),
                    bottomLeft: Radius.circular(_adaptiveRadius(10)),
                  ),
                ),
              ),
              Container(
                width: commissionWidth * 0.01 * barWidth,
                color: Colors.purple.shade700,
              ),
              Container(
                width: loadWidth * 0.01 * barWidth,
                decoration: BoxDecoration(
                  color: loadProfit >= 0
                      ? Colors.blue.shade700
                      : Colors.orange.shade700,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(_adaptiveRadius(10)),
                    bottomRight: Radius.circular(_adaptiveRadius(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: _adaptiveSpacing(8)),
        Wrap(
          spacing: _adaptiveSpacing(16),
          runSpacing: _adaptiveSpacing(8),
          children: [
            _buildLegendItem('GCash',
                gcashProfit >= 0 ? Colors.green.shade700 : Colors.red.shade700),
            _buildLegendItem('Commission', Colors.purple.shade700),
            _buildLegendItem(
                'Load',
                loadProfit >= 0
                    ? Colors.blue.shade700
                    : Colors.orange.shade700),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _adaptiveSize(12),
          height: _adaptiveSize(12),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: _adaptiveSpacing(4)),
        Text(
          label,
          style: TextStyle(
            fontSize: _adaptiveFontSize(10),
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildGCashSection() {
    // Calculate net profit as total service fees
    double gcashServiceFees = 0.0;
    
    final transactionsBox = Hive.box('transactions');
    final filteredTransactions = _isFilterApplied
        ? _filterTransactionsByCustomFilters(transactionsBox.values.toList())
        : _filterTransactionsByPeriod(transactionsBox.values.toList(), _selectedPeriod);

    for (var tx in filteredTransactions) {
      if (tx['type'] == 'gcash_in' || tx['type'] == 'gcash_out') {
        final serviceFee = (tx['serviceFee'] as num?)?.toDouble() ?? 0.0;
        gcashServiceFees += serviceFee;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('GCash Performance'),
        SizedBox(height: _adaptiveSpacing(16)),
        Container(
          padding: EdgeInsets.all(_adaptivePadding(20)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_adaptiveRadius(16)),
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
              _buildResponsiveRow(
                first: _buildMetricCard(
                  'Cash In',
                  _gcashExpense,
                  Icons.arrow_upward,
                  Colors.red[700]!,
                ),
                second: _buildMetricCard(
                  'Cash Out',
                  _gcashIncome,
                  Icons.arrow_downward,
                  Colors.green[700]!,
                ),
                spacing: _adaptiveSpacing(16),
              ),
              SizedBox(height: _adaptiveSpacing(16)),
              _buildResponsiveRow(
                first: _buildMetricCard(
                  'GCash Topup',
                  _gcashTopup,
                  Icons.add_circle_outline,
                  Colors.blue[700]!,
                ),
                second: _buildMetricCard(
                  'Net Profit',
                  gcashServiceFees, // Use accumulated service fees for net profit
                  Icons.account_balance_wallet,
                  Colors.green[700]!,
                ),
                spacing: _adaptiveSpacing(16),
              ),
              SizedBox(height: _adaptiveSpacing(20)),
              _buildGCashChart(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadSection() {
    final loadProfit = _loadIncome - _loadTopup + _loadCommission;
    final profitMargin =
        _loadIncome > 0 ? (_loadCommission / _loadIncome * 100) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Load Wallet Performance'),
        SizedBox(height: _adaptiveSpacing(16)),
        Container(
          padding: EdgeInsets.all(_adaptivePadding(20)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_adaptiveRadius(16)),
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
              _buildResponsiveRow(
                first: _buildMetricCard(
                  'Sales Revenue',
                  _loadIncome,
                  Icons.shopping_cart,
                  Colors.green.shade700,
                ),
                second: _buildMetricCard(
                  'Commission',
                  _loadCommission,
                  Icons.monetization_on,
                  Colors.purple.shade700,
                ),
                spacing: _adaptiveSpacing(16),
              ),
              SizedBox(height: _adaptiveSpacing(16)),
              _buildResponsiveRow(
                first: _buildMetricCard(
                  'Load Topup',
                  _loadTopup,
                  Icons.add_circle_outline,
                  Colors.orange.shade700,
                ),
                second: _buildMetricCard(
                  'Net Profit',
                  loadProfit,
                  Icons.account_balance_wallet,
                  loadProfit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                ),
                spacing: _adaptiveSpacing(16),
              ),
              SizedBox(height: _adaptiveSpacing(20)),
              Container(
                padding: EdgeInsets.all(_adaptivePadding(16)),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(_adaptiveRadius(12)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Colors.purple.shade700,
                      size: _adaptiveIconSize(24),
                    ),
                    SizedBox(width: _adaptiveSpacing(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Commission Rate',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                              fontSize: _adaptiveFontSize(14),
                            ),
                          ),
                          SizedBox(height: _adaptiveSpacing(4)),
                          Text(
                            '${profitMargin.toStringAsFixed(2)}% of sales',
                            style: TextStyle(
                              fontSize: _adaptiveFontSize(18),
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                          SizedBox(height: _adaptiveSpacing(8)),
                          Text(
                            'For every ₱100 in load sales, you earn ₱${profitMargin.toStringAsFixed(2)} in commission',
                            style: TextStyle(
                              fontSize: _adaptiveFontSize(12),
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: _adaptiveSpacing(20)),
              _buildLoadChart(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopupSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Topup Analysis'),
        SizedBox(height: _adaptiveSpacing(16)),
        Container(
          padding: EdgeInsets.all(_adaptivePadding(20)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_adaptiveRadius(16)),
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
              _buildResponsiveRow(
                first: _buildMetricCard(
                  'GCash Topup',
                  _gcashTopup,
                  Icons.account_balance_wallet,
                  Colors.blue.shade700,
                ),
                second: _buildMetricCard(
                  'Load Wallet Topup',
                  _loadTopup,
                  Icons.phone_android,
                  Colors.orange.shade700,
                ),
                spacing: _adaptiveSpacing(16),
              ),
              SizedBox(height: _adaptiveSpacing(16)),
              _buildResponsiveRow(
                first: _buildMetricCard(
                  'Load Topup from GCash',
                  _gcashLoadTopup,
                  Icons.swap_horiz,
                  Colors.purple.shade700,
                ),
                second: _buildMetricCard(
                  'Total Topup',
                  _gcashTopup + _loadTopup,
                  Icons.add_circle,
                  Colors.teal.shade700,
                ),
                spacing: _adaptiveSpacing(16),
              ),
              SizedBox(height: _adaptiveSpacing(20)),
              Container(
                padding: EdgeInsets.all(_adaptivePadding(16)),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(_adaptiveRadius(12)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: _adaptiveIconSize(24),
                    ),
                    SizedBox(width: _adaptiveSpacing(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Topup Distribution',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                              fontSize: _adaptiveFontSize(14),
                            ),
                          ),
                          SizedBox(height: _adaptiveSpacing(8)),
                          _buildTopupDistributionBar(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: _adaptiveSpacing(20)),
              _buildTopupChart(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopupDistributionBar() {
    final total = _gcashTopup + _loadTopup;

    if (total == 0) {
      return Text(
        'No topup data available for this period',
        style: TextStyle(
          fontSize: _adaptiveFontSize(12),
          color: Colors.grey.shade600,
        ),
      );
    }

    final gcashWidth = (_gcashTopup / total * 100);
    final loadWidth = (_loadTopup / total * 100);

    // Calculate responsive widths based on available space
    final availableWidth =
        screenWidth - _adaptivePadding(80); // Accounting for padding
    final barWidth = isTablet ? availableWidth * 0.7 : availableWidth * 0.6;

    return Column(
      children: [
        Container(
          height: _adaptiveHeight(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_adaptiveRadius(10)),
          ),
          child: Row(
            children: [
              Container(
                width: gcashWidth * 0.01 * barWidth,
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(_adaptiveRadius(10)),
                    bottomLeft: Radius.circular(_adaptiveRadius(10)),
                  ),
                ),
              ),
              Container(
                width: loadWidth * 0.01 * barWidth,
                decoration: BoxDecoration(
                  color: Colors.orange.shade700,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(_adaptiveRadius(10)),
                    bottomRight: Radius.circular(_adaptiveRadius(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: _adaptiveSpacing(8)),
        Wrap(
          spacing: _adaptiveSpacing(16),
          runSpacing: _adaptiveSpacing(8),
          alignment: WrapAlignment.spaceBetween,
          children: [
            _buildLegendItem('GCash Topup', Colors.blue.shade700),
            _buildLegendItem('Load Wallet Topup', Colors.orange.shade700),
          ],
        ),
        SizedBox(height: _adaptiveSpacing(8)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${gcashWidth.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: _adaptiveFontSize(12),
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            Text(
              '${loadWidth.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: _adaptiveFontSize(12),
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, double amount, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(_adaptivePadding(16)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_adaptiveRadius(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: _adaptiveIconSize(20)),
              SizedBox(width: _adaptiveSpacing(8)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: _adaptiveFontSize(14),
                    color: Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: _adaptiveSpacing(12)),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: _adaptiveFontSize(20),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, double amount, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(_adaptivePadding(16)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_adaptiveRadius(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: _adaptiveIconSize(20)),
              SizedBox(width: _adaptiveSpacing(8)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: _adaptiveFontSize(14),
                    color: Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: _adaptiveSpacing(12)),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: _adaptiveFontSize(18),
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
      height: _adaptiveHeight(200),
      child: _gcashSpots.isEmpty
          ? Center(
              child: Text(
                'No GCash data available for selected period',
                style: TextStyle(fontSize: _adaptiveFontSize(14)),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value == 0)
                              return Text('0',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: _adaptiveFontSize(10)));
                            if (value % (_maxY / 3).round() != 0)
                              return Text('');
                            return Text(
                              '₱${value.toInt()}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: _adaptiveFontSize(10),
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
                            if (_selectedPeriod == 'Today') {
                              // Show hours for today
                              if (value % 3 == 0) {
                                final hour = value.toInt();
                                final amPm = hour >= 12 ? 'PM' : 'AM';
                                final hour12 = hour == 0
                                    ? 12
                                    : (hour > 12 ? hour - 12 : hour);
                                text = '$hour12$amPm';
                              }
                            } else if (_selectedPeriod == 'Week') {
                              final weekdays = [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun'
                              ];
                              if (value >= 0 && value < weekdays.length) {
                                text = weekdays[value.toInt()];
                              }
                            } else if (_selectedPeriod == 'Month') {
                              if (value % 5 == 0) {
                                text = '${value.toInt() + 1}';
                              }
                            } else if (_selectedPeriod == 'Quarter') {
                              if (value.toInt() == 0) text = 'Month 1';
                              if (value.toInt() == 1) text = 'Month 2';
                              if (value.toInt() == 2) text = 'Month 3';
                            } else {
                              if (value % 5 == 0) {
                                text = '${value.toInt()}';
                              }
                            }
                            return Text(
                              text,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: _adaptiveFontSize(10),
                              ),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            final isIncome = spot.y >= 0;
                            return LineTooltipItem(
                              '${isIncome ? "Income" : "Expense"}: ₱${spot.y.abs().toStringAsFixed(2)}',
                              TextStyle(
                                color: isIncome
                                    ? Colors.green.shade300
                                    : Colors.red.shade300,
                                fontWeight: FontWeight.bold,
                                fontSize: _adaptiveFontSize(12),
                                backgroundColor: Colors.blueGrey.shade800,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildLoadChart() {
    return Container(
      height: _adaptiveHeight(200),
      child: _loadSpots.isEmpty
          ? Center(
              child: Text(
                'No Load data available for selected period',
                style: TextStyle(fontSize: _adaptiveFontSize(14)),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value == 0)
                              return Text('0',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: _adaptiveFontSize(10)));
                            if (value % (_maxY / 3).round() != 0)
                              return Text('');
                            return Text(
                              '₱${value.toInt()}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: _adaptiveFontSize(10),
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
                            if (_selectedPeriod == 'Today') {
                              // Show hours for today
                              if (value % 3 == 0) {
                                final hour = value.toInt();
                                final amPm = hour >= 12 ? 'PM' : 'AM';
                                final hour12 = hour == 0
                                    ? 12
                                    : (hour > 12 ? hour - 12 : hour);
                                text = '$hour12$amPm';
                              }
                            } else if (_selectedPeriod == 'Week') {
                              final weekdays = [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun'
                              ];
                              if (value >= 0 && value < weekdays.length) {
                                text = weekdays[value.toInt()];
                              }
                            } else if (_selectedPeriod == 'Month') {
                              if (value % 5 == 0) {
                                text = '${value.toInt() + 1}';
                              }
                            } else if (_selectedPeriod == 'Quarter') {
                              if (value.toInt() == 0) text = 'Month 1';
                              if (value.toInt() == 1) text = 'Month 2';
                              if (value.toInt() == 2) text = 'Month 3';
                            } else {
                              if (value % 5 == 0) {
                                text = '${value.toInt()}';
                              }
                            }
                            return Text(
                              text,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: _adaptiveFontSize(10),
                              ),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            final isIncome = spot.y >= 0;
                            return LineTooltipItem(
                              '${isIncome ? "Income" : "Expense"}: ₱${spot.y.abs().toStringAsFixed(2)}',
                              TextStyle(
                                color: isIncome
                                    ? Colors.purple.shade300
                                    : Colors.orange.shade300,
                                fontWeight: FontWeight.bold,
                                fontSize: _adaptiveFontSize(12),
                                backgroundColor: Colors.blueGrey.shade800,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTopupChart() {
    return Container(
      height: _adaptiveHeight(200),
      child: _topupSpots.isEmpty
          ? Center(
              child: Text(
                'No topup data available for selected period',
                style: TextStyle(fontSize: _adaptiveFontSize(14)),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value == 0)
                              return Text('0',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: _adaptiveFontSize(10)));
                            if (value % (_maxY / 3).round() != 0)
                              return Text('');
                            return Text(
                              '₱${value.toInt()}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: _adaptiveFontSize(10),
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
                            if (_selectedPeriod == 'Today') {
                              // Show hours for today
                              if (value % 3 == 0) {
                                final hour = value.toInt();
                                final amPm = hour >= 12 ? 'PM' : 'AM';
                                final hour12 = hour == 0
                                    ? 12
                                    : (hour > 12 ? hour - 12 : hour);
                                text = '$hour12$amPm';
                              }
                            } else if (_selectedPeriod == 'Week') {
                              final weekdays = [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun'
                              ];
                              if (value >= 0 && value < weekdays.length) {
                                text = weekdays[value.toInt()];
                              }
                            } else if (_selectedPeriod == 'Month') {
                              if (value % 5 == 0) {
                                text = '${value.toInt() + 1}';
                              }
                            } else if (_selectedPeriod == 'Quarter') {
                              if (value.toInt() == 0) text = 'Month 1';
                              if (value.toInt() == 1) text = 'Month 2';
                              if (value.toInt() == 2) text = 'Month 3';
                            } else {
                              if (value % 5 == 0) {
                                text = '${value.toInt()}';
                              }
                            }
                            return Text(
                              text,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: _adaptiveFontSize(10),
                              ),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: _getMinX(_topupSpots),
                    maxX: _getMaxX(_topupSpots),
                    minY: -_maxY,
                    maxY: _maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: _topupSpots,
                        isCurved: true,
                        color: Colors.blue.shade700,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.shade700.withOpacity(0.2),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            final isGCashTopup = spot.y >= 0;
                            return LineTooltipItem(
                              '${isGCashTopup ? "GCash Topup" : "Load Topup"}: ₱${spot.y.abs().toStringAsFixed(2)}',
                              TextStyle(
                                color: isGCashTopup
                                    ? Colors.blue.shade300
                                    : Colors.orange.shade300,
                                fontWeight: FontWeight.bold,
                                fontSize: _adaptiveFontSize(12),
                                backgroundColor: Colors.blueGrey.shade800,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  double _getMinX(List<FlSpot> spots) {
    if (spots.isEmpty) return 0;
    return spots.map((spot) => spot.x).reduce((a, b) => a < b ? a : b);
  }

  double _getMaxX(List<FlSpot> spots) {
    if (spots.isEmpty) {
      if (_selectedPeriod == 'Today') {
        return 23; // 24 hours (0-23)
      } else if (_selectedPeriod == 'Week') {
        return 6; // 7 days (0-6)
      } else if (_selectedPeriod == 'Month') {
        return 30; // 31 days (0-30)
      } else if (_selectedPeriod == 'Quarter') {
        return 2; // 3 months (0-2)
      } else {
        return 30; // Default
      }
    }
    return spots.map((spot) => spot.x).reduce((a, b) => a > b ? a : b);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: _adaptiveFontSize(20),
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  // Helper method to create responsive rows that can switch to columns on small screens
  Widget _buildResponsiveRow({
    required Widget first,
    required Widget second,
    required double spacing,
  }) {
    if (isTablet) {
      // On larger screens, use a row
      return Row(
        children: [
          Expanded(child: first),
          SizedBox(width: spacing),
          Expanded(child: second),
        ],
      );
    } else {
      // On smaller screens, use a column
      return Column(
        children: [
          first,
          SizedBox(height: spacing),
          second,
        ],
      );
    }
  }

  // Responsive helpers
  double _adaptiveFontSize(double size) {
    if (isLargeScreen) return size * 1.2;
    if (isTablet) return size * 1.1;
    return size;
  }

  double _adaptiveIconSize(double size) {
    if (isLargeScreen) return size * 1.2;
    if (isTablet) return size * 1.1;
    return size;
  }

  double _adaptivePadding(double padding) {
    if (isLargeScreen) return padding * 1.5;
    if (isTablet) return padding * 1.2;
    return padding;
  }

  double _adaptiveSpacing(double spacing) {
    if (isLargeScreen) return spacing * 1.5;
    if (isTablet) return spacing * 1.2;
    return spacing;
  }

  double _adaptiveRadius(double radius) {
    if (isLargeScreen) return radius * 1.3;
    if (isTablet) return radius * 1.1;
    return radius;
  }

  double _adaptiveHeight(double height) {
    double scaleFactor = screenHeight / 800; // Base height
    return height * scaleFactor;
  }

  double _adaptiveSize(double size) {
    if (isLargeScreen) return size * 1.3;
    if (isTablet) return size * 1.1;
    return size;
  }
}
