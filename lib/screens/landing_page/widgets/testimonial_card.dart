import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'design_system.dart';

class TestimonialCard extends StatelessWidget {
  final String text;
  final String name;
  final String role;
  final String avatarUrl;

  const TestimonialCard({
    super.key,
    required this.text,
    required this.name,
    required this.role,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(32.0),
      borderRadius: 16.0,
      child: SizedBox(
        width: 360.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Stars
            const Row(
              children: [
                Icon(Icons.star, color: LandingColors.tertiary, size: 20.0),
                Icon(Icons.star, color: LandingColors.tertiary, size: 20.0),
                Icon(Icons.star, color: LandingColors.tertiary, size: 20.0),
                Icon(Icons.star, color: LandingColors.tertiary, size: 20.0),
                Icon(Icons.star, color: LandingColors.tertiary, size: 20.0),
              ],
            ),
            const SizedBox(height: 16.0),
            
            // Text
            Expanded(
              child: Text(
                '"$text"',
                style: getLandingGeistStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w400,
                  color: LandingColors.textPrimary,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            
            // User Profile Row
            Row(
              children: [
                Container(
                  width: 48.0,
                  height: 48.0,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatarUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: LandingColors.surfaceVariant),
                      errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: getLandingGeistStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          color: LandingColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        role,
                        style: getLandingGeistStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.w600,
                          color: LandingColors.textSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
