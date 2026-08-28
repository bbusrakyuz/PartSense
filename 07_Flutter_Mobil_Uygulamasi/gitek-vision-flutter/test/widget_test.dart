import 'package:flutter_test/flutter_test.dart';
import 'package:somun_vida_mobil/main.dart';

void main() {
  testWidgets('Ana ekran temel bileşenleri gösterir', (tester) async {
    await tester.pumpWidget(const SomunVidaUygulamasi());

    expect(find.text('Vida ve Somun Analizi'), findsOneWidget);
    expect(find.text('Kameradan Çek'), findsOneWidget);
    expect(find.text('Galeriden Seç'), findsOneWidget);
    expect(find.text('Analiz Et'), findsOneWidget);
  });
}
