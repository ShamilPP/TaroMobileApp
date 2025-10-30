import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/features/lead/add_lead_model.dart';
import 'package:taro_mobile/features/reminder/notifications/notification_manager.dart';
import 'package:taro_mobile/features/reminder/reminder_edit_screen.dart';

class ReminderDetailsScreen extends StatelessWidget {
  final String reminderId;
  final Map<String, dynamic> reminderData;
  final List<BaseProperty>? leadProperties;
  final NotificationService _notificationService = NotificationService();

  ReminderDetailsScreen({
    Key? key,
    required this.reminderId,
    required this.reminderData,
    this.leadProperties,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 16),
                    _buildStatusBanner(),
                    const SizedBox(height: 16),
                    _buildReminderCard(),
                    const SizedBox(height: 16),
                    _buildActionButtons(context),
                    const SizedBox(height: 16),
                    const Spacer(),
                    _buildCompleteButton(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  margin: const EdgeInsets.only(top: 0.0, left: 5, bottom: 20),
                  transform: Matrix4.translationValues(-10.0, 0.0, 0.0),
                  child: NeumorphicButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: NeumorphicStyle(
                      shape: NeumorphicShape.convex,
                      boxShape: const NeumorphicBoxShape.circle(),
                      depth: 4,
                      intensity: 0.8,
                      lightSource: LightSource.topLeft,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: AppColors.textColor,
                      size: 18,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              "Task Details",
              style: GoogleFonts.lato(
                fontSize: 25,
                fontWeight: FontWeight.w400,
                color: AppColors.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(
            'Reminder Set for ${_getReminderType() ?? 'Task'}',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildReminderHeader(), _buildReminderContent()],
        ),
      ),
    );
  }

  Widget _buildReminderHeader() {
    IconData icon = _getReminderIcon();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getReminderType() ?? 'Reminder',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getFormattedTime(),
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          if (_getDateTime() != null)
            Text(
              _getFormattedDate(),
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReminderContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_getReminderType() != null) ...[
            _buildReminderRow('Reminder Type', _getReminderType()!),
            const SizedBox(height: 16),
          ],
          if (_getLeadName() != null) ...[
            _buildReminderRow('Lead Name', _getLeadName()!),
            const SizedBox(height: 16),
          ],
          if (_getProperty() != null && _getProperty()!.isNotEmpty) ...[
            _buildPropertyRow('Property', _getProperty()!),
            const SizedBox(height: 16),
          ],
          if (_getDateTime() != null) ...[
            _buildReminderRow('Scheduled', _getDateTime()!),
            const SizedBox(height: 16),
          ],
          if (_getSelectedNote() != null) ...[
            _buildReminderRow('Note', _getSelectedNote()!),
            const SizedBox(height: 16),
          ],
          if (_getPrefilledNotes() != null &&
              _getPrefilledNotes()!.isNotEmpty) ...[
            _buildReminderRow(
              'Prefilled Notes',
              _getPrefilledNotes()!.join(', '),
            ),
            const SizedBox(height: 16),
          ],
          if (_getCustomNotes() != null && _getCustomNotes()!.isNotEmpty) ...[
            _buildReminderRow('Custom Notes', _getCustomNotes()!),
          ],
        ],
      ),
    );
  }

  Widget _buildReminderRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
            textAlign: TextAlign.left,
          ),
        ),
        SizedBox(
          width: 20,
          child: Text(
            ':',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryDarkBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
            textAlign: TextAlign.left,
          ),
        ),
        SizedBox(
          width: 20,
          child: Text(
            ':',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.schedule,
              label: 'Reschedule',
              onTap: () async {
                final result = await _showRescheduleDialog(context);
                if (result == true && context.mounted) {
                  _showSuccessSnackBar(
                    context,
                    'Reminder rescheduled successfully!',
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.edit,
              label: 'Edit',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => EditReminderScreen(
                          reminderId: reminderId,
                          reminderData: reminderData,
                          leadProperties: leadProperties ?? [],
                        ),
                  ),
                );

                if (result == true && context.mounted) {
                  _showSuccessSnackBar(
                    context,
                    'Reminder updated successfully!',
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.delete_outline,
              label: 'Delete',
              color: Colors.red,
              onTap: () {
                _showDeleteConfirmationDialog(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: color ?? Colors.grey[600], size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color ?? Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _handleCompleteReminder(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 20),
              const SizedBox(width: 8),
              Column(
                children: [
                  Text(
                    'Mark as Complete',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_getReminderType() ?? 'Task'} done',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showRescheduleDialog(BuildContext context) async {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    return await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Reschedule Reminder'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Reschedule reminder for ${_getLeadName() ?? 'this lead'}',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: dialogContext,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setState(() {
                                selectedDate = date;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
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
                              context: dialogContext,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              setState(() {
                                selectedTime = time;
                              });
                            }
                          },
                          icon: const Icon(Icons.access_time),
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
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      selectedDate != null && selectedTime != null
                          ? () async {
                            try {
                              await _rescheduleReminderInFirestore(
                                reminderId,
                                selectedDate!,
                                selectedTime!,
                                dialogContext,
                              );
                              Navigator.of(dialogContext).pop(true);
                            } catch (e) {
                              Navigator.of(dialogContext).pop(false);
                              if (context.mounted) {
                                _showErrorSnackBar(
                                  context,
                                  'Failed to reschedule reminder',
                                );
                              }
                            }
                          }
                          : null,
                  child: const Text('Reschedule'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Reminder'),
          content: Text(
            'Are you sure you want to delete this reminder for ${_getLeadName() ?? 'this lead'}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteReminderFromFirestore(reminderId, context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _rescheduleReminderInFirestore(
    String reminderId,
    DateTime newDate,
    TimeOfDay newTime,
    BuildContext context,
  ) async {
    try {
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

      // Schedule new notification using the notification service
      await _scheduleNotificationForReminder(
        reminderId,
        scheduledDateTime,
        reminderData: reminderData,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _scheduleNotificationForReminder(
    String reminderId,
    DateTime scheduledDateTime, {
    Map<String, dynamic>? reminderData,
  }) async {
    try {
      // If reminderData is not provided, fetch it from Firestore
      Map<String, dynamic> data = reminderData ?? this.reminderData;

      if (reminderData == null) {
        DocumentSnapshot doc =
            await FirebaseFirestore.instance
                .collection('reminders')
                .doc(reminderId)
                .get();

        if (!doc.exists) return;
        data = doc.data() as Map<String, dynamic>;
      }

      String leadName = data['leadName'] ?? 'Unknown Lead';
      String reminderType = data['reminderType'] ?? 'Reminder';
      String property = data['property'] ?? '';

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

  Future<void> _deleteReminderFromFirestore(
    String reminderId,
    BuildContext context,
  ) async {
    try {
      // Cancel any existing notification for this reminder
      await _notificationService.cancelNotification(reminderId);

      // Delete the reminder from Firestore
      await FirebaseFirestore.instance
          .collection('reminders')
          .doc(reminderId)
          .delete();

      if (context.mounted) {
        _showSuccessSnackBar(context, 'Reminder deleted successfully');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Failed to delete reminder');
      }
    }
  }

  void _handleCompleteReminder(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Complete Reminder'),
          content: Text(
            'Mark this reminder as complete for ${_getLeadName() ?? 'this lead'}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _disableReminderInFirestore(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Complete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _disableReminderInFirestore(BuildContext context) async {
    try {
      // Cancel any existing notification for this reminder
      await _notificationService.cancelNotification(reminderId);

      // Update the reminder status in Firestore
      await FirebaseFirestore.instance
          .collection('reminders')
          .doc(reminderId)
          .update({
            'isDisabled': true,
            'status': 'completed',
            'disabledAt': FieldValue.serverTimestamp(),
          });

      if (context.mounted) {
        _showSuccessSnackBar(context, 'Reminder completed successfully');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Failed to complete reminder');
      }
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Helper methods
  String? _getReminderType() {
    return reminderData['reminderType']?.toString();
  }

  String? _getLeadName() {
    return reminderData['leadName']?.toString() ??
        reminderData['name']?.toString();
  }

  String? _getProperty() {
    print('Reminder Data: $reminderData');

    final property = reminderData['property']?.toString();

    if (property == null || property.isEmpty) return null;

    final parts = property.split('•');

    if (parts.length >= 3) {
      final locationPart = parts[2].trim(); // e.g., "Kannur, Kerala,"
      final firstWord = locationPart.split(',').first.trim();

      // Capitalize first letter
      final cappedLocation =
          firstWord[0].toUpperCase() + firstWord.substring(1).toLowerCase();

      return '${parts[0].trim()} • ${parts[1].trim()} • $cappedLocation';
    }

    return property;
  }

  String? _getDateTime() {
    String? date = reminderData['date']?.toString();
    String? time = reminderData['time']?.toString();
    if (date != null && time != null) {
      return '$date at $time';
    } else if (date != null) {
      return date;
    } else if (time != null) {
      return time;
    }
    return null;
  }

  String? _getSelectedNote() {
    return reminderData['selectedNote']?.toString();
  }

  List<String>? _getPrefilledNotes() {
    if (reminderData['prefilledNotes'] is List) {
      return (reminderData['prefilledNotes'] as List)
          .map((e) => e.toString())
          .toList();
    } else if (reminderData['prefilledNotes'] is String) {
      return [reminderData['prefilledNotes'].toString()];
    }
    return null;
  }

  String? _getCustomNotes() {
    return reminderData['customNotes']?.toString();
  }

  IconData _getReminderIcon() {
    String? type = _getReminderType()?.toLowerCase();
    switch (type) {
      case 'follow up':
      case 'follow-up':
        return Icons.phone_callback;
      case 'site visit':
        return Icons.location_on;
      case 'meeting':
        return Icons.group;
      case 'call':
        return Icons.phone;
      case 'document':
        return Icons.description;
      case 'payment':
        return Icons.payment;
      default:
        return Icons.alarm;
    }
  }

  Color _getReminderColor() {
    String? type = _getReminderType()?.toLowerCase();
    switch (type) {
      case 'follow up':
      case 'follow-up':
        return Colors.blue;
      case 'site visit':
        return Colors.green;
      case 'meeting':
        return Colors.orange;
      case 'call':
        return Colors.purple;
      case 'document':
        return Colors.teal;
      case 'payment':
        return Colors.red;
      default:
        return const Color(0xFF8BC34A);
    }
  }

  String _getFormattedDate() {
    String? date = reminderData['date']?.toString();
    return date ?? 'N/A';
  }

  String _getFormattedTime() {
    String? time = reminderData['time']?.toString();
    return time ?? 'N/A';
  }
}
