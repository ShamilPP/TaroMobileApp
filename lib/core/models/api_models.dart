// 🌐 API Models — Complete Updated Version

class UserModel {
  final String uid;
  final String? orgId;
  final String role;
  final String name;
  final String firstName;
  final String lastName;
  final String? email;
  final String phoneNumber;
  final int tokenVersion;
  final String status;
  final bool isActive;
  final bool isDeleted;
  final String id;
  final String createdAt;
  final String updatedAt;
  final String publicSlug;

  UserModel({
    required this.uid,
    this.orgId,
    required this.role,
    required this.name,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.phoneNumber,
    required this.tokenVersion,
    required this.status,
    required this.isActive,
    required this.isDeleted,
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.publicSlug,
  });

  /// ✅ Parse from API JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      orgId: json['orgId'] as String?,
      role: json['role'] as String? ?? 'Agent',
      name: json['name'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String? ?? '',
      tokenVersion: json['tokenVersion'] as int? ?? 0,
      status: json['status'] as String? ?? 'Active',
      isActive: json['isActive'] as bool? ?? true,
      isDeleted: json['isDeleted'] as bool? ?? false,
      id: json['_id'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      publicSlug: json['publicSlug'] as String? ?? '',
    );
  }

  /// ✅ Convert model → JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'orgId': orgId,
      'role': role,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'tokenVersion': tokenVersion,
      'status': status,
      'isActive': isActive,
      'isDeleted': isDeleted,
      '_id': id,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'publicSlug': publicSlug,
    };
  }

  /// ✅ Easy print in console
  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, phone: $phoneNumber, role: $role, orgId: $orgId)';
  }
}

// ----------------------------------------------------------------------

class OrganizationModel {
  final String id;
  final String name;
  final String slug;
  final String ownerId;
  final String plan;
  final String status;
  final int agentCount;
  final Map<String, dynamic> limits;
  final bool isActive;
  final bool isDeleted;
  final String createdAt;
  final String updatedAt;

  OrganizationModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.ownerId,
    required this.plan,
    required this.status,
    required this.agentCount,
    required this.limits,
    required this.isActive,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  /// ✅ Parse from API JSON
  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      plan: json['plan'] as String? ?? 'free',
      status: json['status'] as String? ?? 'active',
      agentCount: json['agentCount'] as int? ?? 0,
      limits: json['limits'] as Map<String, dynamic>? ?? {},
      isActive: json['isActive'] as bool? ?? true,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  /// ✅ Convert to JSON for logs or caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'ownerId': ownerId,
      'plan': plan,
      'status': status,
      'agentCount': agentCount,
      'limits': limits,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  String toString() {
    return 'OrganizationModel(name: $name, slug: $slug, plan: $plan, status: $status, agentCount: $agentCount)';
  }
}

// ----------------------------------------------------------------------

class OrganizationMemberModel {
  final String id;
  final String orgId;
  final String uid;
  final UserModel user;
  final String role;
  final String status;
  final bool isActive;
  final bool isDeleted;
  final String joinedAt;

  OrganizationMemberModel({
    required this.id,
    required this.orgId,
    required this.uid,
    required this.user,
    required this.role,
    required this.status,
    required this.isActive,
    required this.isDeleted,
    required this.joinedAt,
  });

  factory OrganizationMemberModel.fromJson(Map<String, dynamic> json) {
    return OrganizationMemberModel(
      id: json['_id'] as String? ?? '',
      orgId: json['orgId'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      role: json['role'] as String? ?? 'Agent',
      status: json['status'] as String? ?? 'active',
      isActive: json['isActive'] as bool? ?? true,
      isDeleted: json['isDeleted'] as bool? ?? false,
      joinedAt: json['joinedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'orgId': orgId, 'uid': uid, 'user': user.toJson(), 'role': role, 'status': status, 'isActive': isActive, 'isDeleted': isDeleted, 'joinedAt': joinedAt};
  }

  @override
  String toString() {
    return 'OrganizationMemberModel(uid: $uid, role: $role, user: ${user.name}, joinedAt: $joinedAt)';
  }
}

// ----------------------------------------------------------------------

class OrganizationInviteModel {
  final String id;
  final String orgId;
  final String phone;
  final String role;
  final String token;
  final String expiresAt;
  final bool used;
  final bool isActive;
  final bool isDeleted;
  final String createdAt;
  final String updatedAt;

  OrganizationInviteModel({
    required this.id,
    required this.orgId,
    required this.phone,
    required this.role,
    required this.token,
    required this.expiresAt,
    required this.used,
    required this.isActive,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrganizationInviteModel.fromJson(Map<String, dynamic> json) {
    return OrganizationInviteModel(
      id: json['_id'] as String? ?? '',
      orgId: json['orgId'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'Agent',
      token: json['token'] as String? ?? '',
      expiresAt: json['expiresAt'] as String? ?? '',
      used: json['used'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orgId': orgId,
      'phone': phone,
      'role': role,
      'token': token,
      'expiresAt': expiresAt,
      'used': used,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  String toString() {
    return 'OrganizationInviteModel(phone: $phone, role: $role, used: $used, expiresAt: $expiresAt)';
  }
}

// ----------------------------------------------------------------------

class PaginatedResponse<T> {
  final List<T> data;
  final Paginator paginator;

  PaginatedResponse({required this.data, required this.paginator});

  factory PaginatedResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    return PaginatedResponse<T>(
      data: (json['data'] as List<dynamic>?)?.map((item) => fromJsonT(item as Map<String, dynamic>)).toList() ?? [],
      paginator: Paginator.fromJson(json['paginator'] as Map<String, dynamic>),
    );
  }
}

// ----------------------------------------------------------------------

class Paginator {
  final int itemCount;
  final int perPage;
  final int pageCount;
  final int currentPage;
  final int slNo;
  final bool hasPrevPage;
  final bool hasNextPage;
  final int? prev;
  final int? next;

  Paginator({
    required this.itemCount,
    required this.perPage,
    required this.pageCount,
    required this.currentPage,
    required this.slNo,
    required this.hasPrevPage,
    required this.hasNextPage,
    this.prev,
    this.next,
  });

  factory Paginator.fromJson(Map<String, dynamic> json) {
    return Paginator(
      itemCount: json['itemCount'] as int? ?? 0,
      perPage: json['perPage'] as int? ?? 10,
      pageCount: json['pageCount'] as int? ?? 1,
      currentPage: json['currentPage'] as int? ?? 1,
      slNo: json['slNo'] as int? ?? 1,
      hasPrevPage: json['hasPrevPage'] as bool? ?? false,
      hasNextPage: json['hasNextPage'] as bool? ?? false,
      prev: json['prev'] as int?,
      next: json['next'] as int?,
    );
  }

  @override
  String toString() {
    return 'Paginator(page: $currentPage/$pageCount, items: $itemCount)';
  }
}

// ----------------------------------------------------------------------
// Property Models

class Address {
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  Address({required this.line1, this.line2, required this.city, required this.state, required this.postalCode, required this.country});

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      line1: json['line1'] as String? ?? '',
      line2: json['line2'] as String?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      postalCode: json['postalCode'] as String? ?? '',
      country: json['country'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'line1': line1, if (line2 != null) 'line2': line2, 'city': city, 'state': state, 'postalCode': postalCode, 'country': country};
  }
}

class Location {
  final double lat;
  final double lng;

  Location({required this.lat, required this.lng});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(lat: (json['lat'] as num?)?.toDouble() ?? 0.0, lng: (json['lng'] as num?)?.toDouble() ?? 0.0);
  }

  Map<String, dynamic> toJson() {
    return {'lat': lat, 'lng': lng};
  }
}

class PropertyModel {
  final String id;
  final String title;
  final String type; // "apartment" | "house" | "villa" | "land" | "commercial"
  final String status; // "draft" | "active" | "archived"
  final double price;
  final String currency;
  final Address address;
  final Location location;
  final int? bedrooms;
  final int? bathrooms;
  final double? areaSqFt;
  final List<String> amenities;
  final List<String> images;
  final String? description;
  final String orgSlug;
  final String createdAt;
  final String updatedAt;
  final String? createdBy;

  PropertyModel({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.price,
    required this.currency,
    required this.address,
    required this.location,
    this.bedrooms,
    this.bathrooms,
    this.areaSqFt,
    required this.amenities,
    required this.images,
    this.description,
    required this.orgSlug,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      address: Address.fromJson(json['address'] as Map<String, dynamic>),
      location: Location.fromJson(json['location'] as Map<String, dynamic>),
      bedrooms: json['bedrooms'] as int?,
      bathrooms: json['bathrooms'] as int?,
      areaSqFt: (json['areaSqFt'] as num?)?.toDouble(),
      amenities: (json['amenities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      description: json['description'] as String?,
      orgSlug: json['orgSlug'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      createdBy: json['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'status': status,
      'price': price,
      'currency': currency,
      'address': address.toJson(),
      'location': location.toJson(),
      if (bedrooms != null) 'bedrooms': bedrooms,
      if (bathrooms != null) 'bathrooms': bathrooms,
      if (areaSqFt != null) 'areaSqFt': areaSqFt,
      'amenities': amenities,
      'images': images,
      if (description != null) 'description': description,
      'orgSlug': orgSlug,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (createdBy != null) 'createdBy': createdBy,
    };
  }
}

class PropertySearchRequest {
  final String? orgSlug;
  final String? query;
  final List<String>? type;
  final List<String>? status;
  final double? minPrice;
  final double? maxPrice;
  final BedroomRange? bedrooms;
  final BathroomRange? bathrooms;
  final List<String>? amenities;
  final NearLocation? near;
  final SortOptions? sort;
  final int page;
  final int pageSize;

  PropertySearchRequest({
    this.orgSlug,
    this.query,
    this.type,
    this.status,
    this.minPrice,
    this.maxPrice,
    this.bedrooms,
    this.bathrooms,
    this.amenities,
    this.near,
    this.sort,
    this.page = 1,
    this.pageSize = 20,
  });

  Map<String, dynamic> toJson() {
    return {
      if (orgSlug != null) 'orgSlug': orgSlug,
      if (query != null) 'query': query,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (bedrooms != null) 'bedrooms': bedrooms!.toJson(),
      if (bathrooms != null) 'bathrooms': bathrooms!.toJson(),
      if (amenities != null) 'amenities': amenities,
      if (near != null) 'near': near!.toJson(),
      if (sort != null) 'sort': sort!.toJson(),
      'page': page,
      'pageSize': pageSize,
    };
  }
}

class BedroomRange {
  final int? min;
  final int? max;

  BedroomRange({this.min, this.max});

  Map<String, dynamic> toJson() {
    return {if (min != null) 'min': min, if (max != null) 'max': max};
  }
}

class BathroomRange {
  final int? min;
  final int? max;

  BathroomRange({this.min, this.max});

  Map<String, dynamic> toJson() {
    return {if (min != null) 'min': min, if (max != null) 'max': max};
  }
}

class NearLocation {
  final double lat;
  final double lng;
  final double radiusKm;

  NearLocation({required this.lat, required this.lng, required this.radiusKm});

  Map<String, dynamic> toJson() {
    return {'lat': lat, 'lng': lng, 'radiusKm': radiusKm};
  }
}

class SortOptions {
  final String by; // "createdAt" | "price" | "title" | "distance"
  final String order; // "asc" | "desc"

  SortOptions({required this.by, required this.order});

  Map<String, dynamic> toJson() {
    return {'by': by, 'order': order};
  }
}

class PropertySearchResponse {
  final int total;
  final int page;
  final int pageSize;
  final List<PropertyModel> items;

  PropertySearchResponse({required this.total, required this.page, required this.pageSize, required this.items});

  factory PropertySearchResponse.fromJson(Map<String, dynamic> json) {
    return PropertySearchResponse(
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      items: (json['items'] as List<dynamic>?)?.map((e) => PropertyModel.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }
}

class ImageUploadResponse {
  final List<UploadedImage> uploaded;
  final int count;

  ImageUploadResponse({required this.uploaded, required this.count});

  factory ImageUploadResponse.fromJson(Map<String, dynamic> json) {
    return ImageUploadResponse(
      uploaded: (json['uploaded'] as List<dynamic>?)?.map((e) => UploadedImage.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      count: json['count'] as int? ?? 0,
    );
  }
}

class UploadedImage {
  final String url;
  final String id;

  UploadedImage({required this.url, required this.id});

  factory UploadedImage.fromJson(Map<String, dynamic> json) {
    return UploadedImage(url: json['url'] as String? ?? '', id: json['id'] as String? ?? '');
  }
}

// ----------------------------------------------------------------------
// Lead Models

class LeadAssignee {
  final String userId;
  final String name;

  LeadAssignee({required this.userId, required this.name});

  factory LeadAssignee.fromJson(Map<String, dynamic> json) {
    return LeadAssignee(userId: json['userId'] as String? ?? '', name: json['name'] as String? ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'name': name};
  }
}

class LeadTimelineItem {
  final String type; // "note" | "status_change" | "assignment" | "contact"
  final String at; // ISO-8601
  final String by; // user ID
  final Map<String, dynamic> data;

  LeadTimelineItem({required this.type, required this.at, required this.by, required this.data});

  factory LeadTimelineItem.fromJson(Map<String, dynamic> json) {
    return LeadTimelineItem(
      type: json['type'] as String? ?? '',
      at: json['at'] as String? ?? '',
      by: json['by'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }
}

class LeadModel {
  final String id;
  final String source; // "web" | "app" | "portal" | "phone" | "referral" | "other"
  final String? propertyId;
  final String name;
  final String email;
  final String phone;
  final String? message;
  final String status; // "new" | "contacted" | "qualified" | "lost" | "won"
  final LeadAssignee? assignee;
  final String orgSlug;
  final List<String> tags;
  final Map<String, dynamic>? utm;
  final String createdAt;
  final String updatedAt;
  final List<LeadTimelineItem>? timeline;

  LeadModel({
    required this.id,
    required this.source,
    this.propertyId,
    required this.name,
    required this.email,
    required this.phone,
    this.message,
    required this.status,
    this.assignee,
    required this.orgSlug,
    required this.tags,
    this.utm,
    required this.createdAt,
    required this.updatedAt,
    this.timeline,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: json['id'] as String? ?? '',
      source: json['source'] as String? ?? '',
      propertyId: json['propertyId'] as String?,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'new',
      assignee: json['assignee'] != null ? LeadAssignee.fromJson(json['assignee'] as Map<String, dynamic>) : null,
      orgSlug: json['orgSlug'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      utm: json['utm'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      timeline: (json['timeline'] as List<dynamic>?)?.map((e) => LeadTimelineItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      if (propertyId != null) 'propertyId': propertyId,
      'name': name,
      'email': email,
      'phone': phone,
      if (message != null) 'message': message,
      'status': status,
      if (assignee != null) 'assignee': assignee!.toJson(),
      'orgSlug': orgSlug,
      'tags': tags,
      if (utm != null) 'utm': utm,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class LeadNote {
  final String noteId;
  final String leadId;
  final String text;
  final String createdAt;
  final String createdBy;

  LeadNote({required this.noteId, required this.leadId, required this.text, required this.createdAt, required this.createdBy});

  factory LeadNote.fromJson(Map<String, dynamic> json) {
    return LeadNote(
      noteId: json['noteId'] as String? ?? '',
      leadId: json['leadId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? '',
    );
  }
}

class LeadSearchRequest {
  final String? orgSlug;
  final String? query;
  final List<String>? status;
  final List<String>? assignedTo;
  final String? propertyId;
  final List<String>? tags;
  final DateRange? dateRange;
  final SortOptions? sort;
  final int page;
  final int pageSize;

  LeadSearchRequest({this.orgSlug, this.query, this.status, this.assignedTo, this.propertyId, this.tags, this.dateRange, this.sort, this.page = 1, this.pageSize = 20});

  Map<String, dynamic> toJson() {
    return {
      if (orgSlug != null) 'orgSlug': orgSlug,
      if (query != null) 'query': query,
      if (status != null) 'status': status,
      if (assignedTo != null) 'assignedTo': assignedTo,
      if (propertyId != null) 'propertyId': propertyId,
      if (tags != null) 'tags': tags,
      if (dateRange != null) 'dateRange': dateRange!.toJson(),
      if (sort != null) 'sort': sort!.toJson(),
      'page': page,
      'pageSize': pageSize,
    };
  }
}

class DateRange {
  final String from; // ISO-8601
  final String to; // ISO-8601

  DateRange({required this.from, required this.to});

  Map<String, dynamic> toJson() {
    return {'from': from, 'to': to};
  }
}

class LeadSearchResponse {
  final int total;
  final int page;
  final int pageSize;
  final List<LeadModel> items;

  LeadSearchResponse({required this.total, required this.page, required this.pageSize, required this.items});

  factory LeadSearchResponse.fromJson(Map<String, dynamic> json) {
    return LeadSearchResponse(
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      items: (json['items'] as List<dynamic>?)?.map((e) => LeadModel.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }
}
