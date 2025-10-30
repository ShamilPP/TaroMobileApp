import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/core/constants/image_constants.dart';

class DynamicTimeIndicator extends StatefulWidget {
  final List<DocumentSnapshot> currentDateTasks;
  final Function(Map<String, dynamic>, String) buildReminderTaskItem;

  const DynamicTimeIndicator({
    Key? key,
    required this.currentDateTasks,
    required this.buildReminderTaskItem,
  }) : super(key: key);

  @override
  _DynamicTimeIndicatorState createState() => _DynamicTimeIndicatorState();
}

class _DynamicTimeIndicatorState extends State<DynamicTimeIndicator> {
  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  DateTime _getTaskDateTime(Map<String, dynamic> data) {
    if (data['scheduledDateTime'] != null) {
      Timestamp timestamp = data['scheduledDateTime'] as Timestamp;
      return timestamp.toDate();
    } else {
      String timeStr = data['time'] ?? '12:00 PM';
      DateTime parsedTime = _parseTimeString(timeStr);
      return DateTime(
        _currentTime.year,
        _currentTime.month,
        _currentTime.day,
        parsedTime.hour,
        parsedTime.minute,
      );
    }
  }

  Widget _buildImageDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(child: SizedBox()),

          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
          ),

          Container(
            width: 350,
            child: Image.asset(AppImages.linePng, height: 2, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }

  DateTime _parseTimeString(String timeStr) {
    try {
      RegExp regExp = RegExp(
        r'(\d{1,2}):(\d{2})\s*(AM|PM)?',
        caseSensitive: false,
      );
      Match? match = regExp.firstMatch(timeStr.trim());

      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);
        String? period = match.group(3)?.toUpperCase();

        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }

        return DateTime(2024, 1, 1, hour, minute);
      }
    } catch (e) {
      print('Error parsing time: $timeStr, Error: $e');
    }

    return DateTime(2024, 1, 1, 12, 0);
  }

  Widget _buildCurrentTimeIndicator() {
    return _buildImageDivider();
  }

  String _formatCurrentTime() {
    int hour = _currentTime.hour;
    int minute = _currentTime.minute;
    String period = hour >= 12 ? 'PM' : 'AM';

    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentDateTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    List<Widget> allWidgets = [];
    bool currentTimeIndicatorShown = false;

    for (int i = 0; i < widget.currentDateTasks.length; i++) {
      Map<String, dynamic> data =
          widget.currentDateTasks[i].data() as Map<String, dynamic>;
      DateTime taskTime = _getTaskDateTime(data);

      if (!currentTimeIndicatorShown && _currentTime.isBefore(taskTime)) {
        bool shouldShowIndicator = true;

        if (i > 0) {
          Map<String, dynamic> prevData =
              widget.currentDateTasks[i - 1].data() as Map<String, dynamic>;
          DateTime prevTaskTime = _getTaskDateTime(prevData);

          shouldShowIndicator = _currentTime.isAfter(prevTaskTime);
        }

        if (shouldShowIndicator) {
          allWidgets.add(_buildCurrentTimeIndicator());
          currentTimeIndicatorShown = true;
        }
      }

      allWidgets.add(
        widget.buildReminderTaskItem(data, widget.currentDateTasks[i].id),
      );

      if (!currentTimeIndicatorShown && _currentTime.isAfter(taskTime)) {
        bool shouldShowIndicator = true;

        if (i < widget.currentDateTasks.length - 1) {
          Map<String, dynamic> nextData =
              widget.currentDateTasks[i + 1].data() as Map<String, dynamic>;
          DateTime nextTaskTime = _getTaskDateTime(nextData);

          shouldShowIndicator = _currentTime.isBefore(nextTaskTime);
        }

        if (shouldShowIndicator) {
          allWidgets.add(_buildCurrentTimeIndicator());
          currentTimeIndicatorShown = true;
        }
      }

      if (i < widget.currentDateTasks.length - 1) {
        allWidgets.add(const SizedBox(height: 8));
      }
    }

    if (!currentTimeIndicatorShown && widget.currentDateTasks.isNotEmpty) {
      Map<String, dynamic> lastTaskData =
          widget.currentDateTasks.last.data() as Map<String, dynamic>;
      DateTime lastTaskTime = _getTaskDateTime(lastTaskData);

      if (_currentTime.isAfter(lastTaskTime)) {
        allWidgets.add(_buildCurrentTimeIndicator());
      }
    }

    return Column(children: allWidgets);
  }
}
