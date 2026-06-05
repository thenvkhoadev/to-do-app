import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/features/tasks/data/models/task_attachment_model.dart';

class AttachmentRemoteDataSource {
  AttachmentRemoteDataSource(this._client);
  final SupabaseClient _client;

  static const _bucket = 'task-attachments';

  Future<List<TaskAttachmentModel>> getAttachments(String taskId) async {
    debugPrint('getAttachments: querying task_id=$taskId');
    final response = await _client
        .from('task_attachments')
        .select()
        .eq('task_id', taskId)
        .order('created_at', ascending: true);

    debugPrint('getAttachments: got ${(response as List).length} rows: $response');
    return (response as List<dynamic>)
        .map((json) => TaskAttachmentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> uploadAttachments({
    required String taskId,
    required String userId,
    required List<PlatformFileInfo> files,
  }) async {
    final results = <Map<String, dynamic>>[];
    for (final file in files) {
      try {
        final ext = file.extension.isNotEmpty ? '.${file.extension.toLowerCase()}' : '';
        final baseName = file.name
            .replaceAll(RegExp(r'\.[^.]+$'), '')
            .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
            .replaceAll(RegExp(r'_+'), '_')
            .replaceAll(RegExp(r'^_|_$'), '');
        final safeName = '${baseName.isEmpty ? 'file' : baseName}_${DateTime.now().millisecondsSinceEpoch}$ext';
        final path = '$userId/$taskId/$safeName';
        if (file.bytes != null) {
          await _client.storage.from(_bucket).uploadBinary(
                path,
                file.bytes!,
                fileOptions: FileOptions(
                  upsert: true,
                  contentType: _mimeType(file.extension),
                ),
              );
        } else if (file.filePath != null) {
          await _client.storage.from(_bucket).upload(
                path,
                File(file.filePath!),
                fileOptions: FileOptions(
                  upsert: true,
                  contentType: _mimeType(file.extension),
                ),
              );
        } else {
          continue;
        }

        final url = _client.storage.from(_bucket).getPublicUrl(path).trim();

        final row = await _client
            .from('task_attachments')
            .insert({
              'task_id': taskId,
              'file_name': file.name,
              'file_url': url,
            })
            .select()
            .single();
        results.add(row);
      } catch (e) {
        debugPrint('Attachment upload error for ${file.name}: $e');

      }
    }
    return results;
  }

  String _mimeType(String ext) => switch (ext.toLowerCase()) {
        'pdf' => 'application/pdf',
        'png' => 'image/png',
        'jpg' || 'jpeg' => 'image/jpeg',
        'doc' => 'application/msword',
        'docx' =>
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'txt' => 'text/plain',
        _ => 'application/octet-stream',
      };
}

class PlatformFileInfo {
  const PlatformFileInfo({
    required this.name,
    required this.sizeBytes,
    required this.extension,
    this.bytes,
    this.filePath,
  });

  final String name;
  final int sizeBytes;
  final String extension;
  final Uint8List? bytes;
  final String? filePath;
}
