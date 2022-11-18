import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:scimovement/api/classes.dart';
import 'dart:math' as math;

class BodyPartIcon extends StatelessWidget {
  final BodyPart bodyPart;
  final Arm? arm;
  final double size;

  const BodyPartIcon(
      {Key? key, required this.bodyPart, this.arm, this.size = 64})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(
        arm == Arm.left ? math.pi : 0,
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: SvgPicture.asset('assets/svg/${bodyPart.name}.svg'),
      ),
    );
  }
}
