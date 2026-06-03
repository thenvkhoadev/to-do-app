import 'package:flutter/material.dart';
import 'edit_profile_shared.dart';

class ExportCenterCard extends StatelessWidget {
  const ExportCenterCard({
    required this.onExportJson,
    required this.onExportCsv,
    required this.onExportPdf,
    super.key,
  });

  final VoidCallback onExportJson;
  final VoidCallback onExportCsv;
  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    return EditProfileGlassCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;

          final header = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Export Data Workspace',
                style: TextStyle(
                  color: EditProfileColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Download your full productivity history, neural focus logs, and account settings.',
                style: TextStyle(
                  color: EditProfileColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          );

          final buttons = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildExportButton(
                icon: Icons.code,
                label: 'JSON',
                onTap: onExportJson,
              ),
              const SizedBox(width: 12),
              _buildExportButton(
                icon: Icons.table_chart,
                label: 'CSV',
                onTap: onExportCsv,
              ),
              const SizedBox(width: 12),
              _buildExportButton(
                icon: Icons.picture_as_pdf,
                label: 'PDF',
                onTap: onExportPdf,
              ),
            ],
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(child: header),
                const SizedBox(width: 24),
                buttons,
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: 20),
                Center(child: buttons),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EditProfileColors.borderSides),
        ),
        child: Column(
          children: [
            Icon(icon, color: EditProfileColors.textSecondary, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: EditProfileColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
