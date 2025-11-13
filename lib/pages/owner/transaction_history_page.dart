import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final _api = ApiService();
  List<Map<String, dynamic>> _transactions = [];
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  String? _errorMessage;

  // Filter state
  String? _selectedMonth;
  String? _selectedYear;
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _api.getTransactionHistory(
        month: _selectedMonth,
        year: _selectedYear,
        startDate: _startDate != null
            ? DateFormat('yyyy-MM-dd').format(_startDate!)
            : null,
        endDate: _endDate != null
            ? DateFormat('yyyy-MM-dd').format(_endDate!)
            : null,
        status: _selectedStatus,
      );

      if (response['success'] == true) {
        final data = response['data'] as List<dynamic>?;
        final summary = response['summary'] as Map<String, dynamic>?;

        setState(() {
          _transactions = data?.cast<Map<String, dynamic>>() ?? [];
          _summary = summary;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message']?.toString() ?? 'Gagal memuat data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectMonth() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 2);
    final lastDate = DateTime(now.year + 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth != null
          ? DateTime.parse('$_selectedMonth-01')
          : now,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Pilih Bulan',
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateFormat('yyyy-MM').format(picked);
        _selectedYear = null; // Clear year if month is selected
        _startDate = null;
        _endDate = null;
      });
      _loadTransactions();
    }
  }

  Future<void> _selectYear() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5);
    final lastDate = DateTime(now.year + 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedYear != null
          ? DateTime(int.parse(_selectedYear!), 1, 1)
          : now,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Pilih Tahun',
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _selectedYear = picked.year.toString();
        _selectedMonth = null; // Clear month if year is selected
        _startDate = null;
        _endDate = null;
      });
      _loadTransactions();
    }
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 2);
    final lastDate = now;

    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Pilih Rentang Tanggal',
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (pickedRange != null) {
      setState(() {
        _startDate = pickedRange.start;
        _endDate = pickedRange.end;
        _selectedMonth = null;
        _selectedYear = null;
      });
      _loadTransactions();
    }
  }

  void _showStatusFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filter Status',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF291C0E),
              ),
            ),
            const SizedBox(height: 20),
            _buildStatusOption('Semua', null),
            _buildStatusOption('Pending', 'pending'),
            _buildStatusOption('Disetujui', 'accept'),
            _buildStatusOption('Ditolak', 'reject'),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(String label, String? value) {
    final isSelected = _selectedStatus == value;
    return ListTile(
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected
              ? const Color(0xFF6E473B)
              : const Color(0xFF291C0E),
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: const Color(0xFF6E473B))
          : null,
      onTap: () {
        setState(() {
          _selectedStatus = value;
        });
        Navigator.pop(context);
        _loadTransactions();
      },
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedMonth = null;
      _selectedYear = null;
      _selectedStatus = null;
      _startDate = null;
      _endDate = null;
    });
    _loadTransactions();
  }

  String _formatPrice(int price) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('HH:mm', 'id_ID').format(date);
    } catch (e) {
      return '';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accept':
      case 'approved':
        return Colors.green;
      case 'reject':
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'accept':
      case 'approved':
        return 'Disetujui';
      case 'reject':
      case 'rejected':
        return 'Ditolak';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF291C0E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Laporan Transaksi',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF291C0E),
          ),
        ),
        actions: [
          if (_selectedMonth != null ||
              _selectedYear != null ||
              _selectedStatus != null ||
              _startDate != null ||
              _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear_rounded, color: Color(0xFF6E473B)),
              onPressed: _clearFilters,
              tooltip: 'Hapus Filter',
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6E473B)),
            onPressed: _loadTransactions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          if (_summary != null) _buildSummarySection(),
          // Filter Section
          _buildFilterSection(),
          // Transactions List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6E473B)),
                  )
                : _errorMessage != null
                    ? _buildErrorState()
                    : _transactions.isEmpty
                        ? _buildEmptyState()
                        : _buildTransactionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final summary = _summary!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6E473B),
            const Color(0xFF6E473B).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Booking',
                  '${summary['total_bookings'] ?? 0}',
                  Icons.receipt_long_rounded,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Total Pendapatan',
                  _formatPrice(summary['total_revenue'] ?? 0),
                  Icons.payments_rounded,
                  Colors.green.shade100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Pending',
                  '${summary['pending_count'] ?? 0}',
                  Icons.pending_rounded,
                  Colors.orange.shade100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Disetujui',
                  '${summary['accepted_count'] ?? 0}',
                  Icons.check_circle_rounded,
                  Colors.green.shade100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Ditolak',
                  '${summary['rejected_count'] ?? 0}',
                  Icons.cancel_rounded,
                  Colors.red.shade100,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF291C0E),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterButton(
                  icon: Icons.calendar_month_rounded,
                  label: _selectedMonth != null
                      ? DateFormat('MMM yyyy', 'id_ID')
                          .format(DateTime.parse('$_selectedMonth-01'))
                      : 'Bulan',
                  onTap: _selectMonth,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterButton(
                  icon: Icons.calendar_today_rounded,
                  label: _selectedYear ?? 'Tahun',
                  onTap: _selectYear,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterButton(
                  icon: Icons.date_range_rounded,
                  label: _startDate != null && _endDate != null
                      ? '${DateFormat('dd/MM', 'id_ID').format(_startDate!)} - ${DateFormat('dd/MM', 'id_ID').format(_endDate!)}'
                      : 'Rentang',
                  onTap: _selectDateRange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterButton(
                  icon: Icons.filter_list_rounded,
                  label: _selectedStatus != null
                      ? _getStatusLabel(_selectedStatus!)
                      : 'Status',
                  onTap: _showStatusFilter,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF6E473B)),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF291C0E),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF291C0E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Gagal memuat data',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF291C0E).withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTransactions,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'Coba Lagi',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E473B),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak Ada Transaksi',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF291C0E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada transaksi untuk periode yang dipilih',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF291C0E).withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final status = transaction['status']?.toString() ?? '';
    final statusColor = _getStatusColor(status);
    final kos = transaction['kos'] as Map<String, dynamic>?;
    final room = transaction['room'] as Map<String, dynamic>?;
    final user = transaction['user'] as Map<String, dynamic>?;

    return InkWell(
      onTap: () {
        // Navigate to booking detail
        Navigator.of(context).pushNamed(
          '/booking_detail',
          arguments: transaction['id'] as int,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction['booking_code']?.toString() ?? '-',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF291C0E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(transaction['created_at']?.toString()),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF291C0E).withOpacity(0.6),
                        ),
                      ),
                      if (transaction['created_at'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(transaction['created_at']?.toString()),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF291C0E).withOpacity(0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusLabel(status),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kos != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.apartment_rounded,
                        size: 16,
                        color: const Color(0xFF6E473B).withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          kos['name']?.toString() ?? '-',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF291C0E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (room != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.door_front_door_rounded,
                        size: 16,
                        color: const Color(0xFF6E473B).withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kamar ${room['room_number'] ?? '-'}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF291C0E).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (user != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: const Color(0xFF6E473B).withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        user['name']?.toString() ?? '-',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF291C0E).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: const Color(0xFF6E473B).withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_formatDate(transaction['start_date']?.toString())} - ${_formatDate(transaction['end_date']?.toString())}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF291C0E).withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Pembayaran',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF291C0E).withOpacity(0.7),
                      ),
                    ),
                    Text(
                      _formatPrice(transaction['total_price'] ?? 0),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6E473B),
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
}

