import 'package:flutter/material.dart';

import 'core/app_theme.dart';

import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/shared/splash_page.dart';
import 'pages/society/bookings_page.dart';
import 'pages/society/booking_detail_page.dart';
import 'pages/shared/profile_page.dart';
import 'pages/shared/dashboard_page.dart';
import 'pages/owner/add_kos_page.dart';
import 'pages/auth/change_password_page.dart';
import 'pages/auth/forgot_password_page.dart';
import 'pages/owner/manage_kos_page.dart';
import 'pages/owner/edit_kos_page.dart';
import 'pages/owner/reviews_page.dart';
import 'pages/owner/transaction_history_page.dart';
import 'pages/owner/facility_management_page.dart';
import 'pages/owner/analytics_page.dart';
import 'pages/society/booking_success_page.dart';
import 'models/kos.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gajayana Kost',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const DashboardPage(),
        '/register': (_) => const RegisterPage(),
        '/bookings': (_) => const BookingsPage(),
        '/profile': (_) => const ProfilePage(),
        '/dashboard': (_) => const DashboardPage(),
        '/add_kos': (_) => const AddKosPage(),
        '/manage_kos': (_) => const ManageKosPage(),
        // '/edit_kos' removed - handled by onGenerateRoute to accept arguments
        '/forgot-password': (_) => const ForgotPasswordPage(),
        '/change-password': (_) => const ChangePasswordPage(),
        '/reviews': (_) => const ReviewsPage(),
        '/transaction_history': (_) => const TransactionHistoryPage(),
        '/facility_management': (_) => const FacilityManagementPage(),
        '/analytics': (_) => const AnalyticsPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/booking_detail') {
          final id = settings.arguments as int;
          return MaterialPageRoute(
            builder: (_) => BookingDetailPage(bookingId: id),
          );
        }
        if (settings.name == '/change-password') {
          final email = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (_) => ChangePasswordPage(email: email),
          );
        }
        if (settings.name == '/edit_kos') {
          // Accept Map with id/name, int ID, or Kos object
          final args = settings.arguments;
          print('DEBUG main.dart: ========== ROUTE /edit_kos ==========');
          print('DEBUG main.dart: Received arguments: $args');
          print('DEBUG main.dart: Arguments type: ${args.runtimeType}');
          
          if (args == null) {
            print('DEBUG main.dart: ❌ Arguments is null!');
            return MaterialPageRoute(
              builder: (_) => EditKosPage(kos: Kos(id: 0, name: '', address: '')),
            );
          }
          
          // Check if it's a Map (could be Map<String, dynamic> or Map<String, Object>)
          if (args is Map) {
            print('DEBUG main.dart: ✅ Arguments is a Map');
            print('DEBUG main.dart: Map keys: ${args.keys}');
            print('DEBUG main.dart: Map values: ${args.values}');
            
            // Convert to Map<String, dynamic> for easier access
            final map = Map<String, dynamic>.from(args);
            final id = map['id'];
            final name = map['name'];
            
            print('DEBUG main.dart: Extracted id: $id (type: ${id.runtimeType})');
            print('DEBUG main.dart: Extracted name: "$name" (type: ${name.runtimeType})');
            
            // Convert id to int
            int kosId = 0;
            if (id is int) {
              kosId = id;
            } else if (id is num) {
              kosId = id.toInt();
            } else {
              print('DEBUG main.dart: ⚠️ ID is not a number, trying to parse...');
              kosId = int.tryParse(id.toString()) ?? 0;
            }
            
            // Convert name to String
            String kosName = '';
            if (name is String) {
              kosName = name;
            } else {
              kosName = name?.toString() ?? '';
            }
            
            print('DEBUG main.dart: Final kosId: $kosId, kosName: "$kosName"');
            
            return MaterialPageRoute(
              builder: (_) {
                final kos = Kos(id: kosId, name: kosName, address: '');
                print('DEBUG main.dart: ✅ Created Kos object with ID: ${kos.id}, Name: "${kos.name}"');
                return EditKosPage(kos: kos);
              },
            );
          } else if (args is int) {
            // If ID is passed, create a minimal Kos object with the ID
            print('DEBUG main.dart: Arguments is int: $args');
            return MaterialPageRoute(
              builder: (_) {
                final kos = Kos(id: args, name: '', address: '');
                print('DEBUG main.dart: Created Kos object with ID: ${kos.id}');
                return EditKosPage(kos: kos);
              },
            );
          } else if (args is Kos) {
            print('DEBUG main.dart: Arguments is Kos object with ID: ${args.id}');
            return MaterialPageRoute(builder: (_) => EditKosPage(kos: args));
          } else {
            // Fallback: create empty Kos
            print('DEBUG main.dart: ❌ Unknown arguments type: ${args.runtimeType}');
            return MaterialPageRoute(
              builder: (_) => EditKosPage(kos: Kos(id: 0, name: '', address: '')),
            );
          }
        }
        if (settings.name == '/booking_success') {
          final bookingData = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => BookingSuccessPage(bookingData: bookingData),
          );
        }
        return null;
      },
      home: const SplashPage(),
    );
  }
}
