import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'All';
  final List<String> _periods = ['Today', 'Week', 'Month', 'All'];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (!_isSearching) _buildBalanceCard(),
            if (!_isSearching) _buildTabBar(),
            if (!_isSearching) _buildFilterChips(),
            if (!_isSearching)
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _TransactionHistoryTab(type: 'all', period: _selectedPeriod),
                    _TransactionHistoryTab(type: 'gcash', period: _selectedPeriod),
                    _TransactionHistoryTab(type: 'load', period: _selectedPeriod),
                    _TransactionHistoryTab(type: 'topup', period: _selectedPeriod),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implement export functionality
          _showExportOptions();
        },
        backgroundColor: Colors.green[700],
        child: Icon(Icons.ios_share, color: Colors.white),
        elevation: 4,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.filter_list_rounded,
                    color: Colors.green[700], size: 24),
                onPressed: () {
                  _showFilterOptions();
                },
                splashRadius: 24,
                tooltip: 'Advanced filters',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(dynamic item, BuildContext context) {
    final transactionType = item['type'];
    final isLoad = transactionType == 'load';

    if (isLoad) {
      final date = DateTime.parse(item['date']);
      final formattedTime = DateFormat('h:mm a').format(date);
      final customerPays = item['customerPays'] is num ? item['customerPays'].toDouble() : 0.0;
      final deducted = item['deducted'] is num ? item['deducted'].toDouble() : 0.0;
      final profit = item['profit'] is num ? item['profit'].toDouble() : 0.0;
      final commission = item['commission'] is num ? item['commission'].toDouble() : 0.0;

      return Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFFF8E7FF), // Light purple/pink background to match image
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phone_android,
                    color: Colors.purple[700],
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Load Sale',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[800]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        formattedTime,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+₱${customerPays.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green[700],
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Profit: ₱${profit.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Divider(height: 1, color: Colors.purple[200]),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Wallet Deducted:',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                Text(
                  '-₱${deducted.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red[700]),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Commission:',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                Text(
                  '-₱${commission.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // For other transaction types
    final isIncome =
        transactionType == 'gcash_out' || transactionType == 'gcash_topup';

    double amount = (item['amount'] as num?)?.toDouble() ?? 0.0;

    final date = DateTime.parse(item['date']);
    final formattedTime = DateFormat('hh:mm a').format(date);

    IconData transactionIcon;
    Color iconColor;
    String transactionTitle;
    Color amountColor;
    String amountPrefix;

    if (transactionType == 'gcash_in') {
      transactionIcon = Icons.arrow_upward_rounded;
      iconColor = Colors.red;
      transactionTitle = 'GCash Cash In';
      amountColor = Colors.red[700]!;
      amountPrefix = '-';
    } else if (transactionType == 'gcash_out') {
      transactionIcon = Icons.arrow_downward_rounded;
      iconColor = Colors.green;
      transactionTitle = 'GCash Cash Out';
      amountColor = Colors.green[700]!;
      amountPrefix = '+';
    } else if (transactionType == 'topup') {
      transactionIcon = Icons.add_circle_outline_rounded;
      iconColor = Colors.orange;
      transactionTitle = 'Load Wallet Top-up';
      amountColor = Colors.orange[700]!;
      amountPrefix = '-';
    } else if (transactionType == 'gcash_topup') {
      transactionIcon = Icons.account_balance_wallet_rounded;
      iconColor = Colors.blue;
      transactionTitle = 'GCash Top-up';
      amountColor = Colors.green[700]!;
      amountPrefix = '+';
    } else {
      transactionIcon = Icons.swap_horiz_rounded;
      iconColor = Colors.purple;
      transactionTitle = 'Transaction';
      amountColor = Colors.black;
      amountPrefix = '';
    }

    // Fee (serviceFee) if available
    String? feeText;
    if (item['serviceFee'] != null) {
      final fee = (item['serviceFee'] as num?)?.toDouble() ?? 0.0;
      feeText = 'Fee: ₱${fee.toStringAsFixed(2)}';
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
            _showTransactionDetails(context, item);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon circle
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    transactionIcon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                // Title and time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transactionTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.grey[900],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Amount and fee
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$amountPrefix₱${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: amountColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (feeText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          feeText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w400,
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

    IconData transactionIcon;
    Color iconColor;
    String transactionTitle;

    if (isLoad) {
      transactionIcon = Icons.smartphone_rounded;
      iconColor = Colors.blue;
      transactionTitle = 'Load Sale';
    } else if (transactionType == 'gcash_in') {
      transactionIcon = Icons.arrow_upward_rounded;
      iconColor = Colors.red;
      transactionTitle = 'Cash In';
    } else if (transactionType == 'gcash_out') {
      transactionIcon = Icons.arrow_downward_rounded;
      iconColor = Colors.green;
      transactionTitle = 'Cash Out';
    } else if (transactionType == 'topup') {
      transactionIcon = Icons.add_circle_outline_rounded;
      iconColor = Colors.orange;
      transactionTitle = 'Load Wallet Top-up';
    } else if (transactionType == 'gcash_topup') {
      transactionIcon = Icons.account_balance_wallet_rounded;
      iconColor = Colors.blue;
      transactionTitle = 'GCash Top-up';
    } else {
      transactionIcon = Icons.swap_horiz_rounded;
      iconColor = Colors.purple;
      transactionTitle = 'Transaction';
    }

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
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              transactionIcon,
                              color: iconColor,
                              size: 28,
                            ),
                          ),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transactionTitle,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 12,
                                      color: Colors.green[700],
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Completed',
                                      style: TextStyle(
                                        fontSize: 10,
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
                      SizedBox(height: 24),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildDetailItem('Date', formattedDate,
                                Icons.calendar_today_rounded),
                            Divider(height: 24, color: Colors.grey[200]),
                            _buildDetailItem('Time', formattedTime,
                                Icons.access_time_rounded),
                            Divider(height: 24, color: Colors.grey[200]),
                            _buildDetailItem('Transaction ID',
                                '#${transaction.key}', Icons.tag_rounded),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Transaction Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            if (isLoad) ...[
                              _buildDetailItem(
                                  'Customer Pays',
                                  '₱${transaction['customerPays'].toStringAsFixed(2)}',
                                  Icons.payments_rounded),
                              Divider(height: 24, color: Colors.grey[200]),
                              _buildDetailItem(
                                  'Wallet Deducted',
                                  '₱${transaction['deducted'].toStringAsFixed(2)}',
                                  Icons.remove_circle_outline_rounded),
                              Divider(height: 24, color: Colors.grey[200]),
                              _buildDetailItem(
                                  'Commission',
                                  '₱${transaction['commission'].toStringAsFixed(2)}',
                                  Icons.monetization_on_rounded),
                              Divider(height: 24, color: Colors.grey[200]),
                              _buildDetailItem(
                                  'Profit',
                                  '₱${transaction['profit'].toStringAsFixed(2)}',
                                  Icons.trending_up_rounded),
                            ] else ...[
                              _buildDetailItem(
                                  'Amount',
                                  '₱${transaction['amount'].toStringAsFixed(2)}',
                                  Icons.attach_money_rounded),
                              if (transaction['serviceFee'] != null) ...[
                                Divider(height: 24, color: Colors.grey[200]),
                                _buildDetailItem(
                                    'Service Fee',
                                    '₱${transaction['serviceFee'].toStringAsFixed(2)}',
                                    Icons.receipt_long_rounded),
                              ],
                              if (transaction['totalAmount'] != null) ...[
                                Divider(height: 24, color: Colors.grey[200]),
                                _buildDetailItem(
                                    'Total Amount',
                                    '₱${transaction['totalAmount'].toStringAsFixed(2)}',
                                    Icons.account_balance_wallet_rounded),
                              ],
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Implement share functionality
                                Navigator.pop(context);
                              },
                              icon: Icon(Icons.share_rounded, size: 18),
                              label: Text('Share'),
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
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Implement delete functionality
                                Navigator.pop(context);
                              },
                              icon:
                                  Icon(Icons.delete_outline_rounded, size: 18),
                              label: Text('Delete'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[50],
                                foregroundColor: Colors.red[700],
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
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.grey[700]),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return ValueListenableBuilder(
      valueListenable: Hive.box('balances').listenable(),
      builder: (context, box, _) {
        final gcashBalance = box.get('gcash', defaultValue: 0.0);
        final loadBalance = box.get('load', defaultValue: 0.0);

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        );
      },
    );
  }

  // Updated tab bar to match the image design
  Widget _buildTabBar() {
    final List<String> tabTitles = ['All', 'GCash', 'Load', 'Top-up'];
    final List<IconData> tabIcons = [
      Icons.receipt_long_rounded,
      Icons.account_balance_wallet_rounded,
      Icons.smartphone_rounded,
      Icons.add_circle_outline_rounded,
    ];
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicator: BoxDecoration(),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade600,
            labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: List.generate(
              tabTitles.length,
              (index) => Container(
                height: 50,
                decoration: BoxDecoration(
                  color: _tabController.index == index 
                      ? Color(0xFF26C6DA) // Turquoise color for active tab
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_tabController.index == index) ...[
                        Icon(Icons.touch_app, size: 16),
                        SizedBox(width: 6),
                      ],
                      Text(tabTitles[index].toUpperCase()),
                    ],
                  ),
                ),
              ),
            ),
            onTap: (index) {
              setState(() {});
            },
          ),
          Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 40,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                color: isSelected ? Colors.green.shade700 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? Colors.green.shade700 : Colors.grey.shade300,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  period,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFilterOptions() {
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
                        child: _buildDateField(
                            'Start Date', Icons.calendar_today_rounded),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildDateField(
                            'End Date', Icons.calendar_today_rounded),
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
                    children: [
                      _buildFilterChip('All', true),
                      _buildFilterChip('GCash In', false),
                      _buildFilterChip('GCash Out', false),
                      _buildFilterChip('Load Sale', false),
                      _buildFilterChip('GCash Topup', false),
                      _buildFilterChip('Load Topup', false),
                    ],
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
                  SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
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
                            Navigator.pop(context);
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
          ],
        ),
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
            '₱',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
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

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Export Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 24),
            _buildExportOption(
              icon: Icons.picture_as_pdf_rounded,
              title: 'Export as PDF',
              subtitle: 'Generate a detailed PDF report',
              color: Colors.red[700]!,
            ),
            _buildExportOption(
              icon: Icons.table_chart_rounded,
              title: 'Export as CSV',
              subtitle: 'Export data in spreadsheet format',
              color: Colors.green[700]!,
            ),
            _buildExportOption(
              icon: Icons.print_rounded,
              title: 'Print Report',
              subtitle: 'Send to printer',
              color: Colors.blue[700]!,
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        // Implement export functionality
      },
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
          return _buildEmptyState(context);
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

  Widget _buildEmptyState(BuildContext context) {
    String message;
    IconData icon;

    switch (type) {
      case 'gcash':
        message = 'No GCash transactions yet';
        icon = Icons.account_balance_wallet_rounded;
        break;
      case 'load':
        message = 'No Load transactions yet';
        icon = Icons.smartphone_rounded;
        break;
      case 'topup':
        message = 'No Top-up transactions yet';
        icon = Icons.add_circle_outline_rounded;
        break;
      default:
        message = 'No transactions yet';
        icon = Icons.receipt_long_rounded;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Transactions will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.add_rounded, size: 18),
            label: Text('Add Transaction'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _filterTransactions(List<dynamic> transactions) {
    final now = DateTime.now();
    final filteredTransactions = transactions.where((transaction) {
      if (transaction['type'] == null) return false;

      // Filter by type
      bool matchesType = false;
      if (type == 'all') {
        matchesType = true;
      } else if (type == 'gcash') {
        matchesType = transaction['type'] == 'gcash_in' ||
            transaction['type'] == 'gcash_out' ||
            transaction['type'] == 'gcash_topup';
      } else if (type == 'load') {
        matchesType = transaction['type'] == 'load';
      } else if (type == 'topup') {
        matchesType = transaction['type'] == 'topup' ||
            transaction['type'] == 'gcash_topup';
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
      if (type == 'gcash' || type == 'all') {
        if (transaction['type'] == 'gcash_out') {
          totalIncome += (transaction['amount'] as num).toDouble();
        } else if (transaction['type'] == 'gcash_in') {
          totalExpense += (transaction['amount'] as num).toDouble();
        } else if (transaction['type'] == 'gcash_topup') {
          totalIncome += (transaction['amount'] as num).toDouble();
        }
      }

      if (type == 'load' || type == 'all') {
        if (transaction['type'] == 'load') {
          if (transaction['customerPays'] != null) {
            totalIncome += (transaction['customerPays'] as num).toDouble();
          }
          if (transaction['deducted'] != null) {
            totalExpense += (transaction['deducted'] as num).toDouble();
          }
        }
      }

      if (type == 'topup' || type == 'all') {
        if (transaction['type'] == 'topup') {
          totalExpense += (transaction['amount'] as num).toDouble();
        } else if (transaction['type'] == 'gcash_topup') {
          totalIncome += (transaction['amount'] as num).toDouble();
        }
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.insights_rounded,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${period} Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          '${transactions.length} transactions',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Net: ₱${(totalIncome - totalExpense).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Income',
                    totalIncome,
                    Icons.arrow_downward_rounded,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    'Expense',
                    totalExpense,
                    Icons.arrow_upward_rounded,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String title, double amount, IconData icon, Color color) {
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
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '₱${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
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
    final isLoad = transactionType == 'load';

    if (isLoad) {
      final date = DateTime.parse(item['date']);
      final formattedTime = DateFormat('h:mm a').format(date);
      final customerPays = item['customerPays'] is num ? item['customerPays'].toDouble() : 0.0;
      final deducted = item['deducted'] is num ? item['deducted'].toDouble() : 0.0;
      final profit = item['profit'] is num ? item['profit'].toDouble() : 0.0;
      final commission = item['commission'] is num ? item['commission'].toDouble() : 0.0;

      return Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFFF8E7FF), // Light purple/pink background to match image
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phone_android,
                    color: Colors.purple[700],
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Load Sale',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[800]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        formattedTime,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+₱${customerPays.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green[700],
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Profit: ₱${profit.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Divider(height: 1, color: Colors.purple[200]),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Wallet Deducted:',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                Text(
                  '-₱${deducted.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red[700]),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Commission:',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                Text(
                  '-₱${commission.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // For other transaction types
    final isIncome =
        transactionType == 'gcash_out' || transactionType == 'gcash_topup';

    double amount = (item['amount'] as num?)?.toDouble() ?? 0.0;

    final date = DateTime.parse(item['date']);
    final formattedTime = DateFormat('hh:mm a').format(date);

    IconData transactionIcon;
    Color iconColor;
    String transactionTitle;
    Color amountColor;
    String amountPrefix;

    if (transactionType == 'gcash_in') {
      transactionIcon = Icons.arrow_upward_rounded;
      iconColor = Colors.red;
      transactionTitle = 'GCash Cash In';
      amountColor = Colors.red[700]!;
      amountPrefix = '-';
    } else if (transactionType == 'gcash_out') {
      transactionIcon = Icons.arrow_downward_rounded;
      iconColor = Colors.green;
      transactionTitle = 'GCash Cash Out';
      amountColor = Colors.green[700]!;
      amountPrefix = '+';
    } else if (transactionType == 'topup') {
      transactionIcon = Icons.add_circle_outline_rounded;
      iconColor = Colors.orange;
      transactionTitle = 'Load Wallet Top-up';
      amountColor = Colors.orange[700]!;
      amountPrefix = '-';
    } else if (transactionType == 'gcash_topup') {
      transactionIcon = Icons.account_balance_wallet_rounded;
      iconColor = Colors.blue;
      transactionTitle = 'GCash Top-up';
      amountColor = Colors.green[700]!;
      amountPrefix = '+';
    } else {
      transactionIcon = Icons.swap_horiz_rounded;
      iconColor = Colors.purple;
      transactionTitle = 'Transaction';
      amountColor = Colors.black;
      amountPrefix = '';
    }

    // Fee (serviceFee) if available
    String? feeText;
    if (item['serviceFee'] != null) {
      final fee = (item['serviceFee'] as num?)?.toDouble() ?? 0.0;
      feeText = 'Fee: ₱${fee.toStringAsFixed(2)}';
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
            _showTransactionDetails(context, item);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon circle
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    transactionIcon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                // Title and time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transactionTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.grey[900],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Amount and fee
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$amountPrefix₱${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: amountColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (feeText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          feeText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w400,
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

    IconData transactionIcon;
    Color iconColor;
    String transactionTitle;

    if (isLoad) {
      transactionIcon = Icons.smartphone_rounded;
      iconColor = Colors.blue;
      transactionTitle = 'Load Sale';
    } else if (transactionType == 'gcash_in') {
      transactionIcon = Icons.arrow_upward_rounded;
      iconColor = Colors.red;
      transactionTitle = 'Cash In';
    } else if (transactionType == 'gcash_out') {
      transactionIcon = Icons.arrow_downward_rounded;
      iconColor = Colors.green;
      transactionTitle = 'Cash Out';
    } else if (transactionType == 'topup') {
      transactionIcon = Icons.add_circle_outline_rounded;
      iconColor = Colors.orange;
      transactionTitle = 'Load Wallet Top-up';
    } else if (transactionType == 'gcash_topup') {
      transactionIcon = Icons.account_balance_wallet_rounded;
      iconColor = Colors.blue;
      transactionTitle = 'GCash Top-up';
    } else {
      transactionIcon = Icons.swap_horiz_rounded;
      iconColor = Colors.purple;
      transactionTitle = 'Transaction';
    }

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
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              transactionIcon,
                              color: iconColor,
                              size: 28,
                            ),
                          ),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transactionTitle,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 12,
                                      color: Colors.green[700],
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Completed',
                                      style: TextStyle(
                                        fontSize: 10,
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
                      SizedBox(height: 24),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildDetailItem('Date', formattedDate,
                                Icons.calendar_today_rounded),
                            Divider(height: 24, color: Colors.grey[200]),
                            _buildDetailItem('Time', formattedTime,
                                Icons.access_time_rounded),
                            Divider(height: 24, color: Colors.grey[200]),
                            _buildDetailItem('Transaction ID',
                                '#${transaction.key}', Icons.tag_rounded),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Transaction Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            if (isLoad) ...[
                              _buildDetailItem(
                                  'Customer Pays',
                                  '₱${transaction['customerPays'].toStringAsFixed(2)}',
                                  Icons.payments_rounded),
                              Divider(height: 24, color: Colors.grey[200]),
                              _buildDetailItem(
                                  'Wallet Deducted',
                                  '₱${transaction['deducted'].toStringAsFixed(2)}',
                                  Icons.remove_circle_outline_rounded),
                              Divider(height: 24, color: Colors.grey[200]),
                              _buildDetailItem(
                                  'Commission',
                                  '₱${transaction['commission'].toStringAsFixed(2)}',
                                  Icons.monetization_on_rounded),
                              Divider(height: 24, color: Colors.grey[200]),
                              _buildDetailItem(
                                  'Profit',
                                  '₱${transaction['profit'].toStringAsFixed(2)}',
                                  Icons.trending_up_rounded),
                            ] else ...[
                              _buildDetailItem(
                                  'Amount',
                                  '₱${transaction['amount'].toStringAsFixed(2)}',
                                  Icons.attach_money_rounded),
                              if (transaction['serviceFee'] != null) ...[
                                Divider(height: 24, color: Colors.grey[200]),
                                _buildDetailItem(
                                    'Service Fee',
                                    '₱${transaction['serviceFee'].toStringAsFixed(2)}',
                                    Icons.receipt_long_rounded),
                              ],
                              if (transaction['totalAmount'] != null) ...[
                                Divider(height: 24, color: Colors.grey[200]),
                                _buildDetailItem(
                                    'Total Amount',
                                    '₱${transaction['totalAmount'].toStringAsFixed(2)}',
                                    Icons.account_balance_wallet_rounded),
                              ],
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Implement share functionality
                                Navigator.pop(context);
                              },
                              icon: Icon(Icons.share_rounded, size: 18),
                              label: Text('Share'),
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
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Implement delete functionality
                                Navigator.pop(context);
                              },
                              icon:
                                  Icon(Icons.delete_outline_rounded, size: 18),
                              label: Text('Delete'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[50],
                                foregroundColor: Colors.red[700],
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
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.grey[700]),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}