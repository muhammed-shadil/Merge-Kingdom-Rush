import 'package:flutter_test/flutter_test.dart';

import 'package:game_2/main.dart';

void main() {
  testWidgets('Merge Kingdom boots to the game screen', (tester) async {
    await tester.pumpWidget(const MergeKingdomApp());
    await tester.pump();

    // The HUD shows the summon control.
    expect(find.text('SUMMON'), findsOneWidget);
  });
}
