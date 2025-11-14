import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/api_service.dart';
import '../../models/kos.dart';

class ManageKosPage extends StatefulWidget {
  const ManageKosPage({super.key});

  @override
  State<ManageKosPage> createState() => _ManageKosPageState();
}

class _ManageKosPageState extends State<ManageKosPage>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  List<Kos> _kosList = [];
  List<Kos> _filteredKosList = [];
  bool _isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadKosList();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadKosList() async {
    setState(() => _isLoading = true);

    try {
      final kosList = await ApiService().getMyKos();
      setState(() {
        _kosList = kosList;
        _filteredKosList = kosList;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memuat data kos: ${e.toString()}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterKosList() {
    String searchQuery = _searchController.text.toLowerCase();

    setState(() {
      _filteredKosList = _kosList.where((kos) {
        bool matchesSearch =
            kos.name.toLowerCase().contains(searchQuery) ||
            kos.address.toLowerCase().contains(searchQuery);
        return matchesSearch;
      }).toList();
    });
  }

  void _showDeleteDialog(Kos kos) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF291C0E).withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade200, width: 2),
                ),
                child: Icon(
                  Icons.delete_outline,
                  size: 40,
                  color: Colors.red.shade400,
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

              const SizedBox(height: 24),

              // Title
              Text(
                'Hapus Kos',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF291C0E),
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms),

              const SizedBox(height: 12),

              // Message
              Text(
                'Apakah Anda yakin ingin menghapus kos "${kos.name}"? Tindakan ini tidak dapat dibatalkan.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF291C0E).withOpacity(0.7),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 600.ms, delay: 400.ms),

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: const Color(0xFFBEB5A9),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF291C0E).withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Delete Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _deleteKos(kos),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Hapus',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 600.ms, delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteKos(Kos kos) async {
    Navigator.pop(context); // Close dialog

    try {
      await ApiService().deleteKos(kos.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Kos "${kos.name}" berhasil dihapus',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFF6E473B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Reload the list
        _loadKosList();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menghapus kos: ${e.toString()}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EB),
      body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Search and Filter
              _buildSearchAndFilter(),

              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _filteredKosList.isEmpty
                    ? _buildEmptyState()
                    : _buildKosList(),
              ),
            ],
          ),
        ),
      floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).pushNamed('/add_kos'),
            backgroundColor: const Color(0xFF6E473B),
            foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 24),
            label: Text(
              'Tambah Kos',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
            ),
          ).animate().scale(
            duration: 600.ms,
            delay: 800.ms,
            curve: Curves.elasticOut,
          ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      child: Container(
                decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6E473B),
              const Color(0xFF8B6F5E),
              const Color(0xFF6E473B),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
                  boxShadow: [
                    BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
                    ),
                  ],
                ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 22,
                  ),
                ),
                    const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kelola Kos',
                      style: GoogleFonts.poppins(
                              fontSize: 24,
                        fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                      ),
                          const SizedBox(height: 4),
                    Text(
                      'Kelola kos yang sudah Anda buat',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                  ],
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

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        children: [
          // Search Bar
          Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF291C0E).withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _filterKosList(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF291C0E),
                fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari kos...',
                    hintStyle: GoogleFonts.poppins(
                      color: const Color(0xFF291C0E).withOpacity(0.5),
                  fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: const Icon(
                  Icons.search_rounded,
                      color: Color(0xFF6E473B),
                  size: 24,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                filled: true,
                fillColor: Colors.white,
                  ),
                ),
          ).animate()
              .fadeIn(duration: 800.ms, delay: 200.ms)
              .slideY(
                begin: 0.3,
                end: 0,
                duration: 800.ms,
                delay: 200.ms,
                curve: Curves.easeOutCubic,
              ),

          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              Expanded(
                child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                    vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6E473B),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6E473B).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                ),
                child: Text(
                  'Total: ${_kosList.length}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                      fontSize: 14,
                    fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                    vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFBEB5A9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF6E473B).withOpacity(0.2),
                      width: 1,
                    ),
                ),
                child: Text(
                  'Ditampilkan: ${_filteredKosList.length}',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF291C0E),
                      fontSize: 14,
                    fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 800.ms, delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF6E473B)),
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat data kos...',
            style: GoogleFonts.poppins(
              color: const Color(0xFF291C0E).withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFE1D4C2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.home_outlined,
              size: 60,
              color: const Color(0xFF6E473B).withOpacity(0.7),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

          const SizedBox(height: 24),

          Text(
            'Belum Ada Kos',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF291C0E),
            ),
          ).animate().fadeIn(duration: 800.ms, delay: 200.ms),

          const SizedBox(height: 8),

          Text(
            'Mulai dengan menambahkan kos pertama Anda',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color(0xFF291C0E).withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 800.ms, delay: 400.ms),

          const SizedBox(height: 32),

          ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/add_kos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E473B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: Text(
                  'Tambah Kos Pertama',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              )
              .animate()
              .fadeIn(duration: 800.ms, delay: 600.ms)
              .scale(duration: 600.ms, delay: 600.ms, curve: Curves.elasticOut),
        ],
      ),
    );
  }

  Widget _buildKosList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _filteredKosList.length,
      itemBuilder: (context, index) {
        final kos = _filteredKosList[index];
        return _buildKosCard(kos, index);
      },
    );
  }

  Widget _buildKosCard(Kos kos, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
            color: const Color(0xFF291C0E).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Container(
              height: 180,
                  width: double.infinity,
                  color: const Color(0xFFE1D4C2),
                  child: kos.image != null
                      ? CachedNetworkImage(
                          imageUrl: kos.image!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFE1D4C2),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF6E473B),
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFE1D4C2),
                            child: Icon(
                          Icons.home_rounded,
                          size: 64,
                          color: const Color(0xFF6E473B).withOpacity(0.5),
                            ),
                          ),
                        )
                      : Icon(
                      Icons.home_rounded,
                      size: 64,
                      color: const Color(0xFF6E473B).withOpacity(0.5),
                        ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      kos.name,
                      style: GoogleFonts.poppins(
                    fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF291C0E),
                    height: 1.2,
                      ),
                    ),

                const SizedBox(height: 10),

                    // Address
                    Row(
                      children: [
                        Icon(
                      Icons.location_on_rounded,
                      size: 18,
                      color: const Color(0xFF6E473B).withOpacity(0.8),
                        ),
                    const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            kos.address,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF291C0E).withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                if (kos.description != null && kos.description!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                      Text(
                        kos.description!,
                        style: GoogleFonts.poppins(
                      fontSize: 13,
                          color: const Color(0xFF291C0E).withOpacity(0.6),
                          height: 1.4,
                      fontWeight: FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                const SizedBox(height: 18),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                          // Debug: Print kos data before navigation
                          print('DEBUG ManageKosPage: Navigating to edit kos');
                          print('DEBUG ManageKosPage: Kos ID: ${kos.id}');
                          print('DEBUG ManageKosPage: Kos name: "${kos.name}"');
                          
                          // Pass both ID and name as a Map to ensure data is preserved
                          final argumentsMap = {
                            'id': kos.id,
                            'name': kos.name,
                          };
                          print('DEBUG ManageKosPage: Arguments Map: $argumentsMap');
                          print('DEBUG ManageKosPage: Arguments type: ${argumentsMap.runtimeType}');
                          
                              final result = await Navigator.of(
                                context,
                          ).pushNamed('/edit_kos', arguments: argumentsMap);
                              if (result == true) {
                                // Refresh the list if edit was successful
                                _loadKosList();
                              }
                            },
                            style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFF6E473B),
                            width: 1.5,
                          ),
                              shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                              ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.white,
                            ),
                            icon: const Icon(
                          Icons.edit_rounded,
                          size: 20,
                              color: Color(0xFF6E473B),
                            ),
                            label: Text(
                              'Edit',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF6E473B),
                                fontWeight: FontWeight.w600,
                            fontSize: 15,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showDeleteDialog(kos),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red.shade600,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: Colors.red.shade200,
                              width: 1,
                            ),
                              ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                        ),
                            label: Text(
                              'Hapus',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                            fontSize: 15,
                              ),
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
        )
        .animate()
        .fadeIn(
          duration: 600.ms,
          delay: Duration(milliseconds: 200 + (index * 100)),
        )
        .slideY(
          begin: 0.3,
          end: 0,
          duration: 600.ms,
          delay: Duration(milliseconds: 200 + (index * 100)),
          curve: Curves.easeOutCubic,
        );
  }
}
