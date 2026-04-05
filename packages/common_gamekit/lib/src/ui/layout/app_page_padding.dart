import 'package:flutter/material.dart';

class AppPagePadding extends StatelessWidget {
  final Widget child;

  const AppPagePadding({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final horizontal = isLandscape ? 24.0 : 16.0;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        child: child,
      ),
    );
  }
}