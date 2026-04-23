import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.tooltip = 'Volver', this.fallbackLocation = '/home'});

  final String tooltip;
  final String? fallbackLocation;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);

    return IconButton(
      tooltip: tooltip,
      onPressed: () {
        if (router.canPop()) {
          context.pop();
          return;
        }

        if (fallbackLocation != null) {
          context.go(fallbackLocation!);
        }
      },
      icon: const Icon(Icons.arrow_back),
    );
  }
}