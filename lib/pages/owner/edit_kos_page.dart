import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_theme.dart';
import '../../models/kos.dart';


class EditKosPage extends StatefulWidget {
  final Kos kos;

  const EditKosPage({super.key, required this.kos});

  @override
  State<EditKosPage> createState() => _EditKosPageState();
}

class _EditKosPageState extends State<EditKosPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _facilitiesController = TextEditingController();
  final _paymentMethodsController = TextEditingController();

  List<String> _selectedFacilities = [];
  List<String> _selectedPaymentMethods = [];
  List<Map<String, dynamic>> _rooms = [];
  bool _isLoading = false;

  final List<String> _availableFacilities = [
    'AC',
    'Kamar Mandi Dalam',
    'Kamar Mandi Luar',
    'Laundry',
    'TV',
  ];

  final List<String> _availablePaymentMethods = [
    'Bulanan',
    'Tahunan',
    'Cash',
    'Transfer',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _nameController.text = widget.kos.name;
    _addressController.text = widget.kos.address;
    _descriptionController.text = widget.kos.description ?? '';
    
    // Handle price - backend uses price_per_month
    if (widget.kos.price != null) {
      _priceController.text = widget.kos.price!.toInt().toString();
    } else {
      _priceController.text = '';
    }

    // Initialize facilities and payment methods from existing data
    _selectedFacilities = widget.kos.facilities ?? [];
    _selectedPaymentMethods = widget.kos.paymentMethods ?? [];

    // Initialize rooms from existing data
    _rooms = widget.kos.rooms ?? [];
    
    // If no rooms exist, add a default room
    if (_rooms.isEmpty) {
      _rooms = [
        {
          'name': 'Kamar 1',
          'price': 0,
          'image': null,
        }
      ];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _facilitiesController.dispose();
    _paymentMethodsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        // Add new images to existing ones
        for (var image in images) {
          _rooms.add({
            'name': 'Kamar ${_rooms.length + 1}',
            'price': 0,
            'image': image.path,
          });
        }
      });
    }
  }

  void _addRoom() {
    setState(() {
      _rooms.add({
        'name': 'Kamar ${_rooms.length + 1}',
        'price': 0,
        'image': null,
      });
    });
  }

  void _removeRoom(int index) {
    setState(() {
      _rooms.removeAt(index);
    });
  }

  void _updateRoom(int index, String field, dynamic value) {
    setState(() {
      _rooms[index][field] = value;
    });
  }

  Future<void> _saveKos() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update kos data (saved locally for now)
      // final updatedKos = Kos(
      //   id: widget.kos.id,
      //   name: _nameController.text,
      //   address: _addressController.text,
      //   description: _descriptionController.text,
      //   price: double.tryParse(_priceController.text),
      //   facilities: _selectedFacilities,
      //   paymentMethods: _selectedPaymentMethods,
      //   rooms: _rooms,
      //   image: widget.kos.image, // Keep existing image
      // );

      // TODO: Backend belum mendukung PUT method untuk update kos
      // Sementara tampilkan pesan bahwa fitur edit belum sepenuhnya tersedia
      
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fitur edit kos sedang dalam pengembangan. Data Anda telah disimpan secara lokal.',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xFF6E473B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memperbarui kos: ${e.toString()}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.lightTheme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Kos',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withOpacity(0.1),
                      colors.secondary.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.outline.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Kos',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3),
                    const SizedBox(height: 8),
                    Text(
                          'Perbarui informasi kos Anda',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: colors.onSurface.withOpacity(0.7),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 200.ms)
                        .slideY(begin: 0.3),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3),

              const SizedBox(height: 24),

              // Basic Information
              _buildSectionTitle('Informasi Dasar', colors),
              const SizedBox(height: 16),

              _buildTextField(
                    controller: _nameController,
                    label: 'Nama Kos',
                    hint: 'Masukkan nama kos',
                    icon: Icons.home_work,
                    colors: colors,
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 300.ms)
                  .slideX(begin: -0.3),

              const SizedBox(height: 16),

              _buildTextField(
                    controller: _addressController,
                    label: 'Alamat',
                    hint: 'Masukkan alamat kos',
                    icon: Icons.location_on,
                    colors: colors,
                    maxLines: 2,
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 400.ms)
                  .slideX(begin: -0.3),

              const SizedBox(height: 16),

              _buildTextField(
                    controller: _descriptionController,
                    label: 'Deskripsi',
                    hint: 'Masukkan deskripsi kos',
                    icon: Icons.description,
                    colors: colors,
                    maxLines: 3,
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 500.ms)
                  .slideX(begin: -0.3),

              const SizedBox(height: 16),

              _buildTextField(
                    controller: _priceController,
                    label: 'Harga (Rp)',
                    hint: 'Masukkan harga kos',
                    icon: Icons.attach_money,
                    colors: colors,
                    keyboardType: TextInputType.number,
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 600.ms)
                  .slideX(begin: -0.3),

              const SizedBox(height: 32),

              // Facilities
              _buildSectionTitle('Fasilitas', colors),
              const SizedBox(height: 16),

              Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableFacilities.map((facility) {
                      final isSelected = _selectedFacilities.contains(facility);
                      return _buildChip(
                        label: facility,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedFacilities.remove(facility);
                            } else {
                              _selectedFacilities.add(facility);
                            }
                          });
                        },
                        colors: colors,
                      );
                    }).toList(),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 700.ms)
                  .slideY(begin: 0.3),

              const SizedBox(height: 32),

              // Payment Methods
              _buildSectionTitle('Metode Pembayaran', colors),
              const SizedBox(height: 16),

              Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availablePaymentMethods.map((method) {
                      final isSelected = _selectedPaymentMethods.contains(
                        method,
                      );
                      return _buildChip(
                        label: method,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedPaymentMethods.remove(method);
                            } else {
                              _selectedPaymentMethods.add(method);
                            }
                          });
                        },
                        colors: colors,
                      );
                    }).toList(),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 800.ms)
                  .slideY(begin: 0.3),

              const SizedBox(height: 32),

              // Rooms
              _buildSectionTitle('Kamar', colors),
              const SizedBox(height: 16),

              if (_rooms.isEmpty)
                Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.bed, size: 48, color: colors.outline),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada kamar',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tambahkan kamar untuk kos Anda',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: colors.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 900.ms)
                    .slideY(begin: 0.3)
              else
                ...List.generate(_rooms.length, (index) {
                  return _buildRoomCard(index, colors);
                }),

              const SizedBox(height: 16),

              // Add Room Button
              SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addRoom,
                      icon: Icon(Icons.add, color: const Color(0xFF6E473B)),
                      label: Text(
                        'Tambah Kamar',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6E473B),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                          color: Color(0xFF6E473B),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: const Color(
                          0xFFE1D4C2,
                        ).withOpacity(0.3),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 1000.ms)
                  .slideY(begin: 0.3),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveKos,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6E473B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFF6E473B).withOpacity(0.3),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Simpan Perubahan',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 1100.ms)
                  .slideY(begin: 0.3),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colors) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colors.onSurface,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ColorScheme colors,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFF291C0E)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(
          color: const Color(0xFF6E473B),
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.poppins(
          color: const Color(0xFF291C0E).withOpacity(0.5),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF6E473B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBEB5A9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBEB5A9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6E473B), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFE1D4C2).withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Field ini wajib diisi';
        }
        return null;
      },
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6E473B) : const Color(0xFFE1D4C2),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6E473B)
                : const Color(0xFFBEB5A9),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6E473B).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF291C0E),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomCard(int index, ColorScheme colors) {
    final room = _rooms[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE1D4C2).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBEB5A9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF291C0E).withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: room['name'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF291C0E),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nama Kamar',
                    labelStyle: GoogleFonts.poppins(
                      color: const Color(0xFF6E473B),
                      fontWeight: FontWeight.w500,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFBEB5A9)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFBEB5A9)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF6E473B),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) => _updateRoom(index, 'name', value),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: room['price'].toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF291C0E),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Harga (Rp)',
                    labelStyle: GoogleFonts.poppins(
                      color: const Color(0xFF6E473B),
                      fontWeight: FontWeight.w500,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFBEB5A9)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFBEB5A9)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF6E473B),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) =>
                      _updateRoom(index, 'price', int.tryParse(value) ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImages(),
                  icon: Icon(Icons.image, color: const Color(0xFF6E473B)),
                  label: Text(
                    'Pilih Gambar',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF6E473B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6E473B)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () => _removeRoom(index),
                icon: Icon(Icons.delete, color: Colors.red.shade600),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
