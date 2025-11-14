import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/kos.dart';
import '../../config.dart';
import '../../services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _carouselCurrentIndex = 0;
  final _api = ApiService();
  final _items = <Kos>[];
  int? _nextPage = 1;
  bool _loading = false;
  String _gender = 'all';
  String _sort = '';
  String? _search;
  int? _minPrice;
  int? _maxPrice;
  final _searchCtrl = TextEditingController();
  bool _isGrid = true;
  int _selectedCategory = 0;
  String? _userRole;
  String? _userName;
  String? _userAvatar;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Semua', 'icon': Icons.home_rounded, 'value': 'all'},
    {'name': 'Putra', 'icon': Icons.male_rounded, 'value': 'male'},
    {'name': 'Putri', 'icon': Icons.female_rounded, 'value': 'female'},
    {
      'name': 'Campur',
      'icon': Icons.people_rounded,
      'value':
          'mixed', // Use 'mixed' to distinguish from 'all', will be handled specially
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _reload();
  }

  Future<void> _checkUserRole() async {
    try {
      final user = await _api.getProfile();
      if (mounted) {
        setState(() {
          _userRole = user.role;
          _userName = user.name;
          _userAvatar = user.avatar;
        });
      }
    } catch (e) {
      // Ignore error, user might not be logged in
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Selamat Pagi';
    } else if (hour < 15) {
      return 'Selamat Siang';
    } else if (hour < 19) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
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
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Future<void> _reload() async {
    setState(() {
      _items.clear();
      _nextPage = 1;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_nextPage == null || _loading) return;
    setState(() => _loading = true);
    try {
      final page = _nextPage!;
      final res = await _api.getKosPage(
        page: page,
        gender: _gender,
        search: _search,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        sortBy: _sort.isEmpty ? null : _sort,
      );
      setState(() {
        _items.addAll(res.items);
        _nextPage = res.nextPage;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onCategoryChanged(int index) {
    setState(() {
      _selectedCategory = index;
      _gender = _categories[index]['value'];
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white, // Background putih
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: ClipRRect(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Greeting & Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _userName != null
                                ? '${_getGreeting()}, ${_userName!.split(' ').first}'
                                : 'Selamat Datang',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.1,
                              height: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getFormattedDate(),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.95),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Notification
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              // TODO: Navigate to notifications
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Center(
                                    child: Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade500,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF6E473B),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Three Dots Menu (for Add Kos and other actions)
                        if (_userRole == 'owner' || _userRole == 'admin')
                          PopupMenuButton<String>(
                            icon: Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.more_vert,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: Colors.white,
                            onSelected: (value) async {
                              if (value == 'add_kos') {
                                final result = await Navigator.of(
                                  context,
                                ).pushNamed('/add_kos');
                                if (result == true) {
                                  _reload();
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                value: 'add_kos',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.add_rounded,
                                      color: Color(0xFF6E473B),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Tambah Kos',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF291C0E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        // Avatar
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.of(context).pushNamed('/profile');
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: _userAvatar != null
                                  ? ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl:
                                            '$storageBaseUrl/${_userAvatar!}',
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) =>
                                            const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 20,
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
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Search Section
          SliverToBoxAdapter(
            child: _SearchSection(
              searchController: _searchCtrl,
              onSearch: (query) {
                _search = query.trim().isEmpty ? null : query.trim();
                _reload();
              },
              onFilter: _openFilterSheet,
              isGrid: _isGrid,
              onToggleView: () => setState(() => _isGrid = !_isGrid),
            ),
          ),

          // Categories Section
          SliverToBoxAdapter(
            child: _CategoriesSection(
              categories: _categories,
              selectedIndex: _selectedCategory,
              onCategoryChanged: _onCategoryChanged,
            ),
          ),

          // Featured Section
          if (_items.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _FeaturedSection(
                items: _items.take(3).toList(),
                onRefresh: _reload,
              ),
            ),
          ],

          // Main Content - Daftar Kos Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Row(
                children: [
                  Text(
                    'Daftar Kos',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF291C0E),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_items.length} kos ditemukan',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF291C0E).withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Horizontal Carousel for Daftar Kos
          if (_items.isEmpty && _loading)
            SliverToBoxAdapter(child: _buildShimmerList())
          else if (_items.isEmpty)
            SliverToBoxAdapter(child: _emptyState(context))
          else
            SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Carousel dengan height lebih tinggi agar perlu scroll sedikit
                  SizedBox(
                    height: 420, // Ditinggikan untuk perlu scroll sedikit
                    child: _CarouselWithEffect(
                      items: _items,
                      onTap: (kos) => _navigateToDetail(kos),
                      onPageChanged: (index) {
                        setState(() {
                          _carouselCurrentIndex = index;
                        });
                      },
                    ),
                  ),
                  // Indikator lebih ke bawah, tanpa container pembungkus
                  if (_items.length > 1) ...[
                    const SizedBox(
                      height: 20,
                    ), // Spacing lebih besar antara card dan indikator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _items.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _carouselCurrentIndex == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _carouselCurrentIndex == index
                                ? const Color(0xFF6E473B)
                                : const Color(0xFF6E473B).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16), // Spacing bawah sederhana
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToDetail(Kos kos) {
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (_, a1, a2) => FadeTransition(
              opacity: a1,
              child: KosDetailPage(kosId: kos.id, initial: kos),
            ),
          ),
        )
        .then((result) {
          // Refresh list if kos was deleted
          if (result == true) {
            _reload();
          }
        });
  }

  Widget _buildShimmerList() {
    if (_isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: 6,
        itemBuilder: (context, i) => _buildShimmerTile(context),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, i) => _buildShimmerTile(context),
    );
  }

  Widget _buildShimmerTile(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        height: 200,
      ),
    );
  }

  Future<void> _openFilterSheet() async {
    String gender = _gender;
    String sort = _sort;
    final minCtrl = TextEditingController(text: _minPrice?.toString() ?? '');
    final maxCtrl = TextEditingController(text: _maxPrice?.toString() ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: true,
      builder: (context) {
        return _FilterBottomSheet(
          gender: gender,
          sort: sort,
          minController: minCtrl,
          maxController: maxCtrl,
          onApply: (g, s, min, max) {
            setState(() {
              _gender = g;
              _sort = s;
              _minPrice = min;
              _maxPrice = max;
            });
            _reload();
          },
        );
      },
    );
  }
}

class _SearchSection extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearch;
  final VoidCallback onFilter;
  final bool isGrid;
  final VoidCallback onToggleView;

  const _SearchSection({
    required this.searchController,
    required this.onSearch,
    required this.onFilter,
    required this.isGrid,
    required this.onToggleView,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama/alamat kost...',
                hintStyle: GoogleFonts.poppins(
                  color: colors.onSurface.withOpacity(0.5),
                ),
                prefixIcon: Icon(Icons.search_rounded, color: colors.primary),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isGrid
                            ? Icons.view_agenda_rounded
                            : Icons.grid_view_rounded,
                        color: colors.primary,
                      ),
                      onPressed: onToggleView,
                    ),
                    IconButton(
                      icon: Icon(Icons.tune_rounded, color: colors.primary),
                      onPressed: onFilter,
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: onSearch,
            ),
          ).animate().slideY(
            begin: -0.3,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
          ),
        ],
      ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final int selectedIndex;
  final Function(int) onCategoryChanged;

  const _CategoriesSection({
    required this.categories,
    required this.selectedIndex,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 100,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = index == selectedIndex;

          return Container(
            margin: EdgeInsets.only(
              right: index == categories.length - 1 ? 0 : 12,
            ),
            child: _CategoryCard(
              category: category,
              isSelected: isSelected,
              onTap: () => onCategoryChanged(index),
            ),
          );
        },
      ),
    ).animate().slideX(
      begin: -0.3,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category['icon'],
              color: isSelected ? colors.onPrimary : colors.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              category['name'],
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? colors.onPrimary : colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedSection extends StatelessWidget {
  final List<Kos> items;
  final VoidCallback? onRefresh;

  const _FeaturedSection({required this.items, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Kost Unggulan',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.onBackground,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final kos = items[index];
                return Container(
                  width: 280,
                  margin: EdgeInsets.only(
                    right: index == items.length - 1 ? 0 : 12,
                  ),
                  child: _FeaturedCard(kos: kos, onRefresh: onRefresh),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().slideX(
      begin: -0.3,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOut,
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Kos kos;
  final VoidCallback? onRefresh;

  const _FeaturedCard({required this.kos, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (_, a1, a2) => FadeTransition(
                  opacity: a1,
                  child: KosDetailPage(kosId: kos.id, initial: kos),
                ),
              ),
            )
            .then((result) {
              // Refresh list if kos was deleted
              if (result == true && onRefresh != null) {
                onRefresh!();
              }
            });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Image
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: _imageUrl(kos),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: colors.surface,
                    child: Center(
                      child: CircularProgressIndicator(color: colors.primary),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: colors.surface,
                    child: Icon(
                      Icons.home_rounded,
                      size: 48,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kos.name,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            kos.address,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Featured Badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Unggulan',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.onPrimary,
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

class _ModernKosCard extends StatelessWidget {
  final Kos kos;
  final VoidCallback onTap;

  const _ModernKosCard({required this.kos, required this.onTap});

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: _imageUrl(kos),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: colors.surface,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: colors.primary,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: colors.surface,
                          child: Icon(
                            Icons.home_rounded,
                            size: 32,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.favorite_border_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kos.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: colors.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            kos.address,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: colors.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          kos.averageRating != null && kos.averageRating! > 0
                              ? kos.averageRating!.toStringAsFixed(1)
                              : '0.0',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          kos.price != null
                              ? 'Rp ${_formatPrice(kos.price!)}'
                              : '-',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernKosCardList extends StatelessWidget {
  final Kos kos;
  final VoidCallback onTap;

  const _ModernKosCardList({required this.kos, required this.onTap});

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: SizedBox(
                width: 100,
                height: 100,
                child: CachedNetworkImage(
                  imageUrl: _imageUrl(kos),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: colors.surface,
                    child: Center(
                      child: CircularProgressIndicator(color: colors.primary),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: colors.surface,
                    child: Icon(
                      Icons.home_rounded,
                      size: 32,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kos.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: colors.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            kos.address,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: colors.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          kos.averageRating != null && kos.averageRating! > 0
                              ? kos.averageRating!.toStringAsFixed(1)
                              : '0.0',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          kos.price != null
                              ? 'Rp ${_formatPrice(kos.price!)}'
                              : '-',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final String gender;
  final String sort;
  final TextEditingController minController;
  final TextEditingController maxController;
  final Function(String, String, int?, int?) onApply;

  const _FilterBottomSheet({
    required this.gender,
    required this.sort,
    required this.minController,
    required this.maxController,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String gender;
  late String sort;
  late TextEditingController minController;
  late TextEditingController maxController;

  @override
  void initState() {
    super.initState();
    gender = widget.gender;
    sort = widget.sort;
    minController = widget.minController;
    maxController = widget.maxController;
  }

  Widget _buildGenderChip(
    String value,
    String label,
    String selected,
    VoidCallback onTap,
  ) {
    // Check if this chip is selected
    final isSelected = gender == value;

    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6E473B) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6E473B)
                : const Color(0xFFBEB5A9),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF6E473B),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Filter & Urutkan',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 20),

          // Gender Filter
          Text(
            'Jenis Kost',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildGenderChip('all', 'Semua', gender, () {
                setState(() => gender = 'all');
              }),
              _buildGenderChip('male', 'Putra', gender, () {
                setState(() => gender = 'male');
              }),
              _buildGenderChip('female', 'Putri', gender, () {
                setState(() => gender = 'female');
              }),
              _buildGenderChip('mixed', 'Campur', gender, () {
                setState(
                  () => gender = 'mixed',
                ); // Campur = hanya gender = 'all' (campur)
              }),
            ],
          ),
          const SizedBox(height: 16),

          // Sort Options
          Text(
            'Urutkan',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: sort.isEmpty ? null : sort,
            items: const [
              DropdownMenuItem(
                value: 'price_low',
                child: Text('Harga Terendah'),
              ),
              DropdownMenuItem(
                value: 'price_high',
                child: Text('Harga Tertinggi'),
              ),
              DropdownMenuItem(value: 'popular', child: Text('Terpopuler')),
            ],
            onChanged: (value) => setState(() => sort = value ?? ''),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Price Range
          Text(
            'Rentang Harga',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: minController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Min Harga',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: maxController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Max Harga',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    int? minPrice = int.tryParse(minController.text.trim());
                    int? maxPrice = int.tryParse(maxController.text.trim());
                    widget.onApply(gender, sort, minPrice, maxPrice);
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Terapkan',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedItem extends StatefulWidget {
  final int index;
  final Widget child;
  const _AnimatedItem({required this.index, required this.child});

  @override
  State<_AnimatedItem> createState() => _AnimatedItemState();
}

class _AnimatedItemState extends State<_AnimatedItem> {
  bool _start = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 60 * (widget.index.clamp(0, 8))), () {
      if (mounted) setState(() => _start = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: _start ? 1 : 0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

Widget _emptyState(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_outlined, size: 72, color: colors.outline),
          const SizedBox(height: 12),
          Text(
            'Belum ada kos',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Coba ubah pencarian atau reset filter.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: colors.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    ),
  );
}

String _imageUrl(Kos kos) {
  return kos.image ?? 'https://picsum.photos/seed/kos-${kos.id}/800/450';
}

// Carousel dengan efek highlight
class _CarouselWithEffect extends StatefulWidget {
  final List<Kos> items;
  final Function(Kos) onTap;
  final Function(int)? onPageChanged;

  const _CarouselWithEffect({
    required this.items,
    required this.onTap,
    this.onPageChanged,
  });

  @override
  State<_CarouselWithEffect> createState() => _CarouselWithEffectState();
}

class _CarouselWithEffectState extends State<_CarouselWithEffect> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85, initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              clipBehavior: Clip.none, // Tidak clip shadow
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                // Kirim currentIndex ke parent
                widget.onPageChanged?.call(index);
              },
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final kos = widget.items[index];
                final isActive = index == _currentIndex;

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isActive ? 8 : 16,
                    vertical:
                        0, // Tidak ada padding vertical yang membatasi shadow
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    // Hapus margin vertical yang membatasi shadow
                    child: Transform.scale(
                      scale: isActive ? 1.0 : 0.9,
                      child: _HorizontalKosCard(
                        kos: kos,
                        isActive: isActive,
                        onTap: () => widget.onTap(kos),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Horizontal Kos Card untuk carousel
class _HorizontalKosCard extends StatelessWidget {
  final Kos kos;
  final bool isActive;
  final VoidCallback onTap;

  const _HorizontalKosCard({
    required this.kos,
    required this.isActive,
    required this.onTap,
  });

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                0.3,
              ), // Dipertebal dari 0.1 ke 0.3
              blurRadius: 25, // Ditingkatkan dari 15 ke 25
              offset: const Offset(0, 10), // Ditingkatkan dari 8 ke 10
              spreadRadius:
                  2, // Tambahkan spreadRadius untuk shadow lebih tebal
            ),
            BoxShadow(
              color: Colors.black.withOpacity(
                0.15,
              ), // Shadow kedua untuk efek lebih tebal
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section (Top)
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    // Background Image
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: _imageUrl(kos),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.white,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: const Color(0xFF6E473B),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.white,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.home_rounded,
                                  size: 48,
                                  color: const Color(0xFF6E473B),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Kos Image',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6E473B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Favorite Button
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.favorite_border_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content Section (Bottom)
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      kos.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF291C0E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Address
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: const Color(0xFF291C0E).withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            kos.address,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF291C0E).withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Rating & Price
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          kos.averageRating != null && kos.averageRating! > 0
                              ? kos.averageRating!.toStringAsFixed(1)
                              : '0.0',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF291C0E),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          kos.price != null
                              ? 'Rp ${_formatPrice(kos.price!)}'
                              : '-',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6E473B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Keep existing KosDetailPage class as is
class KosDetailPage extends StatefulWidget {
  final int kosId;
  final Kos? initial;
  const KosDetailPage({super.key, required this.kosId, this.initial});

  @override
  State<KosDetailPage> createState() => _KosDetailPageState();
}

class _KosDetailPageState extends State<KosDetailPage> {
  final _api = ApiService();
  late Future<Map<String, dynamic>> _future;
  String? _userRole;
  int? _currentUserId;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _future = _api.getKosDetail(widget.kosId);
    _checkUserRole();
  }

  Future<void> _refreshKosDetail() async {
    setState(() {
      _future = _api.getKosDetail(widget.kosId);
    });
  }

  Future<void> _checkUserRole() async {
    try {
      final user = await _api.getProfile();
      if (mounted) {
        setState(() {
          _userRole = user.role;
          _currentUserId = user.id;
        });
      }
    } catch (e) {
      // User might not be logged in
    }
  }

  Future<void> _deleteKos() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                  Icons.delete_outline_rounded,
                  size: 40,
                  color: Colors.red.shade600,
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

              const SizedBox(height: 24),

              // Title
              Text(
                'Hapus Kos',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF291C0E),
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

              const SizedBox(height: 12),

              // Message
              Text(
                'Apakah Anda yakin ingin menghapus kos ini? Tindakan ini tidak dapat dibatalkan.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF291C0E).withOpacity(0.7),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: const Color(0xFFBEB5A9),
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
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
                      onPressed: () => Navigator.pop(context, true),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await _api.deleteKos(widget.kosId);
      if (!mounted) return;

      // Show success notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Kos berhasil dihapus',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
        ),
      );

      // Return true to indicate success, so home page can refresh
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Gagal menghapus kos: ${e.toString()}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _showAddReviewDialog(BuildContext context, int kosId) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => _AddReviewDialog(
        kosId: kosId,
        parentContext: context, // Pass parent context
        onReviewAdded: () {
          _refreshKosDetail();
        },
      ),
    );
  }

  Future<void> _showEditReviewDialog(
    BuildContext context,
    int reviewId,
    String currentComment,
    int currentRating,
  ) async {
    final commentController = TextEditingController(text: currentComment);
    int selectedRating = currentRating;

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6E473B),
                            const Color(0xFF8B6F5E),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Edit Ulasan',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Rating
                    Text(
                      'Rating',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF291C0E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        final rating = index + 1;
                        return GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedRating = rating),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              rating <= selectedRating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: rating <= selectedRating
                                  ? Colors.amber
                                  : Colors.grey.shade300,
                              size: 32,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    // Comment
                    Text(
                      'Komentar',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF291C0E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Tulis ulasan Anda...',
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
                          borderSide: const BorderSide(
                            color: Color(0xFF6E473B),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              'Batal',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (commentController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Komentar tidak boleh kosong',
                                    ),
                                  ),
                                );
                                return;
                              }
                              Navigator.pop(context);
                              await _updateReview(
                                reviewId,
                                commentController.text.trim(),
                                selectedRating,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6E473B),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Update',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
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
          ),
        ),
      ),
    ).then((_) {
      // Dispose controller setelah dialog ditutup
      commentController.dispose();
    });
  }

  Future<void> _updateReview(int reviewId, String comment, int rating) async {
    try {
      await _api.updateReview(
        reviewId: reviewId,
        comment: comment,
        rating: rating,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Ulasan berhasil diupdate'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        _refreshKosDetail();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Gagal mengupdate ulasan'),
              ],
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

  Future<void> _deleteReview(int reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header dengan gradient merah
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red.shade600,
                        Colors.red.shade500,
                        Colors.red.shade600,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Hapus Ulasan?',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red.shade600,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Ulasan yang dihapus tidak dapat dikembalikan',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF291C0E),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context, false),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: Text(
                              'Batal',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                              foregroundColor: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context, true),
                            icon: const Icon(Icons.delete_rounded, size: 18),
                            label: Text(
                              'Hapus',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
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
      ),
    );

    if (confirmed == true) {
      try {
        await _api.deleteReview(reviewId);
        if (mounted) {
          // Tampilkan dialog sukses setelah berhasil menghapus
          _showDeleteSuccessNotification(context);
          _refreshKosDetail();
        }
      } catch (e) {
        if (mounted) {
          // Tampilkan dialog error jika gagal menghapus
          _showDeleteErrorNotification(context, e);
        }
      }
    }
  }

  void _showDeleteSuccessNotification(BuildContext context) {
    bool isDialogOpen = true;
    final timerRef = <Timer?>[null];

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        // Auto close setelah 3 detik (hanya sekali)
        if (timerRef[0] == null) {
          timerRef[0] = Timer(const Duration(seconds: 3), () {
            if (isDialogOpen &&
                dialogContext.mounted &&
                Navigator.of(dialogContext, rootNavigator: true).canPop()) {
              Navigator.of(dialogContext, rootNavigator: true).pop();
              isDialogOpen = false;
            }
          });
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header dengan gradient hijau
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green.shade600,
                          Colors.green.shade500,
                          Colors.green.shade600,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Ulasan Berhasil Dihapus',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green.shade600,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Ulasan telah berhasil dihapus',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF291C0E),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            isDialogOpen = false;
                            timerRef[0]?.cancel();
                            Navigator.of(
                              dialogContext,
                              rootNavigator: true,
                            ).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: Text(
                            'Tutup',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
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
      },
    );
  }

  void _showDeleteErrorNotification(BuildContext context, dynamic error) {
    String message = 'Gagal menghapus ulasan';

    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      } else if (data is String) {
        message = data;
      }
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header dengan gradient merah
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red.shade600,
                        Colors.red.shade500,
                        Colors.red.shade600,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Gagal Menghapus Ulasan',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red.shade600,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      message,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF291C0E),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(
                          dialogContext,
                          rootNavigator: true,
                        ).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: Text(
                          'Mengerti',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initial;
    final heroTag = 'kos-image-${widget.kosId}';
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Handle 404 error (kos not found - likely deleted)
            final error = snapshot.error;
            if (error is DioException && error.response?.statusCode == 404) {
              // Kos was deleted, go back and refresh
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.pop(context, true); // Return true to refresh list
                }
              });
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Kos tidak ditemukan',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kos mungkin sudah dihapus',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat data',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      error.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }
          final data = snapshot.data ?? const <String, dynamic>{};
          final name = (data['name'] ?? initial?.name ?? '').toString();
          final address = (data['address'] ?? initial?.address ?? '')
              .toString();
          final description =
              (data['description'] ?? initial?.description ?? '').toString();
          final images = (data['images'] as List?) ?? const [];
          final rooms = (data['rooms'] as List?) ?? const [];
          final facilities = (data['facilities'] as List?) ?? const [];
          final payments =
              (data['payment_methods'] as List?) ??
              (data['paymentMethods'] as List?) ??
              const [];
          final avgRating = data['average_rating']?.toString();
          final reviews = (data['reviews'] as List?) ?? const [];

          // Check if current user is owner
          final owner = data['owner'] as Map<String, dynamic>?;
          final ownerId = (owner?['id'] as num?)?.toInt();
          final isOwner =
              _userRole == 'owner' &&
              ownerId != null &&
              _currentUserId != null &&
              _currentUserId == ownerId;

          return Scaffold(
            backgroundColor: Colors.white,
            extendBodyBehindAppBar: true,
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 350,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF291C0E),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  actions: isOwner
                      ? [
                          Container(
                            margin: const EdgeInsets.only(
                              right: 8,
                              top: 8,
                              bottom: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _isDeleting
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF6E473B),
                                      ),
                                    ),
                                  )
                                : PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert_rounded,
                                      color: Color(0xFF291C0E),
                                    ),
                                    tooltip: 'Menu',
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 8,
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _deleteKos();
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline_rounded,
                                              color: Colors.red.shade600,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Hapus Kos',
                                              style: GoogleFonts.poppins(
                                                color: Colors.red.shade600,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ]
                      : null,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(
                      left: 72,
                      bottom: 16,
                      right: 16,
                    ),
                    centerTitle: false,
                    title: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                          child: Hero(
                            tag: heroTag,
                            child: (images.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl:
                                        '$storageBaseUrl/${(images.first as Map<String, dynamic>)['file']}',
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            const Color(
                                              0xFF6E473B,
                                            ).withOpacity(0.8),
                                            const Color(
                                              0xFF8B6F5E,
                                            ).withOpacity(0.6),
                                          ],
                                        ),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                const Color(
                                                  0xFF6E473B,
                                                ).withOpacity(0.8),
                                                const Color(
                                                  0xFF8B6F5E,
                                                ).withOpacity(0.6),
                                              ],
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.home_rounded,
                                            size: 64,
                                            color: Colors.white70,
                                          ),
                                        ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: _imageUrl(
                                      initial ??
                                          Kos(
                                            id: widget.kosId,
                                            name: name,
                                            address: address,
                                          ),
                                    ),
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            const Color(
                                              0xFF6E473B,
                                            ).withOpacity(0.8),
                                            const Color(
                                              0xFF8B6F5E,
                                            ).withOpacity(0.6),
                                          ],
                                        ),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                const Color(
                                                  0xFF6E473B,
                                                ).withOpacity(0.8),
                                                const Color(
                                                  0xFF8B6F5E,
                                                ).withOpacity(0.6),
                                              ],
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.home_rounded,
                                            size: 64,
                                            color: Colors.white70,
                                          ),
                                        ),
                                  ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(32),
                              bottomRight: Radius.circular(32),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.3, 0.7, 1.0],
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.1),
                                Colors.black.withOpacity(0.5),
                                Colors.black.withOpacity(0.8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Info Cards
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _ModernInfoCard(
                                  icon: Icons.location_on_rounded,
                                  title: 'Lokasi',
                                  value: address,
                                  color: const Color(0xFF6E473B),
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (avgRating != null)
                                Expanded(
                                  child: _ModernInfoCard(
                                    icon: Icons.star_rounded,
                                    title: 'Rating',
                                    value: avgRating,
                                    color: Colors.amber.shade700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Description
                        if (description.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _ModernSectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF6E473B,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.description_rounded,
                                          size: 20,
                                          color: Color(0xFF6E473B),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Deskripsi',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF291C0E),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    description,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: const Color(
                                        0xFF291C0E,
                                      ).withOpacity(0.7),
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Facilities
                        if (facilities.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF6E473B,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.room_preferences_rounded,
                                        size: 20,
                                        color: Color(0xFF6E473B),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Fasilitas',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF291C0E),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    for (final f in facilities)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white,
                                              Colors.white,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF6E473B,
                                              ).withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF6E473B,
                                                ).withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                _getFacilityIcon(
                                                  (f['facility'] as String?) ??
                                                      '',
                                                ),
                                                size: 18,
                                                color: const Color(0xFF6E473B),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              (f['facility'] as String?) ?? '-',
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Payment Methods
                        if (payments.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF6E473B,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.payment_rounded,
                                        size: 20,
                                        color: Color(0xFF6E473B),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Metode Pembayaran',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF291C0E),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    for (final p in payments)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white,
                                              Colors.white,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF6E473B,
                                              ).withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF6E473B,
                                                ).withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                _getPaymentIcon(
                                                  (p['type'] as String?) ?? '',
                                                ),
                                                size: 18,
                                                color: const Color(0xFF6E473B),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              _getPaymentName(
                                                (p['type'] as String?) ?? '',
                                              ),
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Available Rooms
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF6E473B,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.bed_rounded,
                                      size: 20,
                                      color: Color(0xFF6E473B),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Kamar Tersedia',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF291C0E),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (rooms.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF6E473B,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${rooms.length} kamar',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF6E473B),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (rooms.isEmpty)
                                _ModernSectionCard(
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF6E473B,
                                            ).withOpacity(0.05),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.bed_outlined,
                                            size: 48,
                                            color: Color(0xFF6E473B),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Tidak ada kamar tersedia',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(
                                              0xFF291C0E,
                                            ).withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ...rooms.map((r) {
                                  final room = r as Map<String, dynamic>;
                                  final isAvailable =
                                      room['is_available'] ?? true;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _ModernRoomCard(
                                      roomNumber:
                                          room['room_number']?.toString() ?? '',
                                      roomType: _formatRoomType(
                                        room['room_type']?.toString() ??
                                            'single',
                                      ),
                                      isAvailable: isAvailable,
                                      onBooking: isAvailable
                                          ? () => _openBookingSheet(
                                              context,
                                              widget.kosId,
                                              (room['id'] as num).toInt(),
                                            )
                                          : null,
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Reviews Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _ModernSectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF6E473B,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.star_rounded,
                                        size: 20,
                                        color: Color(0xFF6E473B),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Ulasan & Komentar',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF291C0E),
                                        ),
                                      ),
                                    ),
                                    if (_userRole == 'society' && !isOwner)
                                      TextButton.icon(
                                        onPressed: () => _showAddReviewDialog(
                                          context,
                                          widget.kosId,
                                        ),
                                        icon: const Icon(
                                          Icons.add_rounded,
                                          size: 18,
                                        ),
                                        label: Text(
                                          'Tambah',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF6E473B,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (reviews.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.reviews_outlined,
                                            size: 48,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Belum ada ulasan',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  ...reviews.map((r) {
                                    final review = r as Map<String, dynamic>;
                                    final reviewId = (review['id'] as num?)
                                        ?.toInt();
                                    final comment =
                                        review['comment']?.toString() ?? '';
                                    final rating =
                                        review['rating'] as int? ?? 0;
                                    final user =
                                        review['user']
                                            as Map<String, dynamic>? ??
                                        {};
                                    final userName =
                                        user['name']?.toString() ?? 'User';
                                    final createdAt = review['created_at']
                                        ?.toString();
                                    final reply =
                                        review['reply']
                                            as Map<String, dynamic>?;
                                    final isMyReview =
                                        reviewId != null &&
                                        _currentUserId != null &&
                                        (user['id'] as num?)?.toInt() ==
                                            _currentUserId;

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: _ReviewItem(
                                        userName: userName,
                                        comment: comment,
                                        rating: rating,
                                        createdAt: createdAt,
                                        reply: reply,
                                        isMyReview: isMyReview,
                                        onEdit: isMyReview && reviewId != null
                                            ? () => _showEditReviewDialog(
                                                context,
                                                reviewId!,
                                                comment,
                                                rating,
                                              )
                                            : null,
                                        onDelete: isMyReview && reviewId != null
                                            ? () => _deleteReview(reviewId!)
                                            : null,
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButton:
                rooms.isNotEmpty && !isOwner && _userRole == 'society'
                ? FloatingActionButton.extended(
                    onPressed: () {
                      if (rooms.isNotEmpty) {
                        final firstAvailableRoom = rooms.firstWhere(
                          (r) =>
                              (r as Map<String, dynamic>)['is_available'] ??
                              true,
                          orElse: () => rooms.first,
                        );
                        _openBookingSheet(
                          context,
                          widget.kosId,
                          ((firstAvailableRoom as Map<String, dynamic>)['id']
                                  as num)
                              .toInt(),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tidak ada kamar tersedia.'),
                          ),
                        );
                      }
                    },
                    backgroundColor: const Color(0xFF6E473B),
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.event_available_rounded),
                    label: Text(
                      'Booking Sekarang',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }

  IconData _getFacilityIcon(String facility) {
    final lower = facility.toLowerCase();
    if (lower.contains('ac') || lower.contains('air conditioner')) {
      return Icons.ac_unit_rounded;
    } else if (lower.contains('kamar mandi') || lower.contains('bathroom')) {
      return Icons.bathroom_rounded;
    } else if (lower.contains('laundry')) {
      return Icons.local_laundry_service_rounded;
    } else if (lower.contains('tv') || lower.contains('televisi')) {
      return Icons.tv_rounded;
    } else if (lower.contains('wifi') || lower.contains('internet')) {
      return Icons.wifi_rounded;
    } else if (lower.contains('parkir') || lower.contains('parking')) {
      return Icons.local_parking_rounded;
    } else {
      return Icons.check_circle_outline_rounded;
    }
  }

  IconData _getPaymentIcon(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('transfer') || lower.contains('bank')) {
      return Icons.account_balance_rounded;
    } else if (lower.contains('cash') || lower.contains('tunai')) {
      return Icons.money_rounded;
    } else if (lower.contains('qris') ||
        lower.contains('e-wallet') ||
        lower.contains('ewallet')) {
      return Icons.qr_code_rounded;
    } else {
      return Icons.payment_rounded;
    }
  }

  String _getPaymentName(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('transfer')) {
      return 'Transfer Bank';
    } else if (lower.contains('cash')) {
      return 'Cash';
    } else if (lower.contains('qris')) {
      return 'QRIS';
    } else {
      return type;
    }
  }

  String _formatRoomType(String type) {
    final lower = type.toLowerCase();
    if (lower == 'single') {
      return 'Single';
    } else if (lower == 'double') {
      return 'Double';
    } else {
      return type;
    }
  }

  Future<void> _openBookingSheet(
    BuildContext context,
    int kosId,
    int roomId,
  ) async {
    // Check if user is logged in and has society role
    try {
      final user = await _api.getProfile();
      if (user.role != 'society') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    user.role == 'owner'
                        ? 'Pemilik kos tidak dapat melakukan booking. Silakan gunakan akun dengan role "society" untuk booking.'
                        : 'Anda tidak memiliki akses untuk melakukan booking. Silakan gunakan akun dengan role "society".',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }
    } catch (e) {
      // User not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Silakan login terlebih dahulu dengan akun role "society" untuk melakukan booking.',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final parentContext = context; // Save parent context for SnackBar
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _BookingSheet(
          kosId: kosId,
          roomId: roomId,
          parentContext: parentContext,
          sheetContext: sheetContext,
        );
      },
    );
  }
}

class _BookingSheet extends StatefulWidget {
  final int kosId;
  final int roomId;
  final BuildContext parentContext;
  final BuildContext sheetContext;

  const _BookingSheet({
    required this.kosId,
    required this.roomId,
    required this.parentContext,
    required this.sheetContext,
  });

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  final _api = ApiService();
  DateTime? start;
  DateTime? end;
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: start ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() => start = picked);
    }
  }

  Future<void> _pickEnd() async {
    final base = start ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: end ?? base.add(const Duration(days: 30)),
      firstDate: base.add(const Duration(days: 1)),
      lastDate: DateTime(base.year + 2),
    );
    if (picked != null) {
      setState(() => end = picked);
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  Future<void> _handleSubmit() async {
    if (start == null || end == null || _isSubmitting) return;

    if (!mounted) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null; // Clear previous error
    });

    try {
      // Check if user is logged in
      try {
        await _api.getProfile();
      } catch (authError) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
          _errorMessage =
              'Silakan login terlebih dahulu untuk melakukan booking';
        });
        return;
      }

      final res = await _api.createBooking(
        kosId: widget.kosId,
        roomId: widget.roomId,
        startDate: start!,
        endDate: end!,
      );

      // Close modal first
      if (mounted) {
        Navigator.of(widget.sheetContext).pop();
      }

      // Wait a bit for modal to close
      await Future.delayed(const Duration(milliseconds: 300));

      if (!widget.parentContext.mounted) return;

      // Navigate to success page
      Navigator.of(
        widget.parentContext,
      ).pushNamed('/booking_success', arguments: res);
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Gagal melakukan booking';

      if (e is DioException) {
        if (e.response?.statusCode == 403) {
          errorMessage =
              'Akses ditolak. Pastikan Anda sudah login dan memiliki akses untuk booking.';
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'Sesi Anda telah berakhir. Silakan login kembali.';
        } else if (e.response?.statusCode == 422) {
          final errors = e.response?.data?['errors'];
          if (errors != null) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              errorMessage = firstError.first.toString();
            } else {
              errorMessage = e.response?.data?['message'] ?? 'Data tidak valid';
            }
          } else {
            errorMessage = e.response?.data?['message'] ?? 'Data tidak valid';
          }
        } else {
          errorMessage =
              e.response?.data?['message'] ??
              e.message ??
              'Terjadi kesalahan saat melakukan booking';
        }
      } else {
        errorMessage = e.toString();
      }

      // Show error message in modal and SnackBar
      setState(() {
        _isSubmitting = false;
        _errorMessage = errorMessage;
      });

      // Also show SnackBar for better visibility
      if (widget.parentContext.mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(errorMessage, style: GoogleFonts.poppins()),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Booking Kamar',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF291C0E),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : _pickStart,
                  child: Text(start == null ? 'Mulai' : _fmt(start!)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : _pickEnd,
                  child: Text(end == null ? 'Selesai' : _fmt(end!)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Error message display
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.poppins(
                        color: Colors.red.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          FilledButton(
            onPressed: (start == null || end == null || _isSubmitting)
                ? null
                : _handleSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6E473B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Memproses...',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Kirim Booking',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// Modern UI Components
class _ModernInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _ModernInfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF291C0E).withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF291C0E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernSectionCard extends StatelessWidget {
  final Widget child;

  const _ModernSectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6E473B).withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ModernRoomCard extends StatelessWidget {
  final String roomNumber;
  final String roomType;
  final bool isAvailable;
  final VoidCallback? onBooking;

  const _ModernRoomCard({
    required this.roomNumber,
    required this.roomType,
    required this.isAvailable,
    this.onBooking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isAvailable
              ? const Color(0xFF6E473B).withOpacity(0.12)
              : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isAvailable
                ? const Color(0xFF6E473B).withOpacity(0.08)
                : Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isAvailable
                    ? const Color(0xFF6E473B).withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.bed_rounded,
                color: isAvailable
                    ? const Color(0xFF6E473B)
                    : Colors.grey.shade400,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kamar $roomNumber',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF291C0E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? const Color(0xFF6E473B).withOpacity(0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          roomType,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isAvailable
                                ? const Color(0xFF6E473B)
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      if (!isAvailable) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Tidak Tersedia',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isAvailable && onBooking != null)
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6E473B), Color(0xFF8B6F5E)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6E473B).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onBooking,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      child: Text(
                        'Booking',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddReviewDialog extends StatefulWidget {
  final int kosId;
  final BuildContext parentContext;
  final VoidCallback onReviewAdded;

  const _AddReviewDialog({
    required this.kosId,
    required this.parentContext,
    required this.onReviewAdded,
  });

  @override
  State<_AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<_AddReviewDialog> {
  final _api = ApiService();
  late final TextEditingController _commentController;
  int _selectedRating = 5;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Komentar tidak boleh kosong')),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _api.addReview(
        kosId: widget.kosId,
        comment: _commentController.text.trim(),
        rating: _selectedRating,
      );
      if (mounted) {
        Navigator.pop(context);
        // Tampilkan success notification setelah dialog ditutup
        Future.delayed(const Duration(milliseconds: 300), () {
          if (widget.parentContext.mounted) {
            _showSuccessNotification(widget.parentContext);
            widget.onReviewAdded();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        // Tutup dialog terlebih dahulu
        Navigator.pop(context);

        // Tampilkan dialog error setelah dialog ditutup menggunakan parent context
        Future.delayed(const Duration(milliseconds: 300), () {
          if (widget.parentContext.mounted) {
            _showErrorDialog(widget.parentContext, e);
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showErrorDialog(BuildContext context, dynamic error) {
    String message = 'Gagal menambahkan ulasan';
    String title = 'Tidak Dapat Menambahkan Ulasan';
    IconData icon = Icons.error_outline_rounded;
    Color iconColor = Colors.red.shade600;

    if (error is DioException) {
      final data = error.response?.data;
      print('DEBUG Error Dialog - Response data: $data');

      if (data is Map) {
        if (data['message'] != null) {
          message = data['message'].toString();
          print('DEBUG Error Dialog - Message from response: $message');
        }
        if (data['errors'] is Map) {
          final errors = data['errors'] as Map;
          if (errors.isNotEmpty) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              message = firstError.first.toString();
            } else if (firstError is String) {
              message = firstError;
            }
          }
        }
      } else if (data is String) {
        message = data;
      }

      if (error.response?.statusCode == 400) {
        final lowerMessage = message.toLowerCase();
        if (lowerMessage.contains('booked') ||
            lowerMessage.contains('booking') ||
            lowerMessage.contains('diterima') ||
            lowerMessage.contains('accepted')) {
          title = 'Belum Memenuhi Syarat';
          message =
              'Anda hanya bisa memberikan ulasan untuk kos yang sudah Anda booking dan diterima';
          icon = Icons.info_outline_rounded;
          iconColor = Colors.orange.shade600;
        } else if (lowerMessage.contains('already reviewed') ||
            lowerMessage.contains('sudah') ||
            lowerMessage.contains('reviewed')) {
          title = 'Ulasan Sudah Ada';
          message = 'Anda sudah memberikan ulasan untuk kos ini';
          icon = Icons.star_outline_rounded;
          iconColor = Colors.amber.shade700;
        }
      }
    }

    print('DEBUG Error Dialog - Final message: $message');

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header dengan gradient merah/orange
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        iconColor,
                        iconColor.withOpacity(0.8),
                        iconColor,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 48),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      message,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF291C0E),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(
                          dialogContext,
                          rootNavigator: true,
                        ).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: iconColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: Text(
                          'Mengerti',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessNotification(BuildContext context) {
    bool isDialogOpen = true;
    final timerRef = <Timer?>[null];

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        // Auto close setelah 3 detik (hanya sekali)
        if (timerRef[0] == null) {
          timerRef[0] = Timer(const Duration(seconds: 3), () {
            if (isDialogOpen &&
                dialogContext.mounted &&
                Navigator.of(dialogContext, rootNavigator: true).canPop()) {
              Navigator.of(dialogContext, rootNavigator: true).pop();
              isDialogOpen = false;
            }
          });
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header dengan gradient hijau
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green.shade600,
                          Colors.green.shade500,
                          Colors.green.shade600,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Ulasan Berhasil Ditambahkan',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green.shade600,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Terima kasih telah memberikan ulasan!',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF291C0E),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            isDialogOpen = false;
                            timerRef[0]?.cancel();
                            Navigator.of(
                              dialogContext,
                              rootNavigator: true,
                            ).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: Text(
                            'Tutup',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
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
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tambah Ulasan',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Bagikan pengalaman Anda',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rating Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.amber.shade100,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.star_rate_rounded,
                                color: Colors.amber.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Berikan Rating',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF291C0E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                final rating = index + 1;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedRating = rating),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Icon(
                                      rating <= _selectedRating
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      color: rating <= _selectedRating
                                          ? Colors.amber.shade700
                                          : Colors.grey.shade300,
                                      size: rating <= _selectedRating ? 40 : 36,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              _selectedRating == 1
                                  ? 'Sangat Buruk'
                                  : _selectedRating == 2
                                  ? 'Buruk'
                                  : _selectedRating == 3
                                  ? 'Cukup'
                                  : _selectedRating == 4
                                  ? 'Baik'
                                  : 'Sangat Baik',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Comment Section
                    Row(
                      children: [
                        Icon(
                          Icons.edit_note_rounded,
                          color: const Color(0xFF6E473B),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Komentar',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF291C0E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentController,
                      maxLines: 5,
                      enabled: !_isSubmitting,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF291C0E),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tulis ulasan Anda tentang kos ini...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.all(16),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.message_rounded,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF6E473B),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: Text(
                              'Batal',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                              foregroundColor: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _submitReview,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded, size: 18),
                            label: Text(
                              _isSubmitting ? 'Mengirim...' : 'Kirim Ulasan',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6E473B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
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
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final String userName;
  final String comment;
  final int rating;
  final String? createdAt;
  final Map<String, dynamic>? reply;
  final bool isMyReview;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ReviewItem({
    required this.userName,
    required this.comment,
    required this.rating,
    this.createdAt,
    this.reply,
    required this.isMyReview,
    this.onEdit,
    this.onDelete,
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Baru saja';
          }
          return '${difference.inMinutes} menit yang lalu';
        }
        return '${difference.inHours} jam yang lalu';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} hari yang lalu';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6E473B).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6E473B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            userName,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF291C0E),
                            ),
                          ),
                        ),
                        if (isMyReview) ...[
                          if (onEdit != null)
                            IconButton(
                              icon: const Icon(
                                Icons.edit_rounded,
                                size: 18,
                                color: Color(0xFF6E473B),
                              ),
                              onPressed: onEdit,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          if (onDelete != null)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Colors.red,
                              ),
                              onPressed: onDelete,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 14,
                            color: index < rating
                                ? Colors.amber
                                : Colors.grey.shade300,
                          );
                        }),
                        if (createdAt != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(createdAt),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF291C0E).withOpacity(0.8),
              height: 1.5,
            ),
          ),
          if (reply != null && reply!['owner_reply'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6E473B).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6E473B).withOpacity(0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.store_rounded,
                    size: 16,
                    color: const Color(0xFF6E473B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balasan Pemilik',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6E473B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reply!['owner_reply'].toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF291C0E).withOpacity(0.8),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
