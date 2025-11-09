import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:taro_mobile/features/reminder/reminder_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taro_mobile/features/home/controller/lead_controller.dart';
import 'package:taro_mobile/features/home/view/property_details_screen.dart';
import 'package:taro_mobile/features/lead/add_lead_controller.dart';
import 'package:taro_mobile/features/auth/controller/auth_provider.dart';
import 'package:taro_mobile/features/properties/controller/property_provider.dart';
import 'package:taro_mobile/features/lead/controller/lead_api_provider.dart';
import 'package:taro_mobile/features/lead/add_lead_screen.dart';
import 'package:taro_mobile/features/reminder/notifications/notification_manager.dart';
import 'package:taro_mobile/features/home/view/lead_details_screen.dart';
import 'package:taro_mobile/features/lead/add_lead_model.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize NotificationService but DON'T set navigation callbacks yet
  await NotificationService().initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Global navigator key for navigation from notifications
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // MethodChannel for communication with Android
  static const platform = MethodChannel('com.taro.mobileapp/call_detection');

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NewLeadProvider()),
        ChangeNotifierProvider(create: (_) => LeadProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProvider(create: (_) => LeadApiProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'Taro Mobile',
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            theme: ThemeData(
              primarySwatch: Colors.green,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme),
            ),
            home: AppInitializer(),
          );
        },
      ),
    );
  }
}

// Setup notification callbacks when app starts
class AppInitializer extends StatefulWidget {
  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer>
    with WidgetsBindingObserver {
  bool _isInitialized = false;
  String? _pendingReminderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // CRITICAL: Setup notification callbacks immediately in initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotificationCallbacks();
      _initializeApp();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && _isInitialized) {
      print('📱 App resumed - processing pending navigation');

      // Add a small delay to ensure the app is fully resumed
      Future.delayed(Duration(milliseconds: 300), () {
        NotificationService.processPendingNavigation();

        // Process any locally pending navigation
        if (_pendingReminderId != null) {
          print('🔄 Processing locally pending reminder: $_pendingReminderId');
          _navigateToEditReminder(_pendingReminderId!);

          _pendingReminderId = null;
        }
      });
    }
  }

  // CRITICAL: Setup notification callbacks FIRST and EARLY
  void _setupNotificationCallbacks() {
    print('🔧 Setting up notification callbacks...');

    // Set up notification callbacks IMMEDIATELY
    NotificationService.setNavigationCallback(
      navigatorKey: MyApp.navigatorKey,
      onEditReminder: _navigateToEditReminder,
    );

    print('✅ Notification callbacks configured successfully');
  }

  Future<void> _initializeApp() async {
    print('🚀 Initializing app...');

    try {
      // Check if app was launched from notification
      await _checkNotificationLaunch();

      setState(() {
        _isInitialized = true;
      });

      print('✅ App initialization completed');
    } catch (e) {
      print('❌ Error during app initialization: $e');
      setState(() {
        _isInitialized = true; // Still allow app to load
      });
    }
  }

  Future<void> _checkNotificationLaunch() async {
    print('🔍 Checking if app was launched from notification...');

    try {
      // Add delay to ensure notification service is fully ready
      await Future.delayed(Duration(milliseconds: 200));

      // Check if app was launched from notification tap
      final NotificationAppLaunchDetails? notificationAppLaunchDetails =
          await NotificationService().getNotificationAppLaunchDetails();

      if (notificationAppLaunchDetails?.didNotificationLaunchApp == true) {
        print('🎯 App was launched from notification!');

        final String? payload =
            notificationAppLaunchDetails!.notificationResponse?.payload;

        if (payload != null) {
          print('📦 Processing launch payload: $payload');

          try {
            final Map<String, dynamic> data = json.decode(payload);
            final String reminderId = data['reminderId'] ?? '';

            if (reminderId.isNotEmpty) {
              print('🔗 Found reminder ID in launch payload: $reminderId');

              // Store for processing after app is fully ready
              _pendingReminderId = reminderId;

              // Process after a longer delay to ensure everything is ready
              Future.delayed(Duration(milliseconds: 2000), () {
                if (_pendingReminderId != null) {
                  print('🚀 Processing launch notification after delay');
                  _navigateToEditReminder(_pendingReminderId!);
                  _pendingReminderId = null;
                }
              });
            }
          } catch (e) {
            print('❌ Error parsing launch payload: $e');
          }
        }
      } else {
        print('ℹ️ App was not launched from notification');
      }
    } catch (e) {
      print('❌ Error checking notification launch: $e');
    }
  }

  void _navigateToEditReminder(String reminderId) async {
    print('🎯 _navigateToEditReminderAlternative called with ID: $reminderId');

    // Ensure the widget tree is built and ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 100));

      final BuildContext? context = MyApp.navigatorKey.currentContext;

      if (context != null && context.mounted) {
        try {
          // Add haptic feedback for Android
          if (Platform.isAndroid) {
            HapticFeedback.lightImpact();
          }

          print('📡 Fetching reminder data from Firestore for ID: $reminderId');

          // Fetch reminder data from Firestore
          DocumentSnapshot reminderDoc =
              await FirebaseFirestore.instance
                  .collection('reminders')
                  .doc(reminderId)
                  .get();

          if (reminderDoc.exists) {
            Map<String, dynamic> reminderData =
                reminderDoc.data() as Map<String, dynamic>;
            print('✅ Reminder data fetched successfully');

            // Use pushReplacement to replace current route
            await Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder:
                    (context) => ReminderDetailsScreen(
                      reminderId: reminderId,
                      reminderData: reminderData,
                    ),
              ),
            );

            print('📱 Navigation to ReminderDetailsScreen completed');
          } else {
            print('❌ Reminder not found in Firestore');
          }
        } catch (e) {
          print('❌ Error in alternative navigation: $e');
        }
      } else {
        print('❌ Context not available in addPostFrameCallback');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      // Show loading screen while initializing
      return Scaffold(
        backgroundColor: Colors.green.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Initializing Taro Mobile...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Setting up notifications and navigation',
                style: TextStyle(fontSize: 12, color: Colors.green.shade600),
              ),
            ],
          ),
        ),
      );
    }

    // Show shortcuts setup screen first for iOS, then permission screen
    return NavigationHandler(
      child: Platform.isIOS ? IOSShortcutsSetupScreen() : PermissionScreen(),
    );
  }
}

// iOS Shortcuts Setup Screen
class IOSShortcutsSetupScreen extends StatefulWidget {
  @override
  _IOSShortcutsSetupScreenState createState() =>
      _IOSShortcutsSetupScreenState();
}

class _IOSShortcutsSetupScreenState extends State<IOSShortcutsSetupScreen> {
  bool _isShortcutSetup = false;
  bool _isLoading = false;
  bool _isCheckingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkShortcutSetupStatus();
  }

  Future<void> _checkShortcutSetupStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isShortcutSetup =
          prefs.getBool('ios_shortcut_setup_completed') ?? false;

      if (mounted) {
        setState(() {
          _isShortcutSetup = isShortcutSetup;
          _isCheckingStatus = false;
        });
      }

      // If shortcut is already setup, skip directly to permission screen
      if (isShortcutSetup) {
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => PermissionScreen()),
            );
          }
        });
      }
    } catch (e) {
      print('Error checking shortcut setup status: $e');
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
        });
      }
    }
  }

  Future<void> _openShortcutsApp() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      const shortcutUrl =
          'https://www.icloud.com/shortcuts/9e2aa694e342491785f45270b8855a83';

      if (await canLaunchUrl(Uri.parse(shortcutUrl))) {
        await launchUrl(
          Uri.parse(shortcutUrl),
          mode: LaunchMode.externalApplication,
        );

        // Show instructions after opening
        _showReturnInstructions();
      } else {
        _showErrorDialog(
          'Unable to open Shortcuts app. Please check if Shortcuts app is installed.',
        );
      }
    } catch (e) {
      print('Error opening shortcuts URL: $e');
      _showErrorDialog('Error opening Shortcuts app: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showReturnInstructions() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(child: Text('Setup Instructions')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please follow these steps:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              _buildInstructionStep(
                '1',
                'Tap "Get Shortcut" in the Shortcuts app',
              ),
              _buildInstructionStep('2', 'Add the shortcut to your library'),
              _buildInstructionStep('3', 'Return to Taro Mobile app'),
              _buildInstructionStep(
                '4',
                'Tap "I\'ve Set Up the Shortcut" below',
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This shortcut enables call detection features for iOS.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _markShortcutComplete();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('I\'ve Set Up the Shortcut'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstructionStep(String number, String instruction) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(child: Text(instruction, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openShortcutsApp();
              },
              child: Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markShortcutComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ios_shortcut_setup_completed', true);

      if (mounted) {
        setState(() {
          _isShortcutSetup = true;
        });

        // Show success message briefly
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Shortcut setup completed!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to permission screen after a delay
        Future.delayed(Duration(milliseconds: 1000), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => PermissionScreen()),
            );
          }
        });
      }
    } catch (e) {
      print('Error saving shortcut setup status: $e');
      // Still navigate even if saving fails
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => PermissionScreen()),
        );
      }
    }
  }

  void _skipSetup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Skip Shortcut Setup?'),
          content: Text(
            'Skipping the shortcut setup will disable call detection features on iOS. You can set this up later in the app settings.\n\nAre you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToPermissionScreen();
              },
              child: Text('Skip', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _navigateToPermissionScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => PermissionScreen()),
    );
  }

  // Method to reset shortcut setup (for testing or settings)
  static Future<void> resetShortcutSetup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ios_shortcut_setup_completed');
      print('Shortcut setup status reset');
    } catch (e) {
      print('Error resetting shortcut setup: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingStatus) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking setup status...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade400, Colors.blue.shade700],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.shortcut,
                    size: 60,
                    color: Colors.blue.shade700,
                  ),
                ),
                SizedBox(height: 40),
                Text(
                  'iOS Shortcuts Setup',
                  style: GoogleFonts.lato(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Enable call detection features',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),

                // Content
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.phone_iphone,
                                size: 48,
                                color: Colors.white,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'iOS Call Detection',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'To enable call detection features on iOS, you need to install a shortcut that will help the app detect incoming calls.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 20),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'This is required due to iOS privacy restrictions',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _openShortcutsApp,
                        icon:
                            _isLoading
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : Icon(Icons.launch, size: 20),
                        label: Text(
                          _isLoading
                              ? 'Opening Shortcuts...'
                              : 'Set Up iOS Shortcut',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue.shade700,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _skipSetup,
                        child: Text(
                          'Skip for Now',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    if (_isShortcutSetup)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Shortcut setup completed! Proceeding to app...',
                                style: TextStyle(color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationHandler extends StatefulWidget {
  final Widget child;

  const NavigationHandler({Key? key, required this.child}) : super(key: key);

  @override
  _NavigationHandlerState createState() => _NavigationHandlerState();
}

class _NavigationHandlerState extends State<NavigationHandler> {
  static const platform = MethodChannel('com.taro.mobileapp/call_detection');
  StreamSubscription<String>? _urlSubscription; // ADD THIS LINE

  @override
  void initState() {
    super.initState();
    _setupMethodChannelHandler();
    _setupUrlSchemeListener(); // ADD THIS LINE
  }

  @override
  void dispose() {
    _urlSubscription?.cancel(); // ADD THIS LINE
    super.dispose();
  }

  // ADD THIS METHOD - URL Scheme Listener Setup
  void _setupUrlSchemeListener() {
    _urlSubscription = URLSchemeHandler.urlStream.listen((String url) {
      print('📱 Processing URL: $url');
      _handleUrlScheme(url);
    });
  }

  // ADD THIS METHOD - URL Scheme Handler
  void _handleUrlScheme(String url) {
    final Uri uri = Uri.parse(url);
    print('📱 URL scheme: ${uri.scheme}, host: ${uri.host}');

    if (uri.scheme == 'taromobile') {
      switch (uri.host) {
        case 'propertyDetails':
          _handlePropertyDetailsUrl(uri);
          break;
        case 'addLead':
          _handleAddLeadUrl(uri);
          break;
        case 'leadDetails':
          _handleLeadDetailsUrl(uri);
          break;
        default:
          print('Unknown URL host: ${uri.host}');
      }
    }
  }

  // ADD THIS METHOD - Property Details URL Handler
  void _handlePropertyDetailsUrl(Uri uri) {
    final String? leadId = uri.queryParameters['leadId'];
    final String? phoneNumber = uri.queryParameters['phoneNumber'];
    final String? leadName = uri.queryParameters['leadName'];
    final String? propertyCount = uri.queryParameters['propertyCount'];
    final String? source = uri.queryParameters['source'];

    print(
      '📱 Property Details URL - leadId: $leadId, phone: $phoneNumber, name: $leadName',
    );

    if (leadId != null && leadId.isNotEmpty) {
      // Convert to method call arguments and use existing handler
      final arguments = {
        'leadId': leadId,
        'phoneNumber': phoneNumber,
        'leadName': leadName,
        'propertyCount': int.tryParse(propertyCount ?? '0') ?? 0,
        'source': source ?? 'ios_url_scheme',
      };
      _handlePropertyDetailsNavigation(arguments);
    } else if (phoneNumber != null && phoneNumber.isNotEmpty) {
      // If no leadId but phone number exists, try to find lead by phone
      _findLeadByPhoneAndNavigate(phoneNumber, leadName, source);
    }
  }

  // ADD THIS METHOD - Add Lead URL Handler
  void _handleAddLeadUrl(Uri uri) {
    final String? phoneNumber = uri.queryParameters['phoneNumber'];
    final String? source = uri.queryParameters['source'];

    print('📱 Add Lead URL - phone: $phoneNumber, source: $source');

    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      // Convert to method call arguments and use existing handler
      final arguments = {
        'phoneNumber': phoneNumber,
        'source': source ?? 'ios_url_scheme',
      };
      _handleNewLeadNavigation(arguments);
    }
  }

  // ADD THIS METHOD - Lead Details URL Handler
  void _handleLeadDetailsUrl(Uri uri) {
    final String? leadId = uri.queryParameters['leadId'];
    final String? phoneNumber = uri.queryParameters['phoneNumber'];
    final String? leadName = uri.queryParameters['leadName'];
    final String? editMode = uri.queryParameters['editMode'];
    final String? source = uri.queryParameters['source'];

    print(
      '📱 Lead Details URL - leadId: $leadId, phone: $phoneNumber, editMode: $editMode',
    );

    if (leadId != null && leadId.isNotEmpty) {
      // Convert to method call arguments and use existing handler
      final arguments = {
        'leadId': leadId,
        'phoneNumber': phoneNumber,
        'leadName': leadName,
        'editMode': editMode?.toLowerCase() == 'true',
        'source': source ?? 'ios_url_scheme',
      };
      _handleLeadDetailsNavigation(arguments);
    }
  }

  // ADD THIS METHOD - Find Lead by Phone
  void _findLeadByPhoneAndNavigate(
    String phoneNumber,
    String? leadName,
    String? source,
  ) async {
    print('🔍 Finding lead by phone: $phoneNumber');

    final BuildContext? context = MyApp.navigatorKey.currentContext;
    if (context != null && mounted) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Searching for lead...'),
                    ],
                  ),
                ),
              ),
        );

        // Get the lead controller
        final leadController = Provider.of<LeadProvider>(
          context,
          listen: false,
        );

        // Fetch all leads if not already loaded
        if (leadController.leads.isEmpty) {
          await leadController.fetchLeads();
        }

        // Find lead by phone number
        LeadModel? lead;
        try {
          lead = leadController.leads.firstWhere(
            (lead) =>
                lead.phoneNumber == phoneNumber ||
                lead.whatsappNumber == phoneNumber,
          );
        } catch (e) {
          lead = null;
        }

        // Close loading dialog
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        if (lead != null) {
          // Navigate to PropertyDetailsDisplayScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PropertyDetailsDisplayScreen(lead: lead!),
            ),
          );
          print('✅ Successfully navigated to PropertyDetailsDisplayScreen');
        } else {
          print(
            '❌ Lead not found for phone: $phoneNumber, navigating to add lead',
          );
          // Navigate to add lead screen if not found
          final arguments = {
            'phoneNumber': phoneNumber,
            'source': source ?? 'ios_url_scheme_not_found',
          };
          _handleNewLeadNavigation(arguments);
        }
      } catch (e) {
        // Close loading dialog if still open
        try {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        } catch (_) {}

        print('❌ Error finding lead: $e');
        _showErrorSnackBar('Error finding lead: ${e.toString()}');
      }
    }
  }

  // YOUR EXISTING METHOD - Keep exactly as is
  void _setupMethodChannelHandler() {
    platform.setMethodCallHandler(_handleMethodCall);
  }

  // YOUR EXISTING METHOD - Keep exactly as is
  Future<void> _handleMethodCall(MethodCall call) async {
    print('Received method call: ${call.method}');

    switch (call.method) {
      case 'navigateToPropertyDetails':
        await _handlePropertyDetailsNavigation(call.arguments);
        break;
      case 'navigateToLeadDetails':
        await _handleLeadDetailsNavigation(call.arguments);
        break;
      case 'navigateToCallDetails':
        await _handleCallDetailsNavigation(call.arguments);
        break;
      case 'navigateToNewLead':
        await _handleNewLeadNavigation(call.arguments);
        break;
      case 'onIncomingCall':
        _handleIncomingCall(call.arguments);
        break;
      case 'onCallEnded':
        _handleCallEnded(call.arguments);
        break;
      case 'onPermissionResult':
        _handlePermissionResult(call.arguments);
        break;
      case 'onPermissionStatusUpdate':
        _handlePermissionStatusUpdate(call.arguments);
        break;
      default:
        print('Unknown method: ${call.method}');
    }
  }

  // YOUR EXISTING METHOD - Keep exactly as is
  Future<void> _handlePropertyDetailsNavigation(dynamic arguments) async {
    try {
      final String? leadId = arguments['leadId'];
      final String? phoneNumber = arguments['phoneNumber'];
      final String? leadName = arguments['leadName'];
      final int? propertyCount = arguments['propertyCount'];
      final String? source = arguments['source'];

      print('Navigating to PropertyDetailsDisplayScreen for lead: $leadId');

      if (leadId != null && MyApp.navigatorKey.currentContext != null) {
        final context = MyApp.navigatorKey.currentContext!;

        // Get the lead controller
        final leadController = Provider.of<LeadProvider>(
          context,
          listen: false,
        );

        // Try to get the lead by ID
        LeadModel? lead = await _getLeadById(leadController, leadId);

        if (lead != null) {
          // Navigate to PropertyDetailsDisplayScreen
          MyApp.navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => PropertyDetailsDisplayScreen(lead: lead),
            ),
          );
          print('Successfully navigated to PropertyDetailsDisplayScreen');
        } else {
          print('Lead not found for ID: $leadId');
          _showErrorSnackBar('Lead not found');
        }
      }
    } catch (e) {
      print('Error navigating to PropertyDetailsDisplayScreen: $e');
      _showErrorSnackBar('Error opening property details: $e');
    }
  }

  // YOUR EXISTING METHOD - Keep exactly as is
  Future<LeadModel?> _getLeadById(
    LeadProvider leadController,
    String leadId,
  ) async {
    try {
      // Option 1: Try to get from existing leads cache if available
      if (leadController.leads.isNotEmpty) {
        try {
          final existingLead = leadController.leads.firstWhere(
            (lead) => lead.id == leadId,
          );
          return existingLead;
        } catch (e) {
          // Not found, will try next option
        }
      }

      await leadController.fetchLeads();
      try {
        return leadController.leads.firstWhere((lead) => lead.id == leadId);
      } catch (e) {
        return null;
      }
    } catch (e) {
      print('Error fetching lead by ID: $e');
      return null;
    }
  }

  // YOUR EXISTING METHOD - Keep exactly as is
  Future<void> _handleLeadDetailsNavigation(dynamic arguments) async {
    try {
      final String? leadId = arguments['leadId'];
      final String? phoneNumber = arguments['phoneNumber'];
      final String? leadName = arguments['leadName'];
      final bool? editMode = arguments['editMode'];
      final String? source = arguments['source'];

      print(
        'Navigating to LeadDetailsScreen for lead: $leadId, editMode: $editMode',
      );

      if (leadId != null && MyApp.navigatorKey.currentContext != null) {
        final context = MyApp.navigatorKey.currentContext!;

        // Get the lead controller
        final leadController = Provider.of<LeadProvider>(
          context,
          listen: false,
        );

        // Try to get the lead by ID
        LeadModel? lead = await _getLeadById(leadController, leadId);

        if (lead != null) {
          // Navigate to LeadDetailsScreen
          MyApp.navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder:
                  (context) => LeadDetailsScreen(
                    existingLead: lead,
                    isEditMode: editMode ?? true,
                  ),
            ),
          );
          print('Successfully navigated to LeadDetailsScreen');
        } else {
          print('Lead not found for ID: $leadId');
          _showErrorSnackBar('Lead not found');
        }
      }
    } catch (e) {
      print('Error navigating to LeadDetailsScreen: $e');
      _showErrorSnackBar('Error opening lead details: $e');
    }
  }

  // YOUR EXISTING METHOD - Keep exactly as is
  Future<void> _handleCallDetailsNavigation(dynamic arguments) async {
    // Implement call details navigation
    print('Call details navigation: $arguments');
    // Add your call details navigation logic here
  }

  // YOUR EXISTING METHOD - Keep exactly as is
  Future<void> _handleNewLeadNavigation(dynamic arguments) async {
    try {
      final String? phoneNumber = arguments['phoneNumber'];
      final String? source = arguments['source'];
      final String? action = arguments['action'];
      final int? timestamp = arguments['timestamp'];

      print(
        'Navigating to NewLeadFormScreen with phone: $phoneNumber, source: $source',
      );

      if (MyApp.navigatorKey.currentContext != null) {
        final result = await MyApp.navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder:
                (context) =>
                    NewLeadFormScreen(prefilledPhoneNumber: phoneNumber),
          ),
        );

        // Handle the result if a new lead was created
        if (result != null) {
          print('New lead created successfully: $result');

          // Optionally refresh leads list if you have a provider
          if (MyApp.navigatorKey.currentContext != null) {
            final context = MyApp.navigatorKey.currentContext!;
            final leadController = Provider.of<LeadProvider>(
              context,
              listen: false,
            );

            // Refresh leads to include the new one
            try {
              await leadController.fetchLeads();
              print('Leads list refreshed after new lead creation');
            } catch (e) {
              print('Error refreshing leads after creation: $e');
            }
          }
        } else {
          print('New lead creation was cancelled or failed');
        }
      } else {
        print('No navigator context available for new lead navigation');
        _showErrorSnackBar('Unable to open new lead form');
      }
    } catch (e) {
      print('Error navigating to new lead form: $e');
      _showErrorSnackBar('Error opening new lead form: $e');
    }
  }

  // YOUR EXISTING METHOD - Keep exactly as is
  void _handleIncomingCall(dynamic arguments) {
    print('Incoming call: $arguments');
  }

  // YOUR EXISTING METHOD - Keep exactly as is
  void _handleCallEnded(dynamic arguments) {
    print('Call ended: $arguments');
  }

  // YOUR EXISTING METHOD - Keep exactly as is
  void _handlePermissionResult(dynamic arguments) {
    print('Permission result: $arguments');
  }

  // YOUR EXISTING METHOD - Keep exactly as is
  void _handlePermissionStatusUpdate(dynamic arguments) {
    print('Permission status update: $arguments');
  }

  // YOUR EXISTING METHOD - Keep exactly as is
  void _showErrorSnackBar(String message) {
    final context = MyApp.navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // YOUR EXISTING METHOD - Keep exactly as is
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class PermissionScreen extends StatefulWidget {
  @override
  _PermissionScreenState createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isLoading = true;
  bool _allPermissionsGranted = false;
  Map<Permission, PermissionStatus> _permissionStatuses = {};
  int _currentPermissionStep = 0;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  // Get platform-specific required permissions
  List<Permission> get _requiredPermissions {
    if (Platform.isIOS) {
      return [
        Permission.notification,
        Permission.microphone, // iOS equivalent for call-related features
        // No contacts permission for iOS as per request
      ];
    } else {
      // Android permissions - Added contacts permission
      return [
        Permission.notification,
        Permission.phone,
        Permission.contacts, // Added contact permission for Android
        Permission.systemAlertWindow,
        Permission.ignoreBatteryOptimizations,
      ];
    }
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
    });

    // For iOS, skip permission checks and go directly to splash screen
    if (Platform.isIOS) {
      print(
        '🍎 iOS detected - requesting permissions in background and navigating to splash',
      );
      _requestIOSPermissionsInBackground();
      _navigateToSplashScreen();
      return;
    }

    // Android permission checking logic
    Map<Permission, PermissionStatus> statuses = {};
    for (Permission permission in _requiredPermissions) {
      try {
        statuses[permission] = await permission.status;
      } catch (e) {
        print('Error checking permission $permission: $e');
        // Set to denied if we can't check
        statuses[permission] = PermissionStatus.denied;
      }
    }

    setState(() {
      _permissionStatuses = statuses;
      _allPermissionsGranted = _areAllPermissionsGranted();
      _isLoading = false;
    });

    if (_allPermissionsGranted) {
      _navigateToSplashScreen();
    }
  }

  bool _areAllPermissionsGranted() {
    return _permissionStatuses.values.every(
      (status) => status == PermissionStatus.granted,
    );
  }

  Future<void> _requestPermissions() async {
    // Only for Android - iOS skips this step
    if (Platform.isIOS) {
      print('🍎 iOS detected - skipping permission request screen');
      return;
    }

    setState(() {
      _isLoading = true;
      _currentPermissionStep = 0;
    });

    try {
      await _requestAndroidPermissions();

      await _checkPermissions();

      if (_allPermissionsGranted) {
        _navigateToSplashScreen();
      } else {
        _showPermissionDialog();
      }
    } catch (e) {
      print('Error requesting permissions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestIOSPermissionsInBackground() async {
    print('🍎 Requesting iOS permissions in background...');

    try {
      // Request notification permission silently
      PermissionStatus notificationStatus =
          await Permission.notification.request();
      print('iOS notification permission: $notificationStatus');

      // Request microphone permission silently
      if (_requiredPermissions.contains(Permission.microphone)) {
        PermissionStatus micStatus = await Permission.microphone.request();
        print('iOS microphone permission: $micStatus');
      }

      print('✅ iOS permissions requested in background');
    } catch (e) {
      print('Error requesting iOS permissions in background: $e');
    }
  }

  Future<void> _requestAndroidPermissions() async {
    // Request notification permission first and separately
    await _requestNotificationPermission();

    // Then request contacts permission
    await _requestContactsPermission();

    // Then request other permissions
    await _requestOtherAndroidPermissions();
  }

  Future<void> _requestNotificationPermission() async {
    setState(() {
      _currentPermissionStep = 1;
    });

    print('🔔 Requesting notification permission...');

    try {
      // Request notification permission first
      PermissionStatus notificationStatus =
          await Permission.notification.request();

      if (notificationStatus.isGranted) {
        print('✅ Notification permission granted');
      } else {
        print('❌ Notification permission denied');
      }

      // Update the status
      _permissionStatuses[Permission.notification] = notificationStatus;
    } catch (e) {
      print('Error requesting notification permission: $e');
      _permissionStatuses[Permission.notification] = PermissionStatus.denied;
    }
  }

  Future<void> _requestContactsPermission() async {
    setState(() {
      _currentPermissionStep = 2;
    });

    print('📇 Requesting contacts permission...');

    try {
      // Request contacts permission
      PermissionStatus contactsStatus = await Permission.contacts.request();

      if (contactsStatus.isGranted) {
        print('✅ Contacts permission granted');
      } else {
        print('❌ Contacts permission denied');
      }

      // Update the status
      _permissionStatuses[Permission.contacts] = contactsStatus;
    } catch (e) {
      print('Error requesting contacts permission: $e');
      _permissionStatuses[Permission.contacts] = PermissionStatus.denied;
    }
  }

  Future<void> _requestOtherAndroidPermissions() async {
    setState(() {
      _currentPermissionStep = 3;
    });

    // Request remaining Android permissions (excluding notification and contacts)
    List<Permission> otherPermissions =
        _requiredPermissions
            .where(
              (p) => p != Permission.notification && p != Permission.contacts,
            )
            .toList();

    try {
      Map<Permission, PermissionStatus> statuses =
          await otherPermissions.request();

      // Update statuses
      _permissionStatuses.addAll(statuses);

      // Handle special Android permissions
      await _handleSpecialAndroidPermissions();
    } catch (e) {
      print('Error requesting other Android permissions: $e');
      // Set all to denied if batch request fails
      for (Permission permission in otherPermissions) {
        _permissionStatuses[permission] = PermissionStatus.denied;
      }
    }
  }

  Future<void> _handleSpecialAndroidPermissions() async {
    setState(() {
      _currentPermissionStep = 4;
    });

    // Handle system alert window permission
    if (_permissionStatuses.containsKey(Permission.systemAlertWindow)) {
      try {
        if (await Permission.systemAlertWindow.isDenied) {
          PermissionStatus status =
              await Permission.systemAlertWindow.request();
          _permissionStatuses[Permission.systemAlertWindow] = status;
        }
      } catch (e) {
        print('Error handling system alert window permission: $e');
      }
    }

    // Handle battery optimization permission
    if (_permissionStatuses.containsKey(
      Permission.ignoreBatteryOptimizations,
    )) {
      try {
        if (await Permission.ignoreBatteryOptimizations.isDenied) {
          PermissionStatus status =
              await Permission.ignoreBatteryOptimizations.request();
          _permissionStatuses[Permission.ignoreBatteryOptimizations] = status;
        }
      } catch (e) {
        print('Error handling battery optimization permission: $e');
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permissions Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This app requires the following permissions to function properly:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ..._buildPermissionList(),
              SizedBox(height: 10),
              Text(
                Platform.isIOS
                    ? 'Please grant all permissions to continue. You can manage these permissions in Settings.'
                    : 'Please grant all permissions to continue. These permissions are essential for app functionality.',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text('Open Settings'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestPermissions();
              },
              child: Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildPermissionList() {
    return _permissionStatuses.entries.map((entry) {
      String permissionName = _getPermissionName(entry.key);
      bool isGranted = entry.value == PermissionStatus.granted;

      return Padding(
        padding: EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(
              isGranted ? Icons.check_circle : Icons.cancel,
              color: isGranted ? Colors.green : Colors.red,
              size: 16,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                permissionName,
                style: TextStyle(
                  color: isGranted ? Colors.green : Colors.red,
                  fontWeight:
                      entry.key == Permission.notification ||
                              entry.key == Permission.contacts
                          ? FontWeight.bold
                          : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _getPermissionName(Permission permission) {
    if (Platform.isIOS) {
      switch (permission) {
        case Permission.notification:
          return 'Notifications (Required for reminders)';
        case Permission.microphone:
          return 'Microphone (for call features)';
        default:
          return permission.toString().split('.').last;
      }
    } else {
      // Android permission names
      switch (permission) {
        case Permission.notification:
          return 'Notifications (Required for reminders)';
        case Permission.phone:
          return 'Phone Access (for call detection)';
        case Permission.contacts:
          return 'Contacts (Required for lead management)';
        case Permission.systemAlertWindow:
          return 'Display over other apps';
        case Permission.ignoreBatteryOptimizations:
          return 'Battery Optimization';
        default:
          return permission.toString().split('.').last;
      }
    }
  }

  String _getLoadingMessage() {
    String platform = Platform.isIOS ? 'iOS' : 'Android';

    switch (_currentPermissionStep) {
      case 1:
        return 'Requesting notification permission...';
      case 2:
        return 'Requesting contacts permission...';
      case 3:
        return 'Requesting $platform permissions...';
      case 4:
        return 'Configuring special permissions...';
      default:
        return 'Checking permissions...';
    }
  }

  void _navigateToSplashScreen() {
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => SplashScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // For iOS, skip permission screen entirely and show loading while navigating
    if (Platform.isIOS && !_isLoading) {
      return Container(); // Empty container as we're navigating away
    }

    if (!_isLoading && Platform.isAndroid && _allPermissionsGranted) {
      return Container(); // Empty container as we're navigating away
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade400, Colors.green.shade700],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Platform.isIOS ? Icons.phone_iphone : Icons.phone_android,
                      size: 60,
                      color: Colors.green.shade700,
                    ),
                  ),
                  SizedBox(height: 40),
                  Text(
                    'Taro Mobile',
                    style: GoogleFonts.lato(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Running on ${Platform.isIOS ? 'iOS' : 'Android'}',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 20),
                  if (_isLoading || Platform.isIOS)
                    Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          Platform.isIOS
                              ? 'Loading app...'
                              : _getLoadingMessage(),
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    )
                  else if (Platform.isAndroid && _allPermissionsGranted)
                    Column(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 48),
                        SizedBox(height: 20),
                        Text(
                          'All permissions granted!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Loading app...',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    )
                  else if (Platform.isAndroid)
                    Column(
                      children: [
                        Icon(
                          Icons.notifications,
                          color: Colors.white,
                          size: 48,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Permissions Required',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'This app needs permissions for notifications, contacts, and other features to provide you with the best experience.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _requestPermissions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green.shade700,
                            padding: EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            'Grant Permissions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Some permissions may require manual setup in Android settings',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
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

// Add this class to handle URL schemes
class URLSchemeHandler {
  static const MethodChannel _channel = MethodChannel(
    'com.taro.mobileapp/url_scheme',
  );

  static StreamController<String> _urlStreamController =
      StreamController<String>.broadcast();

  static Stream<String> get urlStream => _urlStreamController.stream;

  static Future<void> initialize() async {
    _channel.setMethodCallHandler(_handleMethodCall);

    // Check if app was launched with a URL
    final String? initialUrl = await _channel.invokeMethod('getInitialUrl');
    if (initialUrl != null) {
      _urlStreamController.add(initialUrl);
    }
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onNewUrl':
        final String url = call.arguments as String;
        print('📱 Received URL: $url');
        _urlStreamController.add(url);
        break;
      default:
        print('Unknown method: ${call.method}');
    }
  }

  static void dispose() {
    _urlStreamController.close();
  }
}
