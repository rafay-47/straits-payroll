import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../shared/constants/app_colors.dart';
import '../shared/constants/app_strings.dart';
import 'screens/auth/admin_login_screen.dart';
import 'screens/auth/super_admin_login_screen.dart';
import 'screens/dashboard/super_admin_dashboard_screen.dart';
import 'screens/companies/create_company_screen.dart';
import 'screens/companies/company_details_screen.dart';

/// Web application for Admin/Employer role
class WebApp extends StatelessWidget {
  const WebApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = ThemeData.light().textTheme.apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        );

    return MaterialApp(
      title: '${AppStrings.appName} - Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondaryLight,
          surface: AppColors.surfaceLight,
          background: AppColors.backgroundWhite,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.backgroundWhite,
        textTheme: textTheme,
        dividerColor: AppColors.borderLight,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.backgroundGray,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 1,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardBackground,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        dataTableTheme: DataTableThemeData(
          headingRowColor:
              MaterialStateProperty.all(AppColors.backgroundGray),
          dataRowColor: MaterialStateProperty.all(AppColors.surfaceLight),
        ),
      ),
      // Responsive framework for web
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
      // Initial route - Super Admin Login as entry point
      initialRoute: '/super-admin-login',
      // Define all routes
      routes: {
        '/super-admin-login': (context) => const SuperAdminLoginScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/super-admin-dashboard': (context) => const SuperAdminDashboardScreen(),
        '/create-company': (context) => const CreateCompanyScreen(),
      },
      // Handle dynamic routes (like /company/:id)
      onGenerateRoute: (settings) {
        // Handle company details route: /company/:companyId
        if (settings.name?.startsWith('/company/') ?? false) {
          final companyId = settings.name!.substring('/company/'.length);
          return MaterialPageRoute(
            builder: (context) => CompanyDetailsScreen(companyId: companyId),
            settings: settings,
          );
        }
        
        // If no route matches, return null (will show error)
        return null;
      },
    );
  }
}

