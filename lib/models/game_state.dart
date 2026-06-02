import 'racer.dart';
import '../utils/constants.dart';

/// Mutable game session shared across the three screens.
///
/// A single instance is created on the Home screen and passed by reference to
/// the Race and Result screens. The Result screen mutates [money] via
/// [settleRace]; when control returns to Home it calls `setState` to redraw.
///
/// State is held here (plain object + `setState` in the widgets) rather than in
/// a state-management package, per the lab's requirement to use StatefulWidget.
class GameState {
  /// The player's current wallet.
  int money;

  /// Pending stakes for the upcoming race, keyed by racer id. Only positive
  /// stakes are stored; a racer with no entry has not been bet on.
  final Map<int, int> bets;

  /// Snapshot of the stakes placed on the most recently settled race, taken in
  /// [settleRace] before [clearBets]. Lets "Play Again" restore the prior bets.
  Map<int, int> lastBets = {};

  GameState({this.money = GameConfig.startingMoney}) : bets = {};

  /// Sum of all stakes currently placed.
  int get totalBet => bets.values.fold(0, (sum, stake) => sum + stake);

  /// True when at least one stake is placed and the player can afford it.
  bool get canStartRace => totalBet > 0 && totalBet <= money;

  /// Replace the stake on [racerId]. A stake of 0 (or less) clears the bet.
  void setBet(int racerId, int stake) {
    if (stake <= 0) {
      bets.remove(racerId);
    } else {
      bets[racerId] = stake;
    }
  }

  /// Clear all stakes (used when starting a fresh round).
  void clearBets() => bets.clear();

  /// True when there is a previous bet snapshot that the wallet can still cover.
  bool get canRepeatLastBets =>
      lastBets.isNotEmpty &&
      lastBets.values.fold(0, (a, b) => a + b) <= money;

  /// Restore the previous race's stakes into [bets]. Caller must guard with
  /// [canRepeatLastBets] — this trusts that the snapshot is affordable.
  void repeatLastBets() => bets
    ..clear()
    ..addAll(lastBets);

  /// Apply the outcome of a race to the wallet and return a breakdown.
  ///
  /// Accounting model: every stake is removed from the wallet, then the stake
  /// placed on the winner is paid back at [GameConfig.winMultiplier]x. Losing
  /// stakes return nothing.
  ///
  ///   newMoney = money - totalBet + (stakeOnWinner * winMultiplier)
  ///
  /// [finishOrder] ranks every racer id from 1st (index 0) to last and is
  /// carried into the outcome so the Result screen can show full standings.
  RaceOutcome settleRace(Racer winner, List<int> finishOrder) {
    final int staked = totalBet;
    final int winningStake = bets[winner.id] ?? 0;
    final int payout = winningStake * GameConfig.winMultiplier;
    final int net = payout - staked;

    money = money - staked + payout;

    final outcome = RaceOutcome(
      winner: winner,
      bets: Map<int, int>.from(bets),
      totalStaked: staked,
      payout: payout,
      netChange: net,
      moneyAfter: money,
      finishOrder: List<int>.from(finishOrder),
    );
    // Snapshot the stakes before clearing so "Play Again" can repeat them.
    lastBets = Map<int, int>.from(bets);
    clearBets();
    return outcome;
  }
}

/// Immutable snapshot of a finished race, consumed by the Result screen.
class RaceOutcome {
  final Racer winner;

  /// Stakes that were in play, keyed by racer id.
  final Map<int, int> bets;

  /// Total amount the player staked across all racers.
  final int totalStaked;

  /// Amount returned to the wallet (winning stake x multiplier).
  final int payout;

  /// payout - totalStaked. Positive = profit, negative = loss.
  final int netChange;

  /// Wallet value after the race was settled.
  final int moneyAfter;

  /// Racer ids ranked from 1st (index 0) to last, for the standings list.
  final List<int> finishOrder;

  const RaceOutcome({
    required this.winner,
    required this.bets,
    required this.totalStaked,
    required this.payout,
    required this.netChange,
    required this.moneyAfter,
    required this.finishOrder,
  });

  /// True when the player placed a (winning) stake on [winner].
  bool get didWin => (bets[winner.id] ?? 0) > 0;
}
