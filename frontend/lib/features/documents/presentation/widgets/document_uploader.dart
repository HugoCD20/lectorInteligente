import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/providers.dart';
import '../../../../config/strings.dart';
import '../../domain/entities/document.dart';

const int _maxBytes = 50 * 1024 * 1024;
const List<String> _allowedExtensions = ['pdf', 'epub'];

/// Selecciona un archivo y lo sube al servidor.
///
/// Devuelve el documento subido o `null` si el usuario cancela o la
/// subida falla. Muestra los mensajes de error mediante SnackBar.
Future<Document?> pickAndUploadDocument(
  BuildContext context,
  WidgetRef ref,
) async {
  final messenger = ScaffoldMessenger.of(context);

  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: _allowedExtensions,
    withData: true,
  );
  final file = result?.files.single;
  if (file == null) return null;

  final bytes = file.bytes;
  final extension = file.extension?.toLowerCase();
  if (bytes == null || extension == null || !_allowedExtensions.contains(extension)) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text(AppStrings.invalidFileFormat)),
      );
    return null;
  }
  if (file.size > _maxBytes) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.fileTooLarge)));
    return null;
  }

  try {
    final document = await ref
        .read(documentsControllerProvider.notifier)
        .upload(fileName: file.name, bytes: bytes, mimeType: _mimeTypeFor(extension));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text(AppStrings.documentUploaded)),
      );
    return document;
  } catch (error) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error.toString())));
    return null;
  }
}

String _mimeTypeFor(String extension) {
  return switch (extension) {
    'pdf' => 'application/pdf',
    'epub' => 'application/epub+zip',
    _ => 'application/octet-stream',
  };
}
