import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'screens/main_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stats_screen.dart';
import 'constants/colors.dart';
import 'providers/water_intake_provider.dart';
import 'localization/app_localizations.dart';
import 'services/notification_service.dart';
import 'models/user_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  runApp(
    DevicePreview(
      enabled: true, // Device Preview 활성화
      builder: (context) => ChangeNotifierProvider(
        create: (context) => WaterIntakeProvider(),
        child: const WaterReminderApp(),
      ),
    ),
  );
}

class WaterReminderApp extends StatelessWidget {
  const WaterReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterIntakeProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: AppLocalizations.get('appTitle'),
          debugShowCheckedModeBanner: false,
          useInheritedMediaQuery: true, // Device Preview를 위해 필요
          locale: DevicePreview.locale(context), // Device Preview의 locale 사용
          builder: DevicePreview.appBuilder, // Device Preview wrapper
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ko', 'KR'),
            Locale('en', 'US'),
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: AppColors.background,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.darkPrimary,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: AppColors.darkBackground,
            useMaterial3: true,
          ),
          themeMode: provider.userSettings.isDarkMode 
              ? ThemeMode.dark 
              : ThemeMode.light,
          home: const HomePage(),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initFuture = context.read<WaterIntakeProvider>().initialize();
    // Check persistent notification sync after initialization
    _initFuture.then((_) {
      _checkPersistentNotificationSync();
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<WaterIntakeProvider>().checkAndReloadIfNeeded();
      _checkPersistentNotificationSync();
    }
  }
  
  Future<void> _checkPersistentNotificationSync() async {
    final provider = context.read<WaterIntakeProvider>();
    final notificationService = NotificationService();
    
    // Check if persistent notification is enabled in settings
    if (provider.userSettings.persistentNotificationEnabled) {
      // Check if notification is actually active
      final isActive = await notificationService.isPersistentNotificationActive();
      
      // If notification was dismissed by user, turn off the setting
      if (!isActive) {
        final newSettings = UserSettings(
          dailyGoal: provider.userSettings.dailyGoal,
          reminderInterval: provider.userSettings.reminderInterval,
          reminderStartTime: provider.userSettings.reminderStartTime,
          reminderEndTime: provider.userSettings.reminderEndTime,
          defaultAmount: provider.userSettings.defaultAmount,
          isDarkMode: provider.userSettings.isDarkMode,
          language: provider.userSettings.language,
          notificationsEnabled: provider.userSettings.notificationsEnabled,
          persistentNotificationEnabled: false, // Turn off since notification was dismissed
          customDrinks: provider.userSettings.customDrinks,
          waterReminders: provider.userSettings.waterReminders,
        );
        await provider.updateSettings(newSettings);
      }
    }
  }

  final List<Widget> _screens = [
    const MainScreen(),
    const StatsScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Consumer<WaterIntakeProvider>(
          builder: (context, provider, child) {
            return Scaffold(
              body: _screens[_selectedIndex],
              bottomNavigationBar: BottomNavigationBar(
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: const Icon(Symbols.water_full),
                    label: AppLocalizations.get('home'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.bar_chart),
                    label: AppLocalizations.get('stats'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.settings),
                    label: AppLocalizations.get('settings'),
                  ),
                ],
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
              ),
            );
          },
        );
      },
    );
  }
}