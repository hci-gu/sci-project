import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:onboarding_overlay/onboarding_overlay.dart';
import 'package:scimovement/theme/theme.dart';

const int onboardingSteps = 3;

final onboardingNodesProvider = Provider<List<FocusNode>>(
  (ref) => List<FocusNode>.generate(
    onboardingSteps,
    (int i) => FocusNode(debugLabel: 'Onboarding Focus Node $i'),
    growable: false,
  ),
);

final onboardingStepsProvider = Provider<List<OnboardingStep>>((ref) {
  List<FocusNode> nodes = ref.watch(onboardingNodesProvider);

  return [
    OnboardingStep(
      focusNode: nodes[0],
      titleText: 'Menu',
      bodyText: 'You can open menu from here',
      overlayColor: Colors.black.withOpacity(0.6),
      // shape: const CircleBorder(),
      overlayBehavior: HitTestBehavior.translucent,
      onTapCallback: (
        TapArea area,
        VoidCallback next,
        VoidCallback close,
      ) {
        print('tap callback $area');
        if (area == TapArea.hole) {
          next();
        }
      },
      // showPulseAnimation: true,
      // stepBuilder: (
      //   BuildContext context,
      //   OnboardingStepRenderInfo renderInfo,
      // ) {
      //   return Material(
      //     child: Text(
      //       'HELLO',
      //       style: AppTheme.headLine1,
      //     ),
      //   );
      // },
    ),
    OnboardingStep(
      focusNode: nodes[1],
      titleText: 'WAAAA',
    )
  ];
});
