import 'package:flutter_test/flutter_test.dart';
import 'package:mini_racing_game/models/game_state.dart';
import 'package:mini_racing_game/utils/constants.dart';

void main() {
  group('GameState betting rules', () {
    test('starts with the configured wallet and no bets', () {
      final game = GameState();
      expect(game.money, GameConfig.startingMoney);
      expect(game.totalBet, 0);
      expect(game.canStartRace, isFalse);
    });

    test('setBet stores positive stakes and clears on zero', () {
      final game = GameState();
      game.setBet(0, 30);
      expect(game.bets[0], 30);
      expect(game.totalBet, 30);

      game.setBet(0, 0); // clears
      expect(game.bets.containsKey(0), isFalse);
      expect(game.totalBet, 0);
    });

    test('canStartRace requires a stake within the wallet', () {
      final game = GameState(money: 100);
      expect(game.canStartRace, isFalse); // no bet yet

      game.setBet(0, 100);
      expect(game.canStartRace, isTrue); // exactly affordable

      game.setBet(1, 1); // total 101 > 100
      expect(game.canStartRace, isFalse);
    });
  });

  group('GameState.settleRace (3x payout)', () {
    test('winning bet pays the stake back at 3x', () {
      final game = GameState(money: 100);
      game.setBet(0, 20); // bet 20 on racer 0

      final winner = GameConfig.racers[0];
      final outcome = game.settleRace(winner, [0, 1, 2]);

      // money = 100 - 20 + (20 * 3) = 140
      expect(game.money, 140);
      expect(outcome.payout, 60);
      expect(outcome.netChange, 40);
      expect(outcome.didWin, isTrue);
      expect(outcome.moneyAfter, 140);
      expect(game.bets, isEmpty); // bets cleared after settling
    });

    test('losing bet forfeits the stake', () {
      final game = GameState(money: 100);
      game.setBet(0, 20); // bet on racer 0 ...

      final winner = GameConfig.racers[1]; // ... but racer 1 wins
      final outcome = game.settleRace(winner, [1, 0, 2]);

      // money = 100 - 20 + 0 = 80
      expect(game.money, 80);
      expect(outcome.payout, 0);
      expect(outcome.netChange, -20);
      expect(outcome.didWin, isFalse);
    });

    test('bets on multiple racers settle only the winner', () {
      final game = GameState(money: 100);
      game.setBet(0, 10);
      game.setBet(1, 30);
      game.setBet(2, 20); // total staked = 60

      final outcome =
          game.settleRace(GameConfig.racers[1], [1, 2, 0]); // racer 1 wins

      // money = 100 - 60 + (30 * 3) = 130
      expect(game.money, 130);
      expect(outcome.totalStaked, 60);
      expect(outcome.payout, 90);
      expect(outcome.netChange, 30);
      expect(outcome.didWin, isTrue);
    });
  });

  group('GameState finishing order & repeat-last-bets', () {
    test('settleRace preserves the full finishing order in the outcome', () {
      final game = GameState(money: 100);
      game.setBet(2, 10);

      final outcome = game.settleRace(GameConfig.racers[2], [2, 0, 1]);
      expect(outcome.finishOrder, [2, 0, 1]);
    });

    test('repeatLastBets restores the previous stakes after settling', () {
      final game = GameState(money: 100);
      game.setBet(0, 10);
      game.setBet(1, 20);

      game.settleRace(GameConfig.racers[1], [1, 0, 2]);
      expect(game.bets, isEmpty); // cleared after settling

      expect(game.canRepeatLastBets, isTrue);
      game.repeatLastBets();
      expect(game.bets, {0: 10, 1: 20});
    });

    test('canRepeatLastBets is false when the snapshot exceeds the wallet', () {
      final game = GameState(money: 100);
      game.setBet(0, 60); // bet on a loser, lose it

      game.settleRace(GameConfig.racers[1], [1, 0, 2]);
      // wallet now 40, but the snapshot was 60 → cannot repeat.
      expect(game.money, 40);
      expect(game.lastBets, {0: 60});
      expect(game.canRepeatLastBets, isFalse);
    });
  });
}
