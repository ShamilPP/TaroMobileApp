
// import 'dart:async';
// import 'dart:convert';
// import 'dart:ui';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter/widgets.dart';

// class CallDataService {
//   static const MethodChannel _channel = MethodChannel(
//     'com.taro.mobileapp/call_data',
//   );
//   static CallDataService? _instance;
//   static CallDataService get instance => _instance ??= CallDataService._();

//   CallDataService._();

  
//   final StreamController<CallLeadData?> _callLeadController =
//       StreamController<CallLeadData?>.broadcast();
//   Stream<CallLeadData?> get callLeadStream => _callLeadController.stream;

  
//   @pragma('vm:entry-point')
//   static void backgroundCallback() {
    
//     WidgetsFlutterBinding.ensureInitialized();
//     DartPluginRegistrant.ensureInitialized();
//     CallDataService.instance._initializeBackground();
//   }

  
//   void _initializeBackground() async {
//     try {
//       _channel.setMethodCallHandler(_handleMethodCall);
//       print('CallDataService background initialized');
//     } catch (e) {
//       print('Error initializing background service: $e');
//     }
//   }

  
//   Future<void> initialize() async {
//     try {
//       _channel.setMethodCallHandler(_handleMethodCall);

      
//       await _channel.invokeMethod('registerBackgroundCallback');

//       print('CallDataService initialized with background support');
//     } catch (e) {
//       print('Error initializing CallDataService: $e');
//     }
//   }

  
//   @pragma('vm:entry-point')
//   Future<dynamic> _handleMethodCall(MethodCall call) async {
//     try {
//       switch (call.method) {
//         case 'fetchLeadData':
//           final String phoneNumber = call.arguments['phoneNumber'];
//           final bool isBackground = call.arguments['isBackground'] ?? false;

//           print(
//             'Received request to fetch lead data for: $phoneNumber (background: $isBackground)',
//           );

          
//           if (isBackground) {
//             await _ensureFirebaseInitialized();
//           }

//           return await _fetchAndSendLeadData(phoneNumber, isBackground);

//         case 'callEnded':
//           print('Call ended - clearing lead data');
//           _callLeadController.add(null);
//           return true;

//         case 'keepAlive':
          
//           print('Background service keep-alive ping');
//           return true;

//         default:
//           throw PlatformException(
//             code: 'UNIMPLEMENTED',
//             details: 'Method ${call.method} not implemented',
//           );
//       }
//     } catch (e) {
//       print('Error in _handleMethodCall: $e');
//       return {'success': false, 'error': e.toString()};
//     }
//   }

  
//   Future<void> _ensureFirebaseInitialized() async {
//     try {
      
//       await FirebaseFirestore.instance.enableNetwork();
//     } catch (e) {
//       print('Firebase network enable error: $e');
//     }
//   }

  
//   Future<Map<String, dynamic>> _fetchAndSendLeadData(
//     String phoneNumber, [
//     bool isBackground = false,
//   ]) async {
//     try {
//       print(
//         'Starting lead data fetch for: $phoneNumber (background: $isBackground)',
//       );

      
//       final cleanedNumber = _cleanPhoneNumber(phoneNumber);
//       print('Cleaned phone number: $cleanedNumber');

      
//       final leadData = await _fetchLeadByPhoneNumber(
//         cleanedNumber,
//       ).timeout(Duration(seconds: isBackground ? 10 : 30));

//       if (leadData != null) {
//         print('Lead found: ${leadData.lead.name}');

        
//         if (!isBackground) {
//           _callLeadController.add(leadData);
//         }

        
//         final result = await _sendLeadDataToNative(leadData, isBackground);
//         return result;
//       } else {
//         print('No lead found for phone number: $cleanedNumber');

        
//         await _sendUnknownCallerToNative(cleanedNumber);

//         return {
//           'success': false,
//           'message': 'No lead found',
//           'phoneNumber': cleanedNumber,
//         };
//       }
//     } catch (e) {
//       print('Error in _fetchAndSendLeadData: $e');

      
//       await _sendErrorToNative(phoneNumber, e.toString());

//       return {
//         'success': false,
//         'error': e.toString(),
//         'phoneNumber': phoneNumber,
//       };
//     }
//   }

  
//   Future<void> _sendUnknownCallerToNative(String phoneNumber) async {
//     try {
//       await _channel.invokeMethod('updateOverlayWithLeadData', {
//         'success': false,
//         'phoneNumber': phoneNumber,
//         'displayData': {
//           'leadName': 'Unknown Caller',
//           'phoneNumber': phoneNumber,
//           'propertyInfo': 'No lead information available',
//           'locationInfo': '',
//           'priceInfo': '',
//           'detailsInfo': '',
//           'propertiesCount': 0,
//           'hasMultipleProperties': false,
//         },
//       });
//     } catch (e) {
//       print('Error sending unknown caller data: $e');
//     }
//   }

  
//   Future<void> _sendErrorToNative(String phoneNumber, String error) async {
//     try {
//       await _channel.invokeMethod('updateOverlayWithLeadData', {
//         'success': false,
//         'error': true,
//         'phoneNumber': phoneNumber,
//         'displayData': {
//           'leadName': 'Error',
//           'phoneNumber': phoneNumber,
//           'propertyInfo': 'Failed to fetch lead data',
//           'locationInfo': '',
//           'priceInfo': '',
//           'detailsInfo': error.length > 50 ? 'Connection error' : error,
//           'propertiesCount': 0,
//           'hasMultipleProperties': false,
//         },
//       });
//     } catch (e) {
//       print('Error sending error data: $e');
//     }
//   }

  
//   Future<CallLeadData?> _fetchLeadByPhoneNumber(String phoneNumber) async {
//     try {
//       print('Querying Firestore for phone number: $phoneNumber');

      
//       final leadsQuery = await FirebaseFirestore.instance
//           .collection('leads')
//           .where('phoneNumber', isEqualTo: phoneNumber)
//           .where('status', isNotEqualTo: 'Inactive')
//           .limit(1)
//           .get()
//           .timeout(Duration(seconds: 8));

//       if (leadsQuery.docs.isEmpty) {
//         print('No leads found with phone number: $phoneNumber');
//         return null;
//       }

//       final leadDoc = leadsQuery.docs.first;
//       final leadData = leadDoc.data();
//       final leadId = leadDoc.id;

//       print('Lead found: ${leadData['name']} (ID: $leadId)');

      
//       final lead = LeadModel.fromMap(leadData, leadId);

      
//       final properties = await _fetchPropertiesForLead(
//         leadId,
//       ).timeout(Duration(seconds: 5));

//       print('Found ${properties.length} properties for lead: ${lead.name}');

//       return CallLeadData(lead: lead, properties: properties);
//     } catch (e) {
//       print('Error fetching lead by phone number: $e');
//       return null;
//     }
//   }

  
//   Future<Map<String, dynamic>> _sendLeadDataToNative(
//     CallLeadData leadData, [
//     bool isBackground = false,
//   ]) async {
//     try {
//       final leadJson = leadData.lead.toMap();
//       final propertiesJson = leadData.properties.map((p) => p.toMap()).toList();

      
//       final displayData = _formatLeadDataForDisplay(leadData);

//       print(
//         'Sending lead data to native: ${leadData.lead.name} (background: $isBackground)',
//       );
//       print('Properties count: ${leadData.properties.length}');

//       final result = await _channel
//           .invokeMethod('updateOverlayWithLeadData', {
//             'success': true,
//             'lead': leadJson,
//             'properties': propertiesJson,
//             'displayData': displayData,
//             'isBackground': isBackground,
//           })
//           .timeout(Duration(seconds: 3));

//       return {
//         'success': true,
//         'message': 'Lead data sent to overlay',
//         'leadId': leadData.lead.id,
//         'leadName': leadData.lead.name,
//         'propertiesCount': leadData.properties.length,
//       };
//     } catch (e) {
//       print('Error sending lead data to native: $e');
//       return {'success': false, 'error': e.toString()};
//     }
//   }

  
//   Future<bool> isAppInBackground() async {
//     try {
//       final result = await _channel.invokeMethod('isAppInBackground');
//       return result ?? false;
//     } catch (e) {
//       return false;
//     }
//   }

  
//   Future<List<BaseProperty>> _fetchPropertiesForLead(String leadId) async {
    
//     try {
//       final List<BaseProperty> allProperties = [];

      
//       final timeout = Duration(seconds: 3);

      
//       final residentialQuery = await FirebaseFirestore.instance
//           .collection('Residential')
//           .where('leadId', isEqualTo: leadId)
//           .where('status', isNotEqualTo: 'Inactive')
//           .get()
//           .timeout(timeout);

//       for (final doc in residentialQuery.docs) {
//         try {
//           final property = ResidentialProperty.fromMap(doc.data(), doc.id);
//           allProperties.add(property);
//         } catch (e) {
//           print('Error parsing Residential property ${doc.id}: $e');
//         }
//       }

      
//       final commercialQuery = await FirebaseFirestore.instance
//           .collection('Commercial')
//           .where('leadId', isEqualTo: leadId)
//           .where('status', isNotEqualTo: 'Inactive')
//           .get()
//           .timeout(timeout);

//       for (final doc in commercialQuery.docs) {
//         try {
//           final property = CommercialProperty.fromMap(doc.data(), doc.id);
//           allProperties.add(property);
//         } catch (e) {
//           print('Error parsing Commercial property ${doc.id}: $e');
//         }
//       }

      
//       final plotsQuery = await FirebaseFirestore.instance
//           .collection('Plots')
//           .where('leadId', isEqualTo: leadId)
//           .where('status', isNotEqualTo: 'Inactive')
//           .get()
//           .timeout(timeout);

//       for (final doc in plotsQuery.docs) {
//         try {
//           final property = LandProperty.fromMap(doc.data(), doc.id);
//           allProperties.add(property);
//         } catch (e) {
//           print('Error parsing Land property ${doc.id}: $e');
//         }
//       }

//       return allProperties;
//     } catch (e) {
//       print('Error fetching properties for lead $leadId: $e');
//       return [];
//     }
//   }

  
//   Map<String, dynamic> _formatLeadDataForDisplay(CallLeadData leadData) {
    
//     final lead = leadData.lead;
//     final properties = leadData.properties;

//     String propertyInfo = '';
//     String locationInfo = '';
//     String priceInfo = '';
//     String detailsInfo = '';

//     if (properties.isNotEmpty) {
//       final primaryProperty = properties.first;

//       if (primaryProperty is ResidentialProperty) {
//         propertyInfo =
//             '🏠 ${primaryProperty.selectedBHK ?? 'Residential'} • ${primaryProperty.propertyFor}';
//         locationInfo =
//             primaryProperty.location?.split(',').first.trim() ??
//             'Location not specified';
//         priceInfo = _formatPrice(primaryProperty.askingPrice);

//         final facilities = primaryProperty.facilities.take(2).join(', ');
//         final preferences = primaryProperty.preferences.take(2).join(', ');
//         detailsInfo = [
//           if (facilities.isNotEmpty) '🛠️ $facilities',
//           if (preferences.isNotEmpty) '👥 $preferences',
//         ].join(' • ');
//       } else if (primaryProperty is CommercialProperty) {
//         propertyInfo =
//             '🏢 ${primaryProperty.propertySubType} • ${primaryProperty.propertyFor}';
//         locationInfo =
//             primaryProperty.location?.split(',').first.trim() ??
//             'Location not specified';
//         priceInfo = _formatPrice(primaryProperty.askingPrice);
//         detailsInfo = [
//           if (primaryProperty.squareFeet?.isNotEmpty == true)
//             '📏 ${primaryProperty.squareFeet} sq ft',
//           if (primaryProperty.furnished?.isNotEmpty == true)
//             primaryProperty.furnished!,
//         ].join(' • ');
//       } else if (primaryProperty is LandProperty) {
//         propertyInfo =
//             '🏞️ ${primaryProperty.propertySubType} • ${primaryProperty.propertyFor}';
//         locationInfo =
//             primaryProperty.location?.split(',').first.trim() ??
//             'Location not specified';
//         priceInfo = _formatPrice(primaryProperty.askingPrice);

//         final areaInfo = _getAreaDisplayText(primaryProperty);
//         detailsInfo = areaInfo.isNotEmpty ? areaInfo : 'Land property';
//       }
//     }

//     return {
//       'leadName': lead.name,
//       'leadType': lead.leadType,
//       'leadStatus': lead.status,
//       'phoneNumber': lead.phoneNumber,
//       'propertyInfo':
//           propertyInfo.isEmpty ? 'No property details' : propertyInfo,
//       'locationInfo':
//           locationInfo.isEmpty ? 'Location not specified' : locationInfo,
//       'priceInfo': priceInfo.isEmpty ? 'Price not specified' : priceInfo,
//       'detailsInfo':
//           detailsInfo.isEmpty ? 'No additional details' : detailsInfo,
//       'propertiesCount': properties.length,
//       'hasMultipleProperties': properties.length > 1,
//     };
//   }

//   String _cleanPhoneNumber(String phoneNumber) {
//     String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

//     if (cleaned.startsWith('91') && cleaned.length == 12) {
//       cleaned = cleaned.substring(2);
//     } else if (cleaned.startsWith('1') && cleaned.length == 11) {
//       cleaned = cleaned.substring(1);
//     } else if (cleaned.startsWith('44') && cleaned.length > 10) {
//       cleaned = cleaned.substring(2);
//     }

//     return cleaned.length >= 10
//         ? cleaned
//         : phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
//   }

//   String _formatPrice(String? price) {
//     if (price == null || price.isEmpty) return '';

//     String cleanPrice = price.replaceAll(RegExp(r'[^\d.]'), '');
//     if (cleanPrice.isEmpty) return price;

//     try {
//       double amount = double.parse(cleanPrice);

//       if (amount >= 10000000) {
//         return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
//       } else if (amount >= 100000) {
//         return '₹${(amount / 100000).toStringAsFixed(1)}L';
//       } else if (amount >= 1000) {
//         return '₹${(amount / 1000).toStringAsFixed(1)}K';
//       } else {
//         return '₹${amount.toStringAsFixed(0)}';
//       }
//     } catch (e) {
//       return price;
//     }
//   }

//   String _getAreaDisplayText(LandProperty property) {
//     final List<String> areaParts = [];

//     if (property.cents?.isNotEmpty == true && property.cents != '0') {
//       areaParts.add('${property.cents} cents');
//     }

//     if (property.acres?.isNotEmpty == true && property.acres != '0') {
//       areaParts.add('${property.acres} acres');
//     }

//     if (areaParts.isNotEmpty) {
//       return '📏 ${areaParts.join(', ')}';
//     }

//     return '';
//   }

//   void dispose() {
//     _callLeadController.close();
//   }
// }


// class CallLeadData {
//   final LeadModel lead;
//   final List<BaseProperty> properties;

//   CallLeadData({required this.lead, required this.properties});
// }

// abstract class BaseProperty {
//   String get id;
//   String get leadId;
//   String get propertyFor;
//   String? get location;
//   String? get askingPrice;

//   Map<String, dynamic> toMap();
// }

// class LeadModel {
//   final String? id;
//   final String name;
//   final String leadType;
//   final String status;
//   final String phoneNumber;

//   LeadModel({
//     this.id,
//     required this.name,
//     required this.leadType,
//     required this.status,
//     required this.phoneNumber,
//   });

//   factory LeadModel.fromMap(Map<String, dynamic> map, String id) {
//     return LeadModel(
//       id: id,
//       name: map['name'] ?? '',
//       leadType: map['leadType'] ?? '',
//       status: map['status'] ?? '',
//       phoneNumber: map['phoneNumber'] ?? '',
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'name': name,
//       'leadType': leadType,
//       'status': status,
//       'phoneNumber': phoneNumber,
//     };
//   }
// }

// class ResidentialProperty extends BaseProperty {
//   @override
//   final String id;
//   @override
//   final String leadId;
//   @override
//   final String propertyFor;
//   @override
//   final String? location;
//   @override
//   final String? askingPrice;
//   final String? selectedBHK;
//   final List<String> facilities;
//   final List<String> preferences;

//   ResidentialProperty({
//     required this.id,
//     required this.leadId,
//     required this.propertyFor,
//     this.location,
//     this.askingPrice,
//     this.selectedBHK,
//     this.facilities = const [],
//     this.preferences = const [],
//   });

//   factory ResidentialProperty.fromMap(Map<String, dynamic> map, String id) {
//     return ResidentialProperty(
//       id: id,
//       leadId: map['leadId'] ?? '',
//       propertyFor: map['propertyFor'] ?? '',
//       location: map['location'],
//       askingPrice: map['askingPrice'],
//       selectedBHK: map['selectedBHK'],
//       facilities: List<String>.from(map['facilities'] ?? []),
//       preferences: List<String>.from(map['preferences'] ?? []),
//     );
//   }

//   @override
//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'leadId': leadId,
//       'propertyFor': propertyFor,
//       'location': location,
//       'askingPrice': askingPrice,
//       'selectedBHK': selectedBHK,
//       'facilities': facilities,
//       'preferences': preferences,
//       'type': 'Residential',
//     };
//   }
// }

// class CommercialProperty extends BaseProperty {
//   @override
//   final String id;
//   @override
//   final String leadId;
//   @override
//   final String propertyFor;
//   @override
//   final String? location;
//   @override
//   final String? askingPrice;
//   final String propertySubType;
//   final String? squareFeet;
//   final String? furnished;
//   final String? facilities;

//   CommercialProperty({
//     required this.id,
//     required this.leadId,
//     required this.propertyFor,
//     this.location,
//     this.askingPrice,
//     required this.propertySubType,
//     this.squareFeet,
//     this.furnished,
//     this.facilities,
//   });

//   factory CommercialProperty.fromMap(Map<String, dynamic> map, String id) {
//     return CommercialProperty(
//       id: id,
//       leadId: map['leadId'] ?? '',
//       propertyFor: map['propertyFor'] ?? '',
//       location: map['location'],
//       askingPrice: map['askingPrice'],
//       propertySubType: map['propertySubType'] ?? '',
//       squareFeet: map['squareFeet'],
//       furnished: map['furnished'],
//       facilities: map['facilities'],
//     );
//   }

//   @override
//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'leadId': leadId,
//       'propertyFor': propertyFor,
//       'location': location,
//       'askingPrice': askingPrice,
//       'propertySubType': propertySubType,
//       'squareFeet': squareFeet,
//       'furnished': furnished,
//       'facilities': facilities,
//       'type': 'Commercial',
//     };
//   }
// }

// class LandProperty extends BaseProperty {
//   @override
//   final String id;
//   @override
//   final String leadId;
//   @override
//   final String propertyFor;
//   @override
//   final String? location;
//   @override
//   final String? askingPrice;
//   final String propertySubType;
//   final String? cents;
//   final String? acres;
//   final String? additionalNotes;

//   LandProperty({
//     required this.id,
//     required this.leadId,
//     required this.propertyFor,
//     this.location,
//     this.askingPrice,
//     required this.propertySubType,
//     this.cents,
//     this.acres,
//     this.additionalNotes,
//   });

//   factory LandProperty.fromMap(Map<String, dynamic> map, String id) {
//     return LandProperty(
//       id: id,
//       leadId: map['leadId'] ?? '',
//       propertyFor: map['propertyFor'] ?? '',
//       location: map['location'],
//       askingPrice: map['askingPrice'],
//       propertySubType: map['propertySubType'] ?? '',
//       cents: map['cents'],
//       acres: map['acres'],
//       additionalNotes: map['additionalNotes'],
//     );
//   }

//   @override
//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'leadId': leadId,
//       'propertyFor': propertyFor,
//       'location': location,
//       'askingPrice': askingPrice,
//       'propertySubType': propertySubType,
//       'cents': cents,
//       'acres': acres,
//       'additionalNotes': additionalNotes,
//       'type': 'Land',
//     };
//   }
// }