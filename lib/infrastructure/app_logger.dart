import 'package:logger/logger.dart';

/// アプリ全体で共有するロガー。呼び出し元のメソッド名は追わなくてよいので
/// スタックトレースの表示件数は絞る。
final appLogger = Logger(
  printer: PrettyPrinter(methodCount: 0),
);
