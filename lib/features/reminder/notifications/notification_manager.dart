// Enhanced notification_service.dart with iOS fixes and launch detection
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'reminder_channel';
  static const String _channelName = 'Reminders';
  static const String _channelDescription = 'Notifications for reminders';

  // Navigation callback - static to be accessible from static methods
  static Function(String)? _onEditReminder;
  static GlobalKey<NavigatorState>? _navigatorKey;

  // Store pending navigation actions for when app comes to foreground
  static String? _pendingReminderId;
  static String? _pendingAction;

  // Track initialization state
  bool _isInitialized = false;

  // Set navigation callback
  static void setNavigationCallback({
    required Function(String) onEditReminder,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    print('🔧 Setting navigation callbacks...');
    _onEditReminder = onEditReminder;
    _navigatorKey = navigatorKey;
    print('✅ Navigation callbacks set successfully');

    // Process any pending navigation
    if (_pendingReminderId != null && _pendingAction != null) {
      print(
        '📱 Processing pending navigation: $_pendingAction for $_pendingReminderId',
      );
      if (_pendingAction == 'edit') {
        _editReminder(_pendingReminderId!, {});
      }
      _pendingReminderId = null;
      _pendingAction = null;
    }
  }

  Future<void> initialize() async {
    print('🚀 Initializing NotificationService...');

    tz.initializeTimeZones();

    // Request notification permissions FIRST for iOS
    await _requestPermissions();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: false, // Already requested above
          requestBadgePermission: false,
          requestSoundPermission: false,
          requestCriticalPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    final bool? result = await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Setup iOS categories after initialization
    if (Platform.isIOS) {
      await _setupIOSNotificationCategories();
    }

    _isInitialized = true;
    print('📱 NotificationService initialization result: $result');
  }

  // Setup iOS notification categories
  Future<void> _setupIOSNotificationCategories() async {
    print('🍎 Setting up iOS notification categories...');

    // Define iOS notification actions using the correct constructor
    DarwinNotificationAction finishAction = DarwinNotificationAction.plain(
      'finish',
      'Complete',
      options: <DarwinNotificationActionOption>{
        DarwinNotificationActionOption.destructive,
      },
    );

    DarwinNotificationAction editAction = DarwinNotificationAction.plain(
      'edit',
      'View',
      options: <DarwinNotificationActionOption>{
        DarwinNotificationActionOption.foreground,
      },
    );

    // Create notification category
    DarwinNotificationCategory reminderCategory = DarwinNotificationCategory(
      'reminderCategory',
      actions: <DarwinNotificationAction>[finishAction, editAction],
      options: const <DarwinNotificationCategoryOption>{
        DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
      },
    );

    // Initialize iOS plugin with categories
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.initialize(
          DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
            requestCriticalPermission: false,
            notificationCategories: [reminderCategory],
          ),
        );

    print('✅ iOS notification categories set up successfully');
  }

  // Method to get launch details - this is key for handling app launch from notification
  Future<NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async {
    if (!_isInitialized) {
      print('⚠️ NotificationService not initialized yet');
      return null;
    }

    try {
      final details =
          await _flutterLocalNotificationsPlugin
              .getNotificationAppLaunchDetails();
      print('🔍 Launch details: ${details?.didNotificationLaunchApp}');
      return details;
    } catch (e) {
      print('❌ Error getting launch details: $e');
      return null;
    }
  }

  Future<void> _requestPermissions() async {
    print('🔐 Requesting notification permissions...');

    if (Platform.isIOS) {
      // iOS-specific permission request
      final bool? result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );

      print('📱 iOS Permission result: $result');
    } else {
      // Android permission request
      if (await Permission.notification.isDenied) {
        final PermissionStatus status = await Permission.notification.request();
        print('📱 Android permission status: $status');
      }

      // For Android 13+ (API level 33+), also request POST_NOTIFICATIONS permission
      try {
        final androidInfo = await Permission.notification.status;
        print('📱 Android notification status: $androidInfo');
      } catch (e) {
        print('ℹ️ Could not get Android notification status: $e');
      }
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('🔔 NOTIFICATION TAPPED!');
    print('   - ID: ${response.id}');
    print('   - Action ID: ${response.actionId}');
    print('   - Payload: ${response.payload}');

    final String? payload = response.payload;
    if (payload != null) {
      try {
        final Map<String, dynamic> data = json.decode(payload);
        print('   - Parsed data: $data');

        // Add a small delay to ensure the app is fully resumed
        Future.delayed(Duration(milliseconds: 500), () {
          _handleNotificationAction(data, response.actionId);
        });
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
      }
    } else {
      print('⚠️ No payload found in notification');
    }
  }

  static void _handleNotificationAction(
    Map<String, dynamic> data,
    String? actionId,
  ) {
    final String reminderId = data['reminderId'] ?? '';
    final String reminderType = data['reminderType'] ?? '';

    print('🎯 Handling notification action:');
    print('   - Action ID: "$actionId"');
    print('   - Reminder ID: "$reminderId"');
    print('   - Reminder Type: "$reminderType"');
    print('   - Navigation ready: ${isNavigationReady}');

    // Handle null or empty actionId (notification body tap)
    if (actionId == null || actionId.isEmpty) {
      print('📱 Notification body tapped - opening details');
      _openReminderDetails(reminderId, data);
      return;
    }

    switch (actionId) {
      case 'finish':
        print('✅ Executing finish action');
        _finishReminder(reminderId);
        break;
      case 'edit':
        print('✏️ Executing edit action');
        _editReminder(reminderId, data);
        break;
      default:
        print('📖 Unknown action "$actionId", opening details');
        _openReminderDetails(reminderId, data);
        break;
    }
  }

  static void _finishReminder(String reminderId) async {
    try {
      print('🎯 Marking reminder as complete: $reminderId');

      // Validate reminder ID
      if (reminderId.isEmpty) {
        print('❌ Error: Reminder ID is empty');
        _showSnackBar('Error: Invalid reminder ID', Colors.red, duration: 3);
        return;
      }

      // Update the reminder in Firestore with proper await
      final result = await FirebaseFirestore.instance
          .collection('reminders')
          .doc(reminderId)
          .update({
            'isDisabled': true,
            'status': 'completed',
            'disabledAt': FieldValue.serverTimestamp(),
            'completedAt': FieldValue.serverTimestamp(), // Additional timestamp
          });

      print('✅ Reminder marked as complete successfully');
      print('📊 Firestore update result: ');

      // Show success feedback
      _showSnackBar(
        'Reminder completed successfully',
        Colors.green,
        duration: 2,
      );

      // Provide haptic feedback
      HapticFeedback.lightImpact();

      // Optional: Cancel any pending notifications for this reminder
      NotificationService()._cancelNotificationById(reminderId);
    } catch (e) {
      print('❌ Error marking reminder as complete: $e');
      print('📊 Error type: ${e.runtimeType}');

      // More specific error handling
      String errorMessage = 'Failed to update reminder';
      if (e is FirebaseException) {
        errorMessage = 'Database error: ${e.message}';
      } else if (e is Exception) {
        errorMessage = 'Error: ${e.toString()}';
      }

      // Show error feedback
      _showSnackBar(errorMessage, Colors.red, duration: 4);
    }
  }

  // Add this helper method to cancel notifications
  Future<void> _cancelNotificationById(String reminderId) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(reminderId.hashCode);
      print('🗑️ Notification cancelled for reminder: $reminderId');
    } catch (e) {
      print('⚠️ Could not cancel notification: $e');
    }
  }

  static void _editReminder(String reminderId, Map<String, dynamic> data) {
    try {
      print('✏️ Opening reminder details screen for: $reminderId');
      print('📝 Edit callback available: ${_onEditReminder != null}');
      print('🗝️ Navigator key available: ${_navigatorKey != null}');
      print(
        '🔍 Navigator current context: ${_navigatorKey?.currentContext != null}',
      );

      if (_onEditReminder != null) {
        // Check if we have a valid context
        if (_navigatorKey?.currentContext != null) {
          print('🚀 Calling navigation callback with valid context...');

          // Use post frame callback to ensure navigation happens after the current frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              // Pass both reminderId and the notification data
              _onEditReminder!(reminderId);
              print('📱 Navigation callback executed successfully');

              // Provide haptic feedback
              HapticFeedback.selectionClick();
            } catch (e) {
              print('❌ Error in navigation callback: $e');
              _showSnackBar(
                'Error opening reminder details: $e',
                Colors.red,
                duration: 3,
              );
            }
          });
        } else {
          print('⚠️ No valid context available. Storing for later execution.');
          // Store the pending action for when the app comes to foreground
          _pendingReminderId = reminderId;
          _pendingAction = 'edit';

          // Show feedback that the app needs to be opened
          _showSnackBar(
            'Opening app to view reminder...',
            Colors.blue,
            duration: 3,
          );
        }
      } else {
        print(
          '⚠️ Navigation callback not set. Call setNavigationCallback() first.',
        );

        // Store the pending action for when callbacks are set
        _pendingReminderId = reminderId;
        _pendingAction = 'edit';

        // Fallback: show message that app needs to be opened
        _showSnackBar(
          'Please open the app to view this reminder',
          Colors.blue,
          duration: 3,
        );
      }
    } catch (e) {
      print('❌ Error in _editReminder: $e');
      _showSnackBar(
        'Error opening reminder details: $e',
        Colors.red,
        duration: 3,
      );
    }
  }

  static void _openReminderDetails(
    String reminderId,
    Map<String, dynamic> data,
  ) {
    print('📖 Opening reminder details: $reminderId');
    // For now, open the edit screen when tapping the notification
    _editReminder(reminderId, data);
  }

  static void _showSnackBar(
    String message,
    Color backgroundColor, {
    int duration = 2,
  }) {
    print('📢 Showing snackbar: $message');

    try {
      if (_navigatorKey?.currentContext != null) {
        final context = _navigatorKey!.currentContext!;

        // Use post frame callback to ensure the snackbar is shown after the current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: backgroundColor,
                duration: Duration(seconds: duration),
                behavior: SnackBarBehavior.floating,
              ),
            );
            print('✅ SnackBar shown successfully');
          } catch (e) {
            print('❌ Error showing SnackBar: $e');
          }
        });
      } else {
        print('⚠️ No context available for SnackBar');
      }
    } catch (e) {
      print('❌ Error in _showSnackBar: $e');
    }
  }

  // Method to check if navigation is ready
  static bool get isNavigationReady =>
      _onEditReminder != null && _navigatorKey?.currentContext != null;

  // Method to manually trigger pending navigation (call this when app comes to foreground)
  static void processPendingNavigation() {
    if (_pendingReminderId != null &&
        _pendingAction != null &&
        isNavigationReady) {
      print(
        '📱 Processing pending navigation: $_pendingAction for $_pendingReminderId',
      );

      if (_pendingAction == 'edit') {
        _editReminder(_pendingReminderId!, {});
      }

      _pendingReminderId = null;
      _pendingAction = null;
    }
  }

  Future<void> scheduleReminder({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required int notificationMinutesBefore,
    required Map<String, dynamic> payload,
  }) async {
    try {
      print('📅 Scheduling reminder: $id');
      print('🔍 Platform: ${Platform.isIOS ? 'iOS' : 'Android'}');

      final DateTime notificationTime = scheduledDate.subtract(
        Duration(minutes: notificationMinutesBefore),
      );

      if (notificationTime.isBefore(DateTime.now())) {
        print('⚠️ Notification time is in the past, not scheduling');
        return;
      }

      final tz.TZDateTime tzNotificationTime = tz.TZDateTime.from(
        notificationTime,
        tz.local,
      );

      print('🔍 Notification ID: ${id.hashCode}');
      print('🔍 Scheduled time: $tzNotificationTime');
      print('🔍 Current time: ${DateTime.now()}');

      String enhancedBody = body;
      if (notificationMinutesBefore > 0) {
        enhancedBody +=
            '\n⏰ ${_formatMinutesToText(notificationMinutesBefore)} before scheduled time';
      }

      // Android notification details
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            autoCancel: false,
            ongoing: false,
            styleInformation: BigTextStyleInformation(''),
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'finish',
                '✅ Complete',
                showsUserInterface: false,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                'edit',
                '✏️ View',
                showsUserInterface: true,
                cancelNotification: false,
              ),
            ],
          );

      // Enhanced iOS notification details
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            presentBanner: true,
            presentList: true,
            sound: 'default',
            badgeNumber: 1,
            threadIdentifier: 'reminders',
            categoryIdentifier: 'reminderCategory',
            subtitle: 'Reminder Alert',
            interruptionLevel: InterruptionLevel.active,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id.hashCode,
        title,
        enhancedBody,
        tzNotificationTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: json.encode(payload),
      );

      print(
        '✅ Notification scheduled for: ${_formatDateTime(tzNotificationTime.toLocal())}',
      );
      print(
        '📱 Reminder will notify ${_formatMinutesToText(notificationMinutesBefore)} before scheduled time',
      );
    } catch (e) {
      print('❌ Error scheduling notification: $e');
      throw Exception('Failed to schedule notification: $e');
    }
  }

  // Test notification for general use
  Future<void> testNotification() async {
    print('🧪 Testing notification...');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'test_channel',
          'Test Channel',
          importance: Importance.high,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'finish',
              '✅ Test Complete',
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              'edit',
              '✏️ Test View',
              showsUserInterface: true,
            ),
          ],
        );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      sound: 'default',
      badgeNumber: 1,
      categoryIdentifier: 'reminderCategory',
      subtitle: 'Test Notification',
      interruptionLevel: InterruptionLevel.active,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      999,
      'Test Notification',
      'Tap to test app launch from notification',
      platformChannelSpecifics,
      payload: json.encode({
        'reminderId': 'test-123',
        'reminderType': 'Test',
        'leadName': 'Test Lead',
      }),
    );

    print('🧪 Test notification sent');
  }

  // iOS-specific test notification
  Future<void> testIOSNotification() async {
    print('🧪 Testing iOS notification...');

    // Check if iOS
    if (!Platform.isIOS) {
      print('⚠️ Not running on iOS');
      return;
    }

    // Check permissions
    final bool? permissionGranted = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    print('📱 iOS Permission granted: $permissionGranted');

    if (permissionGranted != true) {
      print('❌ iOS notifications not permitted');
      return;
    }

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      sound: 'default',
      badgeNumber: 1,
      threadIdentifier: 'test',
      categoryIdentifier: 'reminderCategory',
      subtitle: 'Test Notification',
      interruptionLevel: InterruptionLevel.active,
    );

    await _flutterLocalNotificationsPlugin.show(
      998,
      'iOS Test Notification',
      'If you see this, iOS notifications are working!',
      NotificationDetails(iOS: iOSDetails),
      payload: json.encode({
        'reminderId': 'test-ios-123',
        'reminderType': 'Test',
        'leadName': 'Test Lead',
      }),
    );

    print('✅ iOS test notification sent');
  }

  // Check iOS permissions
  Future<void> checkIOSPermissions() async {
    if (Platform.isIOS) {
      final plugin =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();

      print('📱 Checking iOS notification permissions...');

      // Unfortunately, there's no direct way to check current permission status
      // You need to request permissions to know the status
      final bool? hasPermission = await plugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      print('📱 iOS Notification permission status: $hasPermission');
    }
  }

  // Test immediate notification (for debugging)
  Future<void> testImmediateNotification() async {
    print('🧪 Testing immediate notification...');

    // Schedule notification 5 seconds from now
    final testTime = DateTime.now().add(Duration(seconds: 5));
    final tzTestTime = tz.TZDateTime.from(testTime, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'immediate_test',
          'Immediate Test',
          importance: Importance.high,
        );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      sound: 'default',
      categoryIdentifier: 'reminderCategory',
      interruptionLevel: InterruptionLevel.active,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      997,
      'Immediate Test',
      'This should appear in 5 seconds',
      tzTestTime,
      platformChannelSpecifics,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: json.encode({
        'reminderId': 'immediate-test-123',
        'reminderType': 'Immediate Test',
      }),
    );

    print('✅ Immediate test notification scheduled for: $testTime');
  }

  Future<void> cancelNotification(String id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id.hashCode);
      print('🗑️ Notification cancelled for ID: $id');
    } catch (e) {
      print('❌ Error cancelling notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      print('🗑️ All notifications cancelled');
    } catch (e) {
      print('❌ Error cancelling all notifications: $e');
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  // Helper methods for formatting
  String formatNotificationTitle(String reminderType, String? leadName) {
    if (leadName != null && leadName.trim().isNotEmpty) {
      return '🔔 $reminderType Reminder - $leadName';
    } else {
      return '🔔 $reminderType Reminder';
    }
  }

  String formatNotificationBody(
    String reminderType,
    String? leadName,
    String? propertyDetails,
    String? notes,
    DateTime scheduledTime,
  ) {
    final String timeStr = _formatTime(scheduledTime);
    final String dateStr = _formatDate(scheduledTime);

    // Start with basic reminder info
    String body = '📅 $dateStr at $timeStr';

    // Only add lead name if it exists and is not empty
    if (leadName != null && leadName.trim().isNotEmpty) {
      body = '👤 Reminder for $leadName\n$body';
    } else {
      body = '🔔 $reminderType Reminder\n$body';
    }

    // Only add property if it exists and is not empty
    if (propertyDetails != null && propertyDetails.trim().isNotEmpty) {
      body += '\n🏠 Property: $propertyDetails';
    }

    // Only add notes if they exist and are not empty
    if (notes != null && notes.trim().isNotEmpty) {
      body += '\n📝 Note: $notes';
    }

    return body;
  }

  String _formatTime(DateTime dateTime) {
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime dateTime) {
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();
    return '$day/$month/$year';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} at ${_formatTime(dateTime)}';
  }

  String _formatMinutesToText(int minutes) {
    if (minutes < 60) {
      return '$minutes minute${minutes == 1 ? '' : 's'}';
    } else if (minutes < 1440) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      String result = '$hours hour${hours == 1 ? '' : 's'}';
      if (remainingMinutes > 0) {
        result +=
            ' and $remainingMinutes minute${remainingMinutes == 1 ? '' : 's'}';
      }
      return result;
    } else {
      final days = minutes ~/ 1440;
      final remainingHours = (minutes % 1440) ~/ 60;
      String result = '$days day${days == 1 ? '' : 's'}';
      if (remainingHours > 0) {
        result += ' and $remainingHours hour${remainingHours == 1 ? '' : 's'}';
      }
      return result;
    }
  }
}

// Reminder model class for notification payload
class ReminderNotificationData {
  final String reminderId;
  final String reminderType;
  final String? leadName;
  final String? propertyDetails;
  final String? notes;
  final DateTime scheduledTime;
  final int notificationMinutesBefore;

  ReminderNotificationData({
    required this.reminderId,
    required this.reminderType,
    this.leadName,
    this.propertyDetails,
    this.notes,
    required this.scheduledTime,
    required this.notificationMinutesBefore,
  });

  Map<String, dynamic> toJson() {
    return {
      'reminderId': reminderId,
      'reminderType': reminderType,
      'leadName': leadName,
      'propertyDetails': propertyDetails,
      'notes': notes,
      'scheduledTime': scheduledTime.toIso8601String(),
      'notificationMinutesBefore': notificationMinutesBefore,
    };
  }

  factory ReminderNotificationData.fromJson(Map<String, dynamic> json) {
    return ReminderNotificationData(
      reminderId: json['reminderId'] ?? '',
      reminderType: json['reminderType'] ?? '',
      leadName: json['leadName'],
      propertyDetails: json['propertyDetails'],
      notes: json['notes'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      notificationMinutesBefore: json['notificationMinutesBefore'] ?? 30,
    );
  }
}
