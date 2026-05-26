import 'package:flutter/material.dart';

class DashboardBreakpoints {
  const DashboardBreakpoints._();

  static const double mobile = 768;
  static const double desktop = 1200;
}

class DashboardSpacing {
  const DashboardSpacing._();

  static const double unit = 8;
  static const double xs = 8;
  static const double sm = 16;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 48;
  static const double sidebar = 256;
  static const double desktopMaxWidth = 1320;
}

class DashboardRadii {
  const DashboardRadii._();

  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 32;
  static const double full = 999;
}

class DashboardDurations {
  const DashboardDurations._();

  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 700);
}

class DashboardTextStyles {
  const DashboardTextStyles._();

  static const display = TextStyle(
    fontSize: 48,
    height: 1.1,
    letterSpacing: -1.0,
    fontWeight: FontWeight.w800,
  );

  static const headline = TextStyle(
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  static const title = TextStyle(
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w700,
  );

  static const body = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static const label = TextStyle(
    fontSize: 12,
    height: 1.0,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w700,
  );
}
