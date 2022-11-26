import 'dart:async';

import 'package:azure_application_insights/azure_application_insights.dart';
import 'package:logging/logging.dart';

class NullProcessor implements Processor {
  @override
  Processor? get next => null;

  @override
  void process(
      {required List<ContextualTelemetryItem> contextualTelemetryItems}) {}

  @override
  Future<void> flush() async {}
}

void main(List<String> arguments) {
  // If you set the level to NONE here, the listen callback won't be invoked and the problem won't occur.
  Logger.root.level = Level.ALL;

  // If we log during this callback, it causes re-entrancy into the underlying stream of log entries, which is not
  // permitted (Dart's stream controller disallow it).
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');

    // By logging in this logging callback, we can trigger the problem.
    if (record.message.contains('42')) {
      Logger(record.loggerName).info('Trigger re-entrancy');
    }
  });

  final telemetryClient = TelemetryClient(
    // Both the TransmissionProcessor and DebugProcessor write to the log, so using either is sufficient to trigger the
    // problem. Indeed, using azure_application_insights isn't necessary to trigger the problem - any code that logs
    // will do.
    processor: DebugProcessor(
      next: NullProcessor(),
    ),
  );

  print('Starting...');

  for (var i = 0; i < 100; ++i) {
    telemetryClient.trackTrace(
      severity: Severity.information,
      message: 'test $i',
    );
  }

  print('...done');
}
