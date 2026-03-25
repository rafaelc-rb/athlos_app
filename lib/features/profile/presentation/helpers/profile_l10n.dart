import '../../../../core/localization/domain_label_resolver.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/enums/body_aesthetic.dart';
import '../../domain/enums/experience_level.dart';
import '../../domain/enums/gender.dart';
import '../../domain/enums/training_goal.dart';
import '../../domain/enums/training_style.dart';

String localizedTrainingGoalName(TrainingGoal goal, AppLocalizations l10n) =>
    DomainLabelResolver(l10n).toDisplayName(
      kind: DomainLabelKind.trainingGoal,
      canonicalName: goal.name,
      isVerified: true,
    );

String localizedTrainingGoalDescription(
  TrainingGoal goal,
  AppLocalizations l10n,
) => DomainLabelResolver(l10n).toDisplayName(
  kind: DomainLabelKind.trainingGoalDescription,
  canonicalName: goal.name,
  isVerified: true,
);

String localizedTrainingGoalImpact(TrainingGoal goal, AppLocalizations l10n) =>
    DomainLabelResolver(l10n).toDisplayName(
      kind: DomainLabelKind.trainingGoalImpact,
      canonicalName: goal.name,
      isVerified: true,
    );

String localizedBodyAestheticName(
  BodyAesthetic aesthetic,
  AppLocalizations l10n,
) => DomainLabelResolver(l10n).toDisplayName(
  kind: DomainLabelKind.bodyAesthetic,
  canonicalName: aesthetic.name,
  isVerified: true,
);

String localizedBodyAestheticDescription(
  BodyAesthetic aesthetic,
  AppLocalizations l10n,
) => DomainLabelResolver(l10n).toDisplayName(
  kind: DomainLabelKind.bodyAestheticDescription,
  canonicalName: aesthetic.name,
  isVerified: true,
);

String localizedBodyAestheticImpact(
  BodyAesthetic aesthetic,
  AppLocalizations l10n,
) => DomainLabelResolver(l10n).toDisplayName(
  kind: DomainLabelKind.bodyAestheticImpact,
  canonicalName: aesthetic.name,
  isVerified: true,
);

String localizedTrainingStyleName(TrainingStyle style, AppLocalizations l10n) =>
    DomainLabelResolver(l10n).toDisplayName(
      kind: DomainLabelKind.trainingStyle,
      canonicalName: style.name,
      isVerified: true,
    );

String localizedTrainingStyleDescription(
  TrainingStyle style,
  AppLocalizations l10n,
) => DomainLabelResolver(l10n).toDisplayName(
  kind: DomainLabelKind.trainingStyleDescription,
  canonicalName: style.name,
  isVerified: true,
);

String localizedTrainingStyleImpact(
  TrainingStyle style,
  AppLocalizations l10n,
) => DomainLabelResolver(l10n).toDisplayName(
  kind: DomainLabelKind.trainingStyleImpact,
  canonicalName: style.name,
  isVerified: true,
);

String localizedExperienceLevelName(
  ExperienceLevel level,
  AppLocalizations l10n,
) => DomainLabelResolver(l10n).toDisplayName(
  kind: DomainLabelKind.experienceLevel,
  canonicalName: level.name,
  isVerified: true,
);

String localizedExperienceLevelDescription(
  ExperienceLevel level,
  AppLocalizations l10n,
) => DomainLabelResolver(l10n).toDisplayName(
  kind: DomainLabelKind.experienceLevelDescription,
  canonicalName: level.name,
  isVerified: true,
);

String localizedExperienceLevelImpact(
  ExperienceLevel level,
  AppLocalizations l10n,
) => DomainLabelResolver(l10n).toDisplayName(
  kind: DomainLabelKind.experienceLevelImpact,
  canonicalName: level.name,
  isVerified: true,
);

String localizedGenderName(Gender gender, AppLocalizations l10n) =>
    DomainLabelResolver(l10n).toDisplayName(
      kind: DomainLabelKind.gender,
      canonicalName: gender.name,
      isVerified: true,
    );
