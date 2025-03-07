import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LogService {
  static final LogService _instance = LogService._internal();

  factory LogService() {
    return _instance;
  }

  LogService._internal();

  Future<String> _getLogFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final logDirectory = Directory('${directory.path}/logs');
    if (!(await logDirectory.exists())) {
      await logDirectory.create(recursive: true);
    }
    return '${logDirectory.path}/app_log.txt';
  }

  Future<void> log(String message) async {
    final logFilePath = await _getLogFilePath();
    final logFile = File(logFilePath);
    final timestamp = DateTime.now().toIso8601String();
    await logFile.writeAsString('$timestamp: $message\n',
        mode: FileMode.append);
  }
}
