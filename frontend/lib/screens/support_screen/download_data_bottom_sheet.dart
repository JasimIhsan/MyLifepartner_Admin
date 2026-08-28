import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/services/api_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadDataBottomSheet extends StatefulWidget {
  const DownloadDataBottomSheet({super.key});

  @override
  State<DownloadDataBottomSheet> createState() =>
      _DownloadDataBottomSheetState();
}

class _DownloadDataBottomSheetState extends State<DownloadDataBottomSheet> {
  bool _isLoading = true;
  String? _error;
  String? _filePath;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  String get _readableLocation {
    if (Platform.isAndroid) {
      return 'Downloads Folder (Internal Storage > Download)';
    } else if (Platform.isIOS) {
      return 'Files App (On My iPhone > Life Partner Again)';
    }
    return 'Downloads Folder';
  }

  Future<void> _startDownload() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _filePath = null;
      _fileName = null;
    });

    try {
      // 1. If Android <= 12, silently request storage permission in background if possible
      if (Platform.isAndroid) {
        try {
          final status = await Permission.storage.status;
          if (!status.isGranted && !status.isPermanentlyDenied) {
            await Permission.storage.request();
          }
        } catch (_) {}
      }

      // 2. Fetch the PDF from the backend
      final dio = ApiService.client;
      final response = await dio.get(
        '/export-data',
        options: Options(responseType: ResponseType.bytes),
      );

      final dynamic data = response.data;
      if (data == null) {
        throw const FormatException('Empty data received from server');
      }

      final List<int> bytes = data is List<int>
          ? data
          : utf8.encode(data.toString());

      // 3. Save to available directory
      final now = DateTime.now();
      final dateFormatted =
          '${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}';
      final baseFileName = 'life_partner_again_data_$dateFormatted';

      final savedFile = await _saveFileToAvailableDirectory(
        bytes,
        baseFileName,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _filePath = savedFile.path;
          _fileName = savedFile.path.split(Platform.pathSeparator).last;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = _extractErrorMessage(e);
        });
      }
    }
  }

  Future<File> _saveFileToAvailableDirectory(
    List<int> bytes,
    String baseFileName,
  ) async {
    const extension = '.pdf';
    final List<Directory> candidateDirs = [];

    // 1. Public Downloads directory on Android (if accessible)
    if (Platform.isAndroid) {
      try {
        final pubDownload = Directory('/storage/emulated/0/Download');
        if (await pubDownload.exists()) {
          candidateDirs.add(pubDownload);
        }
      } catch (_) {}

      // 2. App-specific external files Download directory
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final extDownload = Directory('${extDir.path}/Download');
          if (!await extDownload.exists()) {
            await extDownload.create(recursive: true);
          }
          candidateDirs.add(extDownload);
          candidateDirs.add(extDir);
        }
      } catch (_) {}
    }

    // 3. System Downloads directory
    try {
      final sysDownload = await getDownloadsDirectory();
      if (sysDownload != null) {
        candidateDirs.add(sysDownload);
      }
    } catch (_) {}

    // 4. Guaranteed App Documents directory
    try {
      final docDir = await getApplicationDocumentsDirectory();
      candidateDirs.add(docDir);
    } catch (_) {}

    FileSystemException? lastFileSystemError;

    for (final dir in candidateDirs) {
      try {
        String fileName = '$baseFileName$extension';
        String filePath = '${dir.path}/$fileName';
        File file = File(filePath);

        int counter = 1;
        while (await file.exists()) {
          fileName = '$baseFileName ($counter)$extension';
          filePath = '${dir.path}/$fileName';
          file = File(filePath);
          counter++;
        }

        await file.writeAsBytes(bytes, flush: true);
        return file;
      } on FileSystemException catch (e) {
        lastFileSystemError = e;
        continue;
      } catch (_) {
        continue;
      }
    }

    if (lastFileSystemError != null) {
      throw lastFileSystemError;
    }

    throw const FileSystemException(
      'Unable to write to storage. Please check device storage permissions.',
    );
  }

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return "Connection timed out. Please check your internet connection and try again.";
        case DioExceptionType.connectionError:
          return "Unable to connect to the server. Please check your internet connection.";
        case DioExceptionType.cancel:
          return "The download request was cancelled.";
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;

          // Attempt to decode JSON error message if returned
          String? serverMessage;
          final responseData = error.response?.data;
          if (responseData != null) {
            try {
              if (responseData is Map && responseData['message'] is String) {
                serverMessage = responseData['message'] as String;
              } else if (responseData is List<int>) {
                final decoded = utf8.decode(responseData);
                final json = jsonDecode(decoded);
                if (json is Map && json['message'] is String) {
                  serverMessage = json['message'] as String;
                }
              } else if (responseData is String) {
                final json = jsonDecode(responseData);
                if (json is Map && json['message'] is String) {
                  serverMessage = json['message'] as String;
                }
              }
            } catch (_) {
              // Ignore decoding failures and fallback to status code messages
            }
          }

          if (serverMessage != null && serverMessage.trim().isNotEmpty) {
            return serverMessage;
          }

          if (statusCode == 401) {
            return "Your session has expired. Please log in again.";
          } else if (statusCode == 403) {
            return "You do not have permission to download this data.";
          } else if (statusCode == 404) {
            return "Data export service is currently unavailable. Please try again later.";
          } else if (statusCode == 429) {
            return "Too many requests. Please wait a moment and try again.";
          } else if (statusCode != null && statusCode >= 500) {
            return "Our server encountered an issue while generating your PDF. Please try again later.";
          }
          return "Unable to complete request ($statusCode). Please try again.";
        default:
          return "A network error occurred while downloading your data. Please try again.";
      }
    } else if (error is FileSystemException || error is IOException) {
      return "Unable to save file to local storage. Please check your device storage permissions.";
    }

    return "Something went wrong while preparing your data. Please try again later.";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary;
    final mutedTextColor =
        theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 14,
          bottom: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 20),
              Text(
                'Preparing your data...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'This might take a few moments.',
                style: TextStyle(fontSize: 15, color: mutedTextColor),
                textAlign: TextAlign.center,
              ),
            ] else if (_error != null) ...[
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error.withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Download Failed',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.4,
                  color: mutedTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.dividerColor),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: mutedTextColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _startDownload,
                      child: const Text(
                        'Try Again',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success.withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Download Complete',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your personal data has been exported into a PDF.',
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.4,
                  color: mutedTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              if (_filePath != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.canvasColor.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.3 : 0.6,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: AppColors.error,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fileName ?? 'User Data Export.pdf',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.folder_open_rounded,
                                      size: 14,
                                      color: theme.primaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _readableLocation,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: theme.primaryColor,
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
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 15,
                              color: mutedTextColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                Platform.isIOS
                                    ? 'Open Files app > On My iPhone > Life Partner Again to view your PDF.'
                                    : 'Open the Files or Downloads app on your device to view the PDF.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: mutedTextColor,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
