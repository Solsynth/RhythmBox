import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rhythm_box/widgets/sized_container.dart';

class NoLoginFallback extends StatelessWidget {
  const NoLoginFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return CenteredContainer(
      maxWidth: 280,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.login,
            size: 48,
          ),
          const Gap(12),
          Text(
            'Connect with your Spotify',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Text(
            'You need to connect RhythmBox with your spotify account in settings page, so that we can access your library.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
