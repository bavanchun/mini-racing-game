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
      final outcome = game.settleRace(winner);

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
      final outcome = game.settleRace(winner);

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

      final outcome = game.settleRace(GameConfig.racers[1]); // racer 1 wins

      // money = 100 - 60 + (30 * 3) = 130
      expect(game.money, 130);
      expect(outcome.totalStaked, 60);
      expect(outcome.payout, 90);
      expect(outcome.netChange, 30);
      expect(outcome.didWin, isTrue);
    });
  });
}
