import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/scanner_screen.dart';
import 'services/local_database_service.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Supabase
    debugPrint('Initializing Supabase...');
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    debugPrint('✓ Supabase initialized successfully');

    // Initialize local database
    debugPrint('Initializing local database...');
    final localDb = LocalDatabaseService();
    await localDb.initialize();
    debugPrint('✓ Local database initialized successfully');

    // Initial sync from Supabase
    debugPrint('Starting initial sync from Supabase...');
    try {
      await localDb.syncFromSupabase(force: true);
      final stats = await localDb.getCacheStats();
      debugPrint(
        '✓ Initial sync completed - ${stats['ticketCount']} tickets cached',
      );
    } catch (e) {
      debugPrint('⚠ Initial sync failed (app will work offline): $e');
    }

    runApp(MyApp(localDb: localDb));
  } catch (e, stackTrace) {
    debugPrint('✗ Fatal error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    runApp(const ErrorApp(error: 'Failed to initialize app'));
  }
}

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          color: Colors.red.shade900,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'App Initialization Error',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    error,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final LocalDatabaseService localDb;

  const MyApp({required this.localDb, super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Timer _syncTimer;

  @override
  void initState() {
    super.initState();
    // Set up periodic sync every 30 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _performBackgroundSync();
    });
  }

  @override
  void dispose() {
    _syncTimer.cancel();
    super.dispose();
  }

  Future<void> _performBackgroundSync() async {
    try {
      debugPrint('[Background Sync] Starting...');
      await widget.localDb.syncFromSupabase();
      final stats = await widget.localDb.getCacheStats();
      debugPrint(
        '[Background Sync] ✓ Completed - ${stats['ticketCount']} tickets',
      );
    } catch (e) {
      debugPrint('[Background Sync] ⚠ Failed: $e');
      // Silent fail - app continues to work with existing cache
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CTU Kiosk Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ScannerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Scanner',
          ),
        ],
      ),
    );
  }
}
