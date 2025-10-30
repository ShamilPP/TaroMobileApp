class Lead {
  final String id;
  final String ownerName;
  final String ownerInitials;
  final String propertyType;
  final String location;
  final double acres;
  final double price;
  final bool isOwner;

  Lead({
    required this.id,
    required this.ownerName,
    required this.ownerInitials,
    required this.propertyType,
    required this.location,
    required this.acres,
    required this.price,
    required this.isOwner,
  });
}