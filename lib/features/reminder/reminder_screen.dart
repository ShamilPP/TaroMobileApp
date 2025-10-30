import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_svg/svg.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/core/constants/image_constants.dart';
import 'package:taro_mobile/features/reminder/notifications/notification_manager.dart';
import 'package:taro_mobile/features/reminder/reminder_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';

enum ReminderFilter { overdue, completed, all }

class RemainderScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const RemainderScreen({super.key, this.onProfileTap});

  @override
  State<RemainderScreen> createState() => RemainderScreenState();
}

class RemainderScreenState extends State<RemainderScreen> {
  int selectedDayIndex = 2;
  final List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final List<int> dates = [8, 9, 10, 11, 12, 13];
  ReminderFilter _reminderFilter = ReminderFilter.all;
  DateTime? _selectedFilterDate;
  bool _isDateFilterActive = false;
  bool _shouldResetCalendar = false;
  // User data variables
  String firstName = 'Loading...';
  String lastName = 'Loading...';
  String userEmail = 'Loading...';
  String userInitials = '';

  // Filter variables
  bool _isFilterActive = false;

  // Cache variables - This is the key improvement
  List<DocumentSnapshot> _cachedReminders = [];
  List<DocumentSnapshot> _filteredReminders = [];
  bool _isLoadingReminders = true;
  StreamSubscription<QuerySnapshot>? _reminderSubscription;

  // Timer for dynamic updates
  Timer? _updateTimer;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  User? get currentUser => _auth.currentUser;
  String? get userId => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeNotifications();
    _startUpdateTimer();
    _setupReminderStream(); // Setup the stream once

    DateTime today = DateTime.now();
    _selectedFilterDate = DateTime(today.year, today.month, today.day);
    _isDateFilterActive = true;
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _reminderSubscription?.cancel();
    super.dispose();
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          // This will trigger a rebuild and update the progress bars every minute
        });
      }
    });
  }

  // Setup single stream that fetches all reminders
  void _setupReminderStream() {
    if (currentUser == null) {
      setState(() {
        _isLoadingReminders = false;
      });
      return;
    }

    // Simple query - just get all user reminders, we'll filter locally
    _reminderSubscription = _firestore
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .orderBy('scheduledDateTime', descending: false)
        .snapshots()
        .listen(
          (QuerySnapshot snapshot) {
            setState(() {
              _cachedReminders = snapshot.docs;
              _isLoadingReminders = false;
            });
            _applyFilters(); // Apply current filters whenever data changes
          },
          onError: (error) {
            print('Error loading reminders: $error');
            setState(() {
              _isLoadingReminders = false;
            });
          },
        );
  }

  void _applyFilters() {
    if (_cachedReminders.isEmpty) {
      setState(() {
        _filteredReminders = [];
      });
      return;
    }

    List<DocumentSnapshot> tempFiltered = List.from(_cachedReminders);

    // ALWAYS apply date filter if a date is selected (including today by default)
    if (_selectedFilterDate != null) {
      tempFiltered =
          tempFiltered.where((reminder) {
            try {
              Map<String, dynamic> data =
                  reminder.data() as Map<String, dynamic>;
              DateTime? reminderDate = _getScheduledDateTime(data);

              if (reminderDate != null) {
                return reminderDate.year == _selectedFilterDate!.year &&
                    reminderDate.month == _selectedFilterDate!.month &&
                    reminderDate.day == _selectedFilterDate!.day;
              }

              // Fallback to date string parsing
              String? dateStr = data['date'] as String?;
              if (dateStr != null && dateStr.isNotEmpty) {
                DateTime? parsedDate = _parseDateString(dateStr);
                if (parsedDate != null) {
                  return parsedDate.year == _selectedFilterDate!.year &&
                      parsedDate.month == _selectedFilterDate!.month &&
                      parsedDate.day == _selectedFilterDate!.day;
                }
              }
              return false;
            } catch (e) {
              print('Error filtering reminder by date: ${reminder.id} - $e');
              return false;
            }
          }).toList();
    }

    // Then apply status filter on the date-filtered results
    switch (_reminderFilter) {
      case ReminderFilter.overdue:
        tempFiltered =
            tempFiltered.where((reminder) {
              Map<String, dynamic> data =
                  reminder.data() as Map<String, dynamic>;
              return _isReminderOverdue(data) && (data['isDisabled'] != true);
            }).toList();
        break;

      case ReminderFilter.completed:
        tempFiltered =
            tempFiltered.where((reminder) {
              Map<String, dynamic> data =
                  reminder.data() as Map<String, dynamic>;
              return data['isDisabled'] == true ||
                  data['status'] == 'completed';
            }).toList();
        break;

      case ReminderFilter.all:
        // Show all active reminders (exclude completed ones)
        tempFiltered =
            tempFiltered.where((reminder) {
              Map<String, dynamic> data =
                  reminder.data() as Map<String, dynamic>;
              bool isCompleted =
                  data['isDisabled'] == true || data['status'] == 'completed';
              return !isCompleted; // Only show non-completed reminders
            }).toList();
        break;
    }

    setState(() {
      _filteredReminders = tempFiltered;
    });
  }

  void _setReminderFilter(ReminderFilter filter) {
    setState(() {
      _reminderFilter = filter;
      // Don't reset date filter - keep the currently selected date
      _shouldResetCalendar = false;
    });
    _applyFilters(); // Apply the new status filter with current date
  }

  // Updated method to handle date selection from calendar
  void _filterRemindersByDate(DateTime selectedDate) {
    setState(() {
      _selectedFilterDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      _isDateFilterActive = true;
      _shouldResetCalendar = false;
    });
    _applyFilters(); // Apply current status filter with new date
  }

  void _clearDateFilter() {
    setState(() {
      _selectedFilterDate = null;
      _isDateFilterActive = false;
      _shouldResetCalendar = true;
    });
    _applyFilters(); // Apply current status filter without date restriction
  }

  // Method to reset to today (can be called from UI if needed)
  void _resetToToday() {
    DateTime today = DateTime.now();
    setState(() {
      _selectedFilterDate = DateTime(today.year, today.month, today.day);
      _isDateFilterActive = true;
      _shouldResetCalendar = true;
      // Keep current reminder filter
    });
    _applyFilters();
  }

  // Calculate real-time progress based on current time and reminder positions
  double _calculateRealTimeProgress(
    List<DocumentSnapshot> reminders,
    List<String> sortedHourKeys,
    Map<String, List<DocumentSnapshot>> groupedReminders,
  ) {
    if (reminders.isEmpty || sortedHourKeys.isEmpty) return 0.0;

    DateTime now = DateTime.now();
    double currentPosition = 0.0;
    double totalHeight = sortedHourKeys.length * 96.0; // Each hour group = 96px

    print('DEBUG: Current time: ${now.hour}:${now.minute}');

    // Go through each hour group
    for (int i = 0; i < sortedHourKeys.length; i++) {
      String hourKey = sortedHourKeys[i];
      List<DocumentSnapshot> hourReminders = groupedReminders[hourKey]!;
      double hourGroupHeight = 96.0; // Fixed height per hour group

      if (hourKey == 'unknown-time') {
        continue; // Skip unknown time for now
      }

      // Parse hour key
      List<String> parts = hourKey.split('-');
      if (parts.length >= 4) {
        try {
          int year = int.parse(parts[0]);
          int month = int.parse(parts[1]);
          int day = int.parse(parts[2]);
          int hour = int.parse(parts[3]);

          DateTime reminderHour = DateTime(year, month, day, hour);
          DateTime currentHour = DateTime(
            now.year,
            now.month,
            now.day,
            now.hour,
          );

          print('DEBUG: Processing hour $hour, current hour ${now.hour}');

          if (reminderHour.isBefore(currentHour)) {
            // Past hour - fully completed
            currentPosition += hourGroupHeight;
            print('DEBUG: Hour $hour is past - fully completed');
          } else if (reminderHour.isAtSameMomentAs(currentHour)) {
            // Current hour - calculate progress within this hour
            print('DEBUG: In current hour $hour');

            // Get all scheduled times in this hour and sort them
            List<DateTime> scheduledTimes = [];
            for (var reminder in hourReminders) {
              Map<String, dynamic> data =
                  reminder.data() as Map<String, dynamic>;
              DateTime? scheduledTime = _getScheduledDateTime(data);
              if (scheduledTime != null &&
                  scheduledTime.year == year &&
                  scheduledTime.month == month &&
                  scheduledTime.day == day &&
                  scheduledTime.hour == hour) {
                scheduledTimes.add(scheduledTime);
                print(
                  'DEBUG: Found reminder at ${scheduledTime.hour}:${scheduledTime.minute}',
                );
              }
            }

            scheduledTimes.sort((a, b) => a.compareTo(b));

            if (scheduledTimes.isEmpty) {
              // No specific times, use simple minute progress
              double minuteProgress = now.minute / 60.0;
              currentPosition += hourGroupHeight * minuteProgress;
              print(
                'DEBUG: No specific times, minute progress: $minuteProgress',
              );
            } else {
              // Calculate progress based on scheduled reminder times
              double progressWithinHour = 0.0;

              // Find the current position among scheduled reminders
              int currentReminderIndex = -1;
              for (int j = 0; j < scheduledTimes.length; j++) {
                if (now.isBefore(scheduledTimes[j])) {
                  currentReminderIndex = j - 1; // Previous reminder index
                  break;
                }
              }

              // If we didn't find a future reminder, we're past all reminders
              if (currentReminderIndex == -1) {
                if (now.isAfter(scheduledTimes.last) ||
                    now.isAtSameMomentAs(scheduledTimes.last)) {
                  currentReminderIndex =
                      scheduledTimes.length - 1; // Last reminder
                } else {
                  currentReminderIndex = -1; // Before first reminder
                }
              }

              print(
                'DEBUG: Current reminder index: $currentReminderIndex of ${scheduledTimes.length}',
              );

              if (currentReminderIndex == -1) {
                // Before first reminder
                DateTime firstReminder = scheduledTimes.first;
                if (now.minute <= firstReminder.minute) {
                  // Progress from start of hour to current time, but only up to first reminder position
                  double currentProgress = now.minute / 60.0;
                  double firstReminderProgress = firstReminder.minute / 60.0;
                  progressWithinHour =
                      (currentProgress / firstReminderProgress) *
                      firstReminderProgress;
                  progressWithinHour = progressWithinHour.clamp(
                    0.0,
                    firstReminderProgress,
                  );
                } else {
                  progressWithinHour = firstReminder.minute / 60.0;
                }
              } else if (currentReminderIndex == scheduledTimes.length - 1) {
                // After last reminder
                DateTime lastReminder = scheduledTimes.last;
                if (now.isAfter(lastReminder)) {
                  double lastReminderProgress = lastReminder.minute / 60.0;
                  double currentProgress = now.minute / 60.0;
                  progressWithinHour =
                      lastReminderProgress +
                      ((currentProgress - lastReminderProgress) *
                          0.5); // Slow progress after last reminder
                  progressWithinHour = progressWithinHour.clamp(0.0, 1.0);
                } else {
                  progressWithinHour = lastReminder.minute / 60.0;
                }
              } else {
                // Between two reminders
                DateTime currentReminder = scheduledTimes[currentReminderIndex];
                DateTime nextReminder =
                    scheduledTimes[currentReminderIndex + 1];

                double currentReminderProgress = currentReminder.minute / 60.0;
                double nextReminderProgress = nextReminder.minute / 60.0;

                // Calculate progress between these two reminders
                Duration totalSegment = nextReminder.difference(
                  currentReminder,
                );
                Duration elapsedSegment = now.difference(currentReminder);

                if (totalSegment.inMinutes > 0) {
                  double segmentProgress =
                      elapsedSegment.inMinutes / totalSegment.inMinutes;
                  segmentProgress = segmentProgress.clamp(0.0, 1.0);
                  double segmentSize =
                      nextReminderProgress - currentReminderProgress;
                  progressWithinHour =
                      currentReminderProgress + (segmentSize * segmentProgress);
                } else {
                  progressWithinHour = currentReminderProgress;
                }
              }

              progressWithinHour = progressWithinHour.clamp(0.0, 1.0);
              currentPosition += hourGroupHeight * progressWithinHour;
              print('DEBUG: Progress within hour: $progressWithinHour');
            }

            break; // Stop here as we've reached current hour
          } else {
            // Future hour - don't add to position
            print('DEBUG: Hour $hour is in future - stopping');
            break;
          }
        } catch (e) {
          print('Error parsing hour key: $hourKey - $e');
          continue;
        }
      }
    }

    // Return progress as a percentage of total height
    if (totalHeight == 0) return 0.0;
    double finalProgress = (currentPosition / totalHeight).clamp(0.0, 1.0);
    print(
      'DEBUG: Final progress: $finalProgress (${currentPosition}px / ${totalHeight}px)',
    );
    return finalProgress;
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
  }

  // Helper method to determine if a reminder is overdue
  bool _isReminderOverdue(Map<String, dynamic> reminderData) {
    try {
      DateTime now = DateTime.now();

      // Check if already disabled/completed
      if (reminderData['isDisabled'] == true ||
          reminderData['status'] == 'completed') {
        return false;
      }

      // Try to get scheduled date time
      if (reminderData['scheduledDateTime'] != null) {
        Timestamp timestamp = reminderData['scheduledDateTime'] as Timestamp;
        DateTime scheduledTime = timestamp.toDate();
        return scheduledTime.isBefore(now);
      } else {
        // Parse from date and time strings
        String dateStr = reminderData['date'] ?? '';
        String timeStr = reminderData['time'] ?? '';

        DateTime? parsedDate = _parseDateString(dateStr);
        DateTime parsedTime = _parseTimeString(timeStr);

        if (parsedDate != null) {
          DateTime scheduledDateTime = DateTime(
            parsedDate.year,
            parsedDate.month,
            parsedDate.day,
            parsedTime.hour,
            parsedTime.minute,
          );
          return scheduledDateTime.isBefore(now);
        }
      }

      return false;
    } catch (e) {
      print('Error checking if reminder is overdue: $e');
      return false;
    }
  }

  // Build grouped reminders for same time
  Widget _buildGroupedReminders(List<DocumentSnapshot> reminders) {
    if (reminders.length == 1) {
      // Single reminder - use existing layout
      DocumentSnapshot doc = reminders.first;
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      bool isOverdue = _isReminderOverdue(data);
      bool isCompleted = data['isDisabled'] == true;

      return _buildSingleProgressTimelineItem(
        data,
        doc.id,
        isOverdue: isOverdue,
        isCompleted: isCompleted,
        itemIndex: 0,
        totalItems: 1,
        overallProgress: 0.0,
      );
    } else {
      // Multiple reminders in same hour - create grouped layout
      Map<String, dynamic> firstReminderData =
          reminders.first.data() as Map<String, dynamic>;

      // Calculate dynamic height based on number of reminders
      double cardHeight = 60.0; // Height of each task card
      double cardSpacing = 10.0; // Reduced spacing between cards
      double totalCardsHeight =
          (reminders.length * cardHeight) +
          ((reminders.length - 1) * cardSpacing);

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Single time frame for the group with dynamic height
            _buildSimplifiedTimeFrame(
              firstReminderData,
              height: totalCardsHeight,
            ),

            const SizedBox(width: 8),

            // Multiple task cards in column with reduced spacing
            Expanded(
              child: Column(
                children:
                    reminders.asMap().entries.map((entry) {
                      int index = entry.key;
                      DocumentSnapshot reminder = entry.value;
                      Map<String, dynamic> data =
                          reminder.data() as Map<String, dynamic>;
                      bool isOverdue = _isReminderOverdue(data);
                      bool isCompleted = data['isDisabled'] == true;

                      return Container(
                        margin: EdgeInsets.only(
                          bottom:
                              index < reminders.length - 1 ? cardSpacing : 0,
                        ),
                        child: _buildTaskCard(
                          data,
                          reminder.id,
                          isOverdue: isOverdue,
                          isCompleted: isCompleted,
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      );
    }
  }

  // Also update the _buildSimplifiedTimeFrame method to better handle dynamic heights
  Widget _buildSimplifiedTimeFrame(
    Map<String, dynamic> reminderData, {
    double height = 80,
  }) {
    Map<String, dynamic> timeFrame = _getSimplifiedTimeFrame(reminderData);
    bool isCurrentFrame = timeFrame['isCurrentFrame'];
    bool isOverdue = _isReminderOverdue(reminderData);
    bool isCompleted = reminderData['isDisabled'] ?? false;

    // Calculate line position if this is the current frame
    double linePosition = 0.0;
    if (isCurrentFrame) {
      linePosition = _getCurrentTimeLinePosition(
        timeFrame['startTime'],
        timeFrame['endTime'],
        timeFrame['actualScheduledTime'],
      );
    }

    // Determine colors based on status
    Color frameColor = const Color(0xFF8E8E93);
    Color dotColor = const Color(0xFF4CAF50);

    if (isCompleted) {
      // frameColor = Colors.grey;
      // dotColor = Colors.grey;
    } else if (isOverdue) {
      frameColor = Colors.red;
      dotColor = Colors.red;
    } else if (isCurrentFrame) {
      frameColor = AppColors.textColor;
      dotColor = AppColors.textColor;
    }

    // Adjust line height based on container height
    double lineHeight = height - 24; // Subtract top and bottom padding
    double lineTopOffset = 12; // Half of the 24 total padding

    return SizedBox(
      width: 60,
      height: height,
      child: Stack(
        children: [
          // Left side - time labels
          Positioned(
            left: 0,
            top: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Start time
                Text(
                  timeFrame['startFormatted'],
                  style: TextStyle(
                    fontSize: 8,
                    color: frameColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),

                // Status indicator
                if (isOverdue && !isCompleted)
                  Text(
                    'Overdue',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),

          // Positioned(
          //   right: 8,
          //   top: lineTopOffset,
          //   child: Container(
          //     width: 30, // ADD THIS: Specify explicit width
          //     height: lineHeight,
          //     child: Stack(
          //       children: [
          //         // Background line
          //         Positioned(
          //           left: 2,
          //           top: 0,
          //           child: Container(
          //             width: 2,
          //             height: lineHeight,
          //             decoration: BoxDecoration(
          //               color: frameColor.withOpacity(0.3),
          //               borderRadius: BorderRadius.circular(1),
          //             ),
          //           ),
          //         ),

          //         // Progress line for current frame
          //         if (isCurrentFrame && !isCompleted)
          //           Positioned(
          //             left: 2,
          //             top: 0,
          //             child: Container(
          //               width: 2,
          //               height: lineHeight * linePosition,
          //               decoration: BoxDecoration(
          //                 color: const Color(0xFF4CAF50),
          //                 borderRadius: BorderRadius.circular(1),
          //                 boxShadow: [
          //                   BoxShadow(
          //                     color: const Color(0xFF4CAF50).withOpacity(0.4),
          //                     blurRadius: 3,
          //                     spreadRadius: 1,
          //                   ),
          //                 ],
          //               ),
          //             ),
          //           ),

          //         // Completed line
          //         if (isCompleted)
          //           Positioned(
          //             left: 2,
          //             top: 0,
          //             child: Container(
          //               width: 2,
          //               height: lineHeight,
          //               decoration: BoxDecoration(
          //                 color: Colors.grey,
          //                 borderRadius: BorderRadius.circular(1),
          //               ),
          //             ),
          //           ),

          //         // Top dot
          //         Positioned(
          //           left: 0,
          //           top: -3,
          //           child: Container(
          //             width: 6,
          //             height: 6,
          //             decoration: BoxDecoration(
          //               color: dotColor,
          //               shape: BoxShape.circle,
          //               border: Border.all(color: Colors.white, width: 1),
          //               boxShadow: [
          //                 BoxShadow(
          //                   color: dotColor.withOpacity(0.3),
          //                   blurRadius: 2,
          //                   spreadRadius: 1,
          //                 ),
          //               ],
          //             ),
          //           ),
          //         ),

          //         // Bottom dot
          //         // Positioned(
          //         //   left: 0,
          //         //   bottom: -3,
          //         //   child: Container(
          //         //     width: 6,
          //         //     height: 6,
          //         //     decoration: BoxDecoration(
          //         //       color: frameColor.withOpacity(0.6),
          //         //       shape: BoxShape.circle,
          //         //       border: Border.all(color: Colors.white, width: 1),
          //         //     ),
          //         //   ),
          //         // ),

          //         // Current time indicator line
          //         // if (isCurrentFrame && !isCompleted)
          //         //   Positioned(
          //         //     left: -12,
          //         //     top: (lineHeight * linePosition) - 1,
          //         //     child: Container(
          //         //       width: 24,
          //         //       height: 2,
          //         //       decoration: BoxDecoration(
          //         //         color: const Color(0xFF4CAF50),
          //         //         borderRadius: BorderRadius.circular(1),
          //         //         boxShadow: [
          //         //           BoxShadow(
          //         //             color: const Color(0xFF4CAF50).withOpacity(0.6),
          //         //             blurRadius: 4,
          //         //             spreadRadius: 1,
          //         //           ),
          //         //         ],
          //         //       ),
          //         //     ),
          //         //   ),
          //       ],
          //     ),
          //   ),
          // ),

          // End time label
          // Positioned(
          //   left: -20,
          //   bottom: 0,
          //   child: Text(
          //     timeFrame['endFormatted'],
          //     style: TextStyle(
          //       fontSize: 9,
          //       color: frameColor.withOpacity(0.7),
          //       fontWeight: FontWeight.w500,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  // Extract task card building logic
  Widget _buildTaskCard(
    Map<String, dynamic> reminderData,
    String reminderId, {
    bool isOverdue = false,
    bool isCompleted = false,
  }) {
    String reminderType = reminderData['reminderType'] ?? 'Call';
    String? leadName = reminderData['leadName']; // Can be null
    String property = reminderData['property'] ?? '';
    String note = reminderData['note'] ?? '';
    String customNotes = reminderData['customNotes'] ?? '';
    String combinedNotes = reminderData['combinedNotes'] ?? '';
    String scheduledDate = reminderData['date'] ?? '';
    String scheduledTime = reminderData['time'] ?? '';
    bool isDisabled = reminderData['isDisabled'] ?? false;

    // Handle prefilledNotes array
    List<dynamic> prefilledNotesArray = reminderData['prefilledNotes'] ?? [];
    List<String> prefilledNotes =
        prefilledNotesArray
            .map((note) => note.toString())
            .where((note) => note.isNotEmpty)
            .toList();

    Color categoryColor = _getCategoryColor(reminderType);

    if (isOverdue && !isDisabled) {
      categoryColor = Colors.red;
    } else if (isCompleted) {
      // categoryColor = Colors.grey;
    }

    List<String> tasks = [];

    // Add property if available
    if (property.isNotEmpty) {
      tasks.add('$property');
    }

    // Add all prefilled notes
    for (String prefilledNote in prefilledNotes) {
      tasks.add(prefilledNote);
    }

    // Add custom notes if available and different from combined notes
    if (customNotes.isNotEmpty && customNotes != combinedNotes) {
      tasks.add(customNotes);
    }

    // Add regular note if available
    if (note.isNotEmpty) {
      tasks.add(note);
    }

    // Fallback if no tasks
    if (tasks.isEmpty) {
      tasks.add('No additional details');
    }

    return Dismissible(
      key: Key(reminderId),
      direction:
          isDisabled
              ? DismissDirection.endToStart
              : DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (isDisabled) return false;
          return await _showDisableConfirmation(leadName ?? '');
        } else if (direction == DismissDirection.endToStart) {
          return await _showRescheduleDialog(leadName ?? "", reminderId);
        }
        return false;
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (!isDisabled) {
            await _disableReminderInFirestore(reminderId);
            setState(() {});
          }
        } else if (direction == DismissDirection.endToStart) {
          setState(() {});
        }
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            bottomLeft: Radius.circular(25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 6),
            Text(
              'Complete',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Reschedule',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.schedule, color: Colors.blue, size: 20),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ReminderDetailsScreen(
                    reminderId: reminderId,
                    reminderData: reminderData,
                    leadProperties: [],
                  ),
            ),
          );
        },
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F3),
            borderRadius: BorderRadius.circular(25),
            border:
                isOverdue && !isDisabled
                    ? Border.all(color: Colors.red, width: 1)
                    : null,
            boxShadow: [
              BoxShadow(
                color: (Colors.grey).withOpacity(0.4),
                offset: const Offset(0, 4),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Row(
              children: [
                // Left colored category section
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        categoryColor.withOpacity(0.9),
                        categoryColor,
                        categoryColor.withOpacity(0.8),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isOverdue && !isDisabled)
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 12,
                          ),

                        Text(
                          reminderType,
                          style: TextStyle(
                            color:
                                isOverdue ? Colors.white : AppColors.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (leadName != null &&
                            leadName!.trim().isNotEmpty) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  leadName!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color:
                                        isDisabled
                                            ? const Color(
                                              0xFF2D3A5A,
                                            ).withOpacity(0.7)
                                            : const Color(0xFF2D3A5A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "• ",
                                          style: TextStyle(
                                            fontSize: 9,
                                            color:
                                                isDisabled
                                                    ? const Color(
                                                      0xFF8E8E93,
                                                    ).withOpacity(0.7)
                                                    : isOverdue
                                                    ? Colors.grey[500]
                                                    : const Color(0xFF8E8E93),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            " $scheduledTime ",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  isDisabled
                                                      ? AppColors.textColor
                                                      : isOverdue
                                                      ? AppColors.textColor
                                                      : AppColors.textColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "• ",
                                  style: TextStyle(
                                    fontSize: 9,
                                    color:
                                        isDisabled
                                            ? const Color(
                                              0xFF8E8E93,
                                            ).withOpacity(0.7)
                                            : isOverdue
                                            ? Colors.grey[500]
                                            : const Color(0xFF8E8E93),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    " $scheduledTime ",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          isDisabled
                                              ? AppColors.textColor
                                              : isOverdue
                                              ? AppColors.textColor
                                              : AppColors.textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child:
                                Container(), // Empty container or add other content here
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Action buttons section
                // Only show WhatsApp and Call buttons if leadName is not empty
                if (leadName != null && leadName.trim().isNotEmpty)
                  Container(
                    width: 90,
                    padding: const EdgeInsets.only(right: 8, top: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AbsorbPointer(
                          absorbing: isDisabled,
                          child: _neumorphicIconButton(
                            AppImages.whatsappIcon,
                            () =>
                                isDisabled
                                    ? null
                                    : _openWhatsApp(leadName, reminderId),
                            isDisabled: isDisabled,
                            isOverdue: isOverdue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AbsorbPointer(
                          absorbing: isDisabled,
                          child: _neumorphicIconButton(
                            AppImages.callIcon,
                            () =>
                                isDisabled
                                    ? null
                                    : _makePhoneCall(leadName, reminderId),
                            isDisabled: isDisabled,
                            isOverdue: isOverdue,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Update your existing _rescheduleReminderInFirestore method
  Future<void> _rescheduleReminderInFirestore(
    String reminderId,
    DateTime newDate,
    TimeOfDay newTime,
  ) async {
    try {
      // Combine date and time
      final scheduledDateTime = DateTime(
        newDate.year,
        newDate.month,
        newDate.day,
        newTime.hour,
        newTime.minute,
      );

      await FirebaseFirestore.instance
          .collection('reminders')
          .doc(reminderId)
          .update({
            'date': '${newDate.day}/${newDate.month}/${newDate.year}',
            'time': newTime.format(context),
            'scheduledDateTime': Timestamp.fromDate(scheduledDateTime),
            'rescheduledAt': FieldValue.serverTimestamp(),
            'status': 'pending',
            'isDisabled': false,
          });

      // Schedule new notification
      await _scheduleNotificationForReminder(reminderId, scheduledDateTime);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder rescheduled successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reschedule reminder: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // New method to schedule notification for a reminder
  Future<void> _scheduleNotificationForReminder(
    String reminderId,
    DateTime scheduledDateTime, {
    Map<String, dynamic>? reminderData,
  }) async {
    try {
      // If reminderData is not provided, fetch it from Firestore
      if (reminderData == null) {
        DocumentSnapshot doc =
            await FirebaseFirestore.instance
                .collection('reminders')
                .doc(reminderId)
                .get();

        if (!doc.exists) return;
        reminderData = doc.data() as Map<String, dynamic>;
      }

      String leadName = reminderData['leadName'] ?? 'Unknown Lead';
      String reminderType = reminderData['reminderType'] ?? 'Reminder';
      String property = reminderData['property'] ?? '';

      String title = '$reminderType Reminder';
      String body = 'Time to contact $leadName';

      if (property.isNotEmpty) {
        body += ' about $property';
      }

      print(
        'Notification scheduled for reminder $reminderId at $scheduledDateTime',
      );
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  // Update your existing _disableReminderInFirestore method
  Future<void> _disableReminderInFirestore(String reminderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('reminders')
          .doc(reminderId)
          .update({
            'isDisabled': true,
            'status': 'completed',
            'disabledAt': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder completed successfully'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update reminder: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
        automaticallyImplyLeading: false,
      ),
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(color: AppColors.taroGrey),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header and Calendar Container
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserHeader(context),
                    CalendarDatePicker(
                      shouldResetToToday: _shouldResetCalendar,
                      onDateSelected: (DateTime selectedDate) {
                        _filterRemindersByDate(selectedDate);
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              // Bottom section with corner radius
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: _buildTasksSection(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Improved date parsing that handles multiple formats
  DateTime? _parseDateString(String dateStr) {
    if (dateStr.isEmpty) return null;

    try {
      // Handle different date formats
      if (dateStr.contains('/')) {
        List<String> parts = dateStr.split('/');
        if (parts.length == 3) {
          int day, month, year;

          // Handle both MM/dd/yyyy and dd/MM/yyyy formats
          // Since your data shows formats like "08/06/2025" and "28/6/2025"
          // We need to determine the format based on the values

          int firstPart = int.parse(parts[0]);
          int secondPart = int.parse(parts[1]);
          year = int.parse(parts[2]);

          // If first part > 12, it's likely dd/MM/yyyy format
          // If second part > 12, it's likely MM/dd/yyyy format
          if (firstPart > 12) {
            // dd/MM/yyyy format
            day = firstPart;
            month = secondPart;
          } else if (secondPart > 12) {
            // MM/dd/yyyy format
            month = firstPart;
            day = secondPart;
          } else {
            // Ambiguous case, assume MM/dd/yyyy (US format)
            month = firstPart;
            day = secondPart;
          }

          return DateTime(year, month, day);
        }
      }
      // Handle ISO format as fallback
      else if (dateStr.contains('-')) {
        return DateTime.parse(dateStr);
      }
    } catch (e) {
      print('Error parsing date: $dateStr - $e');
    }

    return null;
  }

  // Parse time string (handles 12-hour format like "12:13 PM")
  DateTime _parseTimeString(String timeStr) {
    try {
      // Handle 12-hour format (e.g., "12:13 PM", "7:00 PM")
      final regex = RegExp(
        r'(\d{1,2}):(\d{2})\s*(AM|PM)',
        caseSensitive: false,
      );
      final match = regex.firstMatch(timeStr.trim());

      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);
        String period = match.group(3)!.toUpperCase();

        // Convert to 24-hour format
        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }

        return DateTime(
          2000,
          1,
          1,
          hour,
          minute,
        ); // Use dummy date for time comparison
      }

      // Fallback for 24-hour format or other formats
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      }
    } catch (e) {
      print('Error parsing time: $timeStr - $e');
    }

    // Default fallback time
    return DateTime(2000, 1, 1, 12, 0);
  }

  String _formatDateForComparison(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Filter indicator widget
  Widget _buildFilterIndicator() {
    List<String> activeFilters = [];

    // Add date filter info
    if (_selectedFilterDate != null) {
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime selectedDay = DateTime(
        _selectedFilterDate!.year,
        _selectedFilterDate!.month,
        _selectedFilterDate!.day,
      );

      if (selectedDay.isAtSameMomentAs(today)) {
        activeFilters.add('Today');
      } else {
        activeFilters.add(_formatSelectedDate(_selectedFilterDate!));
      }
    } else {
      activeFilters.add('All dates');
    }

    // Add status filter info
    switch (_reminderFilter) {
      case ReminderFilter.all:
        activeFilters.add('Active reminders');
        break;
      case ReminderFilter.completed:
        activeFilters.add('Completed');
        break;
      case ReminderFilter.overdue:
        activeFilters.add('Overdue');
        break;
    }

    // Show filter indicator if not showing "Today + Active reminders"
    bool isDefaultFilter =
        _selectedFilterDate != null &&
        _isToday(_formatDateForComparison(_selectedFilterDate!)) &&
        _reminderFilter == ReminderFilter.all;

    if (isDefaultFilter) {
      return SizedBox.shrink(); // Hide for default state
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.textColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list, size: 18, color: AppColors.textColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Showing: ${activeFilters.join(' • ')}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              // Reset to default state
              _resetToToday();
              setState(() {
                _reminderFilter = ReminderFilter.all;
              });
            },
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.textColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.clear, size: 14, color: AppColors.textColor),
            ),
          ),
        ],
      ),
    );
  }

  // Format selected date
  String _formatSelectedDate(DateTime date) {
    List<String> monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    try {
      if (currentUser != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser!.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          setState(() {
            firstName = userData['firstName'] ?? 'User';
            lastName = userData['lastName'] ?? 'User';
            userEmail = userData['email'] ?? currentUser!.email ?? 'No email';
            userInitials = _getInitials('$firstName $lastName');
          });
        } else {
          setState(() {
            firstName = currentUser!.displayName ?? 'User';
            userEmail = currentUser!.email ?? 'No email';
            userInitials = _getInitials(firstName);
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (currentUser != null) {
        setState(() {
          firstName = currentUser!.displayName ?? 'User';
          userEmail = currentUser!.email ?? 'No email';
          userInitials = _getInitials(firstName);
        });
      }
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty || name == 'Loading...') return '';

    List<String> names = name.trim().split(' ');
    if (names.length == 1) {
      return names[0].substring(0, 1).toUpperCase();
    } else {
      return '${names[0].substring(0, 1)}${names[names.length - 1].substring(0, 1)}'
          .toUpperCase();
    }
  }

  Widget _buildUserHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final avatarSize = isSmallScreen ? 40.0 : 44.0;

    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 5,
        left: 15,
      ),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.black.withOpacity(0.1),
        color: AppColors.primaryGreen,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            print('Header tapped in RemainderScreen');
            print('onProfileTap is null: ${widget.onProfileTap == null}');
            if (widget.onProfileTap != null) {
              print('Calling onProfileTap');
              widget.onProfileTap!();
            } else {
              print('onProfileTap is null!');
            }
          },
          child: Container(
            padding: EdgeInsets.all(12), // Add padding for better tap area
            child: Row(
              mainAxisSize: MainAxisSize.min, // Important!
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(0xFF14A76C),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      userInitials.isNotEmpty ? userInitials : 'CJ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$firstName $lastName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Check if a date is today
  bool _isToday(String dateStr) {
    if (dateStr.isEmpty) return false;

    try {
      DateTime today = DateTime.now();
      DateTime? reminderDate = _parseDateString(dateStr);

      if (reminderDate != null) {
        return reminderDate.year == today.year &&
            reminderDate.month == today.month &&
            reminderDate.day == today.day;
      }

      return false;
    } catch (e) {
      print('Error checking if today: $dateStr - $e');
      return false;
    }
  }

  // Empty state when no reminders found
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No reminders found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your reminders will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Empty state when filter returns no results
  Widget _buildEmptyFilterState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No reminders found for selected date',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different date or clear the filter',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build overdue section header
  Widget _buildOverdueSectionHeader(int overdueCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border(left: BorderSide(color: Colors.red, width: 4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Text(
            'Overdue ($overdueCount)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),

          // Dropdown button on the right
        ],
      ),
    );
  }

  Widget buildDropdownContainer() {
    // Calculate width based on selected filter
    double getDropdownWidth() {
      switch (_reminderFilter) {
        case ReminderFilter.all:
          return 70.0; // Smaller width for "All"
        case ReminderFilter.completed:
          return 110.0; // Medium width for "Completed"
        case ReminderFilter.overdue:
          return 95.0; // Medium width for "Overdue"
        default:
          return 70.0;
      }
    }

    // Get icon based on selected filter
    Widget getSelectedIcon() {
      switch (_reminderFilter) {
        case ReminderFilter.all:
          return Icon(Icons.list_alt, size: 12, color: Colors.blue);
        case ReminderFilter.completed:
          return Icon(
            Icons.check_circle_outline,
            size: 12,
            color: Colors.green,
          );
        case ReminderFilter.overdue:
          return Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red);
        default:
          return Icon(Icons.list_alt, size: 12, color: Colors.blue);
      }
    }

    // Get text based on selected filter
    String getSelectedText() {
      switch (_reminderFilter) {
        case ReminderFilter.all:
          return 'All';
        case ReminderFilter.completed:
          return 'Completed';
        case ReminderFilter.overdue:
          return 'Overdue';
        default:
          return 'All';
      }
    }

    return Container(
      width: getDropdownWidth(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ReminderFilter>(
          value: _reminderFilter,
          isDense: true,
          icon: Icon(
            Icons.arrow_drop_down,
            size: 11,
            color: Colors.grey.shade700,
          ),
          selectedItemBuilder: (BuildContext context) {
            return ReminderFilter.values.map((ReminderFilter filter) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  getSelectedIcon(),
                  const SizedBox(width: 4),
                  Text(
                    getSelectedText(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3A5A),
                    ),
                  ),
                ],
              );
            }).toList();
          },
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
          items: [
            DropdownMenuItem(
              value: ReminderFilter.all,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.list_alt, size: 8, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    'All',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3A5A),
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: ReminderFilter.completed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 8,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3A5A),
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: ReminderFilter.overdue,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 8, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    'Overdue',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3A5A),
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (ReminderFilter? newValue) {
            if (newValue != null) {
              _setReminderFilter(newValue);
            }
          },
        ),
      ),
    );
  }

  // Replace your _buildTasksSection method with this updated version:
  Widget _buildTasksSection() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed header with "Time" and "Tasks" labels and dropdown
          Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Row(
              children: [
                // Time label (aligned with time column)
                Container(
                  width: 60, // Same width as time column
                  child: Text(
                    'Time',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3A5A),
                    ),
                  ),
                ),

                SizedBox(width: 8),

                // Tasks label (aligned with start of cards)
                Expanded(
                  child: Text(
                    'Tasks',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3A5A),
                    ),
                  ),
                ),

                // Dropdown on the right
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: buildDropdownContainer(),
                ),
              ],
            ),
          ),

          // Scrollable task list with cached data
          Expanded(child: _buildRemindersList()),
        ],
      ),
    );
  }

  // New method to build reminders list using cached data
  Widget _buildRemindersList() {
    if (_isLoadingReminders) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
        ),
      );
    }

    if (_cachedReminders.isEmpty) {
      return _buildEmptyState();
    }

    // Use filtered reminders if any filters are active, otherwise use all
    List<DocumentSnapshot> displayReminders = _filteredReminders;

    if (displayReminders.isEmpty) {
      return _buildEmptyFilterState();
    }

    // Separate reminders into categories
    List<DocumentSnapshot> overdueReminders = [];
    List<DocumentSnapshot> currentDateTasks = [];
    List<DocumentSnapshot> otherTasks = [];

    for (var doc in displayReminders) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      if (_isReminderOverdue(data)) {
        overdueReminders.add(doc);
      } else {
        String dateStr = data['date'] ?? '';
        if (_isToday(dateStr)) {
          currentDateTasks.add(doc);
        } else {
          otherTasks.add(doc);
        }
      }
    }

    // Sort reminders chronologically
    overdueReminders.sort((a, b) {
      Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
      Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;
      DateTime? timeA = _getScheduledDateTime(dataA);
      DateTime? timeB = _getScheduledDateTime(dataB);

      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;

      return timeA.compareTo(timeB);
    });

    currentDateTasks.sort((a, b) {
      Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
      Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;
      DateTime? timeA = _getScheduledDateTime(dataA);
      DateTime? timeB = _getScheduledDateTime(dataB);

      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;

      return timeA.compareTo(timeB);
    });

    otherTasks.sort((a, b) {
      Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
      Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;
      DateTime? timeA = _getScheduledDateTime(dataA);
      DateTime? timeB = _getScheduledDateTime(dataB);

      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;

      return timeA.compareTo(timeB);
    });

    // Combine all reminders in order
    List<DocumentSnapshot> allReminders = [
      ...overdueReminders,
      ...currentDateTasks,
      ...otherTasks,
    ];
    // Group reminders by hour
    Map<String, List<DocumentSnapshot>> groupedReminders =
        _groupRemindersByHour(allReminders);

    // Sort the grouped reminders by time
    List<String> sortedHourKeys = groupedReminders.keys.toList();
    sortedHourKeys.sort((a, b) {
      if (a == 'unknown-time') return 1;
      if (b == 'unknown-time') return -1;

      List<String> partsA = a.split('-');
      List<String> partsB = b.split('-');

      if (partsA.length >= 4 && partsB.length >= 4) {
        DateTime dateA = DateTime(
          int.parse(partsA[0]), // year
          int.parse(partsA[1]), // month
          int.parse(partsA[2]), // day
          int.parse(partsA[3]), // hour
        );
        DateTime dateB = DateTime(
          int.parse(partsB[0]), // year
          int.parse(partsB[1]), // month
          int.parse(partsB[2]), // day
          int.parse(partsB[3]), // hour
        );
        return dateA.compareTo(dateB);
      }
      return a.compareTo(b);
    });

    // Calculate time-based progress with real-time updates aligned to reminder cards
    DateTime now = DateTime.now();
    double timeBasedProgress = _calculateRealTimeProgress(
      allReminders,
      sortedHourKeys,
      groupedReminders,
    );
    int passedItems = 0;
    String progressText = 'No reminders';

    if (allReminders.isNotEmpty) {
      // Calculate how many reminders should have passed by now
      for (var doc in allReminders) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DateTime? scheduledTime = _getScheduledDateTime(data);

        if (scheduledTime != null && scheduledTime.isBefore(now)) {
          passedItems++;
        }
      }

      // Create progress text with time information
      int totalItems = allReminders.length;
      int remainingItems = totalItems - passedItems;

      // Add current time to progress text
      String currentTimeStr =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      if (passedItems == 0) {
        progressText = 'All upcoming • $currentTimeStr';
      } else if (passedItems == totalItems) {
        progressText = 'All completed • $currentTimeStr';
      } else {
        progressText =
            '$passedItems passed • $remainingItems upcoming • $currentTimeStr';
      }
    }

    return Column(
      children: [
        // Main scrollable content
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 20.0,
            ),
            child: Stack(
              children: [
                // Single Continuous Time-Based Progress Bar with real-time updates
                Positioned(
                  left: 56,
                  top: overdueReminders.isNotEmpty ? 50 : 0,
                  bottom: 0,
                  child: Container(
                    width: 6,
                    height: sortedHourKeys.length * 96.0,
                    child: Column(
                      children: [
                        // Passed time section (top)
                        Expanded(
                          flex: (timeBasedProgress * 100).round(),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.textColor.withOpacity(0.9),
                                  AppColors.textColor,
                                  AppColors.textColor,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.textColor.withOpacity(0.1),
                                  blurRadius: 1,
                                  spreadRadius: 1,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Future time section (bottom)
                        Expanded(
                          flex: ((1.0 - timeBasedProgress) * 100).round(),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white,
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.5),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.grey.shade400,
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content that scrolls
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overdue section header (now appears below the dropdown)
                    if (overdueReminders.isNotEmpty) ...[
                      _buildOverdueSectionHeader(overdueReminders.length),
                      // const SizedBox(height: 8),
                    ],

                    // All grouped reminders with timeline dots and dynamic dividers
                    ...sortedHourKeys.map((hourKey) {
                      List<DocumentSnapshot> hourReminders =
                          groupedReminders[hourKey]!;

                      return Column(
                        children: [
                          _buildGroupedReminders(hourReminders),
                          // const SizedBox(height: 8),
                        ],
                      );
                    }).toList(),

                    // If no tasks at all, show empty state
                    if (sortedHourKeys.isEmpty)
                      Container(
                        height: 200,
                        child: Center(child: Text('No tasks to display')),
                      ),

                    // Add some bottom padding
                    // const SizedBox(height: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getSimplifiedTimeFrame(
    Map<String, dynamic> reminderData,
  ) {
    try {
      DateTime? scheduledTime = _getScheduledDateTime(reminderData);

      if (scheduledTime != null) {
        DateTime roundedStartTime = DateTime(
          scheduledTime.year,
          scheduledTime.month,
          scheduledTime.day,
          scheduledTime.hour,
        );
        DateTime roundedEndTime = roundedStartTime.add(Duration(hours: 1));

        return {
          'startTime': roundedStartTime,
          'endTime': roundedEndTime,
          'startFormatted': _formatSimpleTime(roundedStartTime),
          'endFormatted': _formatSimpleTime(roundedEndTime),
          'isCurrentFrame': _isTimeInCurrentFrame(
            roundedStartTime,
            roundedEndTime,
          ),
          'actualScheduledTime': scheduledTime,
        };
      } else {
        String timeStr = reminderData['time'] ?? '12:00 PM';
        DateTime parsedTime = _parseTimeString(timeStr);
        DateTime now = DateTime.now();
        DateTime scheduledDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          parsedTime.hour,
        );
        DateTime endDateTime = scheduledDateTime.add(Duration(hours: 1));

        return {
          'startTime': scheduledDateTime,
          'endTime': endDateTime,
          'startFormatted': _formatSimpleTime(scheduledDateTime),
          'endFormatted': _formatSimpleTime(endDateTime),
          'isCurrentFrame': _isTimeInCurrentFrame(
            scheduledDateTime,
            endDateTime,
          ),
          'actualScheduledTime': DateTime(
            now.year,
            now.month,
            now.day,
            parsedTime.hour,
            parsedTime.minute,
          ),
        };
      }
    } catch (e) {
      print('Error getting simplified time frame: $e');
      DateTime now = DateTime.now();
      DateTime startTime = DateTime(now.year, now.month, now.day, 12);
      return {
        'startTime': startTime,
        'endTime': startTime.add(Duration(hours: 1)),
        'startFormatted': '12 PM',
        'endFormatted': '1 PM',
        'isCurrentFrame': false,
        'actualScheduledTime': startTime,
      };
    }
  }

  String _formatSimpleTime(DateTime dateTime) {
    int hour = dateTime.hour;
    int minute = dateTime.minute;
    String period = hour >= 12 ? 'PM' : 'AM';

    if (hour > 12) {
      hour -= 12;
    } else if (hour == 0) {
      hour = 12;
    }

    // Format minute with leading zero if needed
    String minuteStr = minute.toString().padLeft(2, '0');

    return '$hour:$minuteStr $period';
  }

  bool _isTimeInCurrentFrame(DateTime startTime, DateTime endTime) {
    DateTime now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  double _getCurrentTimeLinePosition(
    DateTime startTime,
    DateTime endTime,
    DateTime actualScheduledTime,
  ) {
    DateTime now = DateTime.now();

    if (now.isBefore(startTime)) {
      return 0.0;
    } else if (now.isAfter(endTime)) {
      return 1.0;
    } else {
      Duration totalDuration = endTime.difference(startTime);
      Duration elapsedDuration = now.difference(startTime);
      return elapsedDuration.inMilliseconds / totalDuration.inMilliseconds;
    }
  }

  Map<String, List<DocumentSnapshot>> _groupRemindersByHour(
    List<DocumentSnapshot> reminders,
  ) {
    Map<String, List<DocumentSnapshot>> groupedReminders = {};

    for (DocumentSnapshot reminder in reminders) {
      Map<String, dynamic> data = reminder.data() as Map<String, dynamic>;
      DateTime? scheduledTime = _getScheduledDateTime(data);

      if (scheduledTime != null) {
        // Create a key based on date and hour
        String hourKey =
            '${scheduledTime.year}-${scheduledTime.month}-${scheduledTime.day}-${scheduledTime.hour}';

        if (!groupedReminders.containsKey(hourKey)) {
          groupedReminders[hourKey] = [];
        }
        groupedReminders[hourKey]!.add(reminder);
      } else {
        // For reminders without proper datetime, use a default key
        String defaultKey = 'unknown-time';
        if (!groupedReminders.containsKey(defaultKey)) {
          groupedReminders[defaultKey] = [];
        }
        groupedReminders[defaultKey]!.add(reminder);
      }
    }

    return groupedReminders;
  }

  Widget _buildSimplifieedTimeFrame(
    Map<String, dynamic> reminderData, {
    double height = 80,
  }) {
    Map<String, dynamic> timeFrame = _getSimplifiedTimeFrame(reminderData);
    bool isCurrentFrame = timeFrame['isCurrentFrame'];
    bool isOverdue = _isReminderOverdue(reminderData);
    bool isCompleted = reminderData['isDisabled'] ?? false;

    // Calculate line position if this is the current frame
    double linePosition = 0.0;
    if (isCurrentFrame) {
      linePosition = _getCurrentTimeLinePosition(
        timeFrame['startTime'],
        timeFrame['endTime'],
        timeFrame['actualScheduledTime'],
      );
    }

    // Determine colors based on status
    Color frameColor = const Color(0xFF8E8E93);
    Color dotColor = const Color(0xFF4CAF50);

    if (isCompleted) {
      // frameColor = Colors.grey;
      // dotColor = Colors.grey;
    } else if (isOverdue) {
      frameColor = Colors.red;
      dotColor = Colors.red;
    } else if (isCurrentFrame) {
      frameColor = AppColors.textColor;
      dotColor = AppColors.textColor;
    }

    return SizedBox(
      width: 60,
      height: height,
      child: Stack(
        children: [
          // Left side - time labels
          Positioned(
            left: 0,
            top: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Start time
                Text(
                  timeFrame['startFormatted'],
                  style: TextStyle(
                    fontSize: 10,
                    color: frameColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),

                // Status indicator
                if (isOverdue && !isCompleted)
                  Text(
                    'Overdue',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),

          Positioned(
            right: 8,
            top: 8,
            child: Container(
              height: height - 16,
              child: Stack(
                children: [
                  Positioned(
                    left: 2,
                    top: 4,
                    child: Container(
                      width: 2,
                      height: height - 24,
                      decoration: BoxDecoration(
                        color: frameColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),

                  if (isCurrentFrame && !isCompleted)
                    Positioned(
                      left: 2,
                      top: 4,
                      child: Container(
                        width: 2,
                        height: (height - 24) * linePosition,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(1),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withOpacity(0.4),
                              blurRadius: 3,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Completed line
                  if (isCompleted)
                    Positioned(
                      left: 2,
                      top: 4,
                      child: Container(
                        width: 2,
                        height: height - 24,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),

                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: dotColor.withOpacity(0.3),
                            blurRadius: 2,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: frameColor.withOpacity(0.6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  ),

                  if (isCurrentFrame && !isCompleted)
                    Positioned(
                      left: -12,
                      top: 4 + ((height - 24) * linePosition) - 1,
                      child: Container(
                        width: 24,
                        height: 2,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(1),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withOpacity(0.6),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),

                  Positioned(
                    left: -20,
                    bottom: -2,
                    child: Text(
                      timeFrame['endFormatted'],
                      style: TextStyle(
                        fontSize: 9,
                        color: frameColor.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Updated _buildSingleProgressTimelineItem method (replace the time section part)
  Widget _buildSingleProgressTimelineItem(
    Map<String, dynamic> reminderData,
    String reminderId, {
    bool isOverdue = false,
    bool isCompleted = false,
    int itemIndex = 0,
    int totalItems = 1,
    double overallProgress = 0.0,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simplified time frame section
          _buildSimplifiedTimeFrame(reminderData, height: 80),

          const SizedBox(width: 8),

          // Task card
          Expanded(
            child: _buildTaskCard(
              reminderData,
              reminderId,
              isOverdue: isOverdue,
              isCompleted: isCompleted,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get scheduled DateTime from reminder data
  DateTime? _getScheduledDateTime(Map<String, dynamic> reminderData) {
    // First try to get from scheduledDateTime field
    if (reminderData['scheduledDateTime'] != null) {
      Timestamp timestamp = reminderData['scheduledDateTime'] as Timestamp;
      return timestamp.toDate();
    }

    // Fallback to parsing from separate date and time fields
    String dateStr = reminderData['date'] ?? '';
    String timeStr = reminderData['time'] ?? '';

    if (dateStr.isEmpty || timeStr.isEmpty) return null;

    try {
      DateTime? parsedDate = _parseDateString(dateStr);
      DateTime parsedTime = _parseTimeString(timeStr);

      if (parsedDate != null) {
        return DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
          parsedTime.hour,
          parsedTime.minute,
        );
      }
    } catch (e) {
      print('Error parsing scheduled DateTime: $e');
    }

    return null;
  }

  // Method to show reschedule dialog
  Future<bool?> _showRescheduleDialog(
    String leadName,
    String reminderId,
  ) async {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Reschedule Reminder'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Reschedule reminder for $leadName'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() {
                                selectedDate = date;
                              });
                            }
                          },
                          icon: Icon(Icons.calendar_today),
                          label: Text(
                            selectedDate != null
                                ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                : 'Select Date',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              setState(() {
                                selectedTime = time;
                              });
                            }
                          },
                          icon: Icon(Icons.access_time),
                          label: Text(
                            selectedTime != null
                                ? selectedTime!.format(context)
                                : 'Select Time',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      selectedDate != null && selectedTime != null
                          ? () async {
                            await _rescheduleReminderInFirestore(
                              reminderId,
                              selectedDate!,
                              selectedTime!,
                            );
                            Navigator.of(context).pop(true);
                          }
                          : null,
                  child: Text('Reschedule'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool?> _showDisableConfirmation(String leadName) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Complete Reminder'),
          content: Text(
            'Are you sure you want to complete the reminder for $leadName?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Complete'),
            ),
          ],
        );
      },
    );
  }

  // Update the _neumorphicIconButton method
  Widget _neumorphicIconButton(
    String svgAssetPath,
    VoidCallback? onTap, {
    bool isDisabled = false,
    bool isOverdue = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.taroGrey,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.textColor, width: 0.1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              offset: const Offset(4, 4),
              blurRadius: 6,
              spreadRadius: 1,
            ),
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-4, -4),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: SvgPicture.asset(
          svgAssetPath,
          fit: BoxFit.contain,
          colorFilter: isDisabled ? null : null,
        ),
      ),
    );
  }

  Color _getCategoryColor(String reminderType) {
    switch (reminderType.toLowerCase()) {
      case 'call':
        return const Color(0xFF48C9B0); // Teal
      case 'message':
        return const Color(0xFF58D68D); // Green
      case 'agreement':
        return const Color(0xFF5DADE2); // Blue
      case 'check':
        return const Color(0xFFAF7AC5); // Purple
      case 'site visit':
        return const Color(0xFFFF8A65); // Orange
      default:
        return const Color(0xFF607D8B); // Default grey-blue
    }
  }

  // Phone call functionality - directly fetch from Firebase
  Future<void> _makePhoneCall(String leadName, String reminderId) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Text('Getting phone number...'),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
        ),
      );

      String? phoneNumber = await _getPhoneNumberFromFirebase(leadName);

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

        if (await canLaunchUrl(launchUri)) {
          await launchUrl(launchUri);
          // Mark reminder as completed after successful call
          // await _markAsCompleted(reminderId);
        } else {
          _showErrorSnackBar('Could not launch phone dialer');
        }
      } else {
        _showErrorSnackBar('Phone number not found for $leadName');
      }
    } catch (e) {
      _showErrorSnackBar('Error making phone call: $e');
    }
  }

  // WhatsApp functionality - directly fetch from Firebase
  Future<void> _openWhatsApp(String leadName, String reminderId) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Text('Getting WhatsApp number...'),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF25D366),
          behavior: SnackBarBehavior.floating,
        ),
      );

      String? whatsappNumber = await _getWhatsAppNumberFromFirebase(leadName);

      if (whatsappNumber != null && whatsappNumber.isNotEmpty) {
        // Remove any special characters and ensure proper format
        String cleanNumber = whatsappNumber.replaceAll(RegExp(r'[^\d+]'), '');

        // Default message
        String message =
            "Hi $leadName, this is regarding your property inquiry. How can I help you today?";

        final Uri whatsappUri = Uri.parse(
          'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}',
        );

        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
          // Mark reminder as completed after successful WhatsApp open
          // await _markAsCompleted(reminderId);
        } else {
          _showErrorSnackBar('WhatsApp is not installed');
        }
      } else {
        _showErrorSnackBar('WhatsApp number not found for $leadName');
      }
    } catch (e) {
      _showErrorSnackBar('Error opening WhatsApp: $e');
    }
  }

  // Get phone number directly from Firebase
  Future<String?> _getPhoneNumberFromFirebase(String leadName) async {
    try {
      // First, try to get from leads collection
      QuerySnapshot leadQuery =
          await _firestore
              .collection('leads')
              .where('name', isEqualTo: leadName)
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

      if (leadQuery.docs.isNotEmpty) {
        Map<String, dynamic> leadData =
            leadQuery.docs.first.data() as Map<String, dynamic>;

        // Try multiple possible field names for phone number
        return leadData['phoneNumber'] ??
            leadData['phone'] ??
            leadData['mobileNumber'] ??
            leadData['contactNumber'];
      }

      // If not found in leads, try reminders collection (in case phone is stored there)
      QuerySnapshot reminderQuery =
          await _firestore
              .collection('reminders')
              .where('leadName', isEqualTo: leadName)
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

      if (reminderQuery.docs.isNotEmpty) {
        Map<String, dynamic> reminderData =
            reminderQuery.docs.first.data() as Map<String, dynamic>;

        return reminderData['phoneNumber'] ??
            reminderData['phone'] ??
            reminderData['mobileNumber'] ??
            reminderData['contactNumber'];
      }

      return null;
    } catch (e) {
      print('Error getting phone number from Firebase: $e');
      return null;
    }
  }

  // Get WhatsApp number directly from Firebase
  Future<String?> _getWhatsAppNumberFromFirebase(String leadName) async {
    try {
      // First, try to get from leads collection
      QuerySnapshot leadQuery =
          await _firestore
              .collection('leads')
              .where('name', isEqualTo: leadName)
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

      if (leadQuery.docs.isNotEmpty) {
        Map<String, dynamic> leadData =
            leadQuery.docs.first.data() as Map<String, dynamic>;

        // Try multiple possible field names for WhatsApp number
        return leadData['whatsappNumber'] ??
            leadData['whatsApp'] ??
            leadData['whatsapp'] ??
            leadData['contactNumber'];
      }

      // If not found in leads, try reminders collection
      QuerySnapshot reminderQuery =
          await _firestore
              .collection('reminders')
              .where('leadName', isEqualTo: leadName)
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

      if (reminderQuery.docs.isNotEmpty) {
        Map<String, dynamic> reminderData =
            reminderQuery.docs.first.data() as Map<String, dynamic>;

        return reminderData['whatsappNumber'] ??
            reminderData['whatsApp'] ??
            reminderData['whatsapp'] ??
            reminderData['phoneNumber'] ??
            reminderData['phone'] ??
            reminderData['mobileNumber'] ??
            reminderData['contactNumber'];
      }

      return null;
    } catch (e) {
      print('Error getting WhatsApp number from Firebase: $e');
      return null;
    }
  }

  // Mark reminder as completed
  Future<void> _markAsCompleted(String reminderId) async {
    try {
      await _firestore.collection('reminders').doc(reminderId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder marked as completed!'),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error updating reminder: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Update the CalendarDatePicker class
class CalendarDatePicker extends StatefulWidget {
  final Function(DateTime)? onDateSelected;
  final bool shouldResetToToday;

  const CalendarDatePicker({
    Key? key,
    this.onDateSelected,
    this.shouldResetToToday = false,
  }) : super(key: key);

  @override
  _CalendarDatePickerState createState() => _CalendarDatePickerState();
}

class _CalendarDatePickerState extends State<CalendarDatePicker> {
  DateTime _currentDate = DateTime.now();
  DateTime _selectedDate = DateTime.now(); // This will be today by default
  String _userName = 'User';
  bool _isLoadingName = true;
  ScrollController _scrollController = ScrollController();

  List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _getUserName();

    // Set current date as selected by default
    DateTime now = DateTime.now();
    _currentDate = DateTime(now.year, now.month, 1);
    _selectedDate = now;

    // Center the current date when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerCurrentDate();
    });
  }

  @override
  void didUpdateWidget(CalendarDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if we need to reset to today
    if (widget.shouldResetToToday && !oldWidget.shouldResetToToday) {
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        resetToCurrentDate();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Method to center the current/selected date in the horizontal list
  void _centerCurrentDate() {
    if (!_scrollController.hasClients) return;

    List<DateTime> monthDates = _getMonthDates();
    int selectedIndex = monthDates.indexWhere(
      (date) =>
          date.day == _selectedDate.day &&
          date.month == _selectedDate.month &&
          date.year == _selectedDate.year,
    );

    if (selectedIndex != -1) {
      double itemWidth = 62.0;
      double screenWidth = MediaQuery.of(context).size.width;
      double centerOffset = (screenWidth / 2) - (itemWidth / 2);
      double targetOffset = (selectedIndex * itemWidth) - centerOffset;

      targetOffset = targetOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );

      _scrollController.animateTo(
        targetOffset,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Method to fetch user name from Firebase
  Future<void> _getUserName() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        String? displayName = currentUser.displayName;

        if (displayName != null && displayName.isNotEmpty) {
          setState(() {
            _userName = displayName;
            _isLoadingName = false;
          });
        } else {
          DocumentSnapshot userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .get();

          if (userDoc.exists) {
            Map<String, dynamic>? userData =
                userDoc.data() as Map<String, dynamic>?;
            String name = userData?['name'] ?? userData?['firstName'] ?? 'User';
            setState(() {
              _userName = name;
              _isLoadingName = false;
            });
          } else {
            setState(() {
              _userName = 'User';
              _isLoadingName = false;
            });
          }
        }
      } else {
        setState(() {
          _userName = 'Guest';
          _isLoadingName = false;
        });
      }
    } catch (e) {
      print('Error fetching user name: $e');
      setState(() {
        _userName = 'User';
        _isLoadingName = false;
      });
    }
  }

  // Reset to current date method
  void resetToCurrentDate() {
    DateTime now = DateTime.now();
    setState(() {
      _currentDate = DateTime(now.year, now.month, 1);
      _selectedDate = now;
    });

    // Center the current date after reset
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerCurrentDate();
    });

    // Call the parent callback with today's date
    if (widget.onDateSelected != null) {
      widget.onDateSelected!(now);
    }
  }

  void _navigateMonth(bool forward) {
    setState(() {
      if (forward) {
        _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
      } else {
        _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
      }
      // Keep the selected date as the first day of the new month
      _selectedDate = DateTime(_currentDate.year, _currentDate.month, 1);
    });

    // Center the newly selected date after month navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerCurrentDate();
    });

    if (widget.onDateSelected != null) {
      widget.onDateSelected!(_selectedDate);
    }
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _currentDate = DateTime(date.year, date.month, 1);
    });

    // Center the newly selected date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerCurrentDate();
    });

    if (widget.onDateSelected != null) {
      widget.onDateSelected!(date);
    }
  }

  List<DateTime> _getMonthDates() {
    List<DateTime> dates = [];
    int lastDay = DateTime(_currentDate.year, _currentDate.month + 1, 0).day;

    for (int i = 1; i <= lastDay; i++) {
      DateTime date = DateTime(_currentDate.year, _currentDate.month, i);
      dates.add(date);
    }

    return dates;
  }

  Widget _dayItem(DateTime date) {
    bool isSelected =
        date.day == _selectedDate.day &&
        date.month == _selectedDate.month &&
        date.year == _selectedDate.year;

    bool isToday =
        date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year;

    return Container(
      width: 60,
      height: 70,
      margin: EdgeInsets.symmetric(horizontal: 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => _selectDate(date),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: 40,
            height: isSelected ? 70 : 60,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border:
                  isToday && !isSelected
                      ? Border.all(color: AppColors.textColor, width: 2)
                      : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        isSelected
                            ? AppColors.primaryGreen
                            : isToday
                            ? Colors.white
                            : Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _dayNames[date.weekday - 1],
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        isSelected
                            ? AppColors.primaryGreen
                            : isToday
                            ? Colors.white
                            : Colors.white,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(height: 2),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    List<DateTime> monthDates = _getMonthDates();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Spacer(),
              GestureDetector(
                onTap: () => _navigateMonth(false),
                child: Icon(Icons.arrow_left, color: Colors.white, size: 24),
              ),
              SizedBox(width: 8),
              Text(
                _monthNames[_currentDate.month - 1],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              GestureDetector(
                onTap: () => _navigateMonth(true),
                child: Icon(Icons.arrow_right, color: Colors.white, size: 24),
              ),
            ],
          ),

          Container(
            height: 70,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8),
              itemCount: monthDates.length,
              itemBuilder: (context, index) {
                return _dayItem(monthDates[index]);
              },
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Date and Today Tasks Section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 10.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Date
                  Text(
                    _getCurrentDate(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Today Tasks Label
                  Text(
                    'Today Tasks',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            _buildCalendarSection(),
          ],
        ),
      ),
    );
  }

  // Helper method to get current date formatted
  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final day = now.day.toString().padLeft(2, '0');
    final year = now.year.toString();

    return '${months[now.month - 1]} $day, $year';
  }
}
