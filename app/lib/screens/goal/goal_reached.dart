import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

class GoalReachedScreen extends HookWidget {
  const GoalReachedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final confettiController = useMemoized(() => ConfettiController(
          duration: const Duration(seconds: 3),
        ));

    useEffect(() {
      confettiController.play();
      Future.delayed(const Duration(seconds: 5)).then((_) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      });
      return () => confettiController.dispose();
    }, [confettiController]);

    return Scaffold(
      backgroundColor: AppTheme.colors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConfettiWidget(
              confettiController: confettiController,
              blastDirection: -1,
              numberOfParticles: 20,
              particleDrag: 0.025,
              child: Text(
                AppLocalizations.of(context)!.reachedGoalMessage,
                textAlign: TextAlign.center,
                style: AppTheme.headLine2.copyWith(
                  color: AppTheme.colors.white,
                ),
              ),
            ),
            AppTheme.spacer2x,
            SvgPicture.asset(
              'assets/svg/goal_done.svg',
              height: 200,
            ),
          ],
        ),
      ),
    );
  }
}
