import 'dart:io';
import 'package:flutter/material.dart';
import 'package:taro_mobile/core/models/api_models.dart';
import 'package:taro_mobile/features/properties/repository/property_repository.dart';

class PropertyProvider extends ChangeNotifier {
  final PropertyRepository _repository = PropertyRepository();

  List<PropertyModel> _properties = [];
  PropertyModel? _selectedProperty;
  bool _isLoading = false;
  String? _error;
  int _total = 0;
  int _currentPage = 1;
  int _pageSize = 20;
  bool _hasMore = true;

  // Search filters
  String? _orgSlug;
  String? _searchQuery;
  List<String>? _typeFilter;
  List<String>? _statusFilter;
  double? _minPrice;
  double? _maxPrice;
  BedroomRange? _bedroomRange;
  BathroomRange? _bathroomRange;
  List<String>? _amenitiesFilter;
  NearLocation? _nearLocation;
  SortOptions? _sortOptions;

  // Getters
  List<PropertyModel> get properties => _properties;
  PropertyModel? get selectedProperty => _selectedProperty;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get total => _total;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;

  // Filter getters
  String? get orgSlug => _orgSlug;
  String? get searchQuery => _searchQuery;
  List<String>? get typeFilter => _typeFilter;
  List<String>? get statusFilter => _statusFilter;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  BedroomRange? get bedroomRange => _bedroomRange;
  BathroomRange? get bathroomRange => _bathroomRange;
  List<String>? get amenitiesFilter => _amenitiesFilter;
  NearLocation? get nearLocation => _nearLocation;
  SortOptions? get sortOptions => _sortOptions;

  /// Fetch properties with search
  Future<void> searchProperties({
    String? orgSlug,
    String? query,
    List<String>? type,
    List<String>? status,
    double? minPrice,
    double? maxPrice,
    BedroomRange? bedrooms,
    BathroomRange? bathrooms,
    List<String>? amenities,
    NearLocation? near,
    SortOptions? sort,
    bool reset = false,
  }) async {
    try {
      if (reset) {
        _currentPage = 1;
        _properties = [];
        _hasMore = true;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      // Update filter state
      _orgSlug = orgSlug;
      _searchQuery = query;
      _typeFilter = type;
      _statusFilter = status;
      _minPrice = minPrice;
      _maxPrice = maxPrice;
      _bedroomRange = bedrooms;
      _bathroomRange = bathrooms;
      _amenitiesFilter = amenities;
      _nearLocation = near;
      _sortOptions = sort;

      final request = PropertySearchRequest(
        orgSlug: orgSlug,
        query: query,
        type: type,
        status: status,
        minPrice: minPrice,
        maxPrice: maxPrice,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        amenities: amenities,
        near: near,
        sort: sort,
        page: _currentPage,
        pageSize: _pageSize,
      );

      final response = await _repository.searchProperties(request);

      if (reset) {
        _properties = response.items;
      } else {
        _properties.addAll(response.items);
      }

      _total = response.total;
      _hasMore = response.items.length == _pageSize && _properties.length < _total;
      _currentPage++;

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Load more properties (pagination)
  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;

    await searchProperties(
      orgSlug: _orgSlug,
      query: _searchQuery,
      type: _typeFilter,
      status: _statusFilter,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      bedrooms: _bedroomRange,
      bathrooms: _bathroomRange,
      amenities: _amenitiesFilter,
      near: _nearLocation,
      sort: _sortOptions,
      reset: false,
    );
  }

  /// Get single property by ID
  Future<void> getProperty(String propertyId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _selectedProperty = await _repository.getProperty(propertyId: propertyId);

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Create property
  Future<PropertyModel?> createProperty({
    required String title,
    required String type,
    required String status,
    required double price,
    required String currency,
    required Address address,
    required Location location,
    int? bedrooms,
    int? bathrooms,
    double? areaSqFt,
    required List<String> amenities,
    required List<String> images,
    String? description,
    required String orgSlug,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final property = await _repository.createProperty(
        title: title,
        type: type,
        status: status,
        price: price,
        currency: currency,
        address: address,
        location: location,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        areaSqFt: areaSqFt,
        amenities: amenities,
        images: images,
        description: description,
        orgSlug: orgSlug,
      );

      _properties.insert(0, property);
      _total++;
      _isLoading = false;
      _error = null;
      notifyListeners();
      return property;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update property
  Future<bool> updateProperty({
    required String propertyId,
    String? title,
    String? type,
    String? status,
    double? price,
    String? currency,
    Address? address,
    Location? location,
    int? bedrooms,
    int? bathrooms,
    double? areaSqFt,
    List<String>? amenities,
    List<String>? images,
    String? description,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedProperty = await _repository.updateProperty(
        propertyId: propertyId,
        title: title,
        type: type,
        status: status,
        price: price,
        currency: currency,
        address: address,
        location: location,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        areaSqFt: areaSqFt,
        amenities: amenities,
        images: images,
        description: description,
      );

      // Update in list
      final index = _properties.indexWhere((p) => p.id == propertyId);
      if (index != -1) {
        _properties[index] = updatedProperty;
      }

      // Update selected property if it's the same
      if (_selectedProperty?.id == propertyId) {
        _selectedProperty = updatedProperty;
      }

      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete property
  Future<bool> deleteProperty(String propertyId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.deleteProperty(propertyId: propertyId);

      _properties.removeWhere((p) => p.id == propertyId);
      if (_selectedProperty?.id == propertyId) {
        _selectedProperty = null;
      }
      _total--;

      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Change property status
  Future<bool> changePropertyStatus({
    required String propertyId,
    required String status,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedProperty = await _repository.changePropertyStatus(
        propertyId: propertyId,
        status: status,
      );

      // Update in list
      final index = _properties.indexWhere((p) => p.id == propertyId);
      if (index != -1) {
        _properties[index] = updatedProperty;
      }

      if (_selectedProperty?.id == propertyId) {
        _selectedProperty = updatedProperty;
      }

      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Upload property images
  Future<List<UploadedImage>?> uploadPropertyImages({
    required String propertyId,
    required List<dynamic> imageFiles, // List<File>
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Convert dynamic to File
      final files = imageFiles.map((f) => f as File).toList();
      final response = await _repository.uploadPropertyImages(
        propertyId: propertyId,
        imageFiles: files,
      );

      // Update property images
      final index = _properties.indexWhere((p) => p.id == propertyId);
      if (index != -1) {
        final property = _properties[index];
        final updatedImages = List<String>.from(property.images)
          ..addAll(response.uploaded.map((img) => img.url));
        _properties[index] = PropertyModel(
          id: property.id,
          title: property.title,
          type: property.type,
          status: property.status,
          price: property.price,
          currency: property.currency,
          address: property.address,
          location: property.location,
          bedrooms: property.bedrooms,
          bathrooms: property.bathrooms,
          areaSqFt: property.areaSqFt,
          amenities: property.amenities,
          images: updatedImages,
          description: property.description,
          orgSlug: property.orgSlug,
          createdAt: property.createdAt,
          updatedAt: property.updatedAt,
          createdBy: property.createdBy,
        );
      }

      _isLoading = false;
      _error = null;
      notifyListeners();
      return response.uploaded;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Clear filters and reset
  void clearFilters() {
    _orgSlug = null;
    _searchQuery = null;
    _typeFilter = null;
    _statusFilter = null;
    _minPrice = null;
    _maxPrice = null;
    _bedroomRange = null;
    _bathroomRange = null;
    _amenitiesFilter = null;
    _nearLocation = null;
    _sortOptions = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

