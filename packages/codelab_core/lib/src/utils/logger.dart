import 'package:logger/logger.dart';

late Logger logger;

void initLogger(LogPrinter printer, MultiOutput output) {
  logger = Logger(printer: printer, output: output);
}
