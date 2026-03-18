import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/bouts.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/models/goals.dart';
import 'package:scimovement/models/journal/journal.dart';

/// Invalidates home-related providers so the next frame re-fetches fresh data.
void refreshHomeProviders(void Function(ProviderOrFamily provider) invalidate) {
  invalidate(energyProvider);
  invalidate(totalEnergyProvider);
  invalidate(averageEnergyProvider);
  invalidate(dailyEnergyChartProvider);
  invalidate(averageMovementMinutesProvider);
  invalidate(totalMovementMinutesProvider);

  invalidate(boutsProvider);
  invalidate(excerciseBoutsProvider);
  invalidate(exerciseCountProvider);
  invalidate(averageSedentaryBout);
  invalidate(totalSedentaryBout);

  invalidate(goalsProvider);
  invalidate(journalGoalsProvider);
  invalidate(pressureReleaseGoalProvider);
  invalidate(bladderEmptyingGoalProvider);

  invalidate(journalProvider);
  invalidate(journalMonthlyProvider);
  invalidate(journalForDayProvider);
  invalidate(paginatedJournalProvider);
  invalidate(pressureReleaseCountProvider);
  invalidate(bladderEmptyingCountProvider);
  invalidate(uniqueEntriesProvider);
  invalidate(pressureUlcerProvider);
  invalidate(utiProvider);
  invalidate(neuroPathicPainAndSpasticityProvider);
}
