import 'package:flutter/material.dart';
import 'package:taro_mobile/core/constants/colors.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  bool _isGridView = true; // true for grid, false for list

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
              child: _buildPropertiesGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
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
                    Text(
                      'Property Catalogue',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Lato',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Manage and share your listings',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontFamily: 'Lato',
                      ),
                    ),
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
                    child: Container(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.grid_view,
                        color: _isGridView ? Colors.white : Colors.white.withOpacity(0.6),
                        size: 24,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isGridView = false;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.list,
                        color: !_isGridView ? Colors.white : Colors.white.withOpacity(0.6),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesGrid() {
    // Sample property data matching the image
    List<PropertyData> properties = [
      PropertyData(
        status: 'active',
        leads: 3,
        title: 'Spacious 3BHK with Lake View',
        location: 'Powai, Mumbai',
        bedrooms: 3,
        bathrooms: 2,
        sqft: 1450,
        price: '₹1,15,00,000',
      ),
      PropertyData(
        status: 'active',
        leads: 2,
        title: 'Modern 3BHK Near Metro',
        location: 'Andheri East, Mumbai',
        bedrooms: 3,
        bathrooms: 2,
        sqft: 1200,
        price: '₹98,00,000',
      ),
      PropertyData(
        status: 'active',
        leads: 1,
        title: 'Semi-furnished 2BHK',
        location: 'Bandra, Mumbai',
        bedrooms: 2,
        bathrooms: 1,
        sqft: 950,
        price: '₹75,00,000',
      ),
      PropertyData(
        status: 'active',
        leads: 0,
        title: '4BHK Penthouse with Sea View',
        location: 'Worli, Mumbai',
        bedrooms: 4,
        bathrooms: 3,
        sqft: 2200,
        price: '₹2,50,00,000',
      ),
    ];

    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20,vertical: 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        return _buildPropertyCard(properties[index]);
      },
    );
  }

  Widget _buildPropertyCard(PropertyData property) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section with Badges
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                // Image Placeholder
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.apartment,
                      size: 60,
                      color: AppColors.primaryGreen.withOpacity(0.5),
                    ),
                  ),
                ),
                // Status Badge (Top Left)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      property.status,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Leads Badge (Top Right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person,
                          size: 12,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${property.leads}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Lato',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.location,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontFamily: 'Lato',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Details Row (Beds, Baths, Sqft)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailItem(Icons.bed, '${property.bedrooms}'),
                      _buildDetailItem(Icons.bathroom, '${property.bathrooms}'),
                      _buildDetailItem(Icons.square_foot, '${property.sqft}'),
                    ],
                  ),
                  Spacer(),

                  // Price
                  Text(
                    property.price,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                      fontFamily: 'Lato',
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

  Widget _buildDetailItem(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey[500],
        ),
        SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontFamily: 'Lato',
          ),
        ),
      ],
    );
  }
}

// Dashed Border Painter
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
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

// Property Data Model
class PropertyData {
  final String status;
  final int leads;
  final String title;
  final String location;
  final int bedrooms;
  final int bathrooms;
  final int sqft;
  final String price;

  PropertyData({
    required this.status,
    required this.leads,
    required this.title,
    required this.location,
    required this.bedrooms,
    required this.bathrooms,
    required this.sqft,
    required this.price,
  });
}

