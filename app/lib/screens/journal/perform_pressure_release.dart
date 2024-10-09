import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/screens/onboarding/widgets/onboarding_stepper.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/progress_indicator_around.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PerformPressureReleaseScreen extends HookWidget {
  final List<PressureReleaseExercise> exercises;

  const PerformPressureReleaseScreen({
    super.key,
    this.exercises = const [
      PressureReleaseExercise.forwards,
      PressureReleaseExercise.rightSide,
      PressureReleaseExercise.leftSide,
    ],
  });

  @override
  Widget build(BuildContext context) {
    ValueNotifier<bool> isPaused = useState(true);
    ValueNotifier<int> currentExercise = useState(0);
    bool isDone = currentExercise.value == exercises.length;

    return Scaffold(
      appBar: AppTheme.appBar(AppLocalizations.of(context)!.pressureRelease),
      body: ListView(
        padding: AppTheme.screenPadding,
        children: [
          Column(
            children: [
              isDone
                  ? _doneWidget(context)
                  : PressureReleaseExerciseWidget(
                      duration: 900 / exercises.length,
                      key: Key(exercises[currentExercise.value].name),
                      exercise: exercises[currentExercise.value],
                      isPaused: isPaused.value,
                      callback: () {
                        isPaused.value = true;
                        currentExercise.value++;
                      },
                    ),
              if (!isDone && exercises.length > 1) AppTheme.spacer2x,
              if (!isDone && exercises.length > 1)
                StepIndicator(
                  count: exercises.length,
                  index: currentExercise.value,
                ),
              AppTheme.spacer4x,
              Button(
                width: 200,
                onPressed: () {
                  if (isDone) {
                    Navigator.pop(context);
                    return;
                  }
                  isPaused.value = !isPaused.value;
                },
                title: isDone
                    ? AppLocalizations.of(context)!.back
                    : isPaused.value
                        ? AppLocalizations.of(context)!.start
                        : AppLocalizations.of(context)!.pause,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _doneWidget(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.check_circle,
          color: AppTheme.colors.success,
          size: 100,
        ),
        Text(
          AppLocalizations.of(context)!.goodWork,
          style: AppTheme.headLine1,
        ),
      ],
    );
  }
}

class PressureReleaseExerciseWidget extends HookWidget {
  final PressureReleaseExercise exercise;
  final bool isPaused;
  final Function callback;
  final double duration;

  const PressureReleaseExerciseWidget({
    super.key,
    this.duration = 300,
    required this.callback,
    required this.isPaused,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    ValueNotifier<double> timeLeft = useState(duration);

    useEffect(() {
      Timer timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        timeLeft.value -= 0.5;
        if (timeLeft.value == 0) {
          callback();
          timer.cancel();
        }
      });
      if (isPaused) {
        timer.cancel();
      }

      return () => timer.cancel();
    }, [isPaused]);

    return Column(
      children: [
        Text(
          exercise.displayString(context),
          style: AppTheme.headLine2,
          textAlign: TextAlign.center,
        ),
        Image.asset(
          exercise.asset,
          height: 225,
        ),
        Text(
          exercise.description(context),
          style: AppTheme.paragraphMedium,
          textAlign: TextAlign.center,
        ),
        AppTheme.spacer4x,
        Text(
          AppLocalizations.of(context)!.holdPositionFor,
          style: AppTheme.headLine3,
          textAlign: TextAlign.center,
        ),
        AppTheme.spacer,
        ProgressIndicatorAround(
          size: 90,
          value: timeLeft.value.toDouble(),
          duration: duration.toDouble(),
          child: Text(
            (timeLeft.value / 10).toStringAsFixed(0),
            style: AppTheme.headLine1,
            textAlign: TextAlign.center,
          ),
        ),
        AppTheme.spacer,
        Text(
          AppLocalizations.of(context)!.seconds,
          style: AppTheme.headLine3,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
