import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    _fail(
      'Usage: dart run tool/check_coverage.dart <lcov.info> --min-line-rate <percent>',
    );
  }

  final file = File(args.first);
  final minIndex = args.indexOf('--min-line-rate');
  final minRate = minIndex == -1 || minIndex + 1 >= args.length
      ? 80.0
      : double.parse(args[minIndex + 1]);

  if (!file.existsSync()) {
    _fail('Coverage file not found: ${file.path}');
  }

  var found = 0;
  var hit = 0;

  for (final line in file.readAsLinesSync()) {
    if (!line.startsWith('DA:')) continue;
    final parts = line.substring(3).split(',');
    if (parts.length < 2) continue;
    found += 1;
    if (int.parse(parts[1]) > 0) hit += 1;
  }

  if (found == 0) {
    _fail('Coverage file has no line data: ${file.path}');
  }

  final rate = hit / found * 100;
  stdout.writeln('Line coverage: ${rate.toStringAsFixed(2)}% ($hit/$found)');

  if (rate < minRate) {
    _fail('Line coverage is below ${minRate.toStringAsFixed(2)}%.');
  }
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
