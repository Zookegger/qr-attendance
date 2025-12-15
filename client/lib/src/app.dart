import 'package:flutter/material.dart';
import 'screens/home/home_page.dart';
import 'screens/attendance/scan_page.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
	const App({super.key});

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			title: 'QR Attendance',
			debugShowCheckedModeBanner: false,
			theme: AppTheme.light(),
			initialRoute: '/',
			routes: {
				'/': (_) => const HomePage(),
				'/scan': (_) => const ScanPage(),
			},
		);
	}
}
