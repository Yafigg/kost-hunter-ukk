import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> with WidgetsBindingObserver {
  final _api = ApiService();
  Future<List<Map<String, dynamic>>>? _future;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkUserRole();
    _checkAuthAndLoad();
  }

  Future<void> _checkUserRole() async {
    try {
      final user = await _api.getProfile();
      setState(() {
        _userRole = user.role;
      });
    } catch (e) {
      // Ignore error, will default to society view
    }
  }

  // Public method to refresh bookings
  void refresh() {
    _checkAuthAndLoad();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh when app comes back to foreground
      _checkAuthAndLoad();
    }
  }

  Future<void> _checkAuthAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null || token.isEmpty) {
      // No token - create a future that will throw an auth error
      setState(() {
        _future = Future<List<Map<String, dynamic>>>.error(
          DioException(
            requestOptions: RequestOptions(path: '/bookings'),
            response: Response(
              requestOptions: RequestOptions(path: '/bookings'),
              statusCode: 401,
            ),
            type: DioExceptionType.badResponse,
          ),
        );
      });
      return;
    }
    
    _loadBookings();
  }

  void _loadBookings() async {
    try {
      print('DEBUG BookingsPage: Starting to load bookings...');
      print('DEBUG BookingsPage: User role: $_userRole');
      final bookings = await _api.getBookings();
      print('DEBUG BookingsPage: ✅ Loaded ${bookings.length} bookings');
      if (bookings.isNotEmpty) {
        print('DEBUG BookingsPage: First booking ID: ${bookings.first['id']}');
        print('DEBUG BookingsPage: First booking status: ${bookings.first['status']}');
        print('DEBUG BookingsPage: First booking kos: ${bookings.first['kos']?['name']}');
      } else {
        print('DEBUG BookingsPage: ⚠️ No bookings found. User role: $_userRole');
      }
      setState(() {
        _future = Future.value(bookings);
      });
    } catch (e, stackTrace) {
      print('DEBUG BookingsPage: ❌ Error loading bookings: $e');
      print('DEBUG BookingsPage: Stack trace: $stackTrace');
      if (e is DioException) {
        print('DEBUG BookingsPage: DioException type: ${e.type}');
        print('DEBUG BookingsPage: Response status: ${e.response?.statusCode}');
        print('DEBUG BookingsPage: Response data: ${e.response?.data}');
        print('DEBUG BookingsPage: Request path: ${e.requestOptions.path}');
      }
      setState(() {
        _future = Future.error(e);
      });
    }
  }

  Future<void> _checkAuthAndRetry() async {
    // Redirect to login page
    if (mounted) {
      final result = await Navigator.of(context).pushNamed('/login');
      // If login successful, reload bookings
      if (result == true && mounted) {
        // Wait a bit for token to be saved, then reload
        await Future.delayed(const Duration(milliseconds: 100));
        await _checkAuthAndLoad();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _userRole == 'owner' ? 'Booking Masuk' : 'Booking Saya',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF291C0E),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF291C0E)),
      ),
      body: _future == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6E473B)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat booking...',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF291C0E).withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }
          
          if (snapshot.hasError) {
            final error = snapshot.error;
            bool isAuthError = false;
            String errorMessage = 'Gagal memuat data booking';
            
            if (error is DioException) {
              final statusCode = error.response?.statusCode;
              final responseData = error.response?.data;
              
              if (statusCode == 403) {
                isAuthError = true;
                // 403 bisa berarti tidak punya akses (role tidak sesuai)
                final message = responseData is Map && responseData['message'] != null
                    ? responseData['message'].toString()
                    : 'Anda tidak memiliki akses ke halaman ini.';
                errorMessage = message;
              } else if (statusCode == 401) {
                isAuthError = true;
                errorMessage = 'Anda belum login atau sesi telah berakhir. Silakan login terlebih dahulu.';
              } else if (statusCode == 404) {
                errorMessage = 'Endpoint tidak ditemukan';
              } else if (statusCode == 500) {
                errorMessage = 'Server error. Silakan coba lagi nanti.';
              } else {
                final message = responseData is Map && responseData['message'] != null
                    ? responseData['message'].toString()
                    : (error.message ?? 'Terjadi kesalahan saat memuat data');
                errorMessage = message;
              }
            } else {
              // For any other error, check if it might be auth related
              isAuthError = true;
              errorMessage = 'Anda belum login. Silakan login terlebih dahulu.';
            }
            
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isAuthError ? Icons.lock_outline : Icons.error_outline,
                      size: 64,
                      color: const Color(0xFF6E473B).withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF291C0E),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isAuthError ? _checkAuthAndRetry : _loadBookings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6E473B),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isAuthError ? 'Login' : 'Coba Lagi',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          final items = snapshot.data ?? const <Map<String, dynamic>>[];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: const Color(0xFF6E473B).withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userRole == 'owner' ? 'Belum ada booking masuk' : 'Belum ada booking',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF291C0E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _userRole == 'owner'
                        ? 'Booking yang masuk akan muncul di sini'
                        : 'Booking Anda akan muncul di sini',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF291C0E).withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_userRole == 'owner') ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Pastikan:\n• Anda sudah membuat kos\n• Penyewa melakukan booking ke kos Anda\n• Anda login dengan akun yang benar',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF291C0E).withOpacity(0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              _loadBookings();
              if (_future != null) {
                await _future;
              }
            },
            color: const Color(0xFF6E473B),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final b = items[index];
                final kos = (b['kos'] as Map<String, dynamic>?) ?? const {};
                final room = (b['room'] as Map<String, dynamic>?) ?? const {};
                final user = (b['user'] as Map<String, dynamic>?) ?? const {};
                return _BookingCard(
                  booking: b,
                  kos: kos,
                  room: room,
                  user: user,
                  isOwner: _userRole == 'owner',
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      '/booking_detail',
                      arguments: b['id'],
                    );
                  },
                  onStatusUpdate: _userRole == 'owner'
                      ? () {
                          _loadBookings();
                        }
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Map<String, dynamic> kos;
  final Map<String, dynamic> room;
  final Map<String, dynamic> user;
  final bool isOwner;
  final VoidCallback onTap;
  final VoidCallback? onStatusUpdate;

  const _BookingCard({
    required this.booking,
    required this.kos,
    required this.room,
    required this.user,
    this.isOwner = false,
    required this.onTap,
    this.onStatusUpdate,
  });

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  final _api = ApiService();
  bool _isProcessing = false;

  void _showSuccessDialog({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon dengan background
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF291C0E),
                ),
              ),
              const SizedBox(height: 12),
              // Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              // OK Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _approveBooking() async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      await _api.updateBookingStatus(
        int.parse(widget.booking['id'].toString()),
        'approved',
      );
      
      if (mounted) {
        _showSuccessDialog(
          icon: Icons.check_circle,
          title: 'Berhasil!',
          message: 'Booking berhasil disetujui',
          color: Colors.green,
        );
        widget.onStatusUpdate?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menyetujui booking: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showRejectDialog() async {
    final reasonController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.cancel_outlined,
                      color: Colors.red.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tolak Booking',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF291C0E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Alasan penolakan (opsional):',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF291C0E),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 4,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF291C0E),
                ),
                decoration: InputDecoration(
                  hintText: 'Masukkan alasan penolakan...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF291C0E),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Tolak',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
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

    if (result == true && mounted) {
      if (_isProcessing) return;
      
      setState(() => _isProcessing = true);
      
      try {
        await _api.updateBookingStatus(
          int.parse(widget.booking['id'].toString()),
          'rejected',
          rejectedReason: reasonController.text.trim(),
        );
        
        if (mounted) {
          _showSuccessDialog(
            icon: Icons.info_outline,
            title: 'Berhasil!',
            message: 'Booking berhasil ditolak',
            color: Colors.orange,
          );
          widget.onStatusUpdate?.call();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal menolak booking: ${e.toString()}',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  String _date(dynamic iso) {
    if (iso == null) return '-';
    final s = iso.toString();
    final d = DateTime.tryParse(s);
    if (d == null) return s;
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Rp 0';
    final numPrice = price is int ? price : (price is String ? int.tryParse(price) ?? 0 : 0);
    final priceStr = numPrice.toString();
    final buffer = StringBuffer('Rp ');
    
    for (int i = 0; i < priceStr.length; i++) {
      if (i > 0 && (priceStr.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(priceStr[i]);
    }
    
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.booking['status']?.toString() ?? '';
    final totalPrice = widget.booking['total_price'] ?? widget.booking['totalPrice'] ?? 0;
    
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan gradient background
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6E473B).withOpacity(0.1),
                    const Color(0xFFE1D4C2).withOpacity(0.2),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon kos
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.apartment,
                      color: const Color(0xFF6E473B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.kos['name']?.toString() ?? 'Kos',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF291C0E),
                            height: 1.2,
                          ),
                        ),
                        if (widget.kos['address'] != null && widget.kos['address'].toString().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: const Color(0xFF6E473B).withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.kos['address']?.toString() ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF291C0E).withOpacity(0.7),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  _StatusChip(status: status),
                ],
              ),
            ),
            // Content area
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Booking Info Grid
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.qr_code_2_rounded,
                          label: 'Kode',
                          value: widget.booking['booking_code']?.toString() ?? widget.booking['bookingCode']?.toString() ?? '-',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.door_front_door_rounded,
                          label: 'Kamar',
                          value: '${widget.room['room_number'] ?? widget.room['roomNumber'] ?? '-'}',
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Periode
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.shade100,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 20,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Periode Sewa',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_date(widget.booking['start_date'] ?? widget.booking['startDate'])} - ${_date(widget.booking['end_date'] ?? widget.booking['endDate'])}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF291C0E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Show user info for owner
                  if (widget.isOwner && widget.user.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.shade100,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 20,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Penyewa',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.user['name']?.toString() ?? '-',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF291C0E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (widget.user['phone'] != null && widget.user['phone'].toString().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_rounded,
                                  size: 16,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.user['phone']?.toString() ?? '-',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF291C0E),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  // Total Price
                  if (totalPrice > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF6E473B).withOpacity(0.1),
                            const Color(0xFF6E473B).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF6E473B).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6E473B).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.payments_rounded,
                                  size: 20,
                                  color: const Color(0xFF6E473B),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Total Pembayaran',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF291C0E).withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _formatPrice(totalPrice),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6E473B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  // Approve/Reject buttons for owner (only if pending)
                  if (widget.isOwner && status.toLowerCase() == 'pending' && widget.onStatusUpdate != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isProcessing ? null : _showRejectDialog,
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Colors.red.shade600,
                            ),
                            label: Text(
                              'Tolak',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.red.shade400, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _approveBooking,
                            icon: Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Setujui',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: widget.onTap,
                        icon: Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: const Color(0xFF6E473B),
                        ),
                        label: Text(
                          'Lihat Detail',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6E473B),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: const Color(0xFF6E473B).withOpacity(0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF291C0E),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color _getStatusColor() {
    final s = status.toLowerCase();
    if (s == 'pending' || s == 'menunggu') {
      return Colors.orange;
    } else if (s == 'accept' || s == 'approved' || s == 'diterima') {
      return Colors.green;
    } else if (s == 'reject' || s == 'rejected' || s == 'ditolak') {
      return Colors.red;
    }
    return Colors.grey;
  }

  String _getStatusText() {
    final s = status.toLowerCase();
    if (s == 'pending' || s == 'menunggu') {
      return 'Menunggu';
    } else if (s == 'accept' || s == 'approved' || s == 'diterima') {
      return 'Diterima';
    } else if (s == 'reject' || s == 'rejected' || s == 'ditolak') {
      return 'Ditolak';
    }
    return status;
  }

  IconData _getStatusIcon() {
    final s = status.toLowerCase();
    if (s == 'pending' || s == 'menunggu') {
      return Icons.access_time_rounded;
    } else if (s == 'accept' || s == 'approved' || s == 'diterima') {
      return Icons.check_circle_rounded;
    } else if (s == 'reject' || s == 'rejected' || s == 'ditolak') {
      return Icons.cancel_rounded;
    }
    return Icons.info_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusText(),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

