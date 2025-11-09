import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/core/models/api_models.dart';
import 'package:taro_mobile/features/properties/controller/property_provider.dart';

class PropertiesScreen extends StatefulWidget {
  final String? orgSlug;

  const PropertiesScreen({super.key, this.orgSlug});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  bool _isGridView = true; // true for grid, false for list
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PropertyProvider>();
      provider.searchProperties(orgSlug: widget.orgSlug, reset: true);
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      context.read<PropertyProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Green Header
            _buildHeader(),
            // Property Grid
            Expanded(
              child: Consumer<PropertyProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.properties.isEmpty) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null && provider.properties.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: ${provider.error}'),
                          SizedBox(height: 16),
                          ElevatedButton(onPressed: () => provider.searchProperties(orgSlug: widget.orgSlug, reset: true), child: Text('Retry')),
                        ],
                      ),
                    );
                  }

                  if (provider.properties.isEmpty) {
                    return Center(child: Text('No properties found', style: TextStyle(fontSize: 16, color: Colors.grey)));
                  }

                  return _buildPropertiesGrid(provider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Property Catalogue', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Lato')),
                    SizedBox(height: 8),
                    Text('Manage and share your listings', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9), fontFamily: 'Lato')),
                  ],
                ),
              ),
              // View Toggle Icons
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isGridView = true;
                      });
                    },
                    child: Container(padding: EdgeInsets.all(8), child: Icon(Icons.grid_view, color: _isGridView ? Colors.white : Colors.white.withOpacity(0.6), size: 24)),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isGridView = false;
                      });
                    },
                    child: Container(padding: EdgeInsets.all(8), child: Icon(Icons.list, color: !_isGridView ? Colors.white : Colors.white.withOpacity(0.6), size: 24)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesGrid(PropertyProvider provider) {
    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _isGridView ? 2 : 1,
        childAspectRatio: _isGridView ? 0.55 : 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: provider.properties.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= provider.properties.length) {
          return Center(child: CircularProgressIndicator());
        }
        return _buildPropertyCard(provider.properties[index]);
      },
    );
  }

  Widget _buildPropertyCard(PropertyModel property) {
    final address = property.address;
    final location = '${address.city}, ${address.state}';
    final priceFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final price = priceFormat.format(property.price);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section with Badges
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                // Property Image
                property.images.isNotEmpty
                    ? ClipRRect(
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                      child: Image.network(
                        property.images.first,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                            ),
                            child: Center(child: Icon(Icons.apartment, size: 60, color: AppColors.primaryGreen.withOpacity(0.5))),
                          );
                        },
                      ),
                    )
                    : Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                      ),
                      child: Center(child: Icon(Icons.apartment, size: 60, color: AppColors.primaryGreen.withOpacity(0.5))),
                    ),
                // Status Badge (Top Left)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(12)),
                    child: Text(property.status.toUpperCase(), style: TextStyle(fontSize: 11, color: Colors.white, fontFamily: 'Lato', fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),

          // Content Section
          Expanded(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    property.title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Lato'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),

                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Expanded(child: Text(location, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontFamily: 'Lato'), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Details Row (Beds, Baths, Sqft)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (property.bedrooms != null) _buildDetailItem(Icons.bed, '${property.bedrooms}'),
                      if (property.bathrooms != null) _buildDetailItem(Icons.bathroom, '${property.bathrooms}'),
                      if (property.areaSqFt != null) _buildDetailItem(Icons.square_foot, '${property.areaSqFt!.toInt()}'),
                    ],
                  ),
                  Spacer(),

                  // Price
                  Text(price, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryGreen, fontFamily: 'Lato')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 14, color: Colors.grey[500]), SizedBox(width: 4), Text(value, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontFamily: 'Lato'))],
    );
  }
}

// Dashed Border Painter
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashSpace;

  DashedBorderPainter({required this.color, required this.strokeWidth, required this.dashLength, required this.dashSpace});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    // Top border
    _drawDashedLine(canvas, Offset(0, 0), Offset(size.width, 0), paint);

    // Right border
    _drawDashedLine(canvas, Offset(size.width, 0), Offset(size.width, size.height), paint);

    // Bottom border
    _drawDashedLine(canvas, Offset(size.width, size.height), Offset(0, size.height), paint);

    // Left border
    _drawDashedLine(canvas, Offset(0, size.height), Offset(0, 0), paint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    double distance = (end - start).distance;
    double step = dashLength + dashSpace;
    double currentDistance = 0;

    bool draw = true;
    Offset currentPoint = start;
    Offset direction = (end - start) / distance;

    while (currentDistance < distance) {
      double stepSize = (currentDistance + step <= distance) ? step : (distance - currentDistance);
      if (draw) {
        double dashSize = (stepSize > dashLength) ? dashLength : stepSize;
        Offset dashEnd = currentPoint + direction * dashSize;
        canvas.drawLine(currentPoint, dashEnd, paint);
      }
      currentPoint = currentPoint + direction * stepSize;
      currentDistance += stepSize;
      draw = !draw;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
