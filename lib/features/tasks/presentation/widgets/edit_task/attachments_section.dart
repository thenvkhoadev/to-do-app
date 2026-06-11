import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:to_do_app/features/tasks/data/datasource/attachment_datasource.dart';
import 'package:to_do_app/features/tasks/data/models/task_attachment_model.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TaskAttachmentsSection extends StatelessWidget {
  const TaskAttachmentsSection({
    required this.attachments,
    required this.newAttachments,
    required this.onAddAttachments,
    required this.onRemoveExistingAttachment,
    required this.onRemoveNewAttachment,
    required this.isMobile,
    super.key,
  });

  final List<TaskAttachmentModel> attachments;
  final List<PlatformFileInfo> newAttachments;
  final ValueChanged<List<PlatformFileInfo>> onAddAttachments;
  final ValueChanged<TaskAttachmentModel> onRemoveExistingAttachment;
  final ValueChanged<int> onRemoveNewAttachment;
  final bool isMobile;

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf', 'zip', 'doc', 'docx', 'txt'],
      );

      if (result != null && result.files.isNotEmpty) {
        final picked = result.files.map((file) {
          return PlatformFileInfo(
            name: file.name,
            sizeBytes: file.size,
            extension: file.extension ?? '',
            bytes: file.bytes,
            filePath: kIsWeb ? null : file.path,
          );
        }).toList();
        onAddAttachments(picked);
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => Icons.picture_as_pdf_rounded,
      'png' || 'jpg' || 'jpeg' => Icons.image_rounded,
      'zip' || 'rar' => Icons.folder_zip_rounded,
      'doc' || 'docx' => Icons.description_rounded,
      _ => Icons.insert_drive_file_rounded,
    };
  }

  Color _getFileColor(String fileName) {
    if (isMobile) {
      final ext = fileName.split('.').last.toLowerCase();
      if (ext == 'png' || ext == 'jpg' || ext == 'jpeg') {
        return DashboardColors.tertiary;
      }
    }
    return DashboardColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.attachment_rounded, color: DashboardColors.primary, size: 22),
              SizedBox(width: 12),
              Text(
                'Attachments',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Upload Area
          InkWell(
            onTap: _pickFiles,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.01),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color.fromRGBO(255, 255, 255, 0.06),
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: DashboardColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.upload_file_rounded, color: DashboardColors.primary, size: 24),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Drop files here or browse',
                      style: TextStyle(
                        color: DashboardColors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Maximum file size: 50MB. PNG, JPG, PDF, ZIP',
                      style: TextStyle(
                        color: DashboardColors.onSurfaceVariant.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Attachments List Grid
          if (attachments.isEmpty && newAttachments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'No attachments selected.',
                  style: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: 0.4), fontSize: 13),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: attachments.length + newAttachments.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isMobile ? 1 : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isMobile ? 5.5 : 4.5,
              ),
              itemBuilder: (context, index) {
                if (index < attachments.length) {
                  final att = attachments[index];
                  return TaskAttachmentCard(
                    fileName: att.fileName,
                    sizeLabel: 'Oct 12', // Mocked / custom label
                    icon: _getFileIcon(att.fileName),
                    color: _getFileColor(att.fileName),
                    onDelete: () => onRemoveExistingAttachment(att),
                  );
                } else {
                  final newIndex = index - attachments.length;
                  final att = newAttachments[newIndex];
                  return TaskAttachmentCard(
                    fileName: att.name,
                    sizeLabel: '${_getFileIcon(att.name) == Icons.image_rounded ? 'New Image' : 'New File'} · ${_formatSize(att.sizeBytes)}',
                    icon: _getFileIcon(att.name),
                    color: _getFileColor(att.name),
                    onDelete: () => onRemoveNewAttachment(newIndex),
                    isNew: true,
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}

class TaskAttachmentCard extends StatelessWidget {
  const TaskAttachmentCard({
    required this.fileName,
    required this.sizeLabel,
    required this.icon,
    required this.color,
    required this.onDelete,
    this.isNew = false,
    super.key,
  });

  final String fileName;
  final String sizeLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onDelete;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.015),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNew
              ? DashboardColors.primary.withValues(alpha: 0.25)
              : const Color.fromRGBO(255, 255, 255, 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DashboardColors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sizeLabel,
                  style: TextStyle(
                    color: DashboardColors.onSurfaceVariant.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white30),
            hoverColor: Colors.white12,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
        ],
      ),
    );
  }
}
