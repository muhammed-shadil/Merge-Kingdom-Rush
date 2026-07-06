import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:game_2/models/game_data.dart';
import 'package:game_2/models/game_models.dart';
import 'package:game_2/screens/menu_screen.dart';

void main() {
  test('GameData round-trips through JSON', () {
    final d = GameData.fresh();
    d.gold = 1234;
    d.wave = 7;
    d.prestigePoints = 3;
    final restored = GameData.decode(d.encode());
    expect(restored.gold, 1234);
    expect(restored.wave, 7);
    expect(restored.prestigePoints, 3);
    expect(restored.board.length, kBoardSize);
  });

  test('Prestige awards points and resets the run', () {
    final d = GameData.fresh();
    d.highestWave = 25; // pending = 2
    expect(d.canPrestige, true);
    expect(d.pendingPrestige, 2);
    d.prestige();
    expect(d.prestigePoints, 2);
    expect(d.wave, 1);
    expect(d.prestigeMult, 1.5);
  });

  testWidgets('Menu shows the PLAY button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: MenuScreen(data: GameData.fresh())),
    );
    await tester.pump();
    expect(find.text('PLAY'), findsOneWidget);
  });
}
