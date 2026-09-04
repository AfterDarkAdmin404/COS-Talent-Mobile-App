import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chat_message.dart';
import '../theme/app_theme.dart';

/// 10 MB, matching `message-attachments`' `file_size_limit` (046) — checked
/// client-side so an oversized pick fails fast with a friendly message
/// instead of a Storage API 400 after the bytes are already sent.
const _maxAttachmentBytes = 10 * 1024 * 1024;

/// Kept in sync with 046's `allowed_mime_types` for the bucket. Neither
/// `ImagePicker` nor `FilePicker` reliably returns a MIME type on every
/// platform, so it's derived from the extension here instead of trusted
/// from the picker.
const _extensionMimeTypes = <String, String>{
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
  'heic': 'image/heic',
  'pdf': 'application/pdf',
  'doc': 'application/msword',
  'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'xls': 'application/vnd.ms-excel',
  'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'txt': 'text/plain',
};

class PickedAttachment {
  final File file;
  final ChatAttachmentKind kind;
  final String fileName;
  final String mimeType;
  final int sizeBytes;

  const PickedAttachment({
    required this.file,
    required this.kind,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
  });
}

/// Opens a "Photo / Document" bottom sheet, runs the matching picker, and
/// validates the result (size, extension) before returning it — `null` on
/// cancel at any step. Shared by both thread screens (application + direct)
/// so the picker UI and validation rules live in exactly one place.
Future<PickedAttachment?> pickChatAttachment(BuildContext context) async {
  final kind = await showModalBottomSheet<ChatAttachmentKind>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Attach…', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.photo_outlined),
            title: const Text('Photo'),
            onTap: () => Navigator.of(sheetContext).pop(ChatAttachmentKind.image),
          ),
          ListTile(
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: const Text('Document'),
            onTap: () => Navigator.of(sheetContext).pop(ChatAttachmentKind.file),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (kind == null || !context.mounted) return null;

  File file;
  String fileName;
  if (kind == ChatAttachmentKind.image) {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (picked == null) return null;
    file = File(picked.path);
    fileName = picked.name;
  } else {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
    );
    final path = result?.files.single.path;
    if (path == null) return null;
    file = File(path);
    fileName = result!.files.single.name;
  }

  final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
  final mimeType = _extensionMimeTypes[ext];
  if (mimeType == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That file type isn\'t supported.')),
      );
    }
    return null;
  }

  final sizeBytes = await file.length();
  if (sizeBytes > _maxAttachmentBytes) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That file is too large — the limit is 10 MB.')),
      );
    }
    return null;
  }

  return PickedAttachment(file: file, kind: kind, fileName: fileName, mimeType: mimeType, sizeBytes: sizeBytes);
}
