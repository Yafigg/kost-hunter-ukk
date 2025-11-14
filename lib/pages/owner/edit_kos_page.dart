import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_theme.dart';
import '../../models/kos.dart';
import '../../services/api_service.dart';


class EditKosPage extends StatefulWidget {
  final Kos kos;

  const EditKosPage({super.key, required this.kos});

  @override
  State<EditKosPage> createState() => _EditKosPageState();
}

class _EditKosPageState extends State<EditKosPage> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();
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
  bool _isLoadingData = true;
  int _currentKosId = 0; // Store the actual kos ID being edited

  List<String> _availableFacilities = [
    'AC',
    'Kamar Mandi Dalam',
    'Kamar Mandi Luar',
    'Laundry',
    'TV',
  ];

  List<String> _availablePaymentMethods = [
    'Bulanan',
    'Tahunan',
    'Cash',
    'Transfer',
  ];

  @override
  void initState() {
    super.initState();
    // Load data after widget tree is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadKosData();
    });
  }

  Future<void> _loadKosData() async {
    setState(() => _isLoadingData = true);
    
    // Debug: Print widget.kos data
    print('DEBUG EditKosPage: ========== LOADING KOS DATA ==========');
    print('DEBUG EditKosPage: widget.kos.id: ${widget.kos.id}');
    print('DEBUG EditKosPage: widget.kos.name: "${widget.kos.name}"');
    print('DEBUG EditKosPage: widget.kos.address: "${widget.kos.address}"');
    
    // Get kos ID - use widget.kos.id directly
    int kosId = widget.kos.id;
    
    // If widget.kos.id is 0 or invalid, try to load from API and find by name or use first
    if (kosId == 0 || kosId < 1) {
      print('DEBUG EditKosPage: widget.kos.id is invalid ($kosId), loading from API...');
      try {
        final kosList = await _api.getMyKos();
        print('DEBUG EditKosPage: Loaded ${kosList.length} kos from API');
        
        if (kosList.isEmpty) {
          print('DEBUG EditKosPage: No kos found in API');
          if (mounted) {
            setState(() => _isLoadingData = false);
            Future.microtask(() {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tidak ada kos ditemukan'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            });
          }
          return;
        }
        
        // Try to find by name if provided (this is the key fix!)
        if (widget.kos.name.isNotEmpty) {
          print('DEBUG EditKosPage: Searching for kos with name: "${widget.kos.name}"');
          print('DEBUG EditKosPage: Available kos: ${kosList.map((k) => '${k.id}:${k.name}').join(', ')}');
          try {
            final foundKos = kosList.firstWhere(
              (k) => k.name == widget.kos.name,
            );
            kosId = foundKos.id;
            print('DEBUG EditKosPage: ✅ Found kos by exact name match: "${foundKos.name}", ID: $kosId');
          } catch (e) {
            // Name not found, try partial match
            print('DEBUG EditKosPage: Exact name not found, trying partial match...');
            try {
              final foundKos = kosList.firstWhere(
                (k) => k.name.toLowerCase().contains(widget.kos.name.toLowerCase()) ||
                       widget.kos.name.toLowerCase().contains(k.name.toLowerCase()),
              );
              kosId = foundKos.id;
              print('DEBUG EditKosPage: ✅ Found kos by partial name match: "${foundKos.name}", ID: $kosId');
            } catch (e2) {
              // Still not found - show error
              print('DEBUG EditKosPage: ❌ Could not find kos with name "${widget.kos.name}"');
              print('DEBUG EditKosPage: Available kos names: ${kosList.map((k) => k.name).toList()}');
              if (mounted) {
                setState(() => _isLoadingData = false);
                Future.microtask(() {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Kos "${widget.kos.name}" tidak ditemukan'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                });
              }
              return;
            }
          }
        } else {
          // No name provided - try to find by ID if available in the list
          print('DEBUG EditKosPage: ⚠️ No name provided, but we have ID: ${widget.kos.id}');
          if (widget.kos.id > 0) {
            try {
              final foundKos = kosList.firstWhere(
                (k) => k.id == widget.kos.id,
              );
              kosId = foundKos.id;
              print('DEBUG EditKosPage: ✅ Found kos by ID: $kosId');
            } catch (e) {
              print('DEBUG EditKosPage: ❌ Could not find kos with ID ${widget.kos.id}');
              print('DEBUG EditKosPage: Available kos IDs: ${kosList.map((k) => k.id).toList()}');
              if (mounted) {
                setState(() => _isLoadingData = false);
                Future.microtask(() {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Kos dengan ID ${widget.kos.id} tidak ditemukan'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                });
              }
              return;
            }
          } else {
            // No name and no valid ID - show error
            print('DEBUG EditKosPage: ❌ No name and no valid ID provided!');
            print('DEBUG EditKosPage: Available kos: ${kosList.map((k) => '${k.id}:${k.name}').join(', ')}');
            if (mounted) {
              setState(() => _isLoadingData = false);
              Future.microtask(() {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Data kos tidak valid. Silakan coba lagi.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
            }
            return;
          }
        }
      } catch (e) {
        print('DEBUG EditKosPage: Error loading kos list: $e');
        if (mounted) {
          setState(() => _isLoadingData = false);
          Future.microtask(() {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal memuat data kos: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
        }
        return;
      }
    } else {
      // ID is valid, use it directly
      print('DEBUG EditKosPage: ✅ ID is valid, using directly: $kosId');
      _currentKosId = kosId;
      print('DEBUG EditKosPage: ✅ Stored kos ID for editing: $_currentKosId');
    }
    
    // Only proceed to load data if we have a valid ID
    if (_currentKosId == 0 || _currentKosId < 1) {
      print('DEBUG EditKosPage: ❌ No valid kos ID found, cannot load data');
      if (mounted) {
        setState(() => _isLoadingData = false);
        Future.microtask(() {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ID kos tidak valid. Silakan coba lagi.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
      return;
    }
    
    // Store the kos ID for later use in save (if not already stored)
    if (_currentKosId == 0) {
      _currentKosId = kosId;
    }
    print('DEBUG EditKosPage: ✅ Final kos ID for editing: $_currentKosId');
      
      // Load full kos data from API
      try {
        print('DEBUG EditKosPage: Loading kos detail for ID: $kosId');
        final kosData = await _api.getOwnerKosDetail(kosId);
      
      print('DEBUG EditKosPage: Loaded kos data - Name: ${kosData['name']}, Price: ${kosData['price_per_month']}');
      
      // Parse facilities
      List<String> facilities = [];
      if (kosData['facilities'] != null) {
        final facilitiesList = kosData['facilities'] as List?;
        if (facilitiesList != null) {
          facilities = facilitiesList.map((f) {
            if (f is Map) {
              final facilityName = (f['facility'] ?? '').toString();
              // Map backend facility names to frontend display names
              if (facilityName.contains('Kamar Mandi Dalam')) return 'Kamar Mandi Dalam';
              if (facilityName.contains('Kamar Mandi Luar')) return 'Kamar Mandi Luar';
              if (facilityName.contains('AC') || facilityName == 'AC') return 'AC';
              if (facilityName.contains('Laundry') || facilityName == 'Laundry') return 'Laundry';
              if (facilityName.contains('TV') || facilityName == 'TV') return 'TV';
              return facilityName;
            }
            return f.toString();
          }).where((f) => f.isNotEmpty).toList();
        }
      }
      print('DEBUG EditKosPage: Parsed ${facilities.length} facilities: $facilities');
      
      // Parse payment methods
      List<String> paymentMethods = [];
      if (kosData['payment_methods'] != null) {
        final paymentList = kosData['payment_methods'] as List?;
        if (paymentList != null) {
          paymentMethods = paymentList.map((p) {
            if (p is Map) {
              // Backend stores payment method name in 'bank_name' field
              // and type in 'type' field (Cash, Transfer, QRIS)
              final bankName = (p['bank_name'] ?? '').toString();
              final type = (p['type'] ?? '').toString();
              
              // Prioritize bank_name as it contains the actual payment method name
              // (e.g., "Cash", "Transfer", "OVO", "QRIS", "Bulanan", "Tahunan")
              if (bankName.isNotEmpty) {
                // Map common backend values to frontend display names
                final name = bankName.trim();
                if (name.toLowerCase() == 'monthly' || name.toLowerCase() == 'bulanan') return 'Bulanan';
                if (name.toLowerCase() == 'yearly' || name.toLowerCase() == 'tahunan') return 'Tahunan';
                if (name.toLowerCase() == 'cash') return 'Cash';
                if (name.toLowerCase() == 'transfer' || name.toLowerCase() == 'transfer bank') return 'Transfer';
                // Return as is for custom payment methods (OVO, QRIS, GoPay, etc.)
                return name;
              }
              
              // Fallback to type if bank_name is empty
              if (type.isNotEmpty) {
                if (type.toLowerCase() == 'monthly') return 'Bulanan';
                if (type.toLowerCase() == 'yearly') return 'Tahunan';
                if (type.toLowerCase() == 'cash') return 'Cash';
                if (type.toLowerCase() == 'transfer') return 'Transfer';
                if (type.toLowerCase() == 'qris') return 'QRIS';
                return type;
              }
              
              return '';
            }
            return p.toString();
          }).where((p) => p.isNotEmpty).toList();
        }
      }
      print('DEBUG EditKosPage: Parsed ${paymentMethods.length} payment methods: $paymentMethods');
      
      // Parse rooms
      List<Map<String, dynamic>> rooms = [];
      if (kosData['rooms'] != null) {
        final roomsList = kosData['rooms'] as List?;
        if (roomsList != null) {
          rooms = roomsList.map((r) {
            if (r is Map) {
              return {
                'name': (r['room_number'] ?? '').toString(),
                'price': (r['price'] as num?)?.toInt() ?? 0,
                'room_type': (r['room_type'] ?? 'single').toString(),
                'image': null,
              };
            }
            return {'name': 'Kamar', 'price': 0, 'image': null};
          }).toList();
        }
      }
      print('DEBUG EditKosPage: Parsed ${rooms.length} rooms');
      
      // Initialize form with loaded data
      if (mounted) {
        setState(() {
          // Basic information
          _nameController.text = (kosData['name'] ?? '').toString();
          _addressController.text = (kosData['address'] ?? '').toString();
          _descriptionController.text = (kosData['description'] ?? '').toString();
          
          // Price
          final price = kosData['price_per_month'] as num?;
          if (price != null && price > 0) {
            _priceController.text = price.toInt().toString();
    } else {
      _priceController.text = '';
    }

          // Facilities
          _selectedFacilities = facilities;
          
          // Payment methods
          _selectedPaymentMethods = paymentMethods;

          // Rooms
          if (rooms.isNotEmpty) {
            _rooms = rooms;
          } else {
      _rooms = [
        {
          'name': 'Kamar 1',
          'price': 0,
          'image': null,
        }
      ];
          }
          
          _isLoadingData = false;
        });
      }
      
      print('DEBUG EditKosPage: Form initialized with data from API');
    } catch (e) {
      print('DEBUG EditKosPage: Error loading kos detail: $e');
      
      // Fallback to widget.kos data if API fails
      if (mounted) {
        setState(() {
          _nameController.text = widget.kos.name.isNotEmpty ? widget.kos.name : '';
          _addressController.text = widget.kos.address.isNotEmpty ? widget.kos.address : '';
          _descriptionController.text = widget.kos.description?.isNotEmpty == true ? widget.kos.description! : '';
          
          if (widget.kos.price != null && widget.kos.price! > 0) {
            _priceController.text = widget.kos.price!.toInt().toString();
          } else {
            _priceController.text = '';
          }
          
          _selectedFacilities = List<String>.from(widget.kos.facilities ?? []);
          _selectedPaymentMethods = List<String>.from(widget.kos.paymentMethods ?? []);
          
          if (widget.kos.rooms != null && widget.kos.rooms!.isNotEmpty) {
            _rooms = widget.kos.rooms!.map((room) {
              final roomMap = Map<String, dynamic>.from(room);
              if (!roomMap.containsKey('name') || roomMap['name'] == null || roomMap['name'].toString().isEmpty) {
                roomMap['name'] = 'Kamar 1';
              }
              if (!roomMap.containsKey('price') || roomMap['price'] == null) {
                roomMap['price'] = 0;
              }
              if (!roomMap.containsKey('image')) {
                roomMap['image'] = null;
              }
              return roomMap;
            }).toList();
          } else {
            _rooms = [
              {
                'name': 'Kamar 1',
                'price': 0,
                'image': null,
              }
            ];
          }
          
          _isLoadingData = false;
        });
      }
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

  void _showAddFacilityDialog() {
    final TextEditingController facilityController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) {
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
                        ],
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
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Tambah Fasilitas',
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
                      TextField(
                        controller: facilityController,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Nama Fasilitas',
                          hintText: 'Contoh: WiFi, Parkir, Dapur',
                          prefixIcon: const Icon(Icons.home_work_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF6E473B),
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFBEB5A9),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF6E473B),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: GoogleFonts.poppins(),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF6E473B),
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Batal',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6E473B),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final facilityName = facilityController.text.trim();
                                if (facilityName.isNotEmpty) {
    setState(() {
                                    if (!_availableFacilities.contains(facilityName)) {
                                      _availableFacilities.add(facilityName);
                                    }
                                    if (!_selectedFacilities.contains(facilityName)) {
                                      _selectedFacilities.add(facilityName);
                                    }
                                  });
                                  Navigator.of(dialogContext).pop();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6E473B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                'Tambah',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
          ),
        );
      },
    );
  }

  void _showAddPaymentMethodDialog() {
    final TextEditingController methodController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) {
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
                        ],
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
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Tambah Metode Pembayaran',
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
                      TextField(
                        controller: methodController,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Nama Metode Pembayaran',
                          hintText: 'Contoh: QRIS, OVO, GoPay',
                          prefixIcon: const Icon(Icons.payment_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF6E473B),
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFBEB5A9),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF6E473B),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: GoogleFonts.poppins(),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF6E473B),
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Batal',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6E473B),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final methodName = methodController.text.trim();
                                if (methodName.isNotEmpty) {
                                  setState(() {
                                    if (!_availablePaymentMethods.contains(methodName)) {
                                      _availablePaymentMethods.add(methodName);
                                      print('DEBUG EditKosPage: Added custom payment method to available list: $methodName');
                                    }
                                    if (!_selectedPaymentMethods.contains(methodName)) {
                                      _selectedPaymentMethods.add(methodName);
                                      print('DEBUG EditKosPage: Added custom payment method to selected list: $methodName');
                                    }
                                    print('DEBUG EditKosPage: Current selected payment methods: $_selectedPaymentMethods');
                                  });
                                  Navigator.of(dialogContext).pop();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6E473B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                'Tambah',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
          ),
        );
      },
    );
  }

  void _showUpdateSuccessDialog() {
    bool isDialogOpen = true;
    Timer? autoCloseTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // Set auto-close timer
        if (autoCloseTimer == null) {
          autoCloseTimer = Timer(const Duration(seconds: 3), () {
            if (isDialogOpen && dialogContext.mounted && Navigator.of(dialogContext, rootNavigator: true).canPop()) {
              Navigator.of(dialogContext, rootNavigator: true).pop();
              isDialogOpen = false;
              // Return to previous page after dialog closes
              Navigator.of(context).pop(true);
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
                // Header dengan gradient coklat
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
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Update Berhasil',
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
                          color: const Color(0xFF6E473B).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF6E473B),
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Kos berhasil diperbarui!',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF291C0E),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Perubahan yang Anda buat telah disimpan.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF291C0E).withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            autoCloseTimer?.cancel();
                            isDialogOpen = false;
                            Navigator.of(dialogContext, rootNavigator: true).pop();
                            // Return to previous page after dialog closes
                            Navigator.of(context).pop(true);
                          },
                          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6E473B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
            ),
                            elevation: 2,
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
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveKos() async {
    if (!_formKey.currentState!.validate()) return;

    // Use stored kos ID, fallback to widget.kos.id if not set
    final kosIdToUpdate = _currentKosId > 0 ? _currentKosId : widget.kos.id;
    
    if (kosIdToUpdate == 0 || kosIdToUpdate < 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ID kos tidak valid. Silakan tutup dan buka kembali halaman edit.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final price = double.tryParse(_priceController.text) ?? 0.0;
      
      print('DEBUG EditKosPage: Saving kos with ID: $kosIdToUpdate');
      print('DEBUG EditKosPage: Name: ${_nameController.text.trim()}');
      print('DEBUG EditKosPage: Price: $price');
      print('DEBUG EditKosPage: Selected facilities: $_selectedFacilities');
      print('DEBUG EditKosPage: Selected payment methods: $_selectedPaymentMethods');
      
      // Update kos information including facilities and payment methods
      await _api.updateKos(
        id: kosIdToUpdate,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim(),
        pricePerMonth: price,
        gender: widget.kos.gender ?? 'all',
        facilities: _selectedFacilities,
        paymentMethods: _selectedPaymentMethods,
      );

      if (mounted) {
        // Show success dialog
        _showUpdateSuccessDialog();
      }
    } catch (e) {
      print('Error saving kos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memperbarui kos: ${e.toString()}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
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
      backgroundColor: const Color(0xFFF5F1EB),
      body: Column(
            children: [
          // Header dengan gradient brown
          ClipRRect(
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
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
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
                      'Edit Kos',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                      ),
                            ),
                            const SizedBox(height: 4),
                    Text(
                          'Perbarui informasi kos Anda',
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
                ),
              ),
            ),
          ),
          // Form Content
          Expanded(
            child: _isLoadingData
                ? Center(
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
                          'Memuat data kos...',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF291C0E).withOpacity(0.7),
                            fontSize: 16,
                          ),
                          ),
                  ],
                ),
                  )
                : Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
              // Basic Information
              _buildSectionTitle('Informasi Dasar', colors),
              const SizedBox(height: 16),

              _buildTextField(
                    controller: _nameController,
                    label: 'Nama Kos',
                    hint: 'Masukkan nama kos',
                      icon: Icons.home_work_rounded,
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
                      icon: Icons.location_on_rounded,
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
                      icon: Icons.description_rounded,
                    colors: colors,
                    maxLines: 3,
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 500.ms)
                  .slideX(begin: -0.3),

              const SizedBox(height: 16),

              _buildTextField(
                    controller: _priceController,
                      label: 'Harga per Kamar (Rp)',
                      hint: 'Masukkan harga per kamar',
                      icon: Icons.attach_money_rounded,
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
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ..._availableFacilities.map((facility) {
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
                        }),
                        // Add button for custom facility
                        _buildAddChip(
                          label: 'Tambah',
                          icon: Icons.add_rounded,
                          onTap: () => _showAddFacilityDialog(),
                          colors: colors,
                        ),
                      ],
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 700.ms)
                  .slideY(begin: 0.3),

              const SizedBox(height: 32),

              // Payment Methods
              _buildSectionTitle('Metode Pembayaran', colors),
              const SizedBox(height: 16),

              Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ..._availablePaymentMethods.map((method) {
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
                        }),
                        // Add button for custom payment method
                        _buildAddChip(
                          label: 'Tambah',
                          icon: Icons.add_rounded,
                          onTap: () => _showAddPaymentMethodDialog(),
                          colors: colors,
                        ),
                      ],
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFBEB5A9).withOpacity(0.3),
                            width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                            Icon(
                              Icons.bed_rounded,
                              size: 48,
                              color: const Color(0xFF6E473B).withOpacity(0.5),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada kamar',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF291C0E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tambahkan kamar untuk kos Anda',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                                color: const Color(0xFF291C0E).withOpacity(0.6),
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
                        icon: const Icon(
                          Icons.add_rounded,
                          color: Color(0xFF6E473B),
                          size: 22,
                        ),
                      label: Text(
                        'Tambah Kamar',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6E473B),
                            fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                          color: Color(0xFF6E473B),
                            width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                        ),
                          backgroundColor: Colors.white,
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
                            ? const SizedBox(
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
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colors) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF291C0E),
        letterSpacing: 0.3,
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
        prefixIcon: Icon(icon, color: const Color(0xFF6E473B), size: 22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFBEB5A9), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFBEB5A9), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6E473B), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
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

  Widget _buildAddChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required ColorScheme colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFF6E473B),
            width: 2,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6E473B).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: const Color(0xFF6E473B),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6E473B),
              ),
            ),
          ],
        ),
      ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFBEB5A9).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF291C0E).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                    labelText: 'Harga per Kamar (Rp)',
                    hintText: 'Masukkan harga per kamar',
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
                  icon: const Icon(
                    Icons.image_rounded,
                    color: Color(0xFF6E473B),
                    size: 20,
                  ),
                  label: Text(
                    'Pilih Gambar',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF6E473B),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFF6E473B),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _removeRoom(index),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 22,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
