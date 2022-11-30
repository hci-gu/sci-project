import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:url_launcher/url_launcher.dart';

class NoDataMessage extends StatelessWidget {
  const NoDataMessage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 128,
          child: SvgPicture.asset('assets/svg/empty_state.svg'),
        ),
        AppTheme.spacer2x,
        Text(
          'Ingen data',
          style: AppTheme.headLine3,
        ),
        AppTheme.spacer2x,
        Text(
          'Om du har en Fitbitklocka kan du trycka på för att ladda ner klockappen som behövs för att använda RullaPå.',
          style: AppTheme.paragraphMedium,
        ),
        AppTheme.spacer2x,
        Button(
          width: 160,
          title: 'Öppna Fitbit',
          onPressed: () => _launchFitbitGallery(),
        ),
      ],
    );
  }

  Future<void> _launchFitbitGallery() async {
    if (!await launchUrl(
      Uri.https(
        'gallery.fitbit.com',
        'details/1c0a1dfd-e31d-4ed7-bb74-b653337a9e8d/openapp',
      ),
      mode: LaunchMode.externalApplication,
    )) {
      throw 'Could not launch';
    }
  }
}
