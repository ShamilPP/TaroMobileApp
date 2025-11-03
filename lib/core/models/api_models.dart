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
    return {
      'id': id,
      'orgId': orgId,
      'uid': uid,
      'user': user.toJson(),
      'role': role,
      'status': status,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'joinedAt': joinedAt,
    };
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

  PaginatedResponse({
    required this.data,
    required this.paginator,
  });

  factory PaginatedResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJsonT,
      ) {
    return PaginatedResponse<T>(
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList() ??
          [],
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
