import 'package:flutter/material.dart';

class SizedContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final double maxHeight;

  const SizedContainer({
    super.key,
    required this.child,
    this.maxWidth = 720,
    this.maxHeight = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: child,
      ),
    );
  }
}

class CenteredContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const CenteredContainer({
    super.key,
    required this.child,
    this.maxWidth = 720,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
