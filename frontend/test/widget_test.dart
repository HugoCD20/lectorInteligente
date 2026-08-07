import 'package:flutter_test/flutter_test.dart';

import 'package:lector_inteligente/app.dart';
import 'package:lector_inteligente/config/strings.dart';

void main() {
  testWidgets('La aplicación inicia y muestra la página de inicio', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LectorInteligenteApp());

    expect(find.text(AppStrings.appName), findsWidgets);
    expect(find.text(AppStrings.uploadDocument), findsOneWidget);
    expect(find.text(AppStrings.openGallery), findsOneWidget);
  });
}
