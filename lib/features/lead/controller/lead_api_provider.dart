import 'package:flutter/material.dart';
import 'package:taro_mobile/core/models/api_models.dart';
import 'package:taro_mobile/features/lead/repository/lead_repository.dart';

class LeadApiProvider extends ChangeNotifier {
  final LeadRepository _repository = LeadRepository();

  List<LeadModel> _leads = [];
  LeadModel? _selectedLead;
  bool _isLoading = false;
  String? _error;
  int _total = 0;
  int _currentPage = 1;
  int _pageSize = 20;
  bool _hasMore = true;

  // Search filters
  String? _orgSlug;
  String? _searchQuery;
  List<String>? _statusFilter;
  List<String>? _assignedToFilter;
  String? _propertyIdFilter;
  List<String>? _tagsFilter;
  DateRange? _dateRange;
  SortOptions? _sortOptions;

  // Getters
  List<LeadModel> get leads => _leads;
  LeadModel? get selectedLead => _selectedLead;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get total => _total;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;

  // Filter getters
  String? get orgSlug => _orgSlug;
  String? get searchQuery => _searchQuery;
  List<String>? get statusFilter => _statusFilter;
  List<String>? get assignedToFilter => _assignedToFilter;
  String? get propertyIdFilter => _propertyIdFilter;
  List<String>? get tagsFilter => _tagsFilter;
  DateRange? get dateRange => _dateRange;
  SortOptions? get sortOptions => _sortOptions;

  /// Search leads
  Future<void> searchLeads({
    String? orgSlug,
    String? query,
    List<String>? status,
    List<String>? assignedTo,
    String? propertyId,
    List<String>? tags,
    DateRange? dateRange,
    SortOptions? sort,
    bool reset = false,
  }) async {
    try {
      if (reset) {
        _currentPage = 1;
        _leads = [];
        _hasMore = true;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      // Update filter state
      _orgSlug = orgSlug;
      _searchQuery = query;
      _statusFilter = status;
      _assignedToFilter = assignedTo;
      _propertyIdFilter = propertyId;
      _tagsFilter = tags;
      _dateRange = dateRange;
      _sortOptions = sort;

      final request = LeadSearchRequest(
        orgSlug: orgSlug,
        query: query,
        status: status,
        assignedTo: assignedTo,
        propertyId: propertyId,
        tags: tags,
        dateRange: dateRange,
        sort: sort,
        page: _currentPage,
        pageSize: _pageSize,
      );

      final response = await _repository.searchLeads(request);

      if (reset) {
        _leads = response.items;
      } else {
        _leads.addAll(response.items);
      }

      _total = response.total;
      _hasMore = response.items.length == _pageSize && _leads.length < _total;
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

  /// Load more leads (pagination)
  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;

    await searchLeads(
      orgSlug: _orgSlug,
      query: _searchQuery,
      status: _statusFilter,
      assignedTo: _assignedToFilter,
      propertyId: _propertyIdFilter,
      tags: _tagsFilter,
      dateRange: _dateRange,
      sort: _sortOptions,
      reset: false,
    );
  }

  /// Get single lead by ID
  Future<void> getLead(String leadId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _selectedLead = await _repository.getLead(leadId: leadId);

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Create lead
  Future<LeadModel?> createLead({
    required String source,
    String? propertyId,
    required String name,
    required String email,
    required String phone,
    String? message,
    required String orgSlug,
    required List<String> tags,
    Map<String, dynamic>? utm,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final lead = await _repository.createLead(
        source: source,
        propertyId: propertyId,
        name: name,
        email: email,
        phone: phone,
        message: message,
        orgSlug: orgSlug,
        tags: tags,
        utm: utm,
      );

      _leads.insert(0, lead);
      _total++;
      _isLoading = false;
      _error = null;
      notifyListeners();
      return lead;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update lead
  Future<bool> updateLead({
    required String leadId,
    String? name,
    String? email,
    String? phone,
    String? message,
    List<String>? tags,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedLead = await _repository.updateLead(
        leadId: leadId,
        name: name,
        email: email,
        phone: phone,
        message: message,
        tags: tags,
      );

      // Update in list
      final index = _leads.indexWhere((l) => l.id == leadId);
      if (index != -1) {
        _leads[index] = updatedLead;
      }

      // Update selected lead if it's the same
      if (_selectedLead?.id == leadId) {
        _selectedLead = updatedLead;
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

  /// Change lead status
  Future<bool> changeLeadStatus({
    required String leadId,
    required String status,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedLead = await _repository.changeLeadStatus(
        leadId: leadId,
        status: status,
      );

      // Update in list
      final index = _leads.indexWhere((l) => l.id == leadId);
      if (index != -1) {
        _leads[index] = updatedLead;
      }

      if (_selectedLead?.id == leadId) {
        _selectedLead = updatedLead;
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

  /// Assign lead
  Future<bool> assignLead({
    required String leadId,
    required String userId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedLead = await _repository.assignLead(
        leadId: leadId,
        userId: userId,
      );

      // Update in list
      final index = _leads.indexWhere((l) => l.id == leadId);
      if (index != -1) {
        _leads[index] = updatedLead;
      }

      if (_selectedLead?.id == leadId) {
        _selectedLead = updatedLead;
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

  /// Add lead note
  Future<LeadNote?> addLeadNote({
    required String leadId,
    required String text,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final note = await _repository.addLeadNote(
        leadId: leadId,
        text: text,
      );

      // Refresh lead to get updated timeline
      await getLead(leadId);

      _isLoading = false;
      _error = null;
      notifyListeners();
      return note;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Delete lead
  Future<bool> deleteLead(String leadId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.deleteLead(leadId: leadId);

      _leads.removeWhere((l) => l.id == leadId);
      if (_selectedLead?.id == leadId) {
        _selectedLead = null;
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

  /// Clear filters and reset
  void clearFilters() {
    _orgSlug = null;
    _searchQuery = null;
    _statusFilter = null;
    _assignedToFilter = null;
    _propertyIdFilter = null;
    _tagsFilter = null;
    _dateRange = null;
    _sortOptions = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

