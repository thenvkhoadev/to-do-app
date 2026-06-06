import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/data/models/task_attachment_model.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/screens/task_details/widgets/attachment_preview_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DesktopAttachments extends ConsumerWidget {
  const DesktopAttachments({required this.taskId, super.key});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(taskAttachmentsProvider(taskId));
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attachments',
            style: TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: -.01,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          async.when(
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, _) => Text(
              'Error: $e',
              style: const TextStyle(color: DashboardColors.error),
            ),
            data: (attachments) {
              if (attachments.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: .04)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.attachment_rounded,
                        color: DashboardColors.onSurfaceVariant,
                        size: 36,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No attachments',
                        style: TextStyle(
                          color: DashboardColors.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Files attached to this task will appear here.',
                        style: TextStyle(
                          color: DashboardColors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 2;
                  if (constraints.maxWidth > 900) {
                    crossAxisCount = 4;
                  } else if (constraints.maxWidth > 650) {
                    crossAxisCount = 3;
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 2.1,
                    ),
                    itemCount: attachments.length,
                    itemBuilder: (context, i) {
                      return _AttachmentCard(attachment: attachments[i]);
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({required this.attachment});
  final TaskAttachmentModel attachment;

  String _getFileTypeLabel(String mime, String ext) {
    if (mime.startsWith('image/') || ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'].contains(ext)) return '🖼️ Image';
    if (mime == 'application/pdf' || ext == 'pdf') return '📄 PDF';
    if (mime.contains('wordprocessingml') || mime.contains('msword') || ['doc', 'docx'].contains(ext)) return '📝 DOCX';
    if (mime.contains('spreadsheetml') || mime.contains('excel') || ['xls', 'xlsx'].contains(ext)) return '📊 XLSX';
    if (mime.contains('zip') || mime.contains('x-rar') || ['zip', 'rar', '7z'].contains(ext)) return '📦 ZIP';
    return '📁 File';
  }

  IconData _getFileIcon(String mime, String ext) {
    if (mime.startsWith('image/') || ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'].contains(ext)) return Icons.image_rounded;
    if (mime == 'application/pdf' || ext == 'pdf') return Icons.picture_as_pdf_rounded;
    if (mime.contains('wordprocessingml') || mime.contains('msword') || ['doc', 'docx'].contains(ext)) return Icons.description_rounded;
    if (mime.contains('spreadsheetml') || mime.contains('excel') || ['xls', 'xlsx'].contains(ext)) return Icons.table_view_rounded;
    if (mime.contains('zip') || mime.contains('x-rar') || ['zip', 'rar', '7z'].contains(ext)) return Icons.archive_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _getFileColor(String mime, String ext) {
    if (mime.startsWith('image/') || ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'].contains(ext)) return const Color(0xFFC084FC); // Purple
    if (mime == 'application/pdf' || ext == 'pdf') return const Color(0xFFEF4444); // Red
    if (mime.contains('wordprocessingml') || mime.contains('msword') || ['doc', 'docx'].contains(ext)) return const Color(0xFF60A5FA); // Blue
    if (mime.contains('spreadsheetml') || mime.contains('excel') || ['xls', 'xlsx'].contains(ext)) return const Color(0xFF34D399); // Green
    if (mime.contains('zip') || mime.contains('x-rar') || ['zip', 'rar', '7z'].contains(ext)) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFF9CA3AF); // Grey
  }

  Widget _buildPreviewBox(BuildContext context, String ext, Color fileColor, IconData icon, bool isImage) {
    if (isImage) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: CachedNetworkImage(
          imageUrl: attachment.fileUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: fileColor.withValues(alpha: 0.08),
            child: const Center(
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: fileColor.withValues(alpha: 0.12),
            child: Icon(icon, color: fileColor, size: 22),
          ),
        ),
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Mock lines in the background
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: 2,
                  width: 20,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 3),
                Container(
                  height: 2,
                  width: 28,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ],
            ),
          ),
          // Top accent strip
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: fileColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
          ),
          // Central small icon
          Center(
            child: Icon(icon, color: fileColor.withValues(alpha: 0.8), size: 18),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mime = attachment.mimeType;
    final ext = attachment.fileName.split('.').last.toLowerCase();
    final fileColor = _getFileColor(mime, ext);
    final icon = _getFileIcon(mime, ext);
    final typeLabel = _getFileTypeLabel(mime, ext);
    final isImage = mime.startsWith('image/') ||
        ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'].contains(ext);

    return InkWell(
      onTap: () => AttachmentPreviewDialog.show(context, attachment),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with Icon, Info
            Expanded(
              child: Row(
                children: [
                  _buildPreviewBox(context, ext, fileColor, icon, isImage),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          attachment.fileName,
                          style: const TextStyle(
                            color: DashboardColors.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              typeLabel,
                              style: const TextStyle(
                                color: DashboardColors.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '•',
                              style: TextStyle(
                                color: DashboardColors.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: AttachmentSizeWidget(
                                url: attachment.fileUrl,
                                builder: (context, sizeStr) => Text(
                                  sizeStr,
                                  style: const TextStyle(
                                    color: DashboardColors.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Actions Row
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'View',
                    icon: Icons.visibility_rounded,
                    onPressed: () => AttachmentPreviewDialog.show(context, attachment),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ActionButton(
                    label: 'Download',
                    icon: Icons.download_rounded,
                    onPressed: () => AttachmentActions.downloadFile(context, attachment, openAfter: false),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ActionButton(
                    label: 'Open',
                    icon: Icons.open_in_new_rounded,
                    onPressed: () => AttachmentActions.openInBrowser(context, attachment),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .02),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: .06)),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.share_rounded, size: 14, color: DashboardColors.onSurfaceVariant),
                    tooltip: 'Share link',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: attachment.fileUrl));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            duration: Duration(seconds: 1),
                            backgroundColor: DashboardColors.secondary,
                            content: Text('Link copied to clipboard'),
                          ),
                        );
                      }
                    },
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          hoverColor: Colors.white.withValues(alpha: .04),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 13, color: DashboardColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
            ),
            child: child,
          ),
        ),
      );
}
