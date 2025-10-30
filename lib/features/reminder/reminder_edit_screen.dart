import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/features/lead/add_lead_model.dart';
import 'package:taro_mobile/features/reminder/reminder_controller.dart';
import 'package:taro_mobile/core/widgets/chip_widget.dart';

class EditReminderScreen extends StatefulWidget {
  final String reminderId;
  final Map<String, dynamic> reminderData;
  final List<BaseProperty>? leadProperties;

  const EditReminderScreen({
    Key? key,
    required this.reminderId,
    required this.reminderData,
    this.leadProperties,
  }) : super(key: key);

  @override
  State<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  bool showPropertyDropdown = false;
  late ReminderController controller;

  @override
  void initState() {
    super.initState();

    controller = ReminderController(
      editingReminderId: widget.reminderId,
      existingReminderData: widget.reminderData,
      leadProperties: widget.leadProperties,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePrefilledData();
    });
  }

  // Helper methods to check requirements
  bool _isLeadDetailsRequired(String? reminderType) {
    return reminderType == '' || reminderType == '';
  }

  bool _isPropertyRequired(String? reminderType) {
    return reminderType == '' || reminderType == '';
  }

  void _initializePrefilledData() {
    String? reminderType = widget.reminderData['reminderType']?.toString();
    if (reminderType != null &&
        controller.reminderTypes.contains(reminderType)) {
      controller.setReminderType(reminderType);
    }

    String? leadName =
        widget.reminderData['leadName']?.toString() ??
        widget.reminderData['name']?.toString();
    if (leadName != null && controller.leadNames.contains(leadName)) {
      controller.setName(leadName);
    }

    String? propertyName = widget.reminderData['property']?.toString();
    if (propertyName != null &&
        controller.leadPropertyNames.contains(propertyName)) {
      controller.setLeadProperty(propertyName);
    } else if (controller.leadPropertyNames.isNotEmpty) {
      controller.setLeadProperty(controller.leadPropertyNames.first);
    }

    String? selectedNote = widget.reminderData['selectedNote']?.toString();
    if (selectedNote != null && controller.noteOptions.contains(selectedNote)) {
      controller.setNote(selectedNote);
    }

    if (widget.reminderData['prefilledNotes'] != null) {
      List<String> prefilledNotes = [];
      if (widget.reminderData['prefilledNotes'] is List) {
        prefilledNotes =
            (widget.reminderData['prefilledNotes'] as List)
                .map((e) => e.toString())
                .toList();
      } else if (widget.reminderData['prefilledNotes'] is String) {
        prefilledNotes = [widget.reminderData['prefilledNotes'].toString()];
      }

      controller.selectedPrefilledNotes.clear();
      for (String note in prefilledNotes) {
        if (_isValidPrefilledNote(note)) {
          controller.selectedPrefilledNotes.add(note);
        }
      }
      controller.notifyListeners();
    }

    String? customNotes = widget.reminderData['customNotes']?.toString();
    if (customNotes != null) {
      controller.customNotesController.text = customNotes;
    }

    String? date = widget.reminderData['date']?.toString();
    if (date != null) {
      controller.setDate(date);
    }

    String? time = widget.reminderData['time']?.toString();
    if (time != null) {
      controller.setTime(time);
    }

    // Initialize toggle state based on existing data
    bool hasLeadData = leadName != null && leadName.isNotEmpty;
    bool hasPropertyData = propertyName != null && propertyName.isNotEmpty;

    // If reminder type makes details optional and we have existing data, enable the toggle
    if ((!_isLeadDetailsRequired(reminderType) ||
            !_isPropertyRequired(reminderType)) &&
        (hasLeadData || hasPropertyData)) {
      controller.toggleOptionalDetails(true);
    }
  }

  bool _isValidPrefilledNote(String note) {
    List<String> validOptions = [
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
    ];
    return validOptions.contains(note);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
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

                  // Name Field - Always show if required, or show if toggle is enabled
                  if (_isLeadDetailsRequired(controller.selectedReminderType) ||
                      (!_isLeadDetailsRequired(
                            controller.selectedReminderType,
                          ) &&
                          controller.showOptionalDetails))
                    _buildNameField(controller),

                  SizedBox(height: 16),

                  // Property Field - Always show if required, or show if toggle is enabled
                  if (_isPropertyRequired(controller.selectedReminderType) ||
                      (!_isPropertyRequired(controller.selectedReminderType) &&
                          controller.showOptionalDetails))
                    _buildPropertyField(controller),

                  SizedBox(height: 16),
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

                  _buildNotificationScheduleField(controller),

                  SizedBox(height: 16),

                  _buildNotesSection(controller),
                  SizedBox(height: 16),

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
                                  bool success =
                                      await controller.updateReminder();
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Reminder updated successfully!',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    Navigator.pop(context, true);
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                      backgroundColor: Colors.red,
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
                                'Update',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),

                  SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Single toggle widget for both lead and property details
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
              "Edit Reminder",
              style: GoogleFonts.lato(
                fontSize: 25,
                fontWeight: FontWeight.w400,
                color: AppColors.textColor,
              ),
            ),

            const SizedBox(height: 8),
            // Container(
            //   padding: EdgeInsets.all(8),
            //   decoration: BoxDecoration(
            //     color: Colors.blue[50],
            //     borderRadius: BorderRadius.circular(8),
            //     border: Border.all(color: Colors.blue[200]!),
            //   ),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Text(
            //         'Editing reminder for: ${widget.reminderData['leadName'] ?? 'Unknown Lead'}',
            //         style: TextStyle(
            //           fontWeight: FontWeight.w600,
            //           color: Colors.blue[700],
            //         ),
            //       ),
            //       if (widget.reminderData['property'] != null &&
            //           widget.reminderData['property']
            //               .toString()
            //               .isNotEmpty) ...[
            //         SizedBox(height: 4),
            //         Text(
            //           'Property: ${widget.reminderData['property']}',
            //           style: TextStyle(fontSize: 12, color: Colors.blue[600]),
            //         ),
            //       ],
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyDropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    String? validatedValue = value;
    if (value != null) {
      bool valueExists = items.any((item) => item.value == value);
      if (!valueExists) {
        validatedValue = null;

        print(
          'Warning: Property value "$value" not found in available options',
        );
      }
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
        items: items,
        onChanged: onChanged,
        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
      ),
    );
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

      print(
        'Warning: Dropdown value "$value" not found in available options for $label',
      );
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

  Widget _buildNameField(ReminderController controller) {
    String currentName =
        controller.selectedName ??
        widget.reminderData['leadName']?.toString() ??
        widget.reminderData['name']?.toString() ??
        '';

    String? validatedName =
        currentName.isNotEmpty && controller.leadNames.contains(currentName)
            ? currentName
            : null;

    return _buildDropdownField(
      label: 'Name',
      value: validatedName,
      items: controller.leadNames,
      onChanged: (value) {
        if (value != null) {
          controller.setName(value);
          controller.setLeadProperty('');
        }
      },
    );
  }

  Widget _buildPropertyField(ReminderController controller) {
    String currentProperty =
        controller.selectedProperty ??
        widget.reminderData['property']?.toString() ??
        '';

    Map<String, String> uniqueProperties = {};
    for (String propertyName in controller.leadPropertyNames) {
      String display = controller.getPropertyDisplayDetails(propertyName);
      uniqueProperties[propertyName] = display;
    }

    String? validatedProperty;
    if (currentProperty.isNotEmpty &&
        uniqueProperties.containsKey(currentProperty)) {
      validatedProperty = currentProperty;
    } else if (uniqueProperties.isNotEmpty) {
      validatedProperty = uniqueProperties.keys.first;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.setLeadProperty(validatedProperty!);
      });
    }

    return _buildPropertyDropdownField(
      label: 'Property (Lead Properties)',
      value: validatedProperty,
      items:
          uniqueProperties.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
      onChanged: (value) {
        if (value != null) {
          controller.setLeadProperty(value);
        }
      },
    );
  }
}
