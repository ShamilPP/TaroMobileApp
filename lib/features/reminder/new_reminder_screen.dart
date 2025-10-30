import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/features/lead/add_lead_model.dart';
import 'package:taro_mobile/features/reminder/reminder_controller.dart';
import 'package:taro_mobile/core/widgets/chip_widget.dart';

class NewReminderScreen extends StatelessWidget {
  final String? prefilledName;
  final String? prefilledLeadId;
  final String? prefilledPropertyDetails;
  final String? prefilledLocationDetails;
  final List<BaseProperty>? leadProperties;

  const NewReminderScreen({
    Key? key,
    this.prefilledName,
    this.prefilledLeadId,
    this.prefilledPropertyDetails,
    this.prefilledLocationDetails,
    this.leadProperties,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final controller = ReminderController();

        // Initialize with prefilled data immediately
        controller.initializeWithPrefilledData(
          prefilledName: prefilledName,
          prefilledLeadId: prefilledLeadId,
          prefilledPropertyDetails: prefilledPropertyDetails,
          prefilledLocationDetails: prefilledLocationDetails,
          leadProperties: leadProperties,
        );

        // Set the prefilled values directly to the controller
        if (prefilledName != null && prefilledName!.isNotEmpty) {
          controller.setName(prefilledName!);
        }

        if (prefilledPropertyDetails != null &&
            prefilledPropertyDetails!.isNotEmpty) {
          controller.setLeadProperty(prefilledPropertyDetails!);
        }

        // Auto-enable toggle if there are prefilled data
        bool hasPrefilled = _hasPrefilledData();
        if (hasPrefilled) {
          controller.toggleOptionalDetails(true);
        }

        return controller;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Consumer<ReminderController>(
          builder: (context, controller, child) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(left: 10, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),

                  _buildDropdownField(
                    label: 'Reminder Type',
                    value: controller.selectedReminderType,
                    items: controller.reminderTypes,
                    onChanged: (value) => controller.setReminderType(value!),
                  ),

                  SizedBox(height: 16),

                  // Single Toggle for optional details (only show if reminder type makes them optional)
                  if (!_isLeadDetailsRequired(
                        controller.selectedReminderType,
                      ) ||
                      !_isPropertyRequired(controller.selectedReminderType))
                    _buildOptionalDetailsToggle(controller),

                  // Name Field - Show if required OR if toggle is enabled
                  if (_shouldShowNameField(controller))
                    _buildNameField(controller),

                  SizedBox(height: 16),
                  // _buildTestNotificationButton(controller, context),

                  // Property Field - Show if required OR if toggle is enabled
                  if (_shouldShowPropertyField(controller))
                    _buildPropertyField(controller),

                  SizedBox(height: 16),

                  Text(
                    'Select Date & Time',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTimeField(
                          controller: controller.dateController,
                          label: 'Date',
                          icon: Icons.calendar_today,
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (pickedDate != null) {
                              String formattedDate =
                                  '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';
                              controller.setDate(formattedDate);
                            }
                          },
                        ),
                      ),

                      SizedBox(width: 12),

                      Expanded(
                        child: _buildDateTimeField(
                          controller: controller.timeController,
                          label: 'Time',
                          icon: Icons.access_time,
                          onTap: () async {
                            TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (pickedTime != null) {
                              controller.setTime(pickedTime.format(context));
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // New Notification Schedule Dropdown
                  _buildNotificationScheduleField(controller),

                  SizedBox(height: 16),

                  _buildNotesSection(controller),

                  SizedBox(height: 32),

                  _buildTextField(
                    controller: controller.customNotesController,
                    label: "Custom Notes",
                    maxLines: 3,
                    minLines: 3,
                  ),

                  SizedBox(height: 32),

                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          controller.isLoading
                              ? null
                              : () async {
                                try {
                                  // Custom validation that considers prefilled data
                                  if (!_validateFormWithPrefilledData(
                                    controller,
                                  )) {
                                    List<String> errors =
                                        _getValidationErrorsWithPrefilledData(
                                          controller,
                                        );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Please fill all required fields:\n${errors.join('\n')}',
                                        ),
                                        backgroundColor: Colors.red,
                                        duration: Duration(seconds: 4),
                                      ),
                                    );
                                    return;
                                  }

                                  bool success =
                                      await controller.saveReminder();
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Reminder created successfully!',
                                        ),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    controller.clearForm();
                                    Navigator.pop(context, true);
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child:
                          controller.isLoading
                              ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Text(
                                'Create',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper method to check if we have prefilled data
  bool _hasPrefilledData() {
    return (prefilledName != null && prefilledName!.isNotEmpty) ||
        (prefilledPropertyDetails != null &&
            prefilledPropertyDetails!.isNotEmpty) ||
        (prefilledLocationDetails != null &&
            prefilledLocationDetails!.isNotEmpty);
  }

  // Helper methods to check requirements
  bool _isLeadDetailsRequired(String? reminderType) {
    return reminderType == 'Lead Follow-up' || reminderType == 'Client Meeting';
  }

  bool _isPropertyRequired(String? reminderType) {
    return reminderType == 'Property Visit' ||
        reminderType == 'Document Signing';
  }

  // New helper methods to determine if fields should be shown
  bool _shouldShowNameField(ReminderController controller) {
    return _isLeadDetailsRequired(controller.selectedReminderType) ||
        (!_isLeadDetailsRequired(controller.selectedReminderType) &&
            controller.showOptionalDetails);
  }

  bool _shouldShowPropertyField(ReminderController controller) {
    return _isPropertyRequired(controller.selectedReminderType) ||
        (!_isPropertyRequired(controller.selectedReminderType) &&
            controller.showOptionalDetails);
  }

  // Custom validation that considers prefilled data
  bool _validateFormWithPrefilledData(ReminderController controller) {
    // Basic required fields
    if (controller.selectedReminderType == null ||
        controller.selectedReminderType!.isEmpty) {
      return false;
    }

    if (controller.dateController.text.isEmpty ||
        controller.timeController.text.isEmpty) {
      return false;
    }

    // Check name field if it's shown
    if (_shouldShowNameField(controller)) {
      // If name field is shown, it needs to be filled
      bool hasName =
          (controller.selectedName != null &&
              controller.selectedName!.isNotEmpty) ||
          (prefilledName != null && prefilledName!.isNotEmpty);
      if (!hasName) return false;
    }

    // Check property field if it's shown
    if (_shouldShowPropertyField(controller)) {
      // If property field is shown, it needs to be filled
      bool hasProperty =
          (controller.selectedProperty != null &&
              controller.selectedProperty!.isNotEmpty) ||
          (prefilledPropertyDetails != null &&
              prefilledPropertyDetails!.isNotEmpty);
      if (!hasProperty) return false;
    }

    return true;
  }

  // Custom validation errors that consider prefilled data
  List<String> _getValidationErrorsWithPrefilledData(
    ReminderController controller,
  ) {
    List<String> errors = [];

    if (controller.selectedReminderType == null ||
        controller.selectedReminderType!.isEmpty) {
      errors.add('Reminder Type is required');
    }

    if (controller.dateController.text.isEmpty) {
      errors.add('Date is required');
    }

    if (controller.timeController.text.isEmpty) {
      errors.add('Time is required');
    }

    // Check name field if it's shown
    if (_shouldShowNameField(controller)) {
      bool hasName =
          (controller.selectedName != null &&
              controller.selectedName!.isNotEmpty) ||
          (prefilledName != null && prefilledName!.isNotEmpty);
      if (!hasName) {
        errors.add('Name is required');
      }
    }

    // Check property field if it's shown
    if (_shouldShowPropertyField(controller)) {
      bool hasProperty =
          (controller.selectedProperty != null &&
              controller.selectedProperty!.isNotEmpty) ||
          (prefilledPropertyDetails != null &&
              prefilledPropertyDetails!.isNotEmpty);
      if (!hasProperty) {
        errors.add('Property is required');
      }
    }

    return errors;
  }

  // Rest of your existing methods remain the same...
  // [Include all your existing widget building methods here]

  Widget _buildOptionalDetailsToggle(ReminderController controller) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.add_circle_outline, color: Colors.grey[600], size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Include Lead & Property Details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              controller.toggleOptionalDetails(!controller.showOptionalDetails);
            },
            child: Container(
              width: 50,
              height: 24,
              alignment: Alignment.center,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 35,
                      height: 15,
                      decoration: BoxDecoration(
                        color:
                            controller.showOptionalDetails
                                ? const Color.fromARGB(255, 58, 102, 131)
                                : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  AnimatedAlign(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    alignment:
                        controller.showOptionalDetails
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        color:
                            controller.showOptionalDetails
                                ? AppColors.textColor
                                : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              controller.showOptionalDetails
                                  ? AppColors.textColor
                                  : Colors.grey.shade400,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child:
                          controller.showOptionalDetails
                              ? Icon(Icons.check, size: 18, color: Colors.white)
                              : null,
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
              "New Reminder",
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

  Widget _buildTestNotificationButton(
    ReminderController controller,
    BuildContext context,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                try {
                  await controller.showTestNotification();

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '🧪 Test notification will appear in 2 seconds!',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error: ${e.toString()}',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 4),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: Icon(
                Icons.notifications_active,
                color: Colors.blue[600],
                size: 20,
              ),
              label: Text(
                'Test Notification',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                side: BorderSide(color: Colors.blue[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                try {
                  await controller.debugNotifications();

                  final pending =
                      await controller.notificationService
                          .getPendingNotifications();

                  // Show debug info
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '📱 Pending notifications: ${pending.length}\nCheck console for details',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: Icon(Icons.bug_report, color: Colors.orange[600], size: 20),
              label: Text(
                'Debug Info',
                style: TextStyle(
                  color: Colors.orange[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                side: BorderSide(color: Colors.orange[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationScheduleField(ReminderController controller) {
    // Define notification schedule options with value and display text
    final List<Map<String, dynamic>> notificationOptions = [
      {'value': 5, 'label': '5 minutes before'},
      {'value': 15, 'label': '15 minutes before'},
      {'value': 30, 'label': '30 minutes before'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notification Schedule',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<int>(
            value: controller.selectedNotificationMinutes,
            decoration: InputDecoration(
              labelText: 'Notify me',
              labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
              suffixIcon: Icon(
                Icons.notifications,
                color: Colors.grey[400],
                size: 20,
              ),
            ),
            dropdownColor: Colors.white,
            items:
                notificationOptions.map((option) {
                  return DropdownMenuItem<int>(
                    value: option['value'],
                    child: Text(
                      option['label'],
                      style: TextStyle(color: Colors.black, fontSize: 14),
                    ),
                  );
                }).toList(),
            onChanged: (int? newValue) {
              if (newValue != null) {
                print('🔧 Notification schedule changed to: $newValue minutes');
                controller.setNotificationSchedule(newValue);
              }
            },
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
          ),
        ),
        SizedBox(height: 8),
        // Add info text about notification
        // Container(
        //   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        //   decoration: BoxDecoration(
        //     color: Colors.blue[50],
        //     borderRadius: BorderRadius.circular(4),
        //   ),
        //   child: Row(
        //     children: [
        //       Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
        //       SizedBox(width: 4),
        //       Expanded(
        //         child: Text(
        //           controller.selectedNotificationMinutes != null
        //               ? 'You will receive a notification ${_formatMinutesToText(controller.selectedNotificationMinutes!)} before your reminder'
        //               : 'Select when you want to be notified',
        //           style: TextStyle(fontSize: 12, color: Colors.blue[600]),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  // Helper method to format minutes to text
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

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    List<String> uniqueItems = items.toSet().toList();
    String? validatedValue = value;
    if (value != null && !uniqueItems.contains(value)) {
      validatedValue = null;
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<String>(
        value: validatedValue,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        dropdownColor: Colors.white,
        items:
            uniqueItems.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: TextStyle(color: Colors.black)),
              );
            }).toList(),
        onChanged: onChanged,
        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        minLines: minLines,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildDateTimeField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          suffixIcon: Icon(icon, color: Colors.grey[400], size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildNotesSection(ReminderController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 10),
        ChipRow(
          options: [
            'Property details sharing',
            'Previous conversation follow-up',
            'Price details sharing',
            'Negotiation follow-up',
            'Site visit follow-up',
            'Builder meeting',
            'Property location sharing',
            'Token amount details sharing',
            'Token amount follow-up',
            'Advance amount follow-up',
            'Draft agreement sharing',
            'Draft agreement preparation',
            'Client documents collection',
            'Payment follow-up',
            'Agreement signing follow-up',
            'Sale deed preparation',
            'Sale deed draft sharing',
            'Sale deed signing follow-up',
          ],
          selectedOptions: controller.selectedPrefilledNotes,
          onToggle: (option) {
            // Check if the option is already selected
            if (controller.selectedPrefilledNotes.contains(option)) {
              // If selected, remove it (deselect)
              controller.selectedPrefilledNotes.remove(option);
            } else {
              // If not selected, clear all and add this one (single selection)
              controller.selectedPrefilledNotes.clear();
              controller.selectedPrefilledNotes.add(option);
            }
            controller.notifyListeners();
          },
        ),
      ],
    );
  }

  Widget _buildNameField(ReminderController controller) {
    List<String> nameItems = List<String>.from(controller.leadNames);

    if (prefilledName != null &&
        prefilledName!.isNotEmpty &&
        !nameItems.contains(prefilledName!)) {
      nameItems.insert(0, prefilledName!);
    }

    String? currentValue;
    if (controller.selectedName != null) {
      currentValue = controller.selectedName;
    } else if (prefilledName != null && prefilledName!.isNotEmpty) {
      currentValue = prefilledName;
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        decoration: InputDecoration(
          labelText: 'Name',
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        dropdownColor: Colors.white,
        items:
            nameItems.map((String name) {
              return DropdownMenuItem<String>(
                value: name,
                child: Row(children: [Expanded(child: Text(name))]),
              );
            }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            controller.setName(newValue);
          }
        },
        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
        isExpanded: true,
      ),
    );
  }

  Widget _buildPropertyField(ReminderController controller) {
    List<String> propertyItems = List<String>.from(
      controller.leadPropertyNames,
    );

    if (prefilledPropertyDetails != null &&
        prefilledPropertyDetails!.isNotEmpty &&
        !propertyItems.contains(prefilledPropertyDetails!)) {
      propertyItems.insert(0, prefilledPropertyDetails!);
    }

    String? currentValue;
    if (controller.selectedProperty != null) {
      currentValue = controller.selectedProperty;
    } else if (prefilledPropertyDetails != null &&
        prefilledPropertyDetails!.isNotEmpty) {
      currentValue = prefilledPropertyDetails;
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        decoration: InputDecoration(
          labelText: 'Property (Lead Properties)',
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        dropdownColor: Colors.white,
        items:
            propertyItems.map((String propertyName) {
              bool isPrefilled =
                  propertyName == prefilledPropertyDetails &&
                  controller.selectedProperty == null;
              String displayText =
                  isPrefilled
                      ? propertyName
                      : controller.getPropertyDisplayDetails(propertyName);

              return DropdownMenuItem<String>(
                value: propertyName,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            controller.setLeadProperty(newValue);
          }
        },
        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
        isExpanded: true,
      ),
    );
  }
}
