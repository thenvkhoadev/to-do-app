import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/screens/auth/components/shared_components.dart';

/// A premium, glassmorphic Privacy Policy Dialog for Nexus AI.
class PrivacyPolicyDialog extends StatefulWidget {
  const PrivacyPolicyDialog({super.key});

  @override
  State<PrivacyPolicyDialog> createState() => _PrivacyPolicyDialogState();
}

class _PrivacyPolicyDialogState extends State<PrivacyPolicyDialog> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: GlassCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: RegisterColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: RegisterColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Icon(
                          Icons.security_rounded,
                          color: RegisterColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        "Chính Sách Quyền Riêng Tư",
                        style: getGeistStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                color: RegisterColors.glassStroke,
              ),
              const SizedBox(height: 20),
              
              // Scrollable Policy Content
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("1. Giới thiệu"),
                        _buildParagraph(
                          "Chào mừng bạn đến với Nexus AI (ứng dụng ToDoApp). Chúng tôi cam kết bảo vệ thông tin riêng tư và dữ liệu cá nhân của bạn. Chính sách này giải thích cách chúng tôi thu thập, sử dụng và bảo vệ thông tin khi bạn sử dụng dịch vụ của chúng tôi."
                        ),
                        _buildSectionTitle("2. Thông tin thu thập"),
                        _buildParagraph(
                          "Để cung cấp trải nghiệm quản lý công việc và tính năng AI tối ưu, chúng tôi thu thập các loại dữ liệu sau:"
                        ),
                        _buildBulletPoint(
                          "Thông tin tài khoản: Họ tên, email, ảnh đại diện, và tên người dùng (username) khi đăng ký trực tiếp hoặc thông qua các tài khoản mạng xã hội (Google, GitHub, Facebook)."
                        ),
                        _buildBulletPoint(
                          "Dữ liệu tác vụ: Tiêu đề công việc, mô tả tác vụ, thời gian hết hạn, các nhãn (tags), danh mục (categories), và ghi chú đính kèm."
                        ),
                        _buildBulletPoint(
                          "Chỉ số tập trung và hiệu suất: Thời gian thực hiện các phiên làm việc sâu (Deep Work), điểm tập trung (Focus Score), và chuỗi ngày hoàn thành công việc liên tiếp (streak)."
                        ),
                        _buildBulletPoint(
                          "Nhật ký kỹ thuật: Lịch sử đăng nhập, thiết bị sử dụng (Tên thiết bị, OS), địa chỉ IP, và nhật ký bảo mật (audit logs) để ngăn ngừa các truy cập trái phép."
                        ),
                        _buildSectionTitle("3. Cách chúng tôi sử dụng thông tin"),
                        _buildParagraph(
                          "Thông tin thu thập được sử dụng cho các mục đích chính đáng sau:"
                        ),
                        _buildBulletPoint(
                          "Duy trì, vận hành và đồng bộ hóa các tác vụ của bạn trên tất cả các thiết bị theo thời gian thực."
                        ),
                        _buildBulletPoint(
                          "Cung cấp các đề xuất năng suất, tóm tắt tiến độ và phân tích hiệu suất được tối ưu hóa bằng Trí tuệ Nhân tạo (AI)."
                        ),
                        _buildBulletPoint(
                          "Xác thực danh tính bảo mật qua mã OTP và quản lý phiên đăng nhập thiết bị thông qua khóa JWT của Supabase."
                        ),
                        _buildBulletPoint(
                          "Ngăn chặn gian lận, tấn công hệ thống và bảo mật tài khoản cá nhân của bạn."
                        ),
                        _buildSectionTitle("4. Bảo mật dữ liệu & Chia sẻ"),
                        _buildParagraph(
                          "Nexus AI sử dụng hạ tầng của Supabase tích hợp Row-Level Security (RLS) để cô lập dữ liệu. Mọi thông tin truyền tải đều được mã hóa SSL/TLS. Chúng tôi cam kết KHÔNG bao giờ bán, cho thuê hoặc chia sẻ dữ liệu công việc và thông tin cá nhân của bạn cho các bên thứ ba vì bất kỳ mục đích thương mại nào."
                        ),
                        _buildSectionTitle("5. Quyền kiểm soát của bạn"),
                        _buildParagraph(
                          "Bạn hoàn toàn có quyền truy cập, chỉnh sửa thông tin hồ sơ cá nhân hoặc yêu cầu xóa bỏ hoàn toàn dữ liệu tài khoản và tác vụ của mình bất cứ lúc nào thông qua màn hình Cài đặt Hồ sơ trong ứng dụng."
                        ),
                        _buildSectionTitle("6. Liên hệ chúng tôi"),
                        _buildParagraph(
                          "Nếu bạn có bất kỳ câu hỏi nào về chính sách bảo mật này, xin vui lòng gửi yêu cầu hỗ trợ trực tiếp trong mục Trợ giúp của ứng dụng hoặc liên hệ qua email: support@nexus.ai."
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 1,
                color: RegisterColors.glassStroke,
              ),
              const SizedBox(height: 16),
              
              // Confirm button
              _DialogCloseButton(
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: getGeistStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: RegisterColors.primary,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: getGeistStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: RegisterColors.onSurfaceVariant.withValues(alpha: 0.9),
          height: 1.45,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: RegisterColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: getGeistStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: RegisterColors.onSurfaceVariant.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogCloseButton extends StatefulWidget {
  const _DialogCloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_DialogCloseButton> createState() => _DialogCloseButtonState();
}

class _DialogCloseButtonState extends State<_DialogCloseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.01 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            gradient: const LinearGradient(
              colors: [Color(0xFFE1DFFF), Color(0xFFC0C1FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: const Color(0xFFC0C1FF).withOpacity(0.25),
                      blurRadius: 15.0,
                      spreadRadius: 1.0,
                    )
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10.0),
              onTap: widget.onPressed,
              child: Center(
                child: Text(
                  "ĐÃ HIỂU & ĐỒNG Ý",
                  style: getGeistStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF292B5E),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
