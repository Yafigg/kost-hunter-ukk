import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../society/bookings_page.dart';
import 'home_page.dart';
import 'profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _index = 0;
  final GlobalKey _bookingsKey = GlobalKey();

  late final List<Widget> _pages;

  final _storageBucket = PageStorageBucket();

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(key: PageStorageKey('home')),
      BookingsPage(key: _bookingsKey),
      const ProfilePage(key: PageStorageKey('profile')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageStorage(
        bucket: _storageBucket,
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: _ModernBottomNav(
        index: _index,
        onTap: (i) {
          setState(() => _index = i);
          // Refresh bookings when tab is selected
          if (i == 1) {
            final state = _bookingsKey.currentState;
            // Use dynamic to call refresh method
            if (state != null) {
              try {
                (state as dynamic).refresh();
              } catch (e) {
                // Method doesn't exist, ignore
              }
            }
          }
        },
      ),
    );
  }
}

class _ModernBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _ModernBottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.grey.withOpacity(0.25),
            width: 1.5,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, -8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, -4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ModernNavItem(
                  selected: index == 0,
                  label: 'Home',
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  onTap: () => onTap(0),
                ),
                _ModernNavItem(
                  selected: index == 1,
                  label: 'Bookings',
                  icon: Icons.receipt_long_outlined,
                  selectedIcon: Icons.receipt_long_rounded,
                  onTap: () => onTap(1),
                ),
                _ModernNavItem(
                  selected: index == 2,
                  label: 'Profile',
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  onTap: () => onTap(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernNavItem extends StatefulWidget {
  final bool selected;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final VoidCallback onTap;

  const _ModernNavItem({
    required this.selected,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
  });

  @override
  State<_ModernNavItem> createState() => _ModernNavItemState();
}

class _ModernNavItemState extends State<_ModernNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.selected) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(_ModernNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      if (widget.selected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) {
            _animationController.forward();
          },
          onTapUp: (_) {
            _animationController.reverse();
          },
          onTapCancel: () {
            _animationController.reverse();
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0xFF6E473B).withOpacity(0.08),
          highlightColor: const Color(0xFF6E473B).withOpacity(0.04),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon Container
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        padding: EdgeInsets.all(widget.selected ? 8 : 0),
                        decoration: BoxDecoration(
                          color: widget.selected
                              ? const Color(0xFF6E473B)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: widget.selected
                              ? Border.all(
                                  color: const Color(0xFF6E473B).withOpacity(0.2),
                                  width: 0.5,
                                )
                              : null,
                          boxShadow: widget.selected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF6E473B).withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                    spreadRadius: 0,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF6E473B).withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                    spreadRadius: 0,
                                  ),
                                ]
                              : [],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Icon(
                            widget.selected
                                ? widget.selectedIcon
                                : widget.icon,
                            key: ValueKey(
                                '${widget.selected}_${widget.label}'),
                            color: widget.selected
                                ? Colors.white
                                : const Color(0xFF6E473B).withOpacity(0.6),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Label
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        style: GoogleFonts.inter(
                          fontSize: widget.selected ? 11 : 10,
                          fontWeight: widget.selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          letterSpacing: 0.05,
                          color: widget.selected
                              ? const Color(0xFF6E473B)
                              : const Color(0xFF6E473B).withOpacity(0.5),
                        ),
                        child: Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
