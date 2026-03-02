import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/bouts.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/models/goals.dart';
import 'package:scimovement/models/journal/journal.dart';

/// Invalidates home-related providers so the next frame re-fetches fresh data.
void refreshHomeProviders(WidgetRef ref) {
  ref.invalidate(energyProvider);
  ref.invalidate(totalEnergyProvider);
  ref.invalidate(averageEnergyProvider);
  ref.invalidate(dailyEnergyChartProvider);
  ref.invalidate(averageMovementMinutesProvider);
  ref.invalidate(totalMovementMinutesProvider);

  ref.invalidate(boutsProvider);
  ref.invalidate(excerciseBoutsProvider);
  ref.invalidate(exerciseCountProvider);
  ref.invalidate(averageSedentaryBout);
  ref.invalidate(totalSedentaryBout);

  ref.invalidate(goalsProvider);
  ref.invalidate(journalGoalsProvider);
  ref.invalidate(pressureReleaseGoalProvider);
  ref.invalidate(bladderEmptyingGoalProvider);

  ref.invalidate(journalProvider);
  ref.invalidate(journalMonthlyProvider);
  ref.invalidate(journalForDayProvider);
  ref.invalidate(paginatedJournalProvider);
  ref.invalidate(pressureReleaseCountProvider);
  ref.invalidate(bladderEmptyingCountProvider);
  ref.invalidate(uniqueEntriesProvider);
  ref.invalidate(pressureUlcerProvider);
  ref.invalidate(utiProvider);
  ref.invalidate(neuroPathicPainAndSpasticityProvider);
}
