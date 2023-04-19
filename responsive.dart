import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  final Widget smallScreen;
  final Widget? mediumScreen;
  final Widget bigScreen;
  final VoidCallback? onChange;

  const Responsive({
    Key? key,
    required this.smallScreen,
    this.mediumScreen,
    this.onChange,
    required this.bigScreen,
  }) : super(key: key);

  /* static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;


  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 850;*/

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (onChange != null) {
          onChange!();
        }

        if (constraints.maxWidth >= 1100) {
          return bigScreen;
        } else if (constraints.maxWidth >= 650 && constraints.maxWidth < 1100) {
          return mediumScreen ?? bigScreen;
        } else {
          return smallScreen;
        }
      },
    );
  }
}

enum ScreenSize {
  bigScreen,
  mediumScreen,
  smallScreen,
}
