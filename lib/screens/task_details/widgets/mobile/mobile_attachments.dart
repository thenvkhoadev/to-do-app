import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/data/models/task_attachment_model.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/screens/task_details/widgets/attachment_preview_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MobileAttachments extends ConsumerWidget {
  const MobileAttachments({required this.taskId, super.key});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(taskAttachmentsProvider(taskId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attachments',
          style: TextStyle(
            color: DashboardColors.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        async.when(
          loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (e, _) => Text(
            'Error: $e',
            style: const TextStyle(color: DashboardColors.error, fontSize: 12),
          ),
          data: (attachments) {
            if (attachments.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: .08)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.attachment_rounded,
                      color: DashboardColors.onSurfaceVariant,
                      size: 24,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No attachments',
                      style: TextStyle(
                        color: DashboardColors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Files attached to this task will appear here.',
                      style: TextStyle(
                        color: DashboardColors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return SizedBox(
              height: 195,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: attachments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  return _AttachmentCard(attachment: attachments[i]);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({required this.attachment});
  final TaskAttachmentModel attachment;

  String _getFileTypeLabel(String mime, String ext) {
    if (mime.startsWith('image/') || ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'].contains(ext)) return '🖼️ PNG';
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
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: CachedNetworkImage(
          imageUrl: attachment.fileUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
          errorWidget: (context, url, error) => Center(
            child: Icon(icon, color: fileColor, size: 36),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Mock lines
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 3,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  height: 3,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  height: 3,
                  width: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
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
              height: 4,
              decoration: BoxDecoration(
                color: fileColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
            ),
          ),
          // Document type badge
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
              decoration: BoxDecoration(
                color: fileColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: fileColor.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
              child: Text(
                ext.toUpperCase(),
                style: TextStyle(
                  color: fileColor,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          Center(
            child: Icon(icon, color: fileColor.withValues(alpha: 0.75), size: 30),
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
        width: 175,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview / Type Icon Top Area
            Expanded(
              child: _buildPreviewBox(context, ext, fileColor, icon, isImage),
            ),
            const SizedBox(height: 8),
            // File Info
            Text(
              attachment.fileName,
              style: const TextStyle(
                color: DashboardColors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  typeLabel,
                  style: const TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '•',
                  style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 9),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: AttachmentSizeWidget(
                    url: attachment.fileUrl,
                    builder: (context, sizeStr) => Text(
                      sizeStr,
                      style: const TextStyle(
                        color: DashboardColors.onSurfaceVariant,
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Actions
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'View',
                    icon: Icons.visibility_rounded,
                    onPressed: () => AttachmentPreviewDialog.show(context, attachment),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _ActionButton(
                    label: 'Download',
                    icon: Icons.download_rounded,
                    onPressed: () => AttachmentActions.downloadFile(context, attachment, openAfter: false),
                  ),
                ),
                const SizedBox(width: 4),
                // Popup Menu Button for More Actions
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .02),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withValues(alpha: .06)),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      cardColor: DashboardColors.surfaceLow,
                    ),
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 14,
                        color: DashboardColors.onSurfaceVariant,
                      ),
                      onSelected: (val) async {
                        if (val == 'open') {
                          await AttachmentActions.openInBrowser(context, attachment);
                        } else if (val == 'share') {
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
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'open',
                          height: 36,
                          child: Row(
                            children: [
                              Icon(Icons.open_in_new_rounded, size: 14, color: DashboardColors.onSurface),
                              SizedBox(width: 8),
                              Text('Open', style: TextStyle(fontSize: 12, color: DashboardColors.onSurface)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'share',
                          height: 36,
                          child: Row(
                            children: [
                              Icon(Icons.share_rounded, size: 14, color: DashboardColors.onSurface),
                              SizedBox(width: 8),
                              Text('Share', style: TextStyle(fontSize: 12, color: DashboardColors.onSurface)),
                            ],
                          ),
                        ),
                      ],
                    ),
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
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .02),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 11, color: DashboardColors.onSurfaceVariant),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: const TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
