import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';

class BookingDetailPage extends StatefulWidget {
  final int bookingId;
  const BookingDetailPage({super.key, required this.bookingId});

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  final _api = ApiService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getBookingDetail(widget.bookingId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF291C0E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Detail Booking',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF291C0E),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF291C0E)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF6E473B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat detail booking...',
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
            String errorMessage = 'Gagal memuat detail booking';
            bool isAuthError = false;

            if (error is DioException) {
              final statusCode = error.response?.statusCode;
              if (statusCode == 403) {
                isAuthError = true;
                errorMessage =
                    'Anda tidak memiliki akses untuk melihat booking ini';
              } else if (statusCode == 404) {
                errorMessage = 'Booking tidak ditemukan';
              } else if (statusCode == 401) {
                isAuthError = true;
                errorMessage = 'Sesi telah berakhir. Silakan login ulang';
              } else {
                String message = 'Terjadi kesalahan saat memuat data';
                if (error.response?.data is Map) {
                  final responseData =
                      error.response!.data as Map<String, dynamic>;
                  if (responseData['message'] != null) {
                    message = responseData['message'].toString();
                  }
                }
                if (error.message != null && error.message!.isNotEmpty) {
                  message = error.message!;
                }
                errorMessage = message;
              }
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
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _future = _api.getBookingDetail(widget.bookingId);
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6E473B),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
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

          final b = snapshot.data ?? const <String, dynamic>{};
          final kos = (b['kos'] as Map<String, dynamic>?) ?? const {};
          final user = (b['user'] as Map<String, dynamic>?) ?? const {};
          final room = (b['room'] as Map<String, dynamic>?) ?? const {};
          final status = b['status']?.toString() ?? '';

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _future = _api.getBookingDetail(widget.bookingId);
              });
              await _future;
            },
            color: const Color(0xFF6E473B),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Header Card
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.apartment,
                              color: Color(0xFF6E473B),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kos['name']?.toString() ?? 'Kos',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF291C0E),
                                  ),
                                ),
                                if (kos['address'] != null &&
                                    kos['address'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        size: 14,
                                        color: Color(0xFF6E473B),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          kos['address']?.toString() ?? '-',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: const Color(
                                              0xFF291C0E,
                                            ).withOpacity(0.7),
                                          ),
                                          maxLines: 2,
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Booking Info
                _SectionCard(
                  title: 'Informasi Booking',
                  icon: Icons.receipt_long_rounded,
                  children: [
                    _InfoRow(
                      label: 'Kode Booking',
                      value: b['booking_code']?.toString() ?? '-',
                    ),
                    _InfoRow(label: 'Status', value: _getStatusText(status)),
                    _InfoRow(
                      label: 'Tanggal Mulai',
                      value: _date(b['start_date']),
                    ),
                    _InfoRow(
                      label: 'Tanggal Selesai',
                      value: _date(b['end_date']),
                    ),
                    _InfoRow(
                      label: 'Total Pembayaran',
                      value: _rupiah(b['total_price']),
                      isHighlight: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Room Info
                _SectionCard(
                  title: 'Informasi Kamar',
                  icon: Icons.door_front_door_rounded,
                  children: [
                    _InfoRow(
                      label: 'Nomor Kamar',
                      value: room['room_number']?.toString() ?? '-',
                    ),
                    _InfoRow(
                      label: 'Tipe Kamar',
                      value: room['room_type']?.toString() ?? '-',
                    ),
                  ],
                ),
                // User Info (for owner)
                if (user.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Informasi Penyewa',
                    icon: Icons.person_rounded,
                    children: [
                      _InfoRow(
                        label: 'Nama',
                        value: user['name']?.toString() ?? '-',
                      ),
                      _InfoRow(
                        label: 'Email',
                        value: user['email']?.toString() ?? '-',
                      ),
                      _InfoRow(
                        label: 'Telepon',
                        value: user['phone']?.toString() ?? '-',
                      ),
                    ],
                  ),
                ],
                // Print button for approved bookings (society only)
                if (status.toLowerCase() == 'accept' ||
                    status.toLowerCase() == 'approved') ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Pass complete booking data including kos and room
                          Navigator.of(context).pushNamed(
                            '/booking_success',
                            arguments: {...b, 'kos': kos, 'room': room},
                          );
                        },
                        icon: const Icon(Icons.print_rounded),
                        label: Text(
                          'Cetak Bukti Booking',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6E473B),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getStatusText(String status) {
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

  String _date(dynamic iso) {
    if (iso == null) return '-';
    final s = iso.toString();
    final d = DateTime.tryParse(s);
    if (d == null) return s;
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  }

  String _rupiah(dynamic v) {
    if (v == null) return '-';
    final n = (v is num) ? v.toInt() : int.tryParse(v.toString()) ?? 0;
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i - 1;
      buf.write(s[idx]);
      if (i % 3 == 2 && idx != 0) buf.write('.');
    }
    return 'Rp ' + buf.toString().split('').reversed.join();
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE1D4C2).withOpacity(0.3),
          width: 1,
        ),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6E473B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF6E473B)),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF291C0E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF291C0E).withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: isHighlight ? 16 : 14,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                color: isHighlight
                    ? const Color(0xFF6E473B)
                    : const Color(0xFF291C0E),
              ),
            ),
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
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(), size: 14, color: color),
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
