import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/enrollments_provider.dart';
import 'providers/admin_enrollments_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/manage_courses_provider.dart';

void main() => runApp(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()..restore()),
      ChangeNotifierProvider(create: (_) => CatalogProvider()),
      ChangeNotifierProvider(create: (_) => EnrollmentsProvider()),
      ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ChangeNotifierProvider(create: (_) => AdminEnrollmentsProvider()),
      ChangeNotifierProvider(create: (_) => ManageCoursesProvider()),
    ],
    child: DevicePreview(builder: (context) => const EnrollmentApp()),
  ),
);
