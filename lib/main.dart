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
        '/edit_kos': (_) => EditKosPage(
          kos: Kos(id: 0, name: '', address: ''),
        ),
        '/forgot-password': (_) => const ForgotPasswordPage(),
        '/change-password': (_) => const ChangePasswordPage(),
        '/reviews': (_) => const ReviewsPage(),
        '/transaction_history': (_) => const TransactionHistoryPage(),
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
          final kos = settings.arguments as Kos;
          return MaterialPageRoute(builder: (_) => EditKosPage(kos: kos));
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
