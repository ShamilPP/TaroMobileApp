import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taro_mobile/features/lead/add_lead_model.dart';
import 'package:taro_mobile/features/reminder/notifications/notification_manager.dart';

class ReminderController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService notificationService = NotificationService();

  // FIXED: Remove default value, let user choose from dropdown
  int? selectedNotificationMinutes;

  User? get currentUser => _auth.currentUser;
  String? get userId => currentUser?.uid;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingLeads = false;
  bool _isLoadingProperties = false;
  bool get isLoadingLeads => _isLoadingLeads;
  bool get isLoadingProperties => _isLoadingProperties;

  final TextEditingController propertyController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController customNotesController = TextEditingController();

  String? _selectedReminderType;
  String? _selectedName;
  String? _selectedLeadId;
  String? _selectedProperty;

  String? get selectedReminderType => _selectedReminderType;
  String? get selectedName => _selectedName;
  String? get selectedLeadId => _selectedLeadId;
  String? get selectedProperty => _selectedProperty;

  bool _isEditing = false;
  String? _editingReminderId;
  Map? _existingReminderData;

  bool get isEditing => _isEditing;
  String? get editingReminderId => _editingReminderId;

  final List<String> reminderTypes = [
    'Message',
    'Agreement',
    'Site Visit',
    'Check',
    'Call',
  ];

  List<Map<String, dynamic>> _leads = [];
  List<Map<String, dynamic>> _properties = [];

  List<Map<String, dynamic>> get leads => _leads;
  List<Map<String, dynamic>> get properties => _properties;

  final List<String> prefilledNotes = [
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

  List<String> _selectedPrefilledNotes = [];
  List<String> get selectedPrefilledNotes => _selectedPrefilledNotes;

  List<String> get noteOptions => prefilledNotes;
  String? get selectedNote =>
      _selectedPrefilledNotes.isNotEmpty ? _selectedPrefilledNotes.first : null;

  bool _isNameDropdownMode = false;
  bool _isPropertyDropdownMode = false;

  bool get isNameDropdownMode => _isNameDropdownMode;
  bool get isPropertyDropdownMode => _isPropertyDropdownMode;

  List<Map<String, dynamic>> _leadProperties = [];
  List<Map<String, dynamic>> get leadProperties => _leadProperties;

  // UPDATED CONSTRUCTOR - No default notification minutes
  ReminderController({
    String? editingReminderId,
    Map? existingReminderData,
    List? leadProperties,
  }) {
    // Initialize notification minutes as null - user must choose
    selectedNotificationMinutes = null;

    _initializeNotificationService();
    if (editingReminderId != null && existingReminderData != null) {
      _isEditing = true;
      _editingReminderId = editingReminderId;
      _existingReminderData = existingReminderData;
    } else {
      _isEditing = false;
    }

    _initializeData();
  }

  Future<void> _initializeNotificationService() async {
    try {
      await notificationService.initialize();
      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing notification service: $e');
    }
  }

  Future<void> _initializeData() async {
    try {
      await Future.wait([fetchLeads(), fetchProperties()]);

      if (_isEditing && _existingReminderData != null) {
        await _initializeForEditing();
      }
    } catch (e) {
      print('Error initializing data: $e');
    }
  }

  // UPDATED: Fixed editing initialization for notification minutes
  Future<void> _initializeForEditing() async {
    if (_existingReminderData == null) return;

    try {
      print('📝 Initializing for editing with data: $_existingReminderData');

      _selectedReminderType = _existingReminderData!['reminderType'] ?? 'Call';

      String leadName = _existingReminderData!['leadName']?.toString() ?? '';
      if (leadName.isNotEmpty) {
        _selectedName = leadName;

        Map<String, dynamic>? leadData = getLeadByName(leadName);
        if (leadData != null) {
          _selectedLeadId = leadData['id'];
          await fetchLeadProperties(_selectedLeadId!);
        }
      }

      String propertyValue =
          _existingReminderData!['property']?.toString() ?? '';
      if (propertyValue.isNotEmpty) {
        _selectedProperty = propertyValue;
        propertyController.text = propertyValue;
      }

      dateController.text = _existingReminderData!['date']?.toString() ?? '';
      timeController.text = _existingReminderData!['time']?.toString() ?? '';

      customNotesController.text =
          _existingReminderData!['customNotes']?.toString() ?? '';

      whatsappController.text =
          _existingReminderData!['whatsapp']?.toString() ?? '';
      phoneController.text = _existingReminderData!['phone']?.toString() ?? '';

      // FIXED: Properly load existing notification minutes
      var notificationMinutesFromData =
          _existingReminderData!['notificationMinutes'];
      if (notificationMinutesFromData != null) {
        selectedNotificationMinutes =
            notificationMinutesFromData is int
                ? notificationMinutesFromData
                : int.tryParse(notificationMinutesFromData.toString()) ?? 30;
      } else {
        selectedNotificationMinutes = 30; // Default only if no existing data
      }

      print(
        '📅 Loaded notification minutes from existing data: $selectedNotificationMinutes',
      );

      List prefilledNotesArray = _existingReminderData!['prefilledNotes'] ?? [];
      _selectedPrefilledNotes.clear();
      for (var note in prefilledNotesArray) {
        if (note != null && note.toString().isNotEmpty) {
          _selectedPrefilledNotes.add(note.toString());
        }
      }

      print('✅ Editing initialization complete');
      notifyListeners();
    } catch (e) {
      print('❌ Error in _initializeForEditing: $e');
    }
  }

  @override
  void dispose() {
    propertyController.dispose();
    dateController.dispose();
    timeController.dispose();
    whatsappController.dispose();
    phoneController.dispose();
    customNotesController.dispose();
    super.dispose();
  }

  // NOTIFICATION MANAGEMENT METHODS

  // FIXED: Enhanced setNotificationSchedule with debugging
  void setNotificationSchedule(int minutes) {
    print(
      '🔧 Setting notification schedule from ${selectedNotificationMinutes} to $minutes',
    );
    selectedNotificationMinutes = minutes;
    print(
      '✅ Notification schedule set to: ${_formatMinutesToText(minutes)} before',
    );
    notifyListeners(); // Crucial for UI updates
  }

  Future<void> _scheduleNotification(
    String reminderId,
    Map<String, dynamic> reminderData,
  ) async {
    try {
      // Check if we have all required data for notification
      if (selectedNotificationMinutes == null ||
          reminderData['scheduledDateTime'] == null ||
          reminderData['reminderType'] == null) {
        print('⚠️ Missing required data for notification scheduling');
        print('📅 Notification minutes: $selectedNotificationMinutes');
        print('⏰ Scheduled DateTime: ${reminderData['scheduledDateTime']}');
        print('📝 Reminder Type: ${reminderData['reminderType']}');
        return;
      }

      DateTime scheduledDateTime;
      if (reminderData['scheduledDateTime'] is Timestamp) {
        scheduledDateTime =
            (reminderData['scheduledDateTime'] as Timestamp).toDate();
      } else if (reminderData['scheduledDateTime'] is DateTime) {
        scheduledDateTime = reminderData['scheduledDateTime'];
      } else {
        print('❌ Invalid scheduledDateTime format');
        return;
      }

      // Create notification payload
      final notificationData = ReminderNotificationData(
        reminderId: reminderId,
        reminderType: reminderData['reminderType'] ?? '',
        leadName: reminderData['leadName'] ?? '',
        propertyDetails: reminderData['property'],
        notes: _getFirstNote(reminderData),
        scheduledTime: scheduledDateTime,
        notificationMinutesBefore: selectedNotificationMinutes!,
      );

      // Format notification title and body
      final title = notificationService.formatNotificationTitle(
        reminderData['reminderType'] ?? '',
        reminderData['leadName'] ?? '',
      );

      final body = notificationService.formatNotificationBody(
        reminderData['reminderType'] ?? '',
        reminderData['leadName'] ?? '',
        reminderData['property'],
        _getFirstNote(reminderData),
        scheduledDateTime,
      );

      // Schedule the notification
      await notificationService.scheduleReminder(
        id: reminderId,
        title: title,
        body: body,
        scheduledDate: scheduledDateTime,
        notificationMinutesBefore: selectedNotificationMinutes!,
        payload: notificationData.toJson(),
      );

      print('✅ Notification scheduled successfully for reminder: $reminderId');
      print(
        '📱 Will notify at: ${_formatDateTime(scheduledDateTime.subtract(Duration(minutes: selectedNotificationMinutes!)))}',
      );
    } catch (e) {
      print('❌ Error scheduling notification: $e');
      // Don't throw here as the reminder was saved successfully
    }
  }

  String? _getFirstNote(Map<String, dynamic> reminderData) {
    // Try to get the first prefilled note
    if (reminderData['prefilledNotes'] != null &&
        reminderData['prefilledNotes'] is List &&
        (reminderData['prefilledNotes'] as List).isNotEmpty) {
      return (reminderData['prefilledNotes'] as List).first?.toString();
    }

    // Fallback to custom notes
    return reminderData['customNotes']?.toString();
  }

  Future<void> cancelReminderNotification(String reminderId) async {
    try {
      await notificationService.cancelNotification(reminderId);
      print('🚫 Reminder notification cancelled for: $reminderId');
    } catch (e) {
      print('❌ Error cancelling notification: $e');
    }
  }

  // FIRESTORE DATA FETCHING METHODS

  Future<void> fetchLeads() async {
    if (currentUser == null) {
      print('⚠️ Current user is null, cannot fetch leads');
      return;
    }

    try {
      _isLoadingLeads = true;
      notifyListeners();

      QuerySnapshot querySnapshot;
      try {
        querySnapshot =
            await _firestore
                .collection('leads')
                .where('userId', isEqualTo: userId)
                .get();

        if (querySnapshot.docs.isEmpty) {
          querySnapshot = await _firestore.collection('leads').get();
        }
      } catch (e) {
        querySnapshot = await _firestore.collection('leads').get();
      }

      _leads =
          querySnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();

      print('📊 Fetched ${_leads.length} leads');
      _isLoadingLeads = false;
      notifyListeners();
    } catch (e) {
      _isLoadingLeads = false;
      notifyListeners();
      print('❌ Error fetching leads: $e');
    }
  }

  Future<void> fetchProperties() async {
    if (currentUser == null) return;

    try {
      _isLoadingProperties = true;
      notifyListeners();

      QuerySnapshot querySnapshot;
      try {
        querySnapshot =
            await _firestore
                .collection('properties')
                .where('userId', isEqualTo: userId)
                .get();
      } catch (e) {
        querySnapshot =
            await _firestore
                .collection('properties')
                .where('userId', isEqualTo: userId)
                .get();
      }

      _properties =
          querySnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();

      print('🏠 Fetched ${_properties.length} properties');
      _isLoadingProperties = false;
      notifyListeners();
    } catch (e) {
      _isLoadingProperties = false;
      notifyListeners();
      print('❌ Error fetching properties: $e');
    }
  }

  Future<void> fetchLeadProperties(String leadId) async {
    if (currentUser == null || leadId.isEmpty) {
      _leadProperties = [];
      notifyListeners();
      return;
    }

    try {
      print('🔍 Fetching properties for lead ID: $leadId');

      List<Map<String, dynamic>> allProperties = [];
      List<String> collections = ['Commercial', 'Residential', 'Plots'];

      for (String collection in collections) {
        try {
          QuerySnapshot querySnapshot =
              await _firestore
                  .collection(collection)
                  .where('leadId', isEqualTo: leadId)
                  .get();

          for (var doc in querySnapshot.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            data['collection'] = collection;
            allProperties.add(data);
          }
        } catch (e) {
          print('❌ Error fetching from $collection: $e');
        }
      }

      _leadProperties = allProperties;
      print('🏗️ Total lead properties found: ${_leadProperties.length}');

      notifyListeners();
    } catch (e) {
      print('❌ Error fetching lead properties: $e');
      _leadProperties = [];
      notifyListeners();
    }
  }

  // GETTER METHODS

  List<String> get leadNames {
    Map<String, List<Map<String, dynamic>>> nameGroups = {};

    for (var lead in _leads) {
      String name = lead['name']?.toString().trim() ?? '';

      if (name.isNotEmpty && name != ' ' && name.length > 1) {
        if (!nameGroups.containsKey(name)) {
          nameGroups[name] = [];
        }
        nameGroups[name]!.add(lead);
      }
    }

    List<String> uniqueNames = [];

    nameGroups.forEach((name, leads) {
      if (leads.length == 1) {
        uniqueNames.add(name);
      } else {
        for (int i = 0; i < leads.length; i++) {
          var lead = leads[i];
          String distinguisher = '';

          String phone = lead['phoneNumber']?.toString().trim() ?? '';
          if (phone.isNotEmpty) {
            String lastDigits =
                phone.length > 4 ? phone.substring(phone.length - 4) : phone;
            distinguisher = ' (...$lastDigits)';
          } else {
            String email = lead['email']?.toString().trim() ?? '';
            if (email.isNotEmpty && email.contains('@')) {
              String emailPrefix = email.split('@')[0];
              distinguisher = ' ($emailPrefix)';
            } else {
              distinguisher = ' #${i + 1}';
            }
          }

          uniqueNames.add('$name$distinguisher');
        }
      }
    });

    return uniqueNames..sort();
  }

  List<String> get leadPropertyNames {
    Set<String> uniqueProperties = {};

    for (var property in _leadProperties) {
      String title = property['title']?.toString() ?? '';
      String location = property['location']?.toString() ?? '';
      String type =
          property['type']?.toString() ??
          property['propertyType']?.toString() ??
          '';

      String displayName;
      if (title.isNotEmpty && location.isNotEmpty) {
        displayName = '$title - $location ($type)';
      } else if (title.isNotEmpty) {
        displayName = '$title ($type)';
      } else if (location.isNotEmpty) {
        displayName = '$location ($type)';
      } else {
        displayName = 'Property ($type)';
      }

      String uniqueDisplayName = displayName;
      int counter = 1;
      while (uniqueProperties.contains(uniqueDisplayName)) {
        uniqueDisplayName = '$displayName #$counter';
        counter++;
      }

      uniqueProperties.add(uniqueDisplayName);
    }

    return uniqueProperties.toList()..sort();
  }

  // HELPER METHODS

  Map<String, dynamic>? getLeadPropertyByName(String propertyName) {
    String cleanPropertyName = propertyName.replaceAll(RegExp(r' #\d+$'), '');

    for (var property in _leadProperties) {
      String title = property['title']?.toString() ?? '';
      String location = property['location']?.toString() ?? '';
      String type =
          property['type']?.toString() ??
          property['propertyType']?.toString() ??
          '';

      String displayName;
      if (title.isNotEmpty && location.isNotEmpty) {
        displayName = '$title - $location ($type)';
      } else if (title.isNotEmpty) {
        displayName = '$title ($type)';
      } else if (location.isNotEmpty) {
        displayName = '$location ($type)';
      } else {
        displayName = 'Property ($type)';
      }

      if (displayName == cleanPropertyName) {
        return property;
      }
    }
    return null;
  }

  Map<String, dynamic>? getLeadByName(String leadName) {
    String baseName = leadName;
    String distinguisher = '';

    if (leadName.contains(' (') && leadName.endsWith(')')) {
      int lastParenIndex = leadName.lastIndexOf(' (');
      baseName = leadName.substring(0, lastParenIndex);
      distinguisher = leadName.substring(
        lastParenIndex + 2,
        leadName.length - 1,
      );
    }

    List<Map<String, dynamic>> matchingLeads = [];

    for (var lead in _leads) {
      String name = lead['name']?.toString()?.trim() ?? '';
      String email = lead['email']?.toString()?.trim() ?? '';
      String phone = lead['phoneNumber']?.toString()?.trim() ?? '';

      bool nameMatches =
          (name == baseName || email == baseName || phone == baseName);

      if (nameMatches) {
        matchingLeads.add(lead);
      }
    }

    if (matchingLeads.isEmpty) return null;

    if (distinguisher.isEmpty) {
      if (matchingLeads.length == 1) {
        return matchingLeads.first;
      } else {
        matchingLeads.sort((a, b) {
          var aTime = a['createdAt'];
          var bTime = b['createdAt'];

          if (aTime != null && bTime != null) {
            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }
          }
          return 0;
        });
        return matchingLeads.first;
      }
    }

    for (var lead in matchingLeads) {
      String phone = lead['phoneNumber']?.toString().trim() ?? '';
      String email = lead['email']?.toString().trim() ?? '';

      if (distinguisher.startsWith('...') && phone.isNotEmpty) {
        String lastDigits =
            phone.length > 4 ? phone.substring(phone.length - 4) : phone;
        if (distinguisher == '...$lastDigits') {
          return lead;
        }
      }

      if (email.isNotEmpty && email.contains('@')) {
        String emailPrefix = email.split('@')[0];
        if (distinguisher == emailPrefix) {
          return lead;
        }
      }

      if (distinguisher.startsWith('#')) {
        int index = int.tryParse(distinguisher.substring(1)) ?? 0;
        if (index > 0 && index <= matchingLeads.length) {
          return matchingLeads[index - 1];
        }
      }
    }

    return matchingLeads.first;
  }

  String getPropertyDisplayDetails(String propertyName) {
    Map<String, dynamic>? propertyData = getLeadPropertyByName(propertyName);
    if (propertyData == null) return propertyName;

    String collection =
        propertyData['propertyType']?.toString().toLowerCase() ??
        propertyData['collection']?.toString().toLowerCase() ??
        '';
    String location = propertyData['location']?.toString() ?? '';

    if (location.isNotEmpty) {
      List<String> locationWords =
          location.split(' ').where((word) => word.trim().isNotEmpty).toList();
      if (locationWords.length > 2) {
        location = locationWords.take(2).join(' ');
      }
    }

    List<String> details = [];

    if (collection == 'residential') {
      String bhk = propertyData['selectedBHK']?.toString() ?? '';
      String subType = propertyData['propertySubType']?.toString() ?? '';

      if (bhk.isNotEmpty) details.add(bhk);
      if (subType.isNotEmpty) details.add(subType);
      if (location.isNotEmpty) details.add(location);
    } else if (collection == 'commercial') {
      String subType = propertyData['propertySubType']?.toString() ?? '';
      String furnished = propertyData['furnished']?.toString() ?? '';
      if (furnished.isNotEmpty) details.add(furnished);
      if (subType.isNotEmpty) details.add(subType);
      if (location.isNotEmpty) details.add(location);
    } else if (collection == 'plots' || collection == 'land') {
      String subType = propertyData['propertySubType']?.toString() ?? '';

      String areaWithUnit = '';

      if (propertyData['acres'] != null &&
          propertyData['acres'].toString().isNotEmpty) {
        areaWithUnit = '${propertyData['acres']} acres';
      } else if (propertyData['cents'] != null &&
          propertyData['cents'].toString().isNotEmpty) {
        areaWithUnit = '${propertyData['cents']} cents';
      } else if (propertyData['squareFeet'] != null &&
          propertyData['squareFeet'].toString().isNotEmpty) {
        areaWithUnit = '${propertyData['squareFeet']} sq ft';
      } else if (propertyData['area'] != null &&
          propertyData['area'].toString().isNotEmpty) {
        String inputUnit = propertyData['inputUnit']?.toString() ?? 'sq ft';
        areaWithUnit = '${propertyData['area']} $inputUnit';
      }

      if (subType.isNotEmpty) details.add(subType);
      if (areaWithUnit.isNotEmpty) details.add(areaWithUnit);
      if (location.isNotEmpty) details.add(location);
    }

    return details.isNotEmpty ? details.join(' • ') : propertyName;
  }

  // INITIALIZATION AND PREFILL METHODS

  Future<void> initializeWithPrefilledData({
    String? prefilledName,
    String? prefilledLeadId,
    String? prefilledPropertyDetails,
    String? prefilledLocationDetails,
    List<BaseProperty>? leadProperties,
  }) async {
    try {
      _isNameDropdownMode = false;
      _isPropertyDropdownMode = false;

      if (prefilledName != null && prefilledName.isNotEmpty) {
        Map<String, dynamic>? leadData;

        if (prefilledLeadId != null && prefilledLeadId.isNotEmpty) {
          leadData = _leads.firstWhere(
            (lead) => lead['id'] == prefilledLeadId,
            orElse: () => getLeadByName(prefilledName) ?? {},
          );
        } else {
          leadData = getLeadByName(prefilledName);
        }

        if (leadData != null && leadData.isNotEmpty) {
          _selectedLeadId = leadData['id'];

          if (leadData['whatsappNumber'] != null) {
            whatsappController.text = leadData['whatsappNumber'].toString();
          }
          if (leadData['phoneNumber'] != null) {
            phoneController.text = leadData['phoneNumber'].toString();
          }

          await fetchLeadProperties(_selectedLeadId!);
        }
      }

      if (prefilledPropertyDetails != null &&
          prefilledPropertyDetails.isNotEmpty) {
        propertyController.text = prefilledPropertyDetails;
      }

      if (leadProperties != null && leadProperties.isNotEmpty) {
        _leadProperties =
            leadProperties.map((property) {
              return {
                'id':
                    property.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                'title': property.selectedSubType ?? '',
                'location': property.location ?? '',
                'type': property.propertyType ?? '',
                'propertyType': property.propertyType ?? '',
              };
            }).toList();
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error in initializeWithPrefilledData: $e');
    }
  }

  // SETTER METHODS

  // void setReminderType(String type) {
  //   _selectedReminderType = type;
  //   if (!showLeadDetails()) {
  //     _selectedName = null;
  //     _selectedLeadId = null;
  //     whatsappController.clear();
  //     phoneController.clear();
  //   }
  //   notifyListeners();
  // }

  void setName(String name) {
    _selectedName = name;

    if (_selectedProperty != null) {
      _selectedProperty = null;
      propertyController.clear();
    }

    Map<String, dynamic>? leadData = getLeadByName(name);
    if (leadData != null) {
      _selectedLeadId = leadData['id'];

      if (leadData['whatsappNumber'] != null) {
        whatsappController.text = leadData['whatsappNumber'].toString();
      } else {
        whatsappController.clear();
      }

      if (leadData['phoneNumber'] != null) {
        phoneController.text = leadData['phoneNumber'].toString();
      } else {
        phoneController.clear();
      }

      fetchLeadProperties(_selectedLeadId!);
    } else {
      _selectedLeadId = null;
      _leadProperties = [];
      whatsappController.clear();
      phoneController.clear();
    }

    notifyListeners();
  }

  void setLeadProperty(String propertyName) {
    if (propertyName == 'ORIGINAL_PROPERTY') {
      _selectedProperty = null;
      notifyListeners();
      return;
    }

    _selectedProperty = propertyName;

    String displayText = getPropertyDisplayDetails(propertyName);
    propertyController.text = displayText;

    notifyListeners();
  }

  void setProperty(String property) {
    _selectedProperty = property;
    _isPropertyDropdownMode = false;
    propertyController.text = property;
    notifyListeners();
  }

  void setDate(String date) {
    dateController.text = date;
    notifyListeners();
  }

  void setTime(String time) {
    timeController.text = time;
    notifyListeners();
  }

  void setNote(String note) {
    _selectedPrefilledNotes.clear();
    _selectedPrefilledNotes.add(note);
    notifyListeners();
  }

  // VALIDATION METHODS

  bool showLeadDetails() {
    return [
      'Message',
      'Agreement',
      'Site Visit',
      'Check',
      'Call',
    ].contains(_selectedReminderType);
  }

  // Single toggle property for both lead and property details
  bool _showOptionalDetails = false;

  // Getter for the toggle state
  bool get showOptionalDetails => _showOptionalDetails;

  // Method to toggle the optional details
  void toggleOptionalDetails(bool value) {
    _showOptionalDetails = value;

    // If turning off, clear the selected values
    if (!value) {
      _selectedName = null;
      _selectedProperty = null;
      // Clear any other related fields if needed
    }

    notifyListeners();
  }

  bool isLeadDetailsRequired() {
    // ALL lead details are OPTIONAL for all reminder types
    return false;
  }

  bool isPropertyRequired() {
    // ALL property details are OPTIONAL for all reminder types
    return false;
  }

  // FIXED: Prefilled data validation methods
  bool hasPrefilledName(String? prefilledName) {
    return prefilledName != null && prefilledName.isNotEmpty;
  }

  bool hasPrefilledProperty(String? prefilledPropertyDetails) {
    return prefilledPropertyDetails != null &&
        prefilledPropertyDetails.isNotEmpty;
  }

  // FIXED: Updated validation method that considers prefilled data
  bool validateFormWithPrefill({
    String? prefilledName,
    String? prefilledPropertyDetails,
  }) {
    print('🔍 Validating form with prefill data...');
    print('📅 Selected notification minutes: $selectedNotificationMinutes');
    print('🎯 Selected reminder type: $_selectedReminderType');
    print('🔄 Show optional details: $_showOptionalDetails');

    if (_selectedReminderType == null || _selectedReminderType!.isEmpty) {
      print('❌ No reminder type selected');
      return false;
    }

    // Basic required fields
    if (dateController.text.trim().isEmpty ||
        timeController.text.trim().isEmpty) {
      print('❌ Date or time not selected');
      return false;
    }

    if (selectedNotificationMinutes == null) {
      print('❌ No notification schedule selected');
      return false;
    }

    // Check if we should validate property
    bool shouldValidateProperty =
        isPropertyRequired() || (!isPropertyRequired() && _showOptionalDetails);

    if (shouldValidateProperty) {
      print('🏠 Property validation needed for ${_selectedReminderType}');

      // Check if we have property from controller OR prefilled data
      bool hasProperty =
          (_selectedProperty != null && _selectedProperty!.isNotEmpty) ||
          propertyController.text.trim().isNotEmpty ||
          hasPrefilledProperty(prefilledPropertyDetails);

      if (!hasProperty) {
        print(
          '❌ No property available (selected: $_selectedProperty, controller: ${propertyController.text}, prefilled: $prefilledPropertyDetails)',
        );
        return false;
      }
    } else {
      print('🏠 Property validation skipped for ${_selectedReminderType}');
    }

    // Check if we should validate lead details
    bool shouldValidateLeadDetails =
        isLeadDetailsRequired() ||
        (!isLeadDetailsRequired() && _showOptionalDetails);

    if (shouldValidateLeadDetails) {
      print('📝 Lead details validation needed for ${_selectedReminderType}');

      // Check if we have name from controller OR prefilled data
      bool hasName =
          (_selectedName != null && _selectedName!.isNotEmpty) ||
          hasPrefilledName(prefilledName);

      if (!hasName) {
        print(
          '❌ No lead name available (selected: $_selectedName, prefilled: $prefilledName)',
        );
        return false;
      }

      // Only validate phone/whatsapp if we don't have prefilled data or if user has entered data
      bool shouldValidatePhoneFields =
          !hasPrefilledName(prefilledName) ||
          whatsappController.text.isNotEmpty ||
          phoneController.text.isNotEmpty;

      if (shouldValidatePhoneFields) {
        if (whatsappController.text.trim().isEmpty) {
          print('❌ No WhatsApp number');
          return false;
        }
        if (phoneController.text.trim().isEmpty) {
          print('❌ No phone number');
          return false;
        }
      } else {
        print('📞 Phone validation skipped due to prefilled data');
      }
    } else {
      print('📝 Lead details validation skipped for ${_selectedReminderType}');
    }

    print('✅ Form validation passed');
    return true;
  }

  // FIXED: Updated validation errors method
  List<String> getValidationErrorsWithPrefill({
    String? prefilledName,
    String? prefilledPropertyDetails,
  }) {
    List<String> errors = [];

    if (_selectedReminderType == null || _selectedReminderType!.isEmpty) {
      errors.add('Reminder type is required');
    }

    if (dateController.text.trim().isEmpty) {
      errors.add('Date is required');
    }

    if (timeController.text.trim().isEmpty) {
      errors.add('Time is required');
    }

    if (selectedNotificationMinutes == null) {
      errors.add('Notification schedule is required');
    }

    // Check property requirements
    bool shouldValidateProperty =
        isPropertyRequired() || (!isPropertyRequired() && _showOptionalDetails);

    if (shouldValidateProperty) {
      bool hasProperty =
          (_selectedProperty != null && _selectedProperty!.isNotEmpty) ||
          propertyController.text.trim().isNotEmpty ||
          hasPrefilledProperty(prefilledPropertyDetails);

      if (!hasProperty) {
        errors.add('Property is required');
      }
    }

    // Check lead details requirements
    bool shouldValidateLeadDetails =
        isLeadDetailsRequired() ||
        (!isLeadDetailsRequired() && _showOptionalDetails);

    if (shouldValidateLeadDetails) {
      bool hasName =
          (_selectedName != null && _selectedName!.isNotEmpty) ||
          hasPrefilledName(prefilledName);

      if (!hasName) {
        errors.add('Lead name is required');
      }

      // Only validate phone fields if needed
      bool shouldValidatePhoneFields =
          !hasPrefilledName(prefilledName) ||
          whatsappController.text.isNotEmpty ||
          phoneController.text.isNotEmpty;

      if (shouldValidatePhoneFields) {
        if (whatsappController.text.trim().isEmpty) {
          errors.add('WhatsApp number is required');
        }
        if (phoneController.text.trim().isEmpty) {
          errors.add('Phone number is required');
        }
      }
    }

    return errors;
  }

  // UPDATED: Enhanced saveReminder method
  Future<bool> saveReminderWithPrefill({
    String? prefilledName,
    String? prefilledPropertyDetails,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('💾 Starting reminder save process...');
      print('📅 Notification minutes: $selectedNotificationMinutes');

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // if (!validateFormWithPrefill(
      //   prefilledName: prefilledName,
      //   prefilledPropertyDetails: prefilledPropertyDetails,
      // )) {
      //   List<String> errors = getValidationErrorsWithPrefill(
      //     prefilledName: prefilledName,
      //     prefilledPropertyDetails: prefilledPropertyDetails,
      //   );
      //   print('❌ Validation failed: ${errors.join(', ')}');
      //   throw Exception('Please fill all required fields');
      // }

      // Create scheduled DateTime
      String dateText = dateController.text;
      String timeText = timeController.text;
      DateTime? scheduledDateTime = _createScheduledDateTime(
        dateText,
        timeText,
      );

      if (scheduledDateTime == null) {
        throw Exception('Invalid date or time format');
      }

      if (scheduledDateTime.isBefore(DateTime.now())) {
        throw Exception('Cannot schedule reminder for past date/time');
      }

      // Determine name to save (prefer selected over prefilled)
      String nameToSave = _selectedName ?? prefilledName ?? '';

      // Determine property to save
      String propertyToSave;
      if (_selectedProperty != null) {
        propertyToSave = getPropertyDisplayDetails(_selectedProperty!);
      } else if (propertyController.text.isNotEmpty) {
        propertyToSave = propertyController.text;
      } else if (prefilledPropertyDetails != null &&
          prefilledPropertyDetails.isNotEmpty) {
        propertyToSave = prefilledPropertyDetails;
      } else {
        propertyToSave = '';
      }

      // Create reminder data
      Map<String, dynamic> reminderData = {
        'userId': userId,
        'userEmail': currentUser!.email,
        'reminderType': _selectedReminderType,
        'leadName': nameToSave,
        'leadId': _selectedLeadId,
        'property': propertyToSave,
        'date': dateController.text,
        'time': timeController.text,
        'whatsapp': whatsappController.text.trim(),
        'phone': phoneController.text.trim(),
        'prefilledNotes': _selectedPrefilledNotes,
        'customNotes': customNotesController.text.trim(),
        'combinedNotes': getCombinedNotes(),
        'scheduledDateTime': Timestamp.fromDate(scheduledDateTime),
        'notificationMinutes': selectedNotificationMinutes!,
        'notificationScheduled': true,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      print(
        '💾 Saving reminder with notification minutes: ${selectedNotificationMinutes}',
      );

      // Save to Firestore
      DocumentReference docRef = await _firestore
          .collection('reminders')
          .add(reminderData);
      String reminderId = docRef.id;

      print('✅ Reminder saved with ID: $reminderId');

      // Schedule the notification
      await _scheduleNotification(reminderId, {
        ...reminderData,
        'scheduledDateTime': scheduledDateTime,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('❌ Error saving reminder: $e');
      throw e;
    }
  }

  // Keep the original methods for backward compatibility
  bool validateForm() {
    return validateFormWithPrefill();
  }

  List<String> getValidationErrors() {
    return getValidationErrorsWithPrefill();
  }

  Future<bool> r() async {
    return saveReminderWithPrefill();
  }

  void setReminderType(String type) {
    _selectedReminderType = type;

    notifyListeners();
  }

  // Optional: Method to show requirement status for both property and lead details
  String getRequirementStatusText() {
    if (_selectedReminderType == null || _selectedReminderType!.isEmpty) {
      return '';
    }

    if (isPropertyRequired() && isLeadDetailsRequired()) {
      return 'Property and lead details are required for ${_selectedReminderType}';
    } else if (isPropertyRequired()) {
      return 'Property is required, lead details are optional for ${_selectedReminderType}';
    } else if (isLeadDetailsRequired()) {
      return 'Lead details are required, property is optional for ${_selectedReminderType}';
    } else {
      return 'Property and lead details are optional for ${_selectedReminderType}';
    }
  }

  // DATE/TIME PARSING METHODS

  DateTime? _parseDateFromController(String dateText) {
    if (dateText.isEmpty) return null;

    try {
      if (dateText.contains('/')) {
        List<String> parts = dateText.split('/');
        if (parts.length == 3) {
          int day = int.parse(parts[0]);
          int month = int.parse(parts[1]);
          int year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      } else if (dateText.contains('-')) {
        return DateTime.parse(dateText);
      }
    } catch (e) {
      print('❌ Error parsing date: $dateText - $e');
    }

    return null;
  }

  TimeOfDay? _parseTimeFromController(String timeText) {
    if (timeText.isEmpty) return null;

    try {
      // Handle 12-hour format (e.g., "12:13 PM", "7:00 AM")
      final regex = RegExp(
        r'(\d{1,2}):(\d{2})\s*(AM|PM)',
        caseSensitive: false,
      );
      final match = regex.firstMatch(timeText.trim());

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

        return TimeOfDay(hour: hour, minute: minute);
      }

      // Handle 24-hour format as fallback
      final parts = timeText.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (e) {
      print('❌ Error parsing time: $timeText - $e');
    }

    return null;
  }

  DateTime? _createScheduledDateTime(String dateText, String timeText) {
    DateTime? parsedDate = _parseDateFromController(dateText);
    TimeOfDay? parsedTime = _parseTimeFromController(timeText);

    if (parsedDate != null && parsedTime != null) {
      return DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        parsedTime.hour,
        parsedTime.minute,
      );
    }

    return null;
  }

  // SAVE AND UPDATE METHODS

  // UPDATED: Enhanced saveReminder with proper notification scheduling
  Future<bool> saveReminder() async {
    try {
      _isLoading = true;
      notifyListeners();

      print('💾 Starting reminder save process...');
      print('📅 Notification minutes: $selectedNotificationMinutes');

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // if (!validateForm()) {
      //   List<String> errors = getValidationErrors();
      //   print('❌ Validation failed: ${errors.join(', ')}');
      //   throw Exception('Please fill all required fields');
      // }

      // Create scheduled DateTime
      String dateText = dateController.text;
      String timeText = timeController.text;
      DateTime? scheduledDateTime = _createScheduledDateTime(
        dateText,
        timeText,
      );

      if (scheduledDateTime == null) {
        throw Exception('Invalid date or time format');
      }

      // Check if scheduled time is in the past
      if (scheduledDateTime.isBefore(DateTime.now())) {
        throw Exception('Cannot schedule reminder for past date/time');
      }

      // Determine property to save
      String propertyToSave;
      if (_selectedProperty != null) {
        propertyToSave = getPropertyDisplayDetails(_selectedProperty!);
      } else {
        propertyToSave =
            propertyController.text.isNotEmpty
                ? propertyController.text
                : _existingReminderData?['property']?.toString() ?? '';
      }

      // Create reminder data with proper notification minutes
      Map<String, dynamic> reminderData = {
        'userId': userId,
        'userEmail': currentUser!.email,
        'reminderType': _selectedReminderType,
        'leadName': _selectedName,
        'leadId': _selectedLeadId,
        'property': propertyToSave,
        'date': dateController.text,
        'time': timeController.text,
        'whatsapp': whatsappController.text.trim(),
        'phone': phoneController.text.trim(),
        'prefilledNotes': _selectedPrefilledNotes,
        'customNotes': customNotesController.text.trim(),
        'combinedNotes': getCombinedNotes(),
        'scheduledDateTime': Timestamp.fromDate(scheduledDateTime),
        'notificationMinutes':
            selectedNotificationMinutes!, // Use the selected value
        'notificationScheduled': true,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      print(
        '💾 Saving reminder with notification minutes: ${selectedNotificationMinutes}',
      );

      // Save to Firestore and get the document reference
      DocumentReference docRef = await _firestore
          .collection('reminders')
          .add(reminderData);
      String reminderId = docRef.id;

      print('✅ Reminder saved with ID: $reminderId');

      // Schedule the notification with the actual reminder ID
      await _scheduleNotification(reminderId, {
        ...reminderData,
        'scheduledDateTime':
            scheduledDateTime, // Pass as DateTime for notification scheduling
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('❌ Error saving reminder: $e');
      throw e;
    }
  }

  // UPDATED: Enhanced updateReminder with proper notification rescheduling
  Future<bool> updateReminder() async {
    if (_editingReminderId == null) {
      throw Exception('No reminder ID for editing');
    }

    try {
      _isLoading = true;
      notifyListeners();

      print('📝 Updating reminder with ID: $_editingReminderId');
      print('📅 New notification minutes: $selectedNotificationMinutes');

      // Validate form
      if (!validateForm()) {
        List<String> errors = getValidationErrors();
        print('❌ Validation failed: ${errors.join(', ')}');
        throw Exception('Please fill all required fields');
      }

      // Create scheduled DateTime
      String dateText = dateController.text;
      String timeText = timeController.text;
      DateTime? scheduledDateTime = _createScheduledDateTime(
        dateText,
        timeText,
      );

      if (scheduledDateTime == null) {
        throw Exception('Invalid date or time format');
      }

      // Check if scheduled time is in the past
      if (scheduledDateTime.isBefore(DateTime.now())) {
        throw Exception('Cannot schedule reminder for past date/time');
      }

      // Determine property to save
      String propertyToSave;
      if (_selectedProperty != null) {
        propertyToSave = getPropertyDisplayDetails(_selectedProperty!);
      } else {
        propertyToSave =
            propertyController.text.isNotEmpty
                ? propertyController.text
                : _existingReminderData?['property']?.toString() ?? '';
      }

      Map<String, dynamic> updateData = {
        'reminderType': _selectedReminderType,
        'leadName': _selectedName,
        'leadId': _selectedLeadId,
        'property': propertyToSave,
        'date': dateController.text,
        'time': timeController.text,
        'whatsapp': whatsappController.text.trim(),
        'phone': phoneController.text.trim(),
        'prefilledNotes': _selectedPrefilledNotes,
        'customNotes': customNotesController.text.trim(),
        'combinedNotes': getCombinedNotes(),
        'scheduledDateTime': Timestamp.fromDate(scheduledDateTime),
        'notificationMinutes':
            selectedNotificationMinutes!, // Use updated value
        'notificationScheduled': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print(
        '💾 Updating reminder with notification minutes: ${selectedNotificationMinutes}',
      );

      // Update the reminder in Firestore
      await _firestore
          .collection('reminders')
          .doc(_editingReminderId)
          .update(updateData);

      print('✅ Reminder updated in Firestore');

      // Cancel the existing notification first
      await cancelReminderNotification(_editingReminderId!);

      // Schedule new notification with updated data
      await _scheduleNotification(_editingReminderId!, {
        ...updateData,
        'scheduledDateTime': scheduledDateTime, // Pass as DateTime
      });

      print('✅ Notification rescheduled for updated reminder');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('❌ Error updating reminder: $e');
      throw e;
    }
  }

  // DELETE REMINDER METHOD

  Future<bool> deleteReminder(String reminderId) async {
    try {
      print('🗑️ Deleting reminder with ID: $reminderId');

      // Cancel the notification first
      await cancelReminderNotification(reminderId);

      // Delete from Firestore
      await _firestore.collection('reminders').doc(reminderId).delete();

      print('✅ Reminder deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting reminder: $e');
      throw e;
    }
  }

  // UTILITY METHODS

  String getCombinedNotes() {
    List<String> allNotes = [];
    allNotes.addAll(_selectedPrefilledNotes);

    if (customNotesController.text.trim().isNotEmpty) {
      allNotes.add(customNotesController.text.trim());
    }

    return allNotes.join('; ');
  }

  // UPDATED: Fixed clearForm method
  void clearForm() {
    _selectedReminderType = null;
    _selectedName = null;
    _selectedLeadId = null;
    _selectedProperty = null;
    selectedNotificationMinutes = null; // Reset to null instead of 30
    propertyController.clear();
    dateController.clear();
    timeController.clear();
    whatsappController.clear();
    phoneController.clear();
    customNotesController.clear();
    _selectedPrefilledNotes.clear();
    _leadProperties.clear();
    resetDropdownModes();
    print(
      '🧹 Form cleared - notification minutes reset to: $selectedNotificationMinutes',
    );
    notifyListeners();
  }

  void resetDropdownModes() {
    _isNameDropdownMode = false;
    _isPropertyDropdownMode = false;
    notifyListeners();
  }

  Future<void> refreshData() async {
    await Future.wait([fetchLeads(), fetchProperties()]);
  }

  // DROPDOWN MODE METHODS

  void clearNameSelection() {
    _selectedName = null;
    _isNameDropdownMode = true;
    notifyListeners();
  }

  void clearPropertySelection() {
    _selectedProperty = null;
    _isPropertyDropdownMode = true;
    notifyListeners();
  }

  void enableNameDropdownMode() {
    _isNameDropdownMode = true;
    notifyListeners();
  }

  void disableNameDropdownMode() {
    _isNameDropdownMode = false;
    notifyListeners();
  }

  void enablePropertyDropdownMode() {
    _isPropertyDropdownMode = true;
    notifyListeners();
  }

  void disablePropertyDropdownMode() {
    _isPropertyDropdownMode = false;
    notifyListeners();
  }

  void forcePropertyRefresh() {
    _selectedProperty = null;
    _isPropertyDropdownMode = false;
    propertyController.clear();
    notifyListeners();
  }

  void clearPropertyData() {
    _selectedProperty = null;
    _leadProperties = [];
    _isPropertyDropdownMode = false;
    propertyController.clear();
    notifyListeners();
  }

  void toggleNameDropdownMode() {
    _isNameDropdownMode = !_isNameDropdownMode;
    if (_isNameDropdownMode) {
      _selectedName = null;
    }
    notifyListeners();
  }

  void togglePropertyDropdownMode() {
    _isPropertyDropdownMode = !_isPropertyDropdownMode;
    if (_isPropertyDropdownMode) {
      _selectedProperty = null;
    }
    notifyListeners();
  }

  void togglePrefilledNote(String option) {
    if (_selectedPrefilledNotes.contains(option)) {
      _selectedPrefilledNotes.clear();
    } else {
      _selectedPrefilledNotes.clear();
      _selectedPrefilledNotes.add(option);
    }
    notifyListeners();
  }

  // PREFILL VALIDATION METHODS

  bool shouldUsePrefillForProperty(String? prefilledProperty) {
    return prefilledProperty != null &&
        prefilledProperty.isNotEmpty &&
        !_isPropertyDropdownMode &&
        _selectedProperty == null;
  }

  bool shouldUsePrefillForName(String? prefilledName) {
    return prefilledName != null &&
        prefilledName.isNotEmpty &&
        !_isNameDropdownMode &&
        _selectedName == null;
  }

  String? getCurrentNameDisplay(String? prefilledName) {
    if (_selectedName != null) {
      return _selectedName;
    } else if (shouldUsePrefillForName(prefilledName)) {
      return prefilledName;
    }
    return null;
  }

  String? getCurrentPropertyDisplay(String? prefilledProperty) {
    if (_selectedProperty != null) {
      return _selectedProperty;
    } else if (shouldUsePrefillForProperty(prefilledProperty)) {
      return prefilledProperty;
    }
    return null;
  }

  // ADDITIONAL HELPER METHODS

  List<Map<String, dynamic>> getAllLeadsByName(String leadName) {
    List<Map<String, dynamic>> matchingLeads = [];

    for (var lead in _leads) {
      String name = lead['name']?.toString()?.trim() ?? '';
      String email = lead['email']?.toString()?.trim() ?? '';
      String phone = lead['phoneNumber']?.toString()?.trim() ?? '';

      if (name == leadName || email == leadName || phone == leadName) {
        matchingLeads.add(lead);
      }
    }

    return matchingLeads;
  }

  // FORMATTING HELPER METHODS

  String _formatDateTime(DateTime dateTime) {
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year at $hour:$minute';
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

  // NOTIFICATION DEBUGGING METHODS

  Future<void> debugNotifications() async {
    try {
      final pending = await notificationService.getPendingNotifications();
      print('🔍 Pending notifications: ${pending.length}');

      for (var notification in pending) {
        print('📱 ID: ${notification.id}, Title: ${notification.title}');
        print('⏰ Scheduled for: ${notification.body}');
      }
    } catch (e) {
      print('❌ Error debugging notifications: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await notificationService.cancelAllNotifications();
      print('🚫 All notifications cancelled');
    } catch (e) {
      print('❌ Error cancelling all notifications: $e');
    }
  }

  // TESTING AND DEBUG METHODS
  // Add this method to your ReminderController class

  Future<void> showTestNotification() async {
    try {
      print('🧪 Showing test notification...');

      // Create test notification data
      final testData = ReminderNotificationData(
        reminderId: 'test_${DateTime.now().millisecondsSinceEpoch}',
        reminderType: _selectedReminderType ?? 'Test',
        leadName: _selectedName ?? 'Test User',
        propertyDetails:
            propertyController.text.isNotEmpty
                ? propertyController.text
                : '3BHK Apartment in Test Location',
        notes:
            _selectedPrefilledNotes.isNotEmpty
                ? _selectedPrefilledNotes.first
                : 'This is a test notification',
        scheduledTime: DateTime.now().add(Duration(minutes: 1)),
        notificationMinutesBefore: selectedNotificationMinutes ?? 5,
      );

      // Format notification title and body
      final title = notificationService.formatNotificationTitle(
        testData.reminderType,
        testData.leadName,
      );

      final body = notificationService.formatNotificationBody(
        testData.reminderType,
        testData.leadName,
        testData.propertyDetails,
        testData.notes,
        testData.scheduledTime,
      );

      // Show immediate notification (for testing)
      await notificationService.scheduleReminder(
        id: testData.reminderId,
        title: title,
        body: body,
        scheduledDate: DateTime.now().add(
          Duration(seconds: 2),
        ), // Show in 2 seconds
        notificationMinutesBefore: 0, // Immediate
        payload: testData.toJson(),
      );

      print('✅ Test notification scheduled to show in 2 seconds');
    } catch (e) {
      print('❌ Error showing test notification: $e');
      throw e;
    }
  }

  Future<void> testNotificationScheduling() async {
    print('🧪 Testing notification scheduling...');
    print(
      '📅 Current selectedNotificationMinutes: $selectedNotificationMinutes',
    );
    print('📝 Current reminderType: $_selectedReminderType');
    print('👤 Current selectedName: $_selectedName');
    print('📅 Current date: ${dateController.text}');
    print('⏰ Current time: ${timeController.text}');

    if (validateForm()) {
      print('✅ Form is valid for notification scheduling');
    } else {
      print('❌ Form validation failed');
      List<String> errors = getValidationErrors();
      for (String error in errors) {
        print('   - $error');
      }
    }
  }

  // Get formatted notification info for display
  String getNotificationDisplayText() {
    if (selectedNotificationMinutes == null) {
      return 'No notification schedule selected';
    }
    return 'Notify ${_formatMinutesToText(selectedNotificationMinutes!)} before reminder time';
  }
}
