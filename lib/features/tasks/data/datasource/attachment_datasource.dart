import 'dart:io';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/features/tasks/data/models/task_attachment_model.dart';
import 'package:uuid/uuid.dart';

class AttachmentRemoteDataSource {
  AttachmentRemoteDataSource(this._client);
  final SupabaseClient _client;

  static const _bucket = 'task-attachments';

  Future<List<TaskAttachmentModel>> getAttachments(String taskId) async {
    final response = await _client
        .from('task_attachments')
        .select()
        .eq('task_id', taskId)
        .order('created_at', ascending: true);

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
    const uuid = Uuid();

    for (final file in files) {
      try {
        final safeFileName = sanitizeFileName(file.name);
        final storageFileName = '${uuid.v4()}_$safeFileName';
        final storagePath = '$userId/$taskId/$storageFileName';

        if (file.bytes != null) {
          await _client.storage.from(_bucket).uploadBinary(
                storagePath,
                file.bytes!,
                fileOptions: FileOptions(
                  upsert: true,
                  contentType: _mimeType(file.extension),
                ),
              );
        } else if (file.filePath != null) {
          await _client.storage.from(_bucket).upload(
                storagePath,
                File(file.filePath!),
                fileOptions: FileOptions(
                  upsert: true,
                  contentType: _mimeType(file.extension),
                ),
              );
        } else {
          continue;
        }

        final url = _client.storage.from(_bucket).getPublicUrl(storagePath).trim();

        final row = await _client
            .from('task_attachments')
            .insert({
              'task_id': taskId,
              'file_name': file.name,
              'storage_path': storagePath,
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

  String sanitizeFileName(String fileName) {
    final parts = fileName.split('.');
    if (parts.length < 2) {
      return removeDiacritics(fileName)
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'-+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
    }
    final extension = parts.removeLast();
    final name = parts.join('.');
    final normalized = removeDiacritics(name)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return normalized.isEmpty ? 'file.$extension' : '$normalized.$extension';
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
