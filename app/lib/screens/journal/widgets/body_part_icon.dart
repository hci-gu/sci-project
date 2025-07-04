import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:scimovement/api/classes.dart';
import 'dart:math' as math;

class BodyPartIcon extends StatelessWidget {
  final BodyPart bodyPart;
  final double size;

  const BodyPartIcon({super.key, required this.bodyPart, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(
        bodyPart.side == Side.left ? math.pi : 0,
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: SvgPicture.asset('assets/svg/${bodyPart.type.name}.svg'),
      ),
    );
  }
}
