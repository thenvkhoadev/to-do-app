import 'package:flutter/material.dart';
import 'package:to_do_app/theme/design_tokens.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class EmptyFeedState extends StatelessWidget {
  const EmptyFeedState({super.key, this.onFindFriends});

  final VoidCallback? onFindFriends;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C5CFF).withValues(alpha: .15),
                ),
                child: const Icon(
                  Icons.feed_rounded,
                  color: Color(0xFFA78BFA),
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Bảng tin trống',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Hãy kết bạn để xem hoạt động tập trung của mọi người, hoặc tự mình chia sẻ bài viết đầu tiên ngay nhé!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              if (onFindFriends != null)
                Container(
                  decoration: BoxDecoration(
                    gradient: DesignTokens.gradientPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: onFindFriends,
                    icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
                    label: const Text(
                      'Tìm kiếm bạn bè',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
