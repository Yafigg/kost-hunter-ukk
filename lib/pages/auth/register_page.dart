import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import 'package:dio/dio.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  String _selectedRole = 'society';
  String? _error;

  final _api = ApiService();

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      setState(() => _error = 'Anda harus menyetujui Terms & Conditions');
      return;
    }

    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _api.register(
        name:
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
        phone: _phoneController.text.trim(),
        role: _selectedRole,
        saveToken: false, // Jangan simpan token, user harus login dulu
      );
      if (!mounted) return;
      
      // Tampilkan dialog sukses
      await _showSuccessDialog();
      
      // Kembali ke halaman login
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      String msg = 'Registrasi gagal. Coba lagi.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          if (data['message'] is String) msg = data['message'];
          // Laravel validation errors
          final errors = data['errors'];
          if (errors is Map && errors.isNotEmpty) {
            final firstKey = errors.keys.first;
            final firstMsg = errors[firstKey];
            if (firstMsg is List && firstMsg.isNotEmpty) {
              msg = firstMsg.first.toString();
            }
          }
        }
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: colors.onBackground),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Register',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.onBackground,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Header Section
              _HeaderSection(),

              const SizedBox(height: 32),

              // Form Section
              _FormSection(
                formKey: _formKey,
                firstNameController: _firstNameController,
                lastNameController: _lastNameController,
                emailController: _emailController,
                phoneController: _phoneController,
                passwordController: _passwordController,
                confirmPasswordController: _confirmPasswordController,
                obscurePassword: _obscurePassword,
                obscureConfirmPassword: _obscureConfirmPassword,
                selectedRole: _selectedRole,
                agreeToTerms: _agreeToTerms,
                onTogglePassword: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onToggleConfirmPassword: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
                onRoleChanged: (role) => setState(() => _selectedRole = role),
                onTermsChanged: (value) =>
                    setState(() => _agreeToTerms = value),
                error: _error,
              ),

              const SizedBox(height: 24),

              // Register Button
              _RegisterButton(
                onPressed: _loading ? null : _handleRegister,
                loading: _loading,
              ),

              const SizedBox(height: 24),

              // Divider
              _DividerSection(),

              const SizedBox(height: 24),

              // Social Register Buttons
              _SocialRegisterSection(),

              const SizedBox(height: 32),

              // Login Link
              _LoginLink(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSuccessDialog() async {
    bool isDialogOpen = true;
    final timerRef = <Timer?>[null];
    
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        // Auto close setelah 3 detik (hanya sekali)
        if (timerRef[0] == null) {
          timerRef[0] = Timer(const Duration(seconds: 3), () {
            if (isDialogOpen && dialogContext.mounted && Navigator.of(dialogContext, rootNavigator: true).canPop()) {
              Navigator.of(dialogContext, rootNavigator: true).pop();
              isDialogOpen = false;
            }
          });
        }

        final colors = Theme.of(context).colorScheme;
        
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
                            'Registrasi Berhasil',
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
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: colors.primary,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Akun Anda berhasil dibuat!',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF291C0E),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Silakan login untuk melanjutkan',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF291C0E).withOpacity(0.6),
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
                            Navigator.of(dialogContext, rootNavigator: true).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: Text(
                            'Oke',
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
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [colors.primary, colors.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(Icons.person_add_rounded, color: Colors.white, size: 40),
        ).animate().scale(
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
        ),

        const SizedBox(height: 24),

        // Title
        Text(
          "Let's get started",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: colors.onBackground,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: const Duration(milliseconds: 600)),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Buat akun baru untuk mulai mencari kost',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: colors.onBackground.withOpacity(0.7),
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: const Duration(milliseconds: 800)),
      ],
    );
  }
}

class _FormSection extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final String selectedRole;
  final bool agreeToTerms;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final Function(String) onRoleChanged;
  final Function(bool) onTermsChanged;
  final String? error;

  const _FormSection({
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.selectedRole,
    required this.agreeToTerms,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onRoleChanged,
    required this.onTermsChanged,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error!,
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().shakeX(duration: const Duration(milliseconds: 500)),
            const SizedBox(height: 16),
          ],

          // Name Fields Row
          Row(
            children: [
              Expanded(
                child:
                    _ModernTextField(
                      controller: firstNameController,
                      label: 'First Name',
                      icon: Icons.person_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'First name wajib diisi';
                        }
                        return null;
                      },
                    ).animate().slideX(
                      begin: -0.3,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                    ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child:
                    _ModernTextField(
                      controller: lastNameController,
                      label: 'Last Name',
                      icon: Icons.person_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Last name wajib diisi';
                        }
                        return null;
                      },
                    ).animate().slideX(
                      begin: 0.3,
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOut,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Email Field
          _ModernTextField(
            controller: emailController,
            label: 'Email',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email wajib diisi';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Format email tidak valid';
              }
              return null;
            },
          ).animate().slideX(
            begin: -0.3,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
          ),

          const SizedBox(height: 16),

          // Phone Field
          _ModernTextField(
            controller: phoneController,
            label: 'Phone Number',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone number wajib diisi';
              }
              return null;
            },
          ).animate().slideX(
            begin: -0.3,
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
          ),

          const SizedBox(height: 16),

          // Role Selection
          _RoleSelectionSection(
            selectedRole: selectedRole,
            onRoleChanged: onRoleChanged,
          ).animate().slideX(
            begin: -0.3,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOut,
          ),

          const SizedBox(height: 16),

          // Password Field
          _ModernTextField(
            controller: passwordController,
            label: 'Password',
            icon: Icons.lock_rounded,
            obscure: true,
            obscureText: obscurePassword,
            onToggleObscure: onTogglePassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password wajib diisi';
              }
              if (value.length < 8) {
                return 'Password minimal 8 karakter';
              }
              return null;
            },
          ).animate().slideX(
            begin: -0.3,
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOut,
          ),

          const SizedBox(height: 16),

          // Confirm Password Field
          _ModernTextField(
            controller: confirmPasswordController,
            label: 'Confirm Password',
            icon: Icons.lock_outline_rounded,
            obscure: true,
            obscureText: obscureConfirmPassword,
            onToggleObscure: onToggleConfirmPassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirm password wajib diisi';
              }
              if (value != passwordController.text) {
                return 'Password tidak cocok';
              }
              return null;
            },
          ).animate().slideX(
            begin: -0.3,
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOut,
          ),

          const SizedBox(height: 16),

          // Terms & Conditions
          _TermsCheckbox(
            agreeToTerms: agreeToTerms,
            onChanged: onTermsChanged,
          ).animate().fadeIn(duration: const Duration(milliseconds: 1300)),
        ],
      ),
    );
  }
}

class _ModernTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final String? Function(String?)? validator;

  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.obscureText = false,
    this.onToggleObscure,
    this.validator,
  });

  @override
  State<_ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<_ModernTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
      },
      child: TextFormField(
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        validator: widget.validator,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colors.onSurface,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(
            widget.icon,
            color: _isFocused
                ? colors.primary
                : colors.onSurface.withOpacity(0.6),
          ),
          suffixIcon: widget.obscure
              ? IconButton(
                  icon: Icon(
                    widget.obscureText
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: colors.onSurface.withOpacity(0.6),
                  ),
                  onPressed: widget.onToggleObscure,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colors.outline.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colors.outline.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          filled: true,
          fillColor: colors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: GoogleFonts.poppins(
            color: _isFocused
                ? colors.primary
                : colors.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _RoleSelectionSection extends StatelessWidget {
  final String selectedRole;
  final Function(String) onRoleChanged;

  const _RoleSelectionSection({
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Role',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment<String>(
              value: 'society',
              label: Text('Penyewa', style: GoogleFonts.poppins(fontSize: 14)),
              icon: const Icon(Icons.person_outline, size: 20),
            ),
            ButtonSegment<String>(
              value: 'owner',
              label: Text('Owner', style: GoogleFonts.poppins(fontSize: 14)),
              icon: const Icon(Icons.store_mall_directory_outlined, size: 20),
            ),
          ],
          selected: {selectedRole},
          onSelectionChanged: (Set<String> newSelection) {
            onRoleChanged(newSelection.first);
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
              if (states.contains(MaterialState.selected)) {
                return colors.primary;
              }
              return colors.surface;
            }),
            foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
              if (states.contains(MaterialState.selected)) {
                return colors.onPrimary;
              }
              return colors.onSurface;
            }),
            side: MaterialStateProperty.all(
              BorderSide(color: colors.outline.withOpacity(0.3)),
            ),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  final bool agreeToTerms;
  final Function(bool) onChanged;

  const _TermsCheckbox({required this.agreeToTerms, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Checkbox(
          value: agreeToTerms,
          onChanged: (value) => onChanged(value ?? false),
          activeColor: colors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: colors.onSurface.withOpacity(0.7),
              ),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms & Conditions',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RegisterButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;

  const _RegisterButton({required this.onPressed, required this.loading});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: colors.primary.withOpacity(0.3),
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.onPrimary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.app_registration_rounded, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Sign Up',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 1400));
  }
}

class _DividerSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Divider(color: colors.outline.withOpacity(0.3), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: colors.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: colors.outline.withOpacity(0.3), thickness: 1),
        ),
      ],
    ).animate().fadeIn(duration: const Duration(milliseconds: 1500));
  }
}

class _SocialRegisterSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Google Register
        _SocialRegisterButton(
          icon: 'G',
          label: 'Google',
          onPressed: () {
            // TODO: Implement Google registration
          },
        ).animate().slideY(
          begin: 0.3,
          duration: const Duration(milliseconds: 1600),
          curve: Curves.easeOut,
        ),

        const SizedBox(height: 12),

        // Facebook Register
        _SocialRegisterButton(
          icon: 'f',
          label: 'Facebook',
          onPressed: () {
            // TODO: Implement Facebook registration
          },
        ).animate().slideY(
          begin: 0.3,
          duration: const Duration(milliseconds: 1700),
          curve: Curves.easeOut,
        ),
      ],
    );
  }
}

class _SocialRegisterButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onPressed;

  const _SocialRegisterButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colors.outline.withOpacity(0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: GoogleFonts.poppins(
                    color: colors.onPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Continue with $label',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: colors.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: colors.onSurface.withOpacity(0.7),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
          child: Text(
            'Sign In',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.primary,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: const Duration(milliseconds: 1800));
  }
}
