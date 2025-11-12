import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../services/api_service.dart';

class BookingSuccessPage extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final Map<String, dynamic>? kosData;
  final Map<String, dynamic>? roomData;

  const BookingSuccessPage({
    super.key,
    required this.bookingData,
    this.kosData,
    this.roomData,
  });

  @override
  State<BookingSuccessPage> createState() => _BookingSuccessPageState();
}

class _BookingSuccessPageState extends State<BookingSuccessPage> {
  final _api = ApiService();
  bool _isGenerating = false;

  Future<void> _printBookingProof() async {
    // Check if booking is approved
    final status = widget.bookingData['status']?.toString() ?? '';
    final statusLower = status.toLowerCase();
    if (statusLower != 'accept' && statusLower != 'approved') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Hanya booking yang sudah disetujui yang dapat dicetak',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Get full booking data if not provided
      Map<String, dynamic> booking = widget.bookingData;
      Map<String, dynamic> kos = widget.kosData ?? {};
      Map<String, dynamic> room = widget.roomData ?? {};
      Map<String, dynamic>? user;

      try {
        user = await _api.getProfile().then((u) => {
          'name': u.name,
          'email': u.email,
          'phone': u.phone,
        });
      } catch (e) {
        // Use default if profile fetch fails
        user = {'name': 'Penyewa', 'email': '-', 'phone': '-'};
      }

      // If kos/room data not provided, try to get from booking
      if (kos.isEmpty && booking['kos'] != null) {
        kos = booking['kos'] as Map<String, dynamic>;
      }
      if (room.isEmpty && booking['room'] != null) {
        room = booking['room'] as Map<String, dynamic>;
      }

      // Generate PDF
      final pdf = await _generatePDF(booking, kos, room, user ?? {});

      // Print or share
      try {
        // Try printing first
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => await pdf.save(),
        );
      } catch (printError) {
        // If printing fails (MissingPluginException), automatically fallback to share
        print('Print failed, trying share: $printError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Print tidak tersedia. Membagikan file PDF...',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        // Fallback to share
        await Future.delayed(const Duration(milliseconds: 500));
        await _sharePDFFile(pdf);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        String userMessage = 'Gagal membuat bukti booking';
        
        if (errorMsg.contains('MissingPluginException')) {
          userMessage = 'Fitur print belum tersedia. Silakan restart aplikasi (stop dan jalankan ulang, bukan hot restart) atau gunakan tombol "Bagikan" untuk menyimpan PDF.';
        } else {
          userMessage = 'Gagal membuat bukti booking: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userMessage,
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _sharePDFFile(pw.Document pdf) async {
    try {
      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final bookingCode = widget.bookingData['booking_code']?.toString() ??
          widget.bookingData['id']?.toString() ??
          'booking';
      final file = File('${directory.path}/booking_$bookingCode.pdf');
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);

      // Try to share file
      try {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Bukti Booking - $bookingCode',
        );
      } catch (shareError) {
        // If share also fails, show file location
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'File PDF berhasil dibuat!',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lokasi: ${file.path}',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Catatan: Untuk menggunakan fitur share, silakan restart aplikasi (stop dan jalankan ulang).',
                    style: GoogleFonts.poppins(fontSize: 11),
                  ),
                ],
              ),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 6),
            ),
          );
        }
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _shareBookingProof() async {
    // Check if booking is approved
    final status = widget.bookingData['status']?.toString() ?? '';
    final statusLower = status.toLowerCase();
    if (statusLower != 'accept' && statusLower != 'approved') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Hanya booking yang sudah disetujui yang dapat dibagikan',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      Map<String, dynamic> booking = widget.bookingData;
      Map<String, dynamic> kos = widget.kosData ?? {};
      Map<String, dynamic> room = widget.roomData ?? {};
      Map<String, dynamic>? user;

      try {
        user = await _api.getProfile().then((u) => {
          'name': u.name,
          'email': u.email,
          'phone': u.phone,
        });
      } catch (e) {
        user = {'name': 'Penyewa', 'email': '-', 'phone': '-'};
      }

      if (kos.isEmpty && booking['kos'] != null) {
        kos = booking['kos'] as Map<String, dynamic>;
      }
      if (room.isEmpty && booking['room'] != null) {
        room = booking['room'] as Map<String, dynamic>;
      }

      final pdf = await _generatePDF(booking, kos, room, user ?? {});
      await _sharePDFFile(pdf);
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        String userMessage = 'Gagal membagikan bukti booking';
        
        if (errorMsg.contains('MissingPluginException')) {
          userMessage = 'Fitur share belum tersedia. Silakan restart aplikasi (stop dan jalankan ulang, bukan hot restart).';
        } else {
          userMessage = 'Gagal membagikan bukti booking: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userMessage,
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<pw.Document> _generatePDF(
    Map<String, dynamic> booking,
    Map<String, dynamic> kos,
    Map<String, dynamic> room,
    Map<String, dynamic> user,
  ) async {
    final pdf = pw.Document();

    final bookingCode = booking['booking_code']?.toString() ?? booking['id']?.toString() ?? '-';
    final startDate = _formatDate(booking['start_date']?.toString());
    final endDate = _formatDate(booking['end_date']?.toString());
    final totalPrice = _formatPrice(booking['total_price']);
    final status = _getStatusText(booking['status']?.toString() ?? '');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'BUKTI BOOKING',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Gajayana Kost',
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),

              // Booking Code
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Kode Booking:',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                    pw.Text(
                      bookingCode,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Informasi Kos
              pw.Text(
                'Informasi Kos',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              _buildInfoRow('Nama Kos', kos['name']?.toString() ?? '-'),
              _buildInfoRow('Alamat', kos['address']?.toString() ?? '-'),
              pw.SizedBox(height: 20),

              // Informasi Kamar
              pw.Text(
                'Informasi Kamar',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              _buildInfoRow('Nomor Kamar', room['room_number']?.toString() ?? '-'),
              _buildInfoRow('Tipe Kamar', room['room_type']?.toString() ?? '-'),
              pw.SizedBox(height: 20),

              // Informasi Penyewa
              pw.Text(
                'Informasi Penyewa',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              _buildInfoRow('Nama', user['name']?.toString() ?? '-'),
              _buildInfoRow('Email', user['email']?.toString() ?? '-'),
              _buildInfoRow('Telepon', user['phone']?.toString() ?? '-'),
              pw.SizedBox(height: 20),

              // Informasi Booking
              pw.Text(
                'Detail Booking',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              _buildInfoRow('Tanggal Mulai', startDate),
              _buildInfoRow('Tanggal Selesai', endDate),
              _buildInfoRow('Status', status),
              pw.SizedBox(height: 20),

              // Total Harga
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Pembayaran:',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      totalPrice,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),

              // Footer
              pw.Divider(),
              pw.SizedBox(height: 16),
              pw.Center(
                child: pw.Text(
                  'Terima kasih telah menggunakan layanan Gajayana Kost',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Dicetak pada: ${_formatDate(DateTime.now().toIso8601String())}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
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

  String _getStatusText(String status) {
    final s = status.toLowerCase();
    if (s == 'pending' || s == 'menunggu') {
      return 'Menunggu Persetujuan';
    } else if (s == 'accept' || s == 'approved' || s == 'diterima') {
      return 'Disetujui';
    } else if (s == 'reject' || s == 'rejected' || s == 'ditolak') {
      return 'Ditolak';
    }
    return status;
  }

  @override
  Widget build(BuildContext context) {
    final bookingCode = widget.bookingData['booking_code']?.toString() ??
        widget.bookingData['id']?.toString() ??
        '-';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF291C0E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF291C0E)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Success Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 60,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),

              // Success Message
              Text(
                'Booking Berhasil!',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF291C0E),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kode Booking Anda',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF291C0E).withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),

              // Booking Code
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6E473B).withOpacity(0.1),
                      const Color(0xFFE1D4C2).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6E473B).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  bookingCode,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6E473B),
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Info Card - Status based message
              Builder(
                builder: (context) {
                  final status = widget.bookingData['status']?.toString() ?? '';
                  final statusLower = status.toLowerCase();
                  
                  String message;
                  IconData icon;
                  Color iconColor;
                  Color bgColor;
                  
                  if (statusLower == 'accept' || statusLower == 'approved') {
                    message = 'Booking Anda telah disetujui oleh pemilik kos.';
                    icon = Icons.check_circle_outline_rounded;
                    iconColor = Colors.green.shade600;
                    bgColor = Colors.green.shade50;
                  } else if (statusLower == 'reject' || statusLower == 'rejected') {
                    message = 'Booking Anda telah ditolak oleh pemilik kos.';
                    icon = Icons.cancel_outlined;
                    iconColor = Colors.red.shade600;
                    bgColor = Colors.red.shade50;
                  } else {
                    message = 'Booking Anda sedang menunggu persetujuan dari pemilik kos.';
                    icon = Icons.info_outline_rounded;
                    iconColor = Colors.blue.shade600;
                    bgColor = Colors.grey.shade50;
                  }
                  
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: iconColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          color: iconColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF291C0E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Action Buttons - Only show for approved bookings
              Builder(
                builder: (context) {
                  final status = widget.bookingData['status']?.toString() ?? '';
                  final statusLower = status.toLowerCase();
                  final isApproved = statusLower == 'accept' || statusLower == 'approved';
                  
                  if (!isApproved) {
                    return const SizedBox.shrink();
                  }
                  
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isGenerating ? null : _printBookingProof,
                          icon: _isGenerating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.print_rounded),
                          label: Text(
                            _isGenerating ? 'Membuat PDF...' : 'Cetak Bukti Booking',
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
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isGenerating ? null : _shareBookingProof,
                          icon: const Icon(Icons.share_rounded),
                          label: Text(
                            'Bagikan Bukti Booking',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: const Color(0xFF6E473B).withOpacity(0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacementNamed('/bookings');
                  },
                  child: Text(
                    'Lihat Booking Saya',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6E473B),
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
}

