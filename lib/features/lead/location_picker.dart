import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:taro_mobile/core/constants/colors.dart';

// class LocationPickerScreen extends StatefulWidget {
//   final String? initialValue;
//   final Function(String address, LatLng coordinates)? onLocationSelected;

//   const LocationPickerScreen({
//     Key? key,
//     this.initialValue,
//     this.onLocationSelected,
//   }) : super(key: key);

//   @override
//   _LocationPickerScreenState createState() => _LocationPickerScreenState();
// }

// class _LocationPickerScreenState extends State<LocationPickerScreen>
//     with TickerProviderStateMixin {
//   final MapController _mapController = MapController();
//   final TextEditingController _searchController = TextEditingController();
//   late AnimationController _animationController;
//   late AnimationController _pulseController;

//   LatLng _selectedLocation = LatLng(
//     28.6139,
//     77.2090,
//   ); // Default to New Delhi, India
//   String _selectedAddress = '';
//   List<SearchResult> _searchResults = [];
//   bool _isSearching = false;
//   bool _isLoadingLocation = true;
//   bool _showSearchResults = false;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _pulseController = AnimationController(
//       duration: Duration(milliseconds: 1500),
//       vsync: this,
//     )..repeat();

//     // Set initial value if provided
//     if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
//       _selectedAddress = widget.initialValue!;
//     }

//     _getCurrentLocation();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _pulseController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }

//   Future<void> _getCurrentLocation() async {
//     setState(() {
//       _isLoadingLocation = true;
//     });

//     try {
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//       }

//       if (permission == LocationPermission.whileInUse ||
//           permission == LocationPermission.always) {
//         Position position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high,
//         );

//         final newLocation = LatLng(position.latitude, position.longitude);
//         setState(() {
//           _selectedLocation = newLocation;
//           _isLoadingLocation = false;
//         });

//         _mapController.move(_selectedLocation, 16.0);

//         // Only update address if no initial value was provided
//         if (widget.initialValue == null || widget.initialValue!.isEmpty) {
//           await _reverseGeocode(_selectedLocation);
//         }
//       } else {
//         setState(() {
//           _isLoadingLocation = false;
//         });
//       }
//     } catch (e) {
//       print('Error getting current location: $e');
//       setState(() {
//         _isLoadingLocation = false;
//       });
//     }
//   }

//   Future<void> _searchLocation(String query) async {
//     if (query.isEmpty) {
//       setState(() {
//         _searchResults = [];
//         _showSearchResults = false;
//       });
//       _animationController.reverse();
//       return;
//     }

//     setState(() {
//       _isSearching = true;
//       _showSearchResults = true;
//     });
//     _animationController.forward();

//     try {
//       await Future.delayed(Duration(milliseconds: 300)); // Debounce

//       final url =
//           'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=8&addressdetails=1&countrycodes=in';
//       final response = await http.get(
//         Uri.parse(url),
//         headers: {'User-Agent': 'YourAppName/1.0'},
//       );

//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body);
//         setState(() {
//           _searchResults =
//               data.map((item) => SearchResult.fromJson(item)).toList();
//           _isSearching = false;
//         });
//       }
//     } catch (e) {
//       print('Search error: $e');
//       setState(() {
//         _isSearching = false;
//       });
//     }
//   }

//   Future<void> _reverseGeocode(LatLng location) async {
//     try {
//       final url =
//           'https://nominatim.openstreetmap.org/reverse?lat=${location.latitude}&lon=${location.longitude}&format=json&addressdetails=1';
//       final response = await http.get(
//         Uri.parse(url),
//         headers: {'User-Agent': 'YourAppName/1.0'},
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           _selectedAddress = data['display_name'] ?? 'Unknown location';
//         });
//       }
//     } catch (e) {
//       print('Reverse geocoding error: $e');
//     }
//   }

//   void _selectLocation(LatLng location, String address) {
//     setState(() {
//       _selectedLocation = location;
//       _selectedAddress = address.isNotEmpty ? address : _selectedAddress;
//       _searchResults = [];
//       _showSearchResults = false;
//       _searchController.clear();
//     });
//     _animationController.reverse();
//     _mapController.move(location, 16.0);

//     // If address is empty, get it via reverse geocoding
//     if (address.isEmpty) {
//       _reverseGeocode(location);
//     }
//   }

//   void _confirmSelection() {
//     // Return the selected location data to the calling screen
//     Navigator.pop(context, {
//       'address': _selectedAddress,
//       'latitude': _selectedLocation.latitude,
//       'longitude': _selectedLocation.longitude,
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade50,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black87,
//         title: Text(
//           'Select Location',
//           style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
//         ),
//         actions: [
//           Container(
//             margin: EdgeInsets.only(right: 16),
//             child: TextButton(
//               onPressed: _selectedAddress.isNotEmpty ? _confirmSelection : null,
//               style: TextButton.styleFrom(
//                 backgroundColor:
//                     _selectedAddress.isNotEmpty
//                         ? AppColors.textColor
//                         : Colors.grey.shade300,
//                 foregroundColor: Colors.white,
//                 padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//               child: Text(
//                 'DONE',
//                 style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               // Search Section
//               Container(
//                 color: Colors.white,
//                 padding: EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     // Search Bar
//                     Container(
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade100,
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(
//                           color:
//                               _showSearchResults
//                                   ? AppColors.textColor
//                                   : Colors.grey.shade300,
//                           width: 1.5,
//                         ),
//                       ),
//                       child: TextField(
//                         controller: _searchController,
//                         decoration: InputDecoration(
//                           hintText: 'Search for a location...',
//                           hintStyle: TextStyle(color: Colors.grey.shade600),
//                           prefixIcon: Icon(
//                             Icons.search,
//                             color: Colors.grey.shade600,
//                           ),
//                           suffixIcon:
//                               _isSearching
//                                   ? Container(
//                                     width: 20,
//                                     height: 20,
//                                     padding: EdgeInsets.all(12),
//                                     child: CircularProgressIndicator(
//                                       strokeWidth: 2,
//                                       valueColor: AlwaysStoppedAnimation<Color>(
//                                         AppColors.textColor,
//                                       ),
//                                     ),
//                                   )
//                                   : _searchController.text.isNotEmpty
//                                   ? IconButton(
//                                     icon: Icon(
//                                       Icons.clear,
//                                       color: Colors.grey.shade600,
//                                     ),
//                                     onPressed: () {
//                                       _searchController.clear();
//                                       _searchLocation('');
//                                     },
//                                   )
//                                   : null,
//                           border: InputBorder.none,
//                           contentPadding: EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 16,
//                           ),
//                         ),
//                         onChanged: _searchLocation,
//                       ),
//                     ),

//                     // Selected Location Display
//                     if (_selectedAddress.isNotEmpty) ...[
//                       SizedBox(height: 12),
//                       Container(
//                         width: double.infinity,
//                         padding: EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [Colors.blue.shade50, Colors.blue.shade100],
//                           ),
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(color: Colors.blue.shade200),
//                         ),
//                         child: Row(
//                           children: [
//                             Icon(
//                               Icons.location_on,
//                               color: AppColors.textColor,
//                               size: 20,
//                             ),
//                             SizedBox(width: 8),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'Selected Location',
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.w500,
//                                       color: Colors.blue.shade700,
//                                     ),
//                                   ),
//                                   SizedBox(height: 2),
//                                   Text(
//                                     _selectedAddress,
//                                     style: TextStyle(
//                                       fontSize: 14,
//                                       color: AppColors.textColor,
//                                       fontWeight: FontWeight.w400,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),

//               // Map Section
//               Expanded(
//                 child: Container(
//                   margin: EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 10,
//                         offset: Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(16),
//                     child: FlutterMap(
//                       mapController: _mapController,
//                       options: MapOptions(
//                         center: _selectedLocation,
//                         zoom: 16.0,
//                         onTap: (tapPosition, point) {
//                           _selectLocation(point, '');
//                         },
//                       ),
//                       children: [
//                         TileLayer(
//                           urlTemplate:
//                               'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//                           userAgentPackageName: 'com.example.app',
//                         ),
//                         MarkerLayer(
//                           markers: [
//                             Marker(
//                               width: 50.0,
//                               height: 50.0,
//                               point: _selectedLocation,
//                               child: AnimatedBuilder(
//                                 animation: _pulseController,
//                                 builder: (context, child) {
//                                   return Stack(
//                                     alignment: Alignment.center,
//                                     children: [
//                                       // Pulse effect
//                                       Container(
//                                         width:
//                                             50 *
//                                             (1 + _pulseController.value * 0.3),
//                                         height:
//                                             50 *
//                                             (1 + _pulseController.value * 0.3),
//                                         decoration: BoxDecoration(
//                                           shape: BoxShape.circle,
//                                           color: Colors.red.withOpacity(
//                                             0.3 * (1 - _pulseController.value),
//                                           ),
//                                         ),
//                                       ),
//                                       // Main marker
//                                       Container(
//                                         width: 40,
//                                         height: 40,
//                                         decoration: BoxDecoration(
//                                           color: Colors.red,
//                                           shape: BoxShape.circle,
//                                           border: Border.all(
//                                             color: Colors.white,
//                                             width: 3,
//                                           ),
//                                           boxShadow: [
//                                             BoxShadow(
//                                               color: Colors.black.withOpacity(
//                                                 0.2,
//                                               ),
//                                               blurRadius: 6,
//                                               offset: Offset(0, 3),
//                                             ),
//                                           ],
//                                         ),
//                                         child: Icon(
//                                           Icons.location_on,
//                                           color: Colors.white,
//                                           size: 24,
//                                         ),
//                                       ),
//                                     ],
//                                   );
//                                 },
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           // Search Results Overlay
//           if (_showSearchResults)
//             Positioned(
//               top: _selectedAddress.isNotEmpty ? 140 : 100,
//               left: 16,
//               right: 16,
//               child: SlideTransition(
//                 position: Tween<Offset>(
//                   begin: Offset(0, -0.2),
//                   end: Offset.zero,
//                 ).animate(
//                   CurvedAnimation(
//                     parent: _animationController,
//                     curve: Curves.easeOutBack,
//                   ),
//                 ),
//                 child: FadeTransition(
//                   opacity: _animationController,
//                   child: Container(
//                     constraints: BoxConstraints(maxHeight: 300),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.15),
//                           blurRadius: 20,
//                           offset: Offset(0, 8),
//                         ),
//                       ],
//                     ),
//                     child: ListView.separated(
//                       shrinkWrap: true,
//                       itemCount: _searchResults.length,
//                       separatorBuilder:
//                           (context, index) =>
//                               Divider(height: 1, color: Colors.grey.shade200),
//                       itemBuilder: (context, index) {
//                         final result = _searchResults[index];
//                         return ListTile(
//                           contentPadding: EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 8,
//                           ),
//                           leading: Container(
//                             padding: EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: Colors.blue.shade50,
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Icon(
//                               Icons.location_on,
//                               color: AppColors.textColor,
//                               size: 20,
//                             ),
//                           ),
//                           title: Text(
//                             result.displayName,
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w500,
//                             ),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           trailing: Container(
//                             padding: EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 6,
//                             ),
//                             decoration: BoxDecoration(
//                               color: AppColors.textColor,
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             child: Text(
//                               'SELECT',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                           onTap: () {
//                             _selectLocation(
//                               LatLng(result.lat, result.lon),
//                               result.displayName,
//                             );
//                           },
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//           // Loading Overlay
//           if (_isLoadingLocation)
//             Container(
//               color: Colors.black.withOpacity(0.3),
//               child: Center(
//                 child: Container(
//                   padding: EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       CircularProgressIndicator(
//                         valueColor: AlwaysStoppedAnimation<Color>(
//                           AppColors.textColor,
//                         ),
//                       ),
//                       SizedBox(height: 16),
//                       Text(
//                         'Getting your location...',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _getCurrentLocation,
//         backgroundColor: AppColors.textColor,
//         child: Icon(Icons.my_location, color: Colors.white),
//         tooltip: 'Get current location',
//       ),
//     );
//   }
// }

// // Enhanced Search result model
// class SearchResult {
//   final String displayName;
//   final double lat;
//   final double lon;
//   final String? type;
//   final String? importance;

//   SearchResult({
//     required this.displayName,
//     required this.lat,
//     required this.lon,
//     this.type,
//     this.importance,
//   });

//   factory SearchResult.fromJson(Map<String, dynamic> json) {
//     return SearchResult(
//       displayName: json['display_name'] ?? '',
//       lat: double.parse(json['lat'] ?? '0'),
//       lon: double.parse(json['lon'] ?? '0'),
//       type: json['type'],
//       importance: json['importance']?.toString(),
//     );
//   }
// }

// // Enhanced widget for map text field with location data storage
class LocationData {
  final String address;
  final double latitude;
  final double longitude;

  LocationData({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() => address;

  // Convert to Map for easy serialization
  Map<String, dynamic> toMap() {
    return {'address': address, 'latitude': latitude, 'longitude': longitude};
  }

  // Create from Map
  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      address: map['address'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
    );
  }
}

// // FIXED: Simplified and working buildMapTextField
// Widget buildMapTextField(
//   BuildContext context,
//   String label,
//   LocationData? locationData,
//   Function(LocationData?) onChanged,
// ) {
//   final TextEditingController controller = TextEditingController(
//     text: locationData?.address ?? '',
//   );

//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
//       SizedBox(height: 8),
//       TextFormField(
//         controller: controller,
//         decoration: InputDecoration(
//           hintText: 'Location',
//           contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 20),
//           filled: true,
//           fillColor: Colors.white,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(16),
//             borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(16),
//             borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(16),
//             borderSide: BorderSide(color: Colors.blue.shade300, width: 1.2),
//           ),
//           suffixIcon: Container(
//             height: 60,
//             decoration: BoxDecoration(
//               color: AppColors.textColor,
//               borderRadius: BorderRadius.only(
//                 topRight: Radius.circular(8),
//                 bottomRight: Radius.circular(8),
//               ),
//             ),
//             child: IconButton(
//               icon: Icon(Icons.place, color: Colors.white),
//               onPressed: () async {
//                 final result = await Navigator.push<Map<String, dynamic>>(
//                   context,
//                   MaterialPageRoute(
//                     builder:
//                         (context) => LocationPickerScreen(
//                           initialValue: locationData?.address,
//                         ),
//                   ),
//                 );

//                 if (result != null) {
//                   final newLocationData = LocationData(
//                     address: result['address'] ?? '',
//                     latitude: result['latitude']?.toDouble() ?? 0.0,
//                     longitude: result['longitude']?.toDouble() ?? 0.0,
//                   );

//                   controller.text = newLocationData.address;
//                   onChanged(newLocationData);
//                 }
//               },
//             ),
//           ),
//         ),
//         readOnly: true,
//         onTap: () async {
//           final result = await Navigator.push<Map<String, dynamic>>(
//             context,
//             MaterialPageRoute(
//               builder:
//                   (context) =>
//                       LocationPickerScreen(initialValue: locationData?.address),
//             ),
//           );

//           if (result != null) {
//             final newLocationData = LocationData(
//               address: result['address'] ?? '',
//               latitude: result['latitude']?.toDouble() ?? 0.0,
//               longitude: result['longitude']?.toDouble() ?? 0.0,
//             );

//             controller.text = newLocationData.address;
//             onChanged(newLocationData);
//           }
//         },
//       ),
//     ],
//   );
// }

// // Example usage in your form
// class ExampleForm extends StatefulWidget {
//   @override
//   _ExampleFormState createState() => _ExampleFormState();
// }

// class _ExampleFormState extends State<ExampleForm> {
//   LocationData? _homeLocation;
//   LocationData? _workLocation;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Location Form Example')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             buildMapTextField(context, 'Home Location', _homeLocation, (
//               LocationData? locationData,
//             ) {
//               setState(() {
//                 _homeLocation = locationData;
//               });
//               print('Home location: ${locationData?.address}');
//               print(
//                 'Coordinates: ${locationData?.latitude}, ${locationData?.longitude}',
//               );
//             }),
//             SizedBox(height: 20),
//             buildMapTextField(context, 'Work Location', _workLocation, (
//               LocationData? locationData,
//             ) {
//               setState(() {
//                 _workLocation = locationData;
//               });
//               print('Work location: ${locationData?.address}');
//               print(
//                 'Coordinates: ${locationData?.latitude}, ${locationData?.longitude}',
//               );
//             }),
//             SizedBox(height: 30),
//             ElevatedButton(
//               onPressed: () {
//                 // Access the selected locations
//                 if (_homeLocation != null) {
//                   print('Home: ${_homeLocation!.address}');
//                   print(
//                     'Home Coords: ${_homeLocation!.latitude}, ${_homeLocation!.longitude}',
//                   );
//                 }
//                 if (_workLocation != null) {
//                   print('Work: ${_workLocation!.address}');
//                   print(
//                     'Work Coords: ${_workLocation!.latitude}, ${_workLocation!.longitude}',
//                   );
//                 }
//               },
//               child: Text('Print Selected Locations'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }import 'package:flutter/material.dart';

class LocationSearchTextField extends StatefulWidget {
  final TextEditingController? controller; // now optional
  final String? initialValue;
  final Function(Map<String, dynamic>) onLocationSelected;
  final String? hintText;
  final InputDecoration? decoration;

  const LocationSearchTextField({
    Key? key,
    this.initialValue,
    this.controller,
    required this.onLocationSelected,
    this.hintText,
    this.decoration,
  }) : super(key: key);

  @override
  _LocationSearchTextFieldState createState() =>
      _LocationSearchTextFieldState();
}

class _LocationSearchTextFieldState extends State<LocationSearchTextField>
    with TickerProviderStateMixin {
  late TextEditingController _searchController;
  late AnimationController _animationController;

  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;

  // Add these for proper lifecycle management
  Timer? _debounceTimer;
  http.Client? _httpClient;

  @override
  void initState() {
    super.initState();

    // Use provided controller or create a new one
    _searchController = widget.controller ?? TextEditingController();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize HTTP client
    _httpClient = http.Client();

    // Set initial value if provided
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      _searchController.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    // Cancel any pending operations
    _debounceTimer?.cancel();
    _httpClient?.close();

    _animationController.dispose();
    // Only dispose the controller if we created it (not provided externally)
    if (widget.controller == null) {
      _searchController.dispose();
    }
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    // Cancel previous timer
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      _animationController.reverse();
      return;
    }

    // Set up debounce timer
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      if (mounted) {
        _performSearch(query);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
      _showSearchResults = true;
    });
    _animationController.forward();

    try {
      final url =
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=8&addressdetails=1&countrycodes=in';

      final response = await _httpClient!.get(
        Uri.parse(url),
        headers: {'User-Agent': 'YourAppName/1.0'},
      );

      // Check if widget is still mounted after async operation
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults =
              data.map((item) => SearchResult.fromJson(item)).toList();
          _isSearching = false;
        });
      } else {
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
      }
    } catch (e) {
      print('Search error: $e');
      // Check if widget is still mounted before calling setState
      if (!mounted) return;

      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    }
  }

  void _selectLocation(SearchResult result) {
    if (!mounted) return;

    setState(() {
      _searchController.text = result.displayName;
      _searchResults = [];
      _showSearchResults = false;
    });
    _animationController.reverse();

    // Return location data
    widget.onLocationSelected({
      'address': result.displayName,
      'latitude': result.lat,
      'longitude': result.lon,
    });
  }

  void _selectOtherLocation() {
    if (!mounted) return;

    setState(() {
      _searchResults = [];
      _showSearchResults = false;
    });
    _animationController.reverse();

    // Return the manually entered text as location
    widget.onLocationSelected({
      'address': _searchController.text,
      'latitude': 0.0, // Default values for manual entry
      'longitude': 0.0,
      'isManualEntry': true, // Flag to indicate this is a manual entry
    });
  }

  void _clearSearch() {
    if (!mounted) return;

    _searchController.clear();
    _searchLocation('');
    widget.onLocationSelected({
      'address': '',
      'latitude': 0.0,
      'longitude': 0.0,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search TextField
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  _showSearchResults
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: _searchController,
            decoration: (widget.decoration ?? InputDecoration()).copyWith(
              hintText: widget.hintText ?? 'Search for a location...',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
              suffixIcon:
                  _isSearching
                      ? Container(
                        width: 20,
                        height: 20,
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      )
                      : _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade600),
                        onPressed: _clearSearch,
                      )
                      : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: _searchLocation,
          ),
        ),

        // Search Results Dropdown
        if (_showSearchResults)
          SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, -0.2),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeOutBack,
              ),
            ),
            child: FadeTransition(
              opacity: _animationController,
              child: Container(
                margin: EdgeInsets.only(top: 4),
                constraints: BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child:
                    _searchResults.isEmpty && !_isSearching
                        ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // No results message
                            Container(
                              height: 60,
                              child: Center(
                                child: Text(
                                  'No locations found',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            // Divider
                            Divider(height: 1, color: Colors.grey.shade200),
                            // Other option
                            ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.edit_location,
                                  color: Colors.orange.shade600,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                'Use "${_searchController.text}" as location',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'Add custom location',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              trailing: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade600,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'OTHER',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              onTap: _selectOtherLocation,
                            ),
                          ],
                        )
                        : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          separatorBuilder:
                              (context, index) => Divider(
                                height: 1,
                                color: Colors.grey.shade200,
                              ),
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];
                            return ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                result.displayName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'SELECT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              onTap: () => _selectLocation(result),
                            );
                          },
                        ),
              ),
            ),
          ),
      ],
    );
  }
}

// SearchResult model class
class SearchResult {
  final String displayName;
  final double lat;
  final double lon;

  SearchResult({
    required this.displayName,
    required this.lat,
    required this.lon,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      displayName: json['display_name'] ?? '',
      lat: double.tryParse(json['lat'].toString()) ?? 0.0,
      lon: double.tryParse(json['lon'].toString()) ?? 0.0,
    );
  }
}
