import 'package:flutter/material.dart';

abstract final class AppRadii {
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double card = 28;
  static const double pill = 999;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get cardAll => BorderRadius.circular(card);
  static BorderRadius get pillAll => BorderRadius.circular(pill);
}
