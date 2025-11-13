import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _api = ApiService();
  late Future<User> _future;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  XFile? _picked;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _api.getProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<User>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6E473B)),
            );
          }
          final user = snapshot.data!;
          _name.text = _name.text.isEmpty ? user.name : _name.text;
          _phone.text = _phone.text.isEmpty ? (user.phone ?? '') : _phone.text;
          final avatarPath = user.avatar;
          final avatarUrl = avatarPath != null
              ? '$storageBaseUrl/$avatarPath'
              : null;

          return CustomScrollView(
            slivers: [
              // Custom App Bar
              SliverAppBar(
                expandedHeight: 200,
                floating: true,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF6E473B).withOpacity(0.1),
                          Colors.white,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          _buildAvatarSection(avatarUrl),
                          const SizedBox(height: 12),
                          Text(
                            user.name,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF291C0E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF291C0E).withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Profile Stats
              SliverToBoxAdapter(child: _buildStatsSection()),

              // Admin Section (if user is admin/owner)
              if (user.role == 'admin' || user.role == 'owner')
                SliverToBoxAdapter(child: _buildAdminSection()),

              // Profile Settings
              SliverToBoxAdapter(child: _buildSettingsSection(user, avatarUrl)),

              // Logout Section
              SliverToBoxAdapter(child: _buildLogoutSection()),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvatarSection(String? avatarUrl) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6E473B).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFFE1D4C2),
            backgroundImage: _picked != null
                ? FileImage(File(_picked!.path))
                : (avatarUrl != null ? NetworkImage(avatarUrl) : null)
                      as ImageProvider<Object>?,
            child: avatarUrl == null && _picked == null
                ? Icon(
                    Icons.person_rounded,
                    size: 50,
                    color: const Color(0xFF6E473B),
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6E473B),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.home_rounded,
              label: 'Kos Favorit',
              value: '12',
              color: const Color(0xFF6E473B),
            ),
          ),
          Container(width: 1, height: 40, color: const Color(0xFFE1D4C2)),
          Expanded(
            child: _buildStatItem(
              icon: Icons.receipt_long_rounded,
              label: 'Total Booking',
              value: '8',
              color: const Color(0xFFA78D78),
            ),
          ),
          Container(width: 1, height: 40, color: const Color(0xFFE1D4C2)),
          Expanded(
            child: _buildStatItem(
              icon: Icons.star_rounded,
              label: 'Rating',
              value: '4.8',
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6E473B).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings_rounded,
                  color: const Color(0xFF6E473B),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Admin Panel',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6E473B),
                  ),
                ),
              ],
            ),
          ),
          _buildAdminItem(
            icon: Icons.add_home_rounded,
            title: 'Tambah Kos',
            subtitle: 'Tambah kos baru ke sistem',
            onTap: () {
              Navigator.of(context).pushNamed('/add_kos');
            },
          ),
          _buildDivider(),
          _buildAdminItem(
            icon: Icons.manage_accounts_rounded,
            title: 'Kelola Kos',
            subtitle: 'Edit dan hapus kos yang ada',
            onTap: () {
              Navigator.of(context).pushNamed('/manage_kos');
            },
          ),
          _buildDivider(),
          _buildAdminItem(
            icon: Icons.reviews_rounded,
            title: 'Review & Balasan',
            subtitle: 'Kelola review dari penyewa',
            onTap: () {
              Navigator.of(context).pushNamed('/reviews');
            },
          ),
          _buildDivider(),
          _buildAdminItem(
            icon: Icons.receipt_long_rounded,
            title: 'Laporan Transaksi',
            subtitle: 'Lihat riwayat dan laporan transaksi',
            onTap: () {
              Navigator.of(context).pushNamed('/transaction_history');
            },
          ),
          _buildDivider(),
          _buildAdminItem(
            icon: Icons.analytics_rounded,
            title: 'Analytics',
            subtitle: 'Lihat statistik dan laporan',
            onTap: () {
              _showComingSoonDialog(
                'Analytics',
                'Fitur Analytics akan segera hadir!',
              );
            },
          ),
          _buildDivider(),
          _buildAdminItem(
            icon: Icons.people_rounded,
            title: 'Kelola User',
            subtitle: 'Kelola user dan booking',
            onTap: () {
              _showComingSoonDialog(
                'Kelola User',
                'Fitur Kelola User akan segera hadir!',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6E473B).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF6E473B), size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF291C0E),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFF291C0E).withOpacity(0.6),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: const Color(0xFF291C0E).withOpacity(0.3),
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF291C0E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF291C0E).withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(User user, String? avatarUrl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.person_rounded,
            title: 'Edit Profil',
            subtitle: 'Ubah informasi pribadi',
            onTap: () => _showEditProfileDialog(user, avatarUrl),
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.notifications_rounded,
            title: 'Notifikasi',
            subtitle: 'Kelola notifikasi',
            onTap: () {},
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.security_rounded,
            title: 'Keamanan',
            subtitle: 'Password & keamanan akun',
            onTap: () {},
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.help_rounded,
            title: 'Bantuan',
            subtitle: 'FAQ & dukungan',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6E473B).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF6E473B), size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF291C0E),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFF291C0E).withOpacity(0.6),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: const Color(0xFF291C0E).withOpacity(0.3),
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 1,
      color: const Color(0xFFE1D4C2),
    );
  }

  Widget _buildLogoutSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red.shade700,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.red.shade200),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Text(
              'Keluar',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(User user, String? avatarUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditProfileBottomSheet(
        user: user,
        avatarUrl: avatarUrl,
        nameController: _name,
        phoneController: _phone,
        pickedImage: _picked,
        onImagePicked: (image) => setState(() => _picked = image),
        onSave: (user) => _save(user),
        saving: _saving,
      ),
    );
  }

  void _showComingSoonDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6E473B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.construction_rounded,
                size: 48,
                color: const Color(0xFF6E473B),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF291C0E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF291C0E).withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E473B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Oke',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (img != null) {
      setState(() => _picked = img);
    }
  }

  Future<void> _save(User user) async {
    setState(() => _saving = true);
    try {
      final updated = await _api.updateProfile(
        name: _name.text.trim().isEmpty ? null : _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        avatarPath: _picked?.path,
      );
      setState(() => _future = Future.value(updated));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil tersimpan')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _EditProfileBottomSheet extends StatefulWidget {
  final User user;
  final String? avatarUrl;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final XFile? pickedImage;
  final Function(XFile?) onImagePicked;
  final Function(User) onSave;
  final bool saving;

  const _EditProfileBottomSheet({
    required this.user,
    required this.avatarUrl,
    required this.nameController,
    required this.phoneController,
    required this.pickedImage,
    required this.onImagePicked,
    required this.onSave,
    required this.saving,
  });

  @override
  State<_EditProfileBottomSheet> createState() =>
      _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends State<_EditProfileBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE1D4C2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Edit Profil',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF291C0E),
            ),
          ),
          const SizedBox(height: 20),

          // Avatar
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFE1D4C2),
                  backgroundImage: widget.pickedImage != null
                      ? FileImage(File(widget.pickedImage!.path))
                      : (widget.avatarUrl != null
                                ? NetworkImage(widget.avatarUrl!)
                                : null)
                            as ImageProvider<Object>?,
                  child: widget.avatarUrl == null && widget.pickedImage == null
                      ? Icon(
                          Icons.person_rounded,
                          size: 40,
                          color: const Color(0xFF6E473B),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6E473B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Form Fields
          TextField(
            controller: widget.nameController,
            decoration: InputDecoration(
              labelText: 'Nama Lengkap',
              labelStyle: GoogleFonts.poppins(
                color: const Color(0xFF291C0E).withOpacity(0.6),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFE1D4C2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFE1D4C2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6E473B)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: widget.phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Nomor HP',
              labelStyle: GoogleFonts.poppins(
                color: const Color(0xFF291C0E).withOpacity(0.6),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFE1D4C2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFE1D4C2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6E473B)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.saving
                  ? null
                  : () {
                      widget.onSave(widget.user);
                      Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E473B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: widget.saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Simpan Perubahan',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (img != null) {
      widget.onImagePicked(img);
    }
  }
}
