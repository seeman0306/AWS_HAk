import 'package:flutter/material.dart';
import 'custom_widgets.dart';

class BrandHeroBanner extends StatelessWidget {
  final bool isCompact;

  const BrandHeroBanner({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF032B76), // Deep Royal Blue
            Color(0xFF0284C7), // Bright Cyan/Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Yellow Diagonal Corner Accents
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Content Layout
          Padding(
            padding: EdgeInsets.all(isCompact ? 16.0 : 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Brand Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Glowing Yellow "R" Logo Container
                    Container(
                      width: isCompact ? 40 : 48,
                      height: isCompact ? 40 : 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFACC15),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66FACC15),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'R',
                          style: TextStyle(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w900,
                            fontSize: isCompact ? 24 : 28,
                            fontFamily: 'sans-serif',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & Tagline
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: isCompact ? 20 : 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontFamily: 'sans-serif',
                              ),
                              children: const [
                                TextSpan(text: 'CivicEye '),
                                TextSpan(
                                  text: 'AI',
                                  style: TextStyle(color: Color(0xFFFACC15)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'AI-Powered Smart Civic Issue Detection & Automatic Routing',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: isCompact ? 10 : 11,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isCompact ? 12 : 16),

                // Workflow Steps Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPill(Icons.camera_alt_outlined, 'Capture'),
                      _buildPill(Icons.location_on_outlined, 'Locate'),
                      _buildPill(Icons.psychology_outlined, 'Detect'),
                      _buildPill(Icons.alt_route_outlined, 'Route'),
                      _buildPill(Icons.analytics_outlined, 'Track'),
                    ],
                  ),
                ),
                SizedBox(height: isCompact ? 12 : 16),

                // Feature Item Badges
                Column(
                  children: [
                    _buildFeatureCard(
                      icon: Icons.grain_rounded,
                      title: 'AI Computer Vision',
                      subtitle: 'YOLOv8 neural net auto-classifies potholes, lighting & traffic',
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureCard(
                      icon: Icons.my_location_rounded,
                      title: 'GPS Geotagging',
                      subtitle: 'Sub-meter accuracy location lock before complaint submission',
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureCard(
                      icon: Icons.alt_route_rounded,
                      title: 'Zero-Touch Routing',
                      subtitle: 'Automatic dispatch to Road, Street Light, or Traffic department',
                    ),
                  ],
                ),
                SizedBox(height: isCompact ? 10 : 14),

                // Department Footer Pills
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildDeptBadge('Road'),
                    const SizedBox(width: 8),
                    _buildDeptBadge('Street Light'),
                    const SizedBox(width: 8),
                    _buildDeptBadge('Traffic'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFFACC15), size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: CivicColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 10,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeptBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
