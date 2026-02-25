import 'package:drift/drift.dart';

import 'exercises_table.dart';

/// Junction table: Exercise ↔ Exercise (self-relation for variations/substitutes).
class ExerciseVariations extends Table {
  @ReferenceName('variationsByExercise')
  IntColumn get exerciseId => integer().references(Exercises, #id)();

  @ReferenceName('variationsByVariation')
  IntColumn get variationId => integer().references(Exercises, #id)();

  @override
  Set<Column> get primaryKey => {exerciseId, variationId};
}
