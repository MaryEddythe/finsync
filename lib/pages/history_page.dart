import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'All';
  final List<String> _periods = ['Today', 'Week', 'Month', 'All'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildBalanceCard(),
            _buildTabBar(),
            _buildFilterChips(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TransactionHistoryTab(type: 'gcash_in', period: _selectedPeriod),
                  _TransactionHistoryTab(type: 'load', period: _selectedPeriod),
                ],
              ),
            ),
          ],
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
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios, color: Colors.green[700]),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Text(
                'Transaction History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.search, color: Colors.green[700]),
            onPressed: () {
              // Implement search functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return ValueListenableBuilder(
      valueListenable: Hive.box('balances').listenable(),
      builder: (context, box, _) {
        final gcashBalance = box.get('gcash', defaultValue: 0.0);
        final loadBalance = box.get('load', defaultValue: 0.0);
        
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade700, Colors.green.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Balance',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.refresh, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Updated',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '₱${(gcashBalance + loadBalance).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBalanceItem('GCash', gcashBalance, Icons.account_balance_wallet),
                    Container(height: 40, width: 1, color: Colors.white.withOpacity(0.3)),
                    _buildBalanceItem('Load Wallet', loadBalance, Icons.phone_android),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceItem(String title, double amount, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              Text(
                '₱${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.green.shade700,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade700,
        tabs: [
          Tab(
            text: 'GCash',
            icon: Icon(Icons.account_balance_wallet, size: 20),
          ),
          Tab(
            text: 'Load',
            icon: Icon(Icons.phone_android, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
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
            },
            child: Container(
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green.shade700 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  period,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
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
}

class _TransactionHistoryTab extends StatelessWidget {
  final String type;
  final String period;
  
  const _TransactionHistoryTab({
    required this.type,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('transactions').listenable(),
      builder: (context, box, _) {
        final items = _filterTransactions(box.values.toList());
        
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type == 'gcash_in' ? Icons.account_balance_wallet : Icons.phone_android,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 16),
                Text(
                  'No ${type == 'gcash_in' ? 'GCash' : 'Load'} transactions yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: items.length + 1, // +1 for the header
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildSummaryCard(items);
            }
            
            final item = items[index - 1];
            return _buildTransactionCard(item, context);
          },
        );
      },
    );
  }

  List<dynamic> _filterTransactions(List<dynamic> transactions) {
    final now = DateTime.now();
    final filteredTransactions = transactions.where((transaction) {
      if (transaction['type'] == null) return false;
      
      // Filter by type
      bool matchesType = false;
      if (type == 'gcash_in') {
        matchesType = transaction['type'] == 'gcash_in' || 
                      transaction['type'] == 'gcash_out' || 
                      transaction['type'] == 'topup';
      } else if (type == 'load') {
        matchesType = transaction['type'] == 'load';
      }
      
      if (!matchesType) return false;
      
      // Filter by period
      if (period == 'All') return true;
      
      final transactionDate = DateTime.parse(transaction['date']);
      if (period == 'Today') {
        return transactionDate.year == now.year && 
               transactionDate.month == now.month && 
               transactionDate.day == now.day;
      } else if (period == 'Week') {
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return transactionDate.isAfter(weekStart.subtract(Duration(days: 1)));
      } else if (period == 'Month') {
        return transactionDate.year == now.year && 
               transactionDate.month == now.month;
      }
      
      return false;
    }).toList();
    
    // Sort by date (newest first)
    filteredTransactions.sort((a, b) {
      final dateA = DateTime.parse(a['date']);
      final dateB = DateTime.parse(b['date']);
      return dateB.compareTo(dateA);
    });
    
    return filteredTransactions;
  }

  Widget _buildSummaryCard(List<dynamic> transactions) {
    double totalIncome = 0;
    double totalExpense = 0;
    
    for (var transaction in transactions) {
      if (type == 'gcash_in') {
        if (transaction['type'] == 'gcash_out') {
          totalIncome += (transaction['amount'] as num).toDouble();
        } else if (transaction['type'] == 'gcash_in') {
          totalExpense += (transaction['amount'] as num).toDouble();
        } else if (transaction['type'] == 'topup') {
          totalExpense += (transaction['amount'] as num).toDouble();
        }
      } else if (type == 'load') {
        if (transaction['customerPays'] != null) {
          totalIncome += (transaction['customerPays'] as num).toDouble();
        }
        if (transaction['deducted'] != null) {
          totalExpense += (transaction['deducted'] as num).toDouble();
        }
      }
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${period} Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                '${transactions.length} transactions',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Income',
                  totalIncome,
                  Icons.arrow_downward,
                  Colors.green,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'Expense',
                  totalExpense,
                  Icons.arrow_upward,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '₱${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(dynamic item, BuildContext context) {
    final transactionType = item['type'];
    final isIncome = transactionType == 'gcash_out';
    final isLoad = transactionType == 'load';
    
    double amount = 0;
    if (isLoad) {
      amount = (item['customerPays'] as num?)?.toDouble() ?? 0.0;
    } else {
      amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
    }
    
    final date = DateTime.parse(item['date']);
    final formattedDate = DateFormat('MMM dd, yyyy').format(date);
    final formattedTime = DateFormat('hh:mm a').format(date);
    
    IconData transactionIcon;
    Color iconColor;
    String transactionTitle;
    
    if (isLoad) {
      transactionIcon = Icons.phone_android;
      iconColor = Colors.blue;
      transactionTitle = 'Load Sale';
    } else if (transactionType == 'gcash_in') {
      transactionIcon = Icons.arrow_upward;
      iconColor = Colors.red;
      transactionTitle = 'Cash In';
    } else if (transactionType == 'gcash_out') {
      transactionIcon = Icons.arrow_downward;
      iconColor = Colors.green;
      transactionTitle = 'Cash Out';
    } else if (transactionType == 'topup') {
      transactionIcon = Icons.add_circle_outline;
      iconColor = Colors.orange;
      transactionTitle = 'Load Wallet Top-up';
    } else {
      transactionIcon = Icons.swap_horiz;
      iconColor = Colors.purple;
      transactionTitle = 'Transaction';
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Show transaction details
            _showTransactionDetails(context, item);
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    transactionIcon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transactionTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$formattedDate • $formattedTime',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? '+' : isLoad ? '+' : '-'}₱${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isIncome || isLoad ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
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
    );
  }

  void _showTransactionDetails(BuildContext context, dynamic transaction) {
    final transactionType = transaction['type'];
    final isLoad = transactionType == 'load';
    final date = DateTime.parse(transaction['date']);
    final formattedDate = DateFormat('MMMM dd, yyyy').format(date);
    final formattedTime = DateFormat('hh:mm a').format(date);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 24),
                  _buildDetailItem('Type', isLoad ? 'Load Sale' : 
                                   transactionType == 'gcash_in' ? 'Cash In' : 
                                   transactionType == 'gcash_out' ? 'Cash Out' : 
                                   'Load Wallet Top-up'),
                  _buildDetailItem('Date', formattedDate),
                  _buildDetailItem('Time', formattedTime),
                  _buildDetailItem('Status', 'Completed'),
                  Divider(height: 32),
                  if (isLoad) ...[
                    _buildDetailItem('Customer Pays', '₱${transaction['customerPays'].toStringAsFixed(2)}'),
                    _buildDetailItem('Wallet Deducted', '₱${transaction['deducted'].toStringAsFixed(2)}'),
                    _buildDetailItem('Commission', '₱${transaction['commission'].toStringAsFixed(2)}'),
                    _buildDetailItem('Profit', '₱${transaction['profit'].toStringAsFixed(2)}'),
                  ] else ...[
                    _buildDetailItem('Amount', '₱${transaction['amount'].toStringAsFixed(2)}'),
                    if (transaction['serviceFee'] != null)
                      _buildDetailItem('Service Fee', '₱${transaction['serviceFee'].toStringAsFixed(2)}'),
                    if (transaction['totalAmount'] != null)
                      _buildDetailItem('Total Amount', '₱${transaction['totalAmount'].toStringAsFixed(2)}'),
                  ],
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}