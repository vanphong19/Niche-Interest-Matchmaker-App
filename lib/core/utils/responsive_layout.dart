import 'package:flutter/widgets.dart';

enum ResponsiveBreakpoint { small, medium, large }

class ResponsiveInfo {
  const ResponsiveInfo({required this.size, required this.breakpoint});

  final Size size;
  final ResponsiveBreakpoint breakpoint;

  double get width => size.width;
  double get height => size.height;
  bool get isLandscape => width > height;
  bool get isVerySmall => width <= 320;
  bool get isSmall => breakpoint == ResponsiveBreakpoint.small;
  bool get isMedium => breakpoint == ResponsiveBreakpoint.medium;
  bool get isLarge => breakpoint == ResponsiveBreakpoint.large;
}

typedef ResponsiveWidgetBuilder =
    Widget Function(BuildContext context, ResponsiveInfo info);

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.small,
    required this.medium,
    required this.large,
  });

  final ResponsiveWidgetBuilder small;
  final ResponsiveWidgetBuilder medium;
  final ResponsiveWidgetBuilder large;

  static ResponsiveBreakpoint resolveBreakpoint(double width) {
    if (width <= 360) {
      return ResponsiveBreakpoint.small;
    }
    if (width <= 600) {
      return ResponsiveBreakpoint.medium;
    }
    return ResponsiveBreakpoint.large;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final breakpoint = resolveBreakpoint(size.width);
        final info = ResponsiveInfo(size: size, breakpoint: breakpoint);

        switch (breakpoint) {
          case ResponsiveBreakpoint.small:
            return small(context, info);
          case ResponsiveBreakpoint.medium:
            return medium(context, info);
          case ResponsiveBreakpoint.large:
            return large(context, info);
        }
      },
    );
  }
}

class ResponsiveValue<T> {
  const ResponsiveValue({
    required this.small,
    required this.medium,
    required this.large,
    this.verySmall,
  });

  final T small;
  final T medium;
  final T large;
  final T? verySmall;

  T resolve(double width) {
    if (width <= 320 && verySmall != null) {
      return verySmall as T;
    }
    if (width <= 360) {
      return small;
    }
    if (width <= 600) {
      return medium;
    }
    return large;
  }

  T of(BuildContext context) {
    return resolve(MediaQuery.sizeOf(context).width);
  }
}
