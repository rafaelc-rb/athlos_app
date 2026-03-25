import 'package:drift/drift.dart';

class CatalogGovernanceAppliedRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteRuleId => text().unique()();
  IntColumn get ruleVersion => integer()();
  TextColumn get status => text().withDefault(const Constant('applied'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get appliedAt => dateTime().withDefault(currentDateAndTime)();
}
