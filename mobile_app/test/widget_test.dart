import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';

void main() {
  testWidgets('Smoke test de inicio de la aplicación Torneo Deportivo', (WidgetTester tester) async {
    await tester.pumpWidget(const TorneoDeportivoApp());
    await tester.pumpAndSettle();

    // Comprobar que carga la pantalla inicial
    expect(find.byType(TorneoDeportivoApp), findsOneWidget);
  });
}
