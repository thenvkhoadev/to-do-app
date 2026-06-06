import 'dart:io' show Platform;
import 'dart:convert' show utf8;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:to_do_app/features/tasks/data/models/task_attachment_model.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart' as xml;

class AttachmentPreviewDialog extends StatefulWidget {
  const AttachmentPreviewDialog({required this.attachment, super.key});
  final TaskAttachmentModel attachment;

  static Future<void> show(BuildContext context, TaskAttachmentModel attachment) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => AttachmentPreviewDialog(attachment: attachment),
    );
  }

  @override
  State<AttachmentPreviewDialog> createState() => _AttachmentPreviewDialogState();
}

class _AttachmentPreviewDialogState extends State<AttachmentPreviewDialog> {
  bool _isLoading = false;
  String _loadingMessage = '';
  bool _isDocx = false;
  String? _docxText;
  String? _docxError;

  @override
  void initState() {
    super.initState();
    final mime = widget.attachment.mimeType;
    final isWord = mime.contains('wordprocessingml') || mime.contains('msword') || widget.attachment.fileName.endsWith('.docx');
    if (isWord && widget.attachment.fileName.endsWith('.docx')) {
      _isDocx = true;
      _loadDocxPreview();
    }
  }

  Future<void> _loadDocxPreview() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Reading Word document...';
    });
    try {
      final dio = Dio();
      final response = await dio.get<List<int>>(
        widget.attachment.fileUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data != null) {
        final bytes = response.data!;
        final text = await _parseDocxText(bytes);
        if (mounted) {
          setState(() {
            _docxText = text;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Empty file response');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _docxError = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _parseDocxText(List<int> bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final file = archive.findFile('word/document.xml');
      if (file == null) return 'No word/document.xml found in docx archive';
      
      final contentBytes = file.content as List<int>;
      final contentStr = utf8.decode(contentBytes);
      final document = xml.XmlDocument.parse(contentStr);
      
      final paragraphs = document.findAllElements('w:p');
      final buffer = StringBuffer();
      
      for (final p in paragraphs) {
        final textElements = p.findAllElements('w:t');
        final pText = textElements.map((e) => e.innerText).join('');
        if (pText.trim().isNotEmpty) {
          buffer.writeln(pText);
          buffer.writeln();
        }
      }
      final parsedText = buffer.toString().trim();
      return parsedText.isEmpty ? '(Empty Document)' : parsedText;
    } catch (e) {
      return 'Failed to extract text from Word document: $e';
    }
  }

  Future<void> _downloadFile({required bool openAfter}) async {
    await DownloadStatusDialog.show(context, widget.attachment, openAfter: openAfter);
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.attachment.fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: DashboardColors.error,
            content: Text('Could not open file in browser'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mime = widget.attachment.mimeType;
    final isImage = mime.startsWith('image/');
    final isPdf = mime == 'application/pdf';
    final fileName = widget.attachment.fileName;

    return Dialog(
      backgroundColor: DashboardColors.background.withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      insetPadding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: isPdf ? 900 : 700,
          height: isPdf ? 800 : 600,
          decoration: BoxDecoration(
            color: DashboardColors.background.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: const TextStyle(
                              color: DashboardColors.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getFileTypeLabel(mime),
                            style: const TextStyle(
                              color: DashboardColors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.download_rounded, color: DashboardColors.primary),
                      tooltip: 'Download',
                      onPressed: () => _downloadFile(openAfter: false),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new_rounded, color: DashboardColors.secondary),
                      tooltip: 'Open in new tab',
                      onPressed: _openInBrowser,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: DashboardColors.onSurfaceVariant),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isLoading)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: DashboardColors.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _loadingMessage,
                            style: const TextStyle(
                              color: DashboardColors.onSurface,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    else if (isImage)
                      InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: CachedNetworkImage(
                          imageUrl: widget.attachment.fileUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              color: DashboardColors.error,
                              size: 64,
                            ),
                          ),
                        ),
                      )
                    else if (isPdf)
                      SfPdfViewer.network(
                        widget.attachment.fileUrl,
                        canShowScrollHead: true,
                        canShowScrollStatus: true,
                      )
                    else if (_isDocx && _docxText != null && _docxError == null)
                      Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: DashboardColors.surfaceLow.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: SelectionArea(
                                child: Text(
                                  _docxText!,
                                  style: const TextStyle(
                                    color: DashboardColors.onSurface,
                                    fontSize: 14,
                                    height: 1.6,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      // Fallback screen for docx, xlsx, zip, etc.
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getFileEmoji(mime),
                              style: const TextStyle(fontSize: 80),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Preview not supported directly in-app',
                              style: TextStyle(
                                color: DashboardColors.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You can open this document using your system viewer or download it locally.',
                              style: TextStyle(
                                color: DashboardColors.onSurfaceVariant,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _downloadFile(openAfter: true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: DashboardColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.menu_book_rounded, color: Colors.black),
                                  label: const Text(
                                    'Open in System Viewer',
                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                OutlinedButton.icon(
                                  onPressed: () => _downloadFile(openAfter: false),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: DashboardColors.primary),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.download_rounded, color: DashboardColors.primary),
                                  label: const Text(
                                    'Download File',
                                    style: TextStyle(color: DashboardColors.primary),
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
            ],
          ),
        ),
      ),
    );
  }

  String _getFileTypeLabel(String mime) {
    if (mime.startsWith('image/')) return 'Image File';
    if (mime == 'application/pdf') return 'PDF Document';
    if (mime.contains('wordprocessingml') || mime.contains('msword')) return 'Word Document (DOCX)';
    if (mime.contains('spreadsheetml') || mime.contains('excel')) return 'Excel Spreadsheet';
    if (mime.contains('zip') || mime.contains('x-rar')) return 'Compressed Archive';
    return 'Document File';
  }

  String _getFileEmoji(String mime) {
    if (mime.startsWith('image/')) return '🖼️';
    if (mime == 'application/pdf') return '📄';
    if (mime.contains('wordprocessingml') || mime.contains('msword')) return '📝';
    if (mime.contains('spreadsheetml') || mime.contains('excel')) return '📊';
    if (mime.contains('zip') || mime.contains('x-rar')) return '📦';
    return '📁';
  }
}

class AttachmentSizeWidget extends StatefulWidget {
  const AttachmentSizeWidget({required this.url, required this.builder, super.key});
  final String url;
  final Widget Function(BuildContext context, String sizeStr) builder;

  @override
  State<AttachmentSizeWidget> createState() => _AttachmentSizeWidgetState();
}

class _AttachmentSizeWidgetState extends State<AttachmentSizeWidget> {
  static final Map<String, String> _sizeCache = {};
  String _sizeStr = 'Loading size...';

  @override
  void initState() {
    super.initState();
    _loadSize();
  }

  Future<void> _loadSize() async {
    if (_sizeCache.containsKey(widget.url)) {
      if (mounted) {
        setState(() {
          _sizeStr = _sizeCache[widget.url]!;
        });
      }
      return;
    }

    try {
      final dio = Dio();
      final response = await dio.head(widget.url);
      final lengthHeader = response.headers.value('content-length');
      if (lengthHeader != null) {
        final bytes = int.tryParse(lengthHeader);
        if (bytes != null) {
          final formatted = _formatFileSize(bytes);
          _sizeCache[widget.url] = formatted;
          if (mounted) {
            setState(() {
              _sizeStr = formatted;
            });
          }
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _sizeStr = 'Unknown size';
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _sizeStr);
  }
}

class DownloadStatusDialog extends StatefulWidget {
  const DownloadStatusDialog({required this.attachment, required this.openAfter, super.key});
  final TaskAttachmentModel attachment;
  final bool openAfter;

  static Future<void> show(BuildContext context, TaskAttachmentModel attachment, {required bool openAfter}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DownloadStatusDialog(attachment: attachment, openAfter: openAfter),
    );
  }

  @override
  State<DownloadStatusDialog> createState() => _DownloadStatusDialogState();
}

class _DownloadStatusDialogState extends State<DownloadStatusDialog> with SingleTickerProviderStateMixin {
  bool _isSuccess = false;
  String _statusMessage = 'Downloading file...';
  double _progress = 0.0;
  String? _savePath;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _startDownload();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<String?> _getDownloadPath() async {
    if (kIsWeb) return null;
    try {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        final dir = await getDownloadsDirectory();
        if (dir != null) return '${dir.path}/${widget.attachment.fileName}';
      }
      final dir = await getApplicationDocumentsDirectory();
      return '${dir.path}/${widget.attachment.fileName}';
    } catch (_) {
      final dir = await getTemporaryDirectory();
      return '${dir.path}/${widget.attachment.fileName}';
    }
  }

  Future<void> _startDownload() async {
    if (kIsWeb) {
      final uri = Uri.parse(widget.attachment.fileUrl);
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        setState(() {
          _isSuccess = true;
          _statusMessage = 'Redirecting to download...';
        });
        _animController.forward();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to open link')),
          );
        }
      }
      return;
    }

    try {
      final path = await _getDownloadPath();
      if (path == null) throw Exception('Could not determine save path');

      final dio = Dio();
      await dio.download(
        widget.attachment.fileUrl,
        path,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            setState(() {
              _progress = received / total;
              _statusMessage = 'Downloading: ${(received / (1024 * 1024)).toStringAsFixed(1)} MB / ${(total / (1024 * 1024)).toStringAsFixed(1)} MB';
            });
          }
        },
      );

      _savePath = path;
      setState(() {
        _isSuccess = true;
        _statusMessage = widget.openAfter ? 'Opening file...' : 'Downloaded successfully!';
      });
      _animController.forward();

      if (widget.openAfter) {
        await OpenFilex.open(path);
      }

      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: DashboardColors.error,
            content: Text('Failed to download: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DashboardColors.background.withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Container(
        width: 320,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isSuccess) ...[
              const SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(DashboardColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.attachment.fileName,
                style: const TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                style: const TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  backgroundColor: Colors.white.withValues(alpha: 0.04),
                  valueColor: const AlwaysStoppedAnimation<Color>(DashboardColors.primary),
                ),
              ),
            ] else ...[
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0x152DD4BF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: DashboardColors.tertiary,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Success!',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                style: const TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              if (_savePath != null) ...[
                const SizedBox(height: 12),
                Text(
                  _savePath!,
                  style: const TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class AttachmentActions {
  static Future<String?> getDownloadPath(String fileName) async {
    if (kIsWeb) return null;
    try {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        final dir = await getDownloadsDirectory();
        if (dir != null) return '${dir.path}/$fileName';
      }
      final dir = await getApplicationDocumentsDirectory();
      return '${dir.path}/$fileName';
    } catch (_) {
      final dir = await getTemporaryDirectory();
      return '${dir.path}/$fileName';
    }
  }

  static Future<void> downloadFile(BuildContext context, TaskAttachmentModel attachment, {required bool openAfter}) async {
    await DownloadStatusDialog.show(context, attachment, openAfter: openAfter);
  }

  static Future<void> openInBrowser(BuildContext context, TaskAttachmentModel attachment) async {
    final uri = Uri.parse(attachment.fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: DashboardColors.error,
            content: Text('Could not open file in browser'),
          ),
        );
      }
    }
  }
}


