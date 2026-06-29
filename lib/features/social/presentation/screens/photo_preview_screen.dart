import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PhotoPreviewScreen extends StatelessWidget {
  final String imagePath;
  const PhotoPreviewScreen({super.key, required this.imagePath});

  Future<String> _uploadOrGetPath() async {
    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      if (session != null) {
        final file = File(imagePath);
        final ext = imagePath.split('.').last;
        final fileName = 'photos/${DateTime.now().millisecondsSinceEpoch}.$ext';
        await supabase.storage.from('chat-media').upload(
              fileName,
              file,
              fileOptions: FileOptions(contentType: 'image/$ext'),
            );
        return supabase.storage.from('chat-media').getPublicUrl(fileName);
      }
    } catch (_) {}
    return imagePath; // Return local path if not logged in or fails
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Taken Photo
          Center(
            child: Image.file(
              File(imagePath),
              fit: BoxFit.contain,
            ),
          ),

          // Top Back Action
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Bottom Actions
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white30, width: 1.5),
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Chụp lại', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0084FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Gửi', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      // Show loading spinner
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.blue)),
                      );
                      
                      final resultPath = await _uploadOrGetPath();
                      if (context.mounted) {
                        Navigator.pop(context); // Dismiss loading
                        Navigator.pop(context, resultPath); // Return path/URL to composer
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
