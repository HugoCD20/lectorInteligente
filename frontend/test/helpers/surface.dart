import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ajusta la superficie de prueba para evitar desbordamientos de layout.
///
/// La superficie por defecto (800x600 físicos) resulta demasiado estrecha
/// para las páginas con formularios.
void configureLargeSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}
