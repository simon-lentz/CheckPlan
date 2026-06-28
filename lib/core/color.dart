import 'package:flutter/material.dart';

/// The colour that reads legibly *on* [background] — white on a dark surface,
/// black on a light one.
///
/// Keeps title and icon text readable when a surface is painted with an
/// arbitrary user-chosen colour (e.g. a checklist's colour on its detail app
/// bar). Defers the light/dark decision to [ThemeData.estimateBrightnessForColor].
Color readableOn(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
    ? Colors.white
    : Colors.black;
