import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < AppConstants.mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppConstants.mobileBreakpoint &&
      MediaQuery.of(context).size.width < AppConstants.desktopBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppConstants.desktopBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppConstants.desktopBreakpoint) {
          return desktop ?? tablet ?? mobile;
        }

        if (constraints.maxWidth >= AppConstants.mobileBreakpoint) {
          return tablet ?? mobile;
        }

        return mobile;
      },
    );
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
    ResponsiveInfo info,
  ) builder;

  const ResponsiveBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final info = ResponsiveInfo(
          deviceWidth: constraints.maxWidth,
          deviceHeight: constraints.maxHeight,
          isMobile: constraints.maxWidth < AppConstants.mobileBreakpoint,
          isTablet: constraints.maxWidth >= AppConstants.mobileBreakpoint &&
              constraints.maxWidth < AppConstants.desktopBreakpoint,
          isDesktop: constraints.maxWidth >= AppConstants.desktopBreakpoint,
        );
        return builder(context, constraints, info);
      },
    );
  }
}

class ResponsiveInfo {
  final double deviceWidth;
  final double deviceHeight;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;

  const ResponsiveInfo({
    required this.deviceWidth,
    required this.deviceHeight,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
  });
}
