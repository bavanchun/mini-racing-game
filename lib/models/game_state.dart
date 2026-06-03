import 'racer.dart';
import '../utils/constants.dart';

/// Session game có thể thay đổi được chia sẻ qua ba màn hình.
///
/// Một instance đơn được tạo trên màn hình Home và truyền bằng tham chiếu đến
/// màn hình Race và Result. Màn hình Result thay đổi [money] qua
/// [settleRace]; khi điều khiển trả về Home nó gọi `setState` để vẽ lại.
///
/// State được giữ ở đây (đối tượng thường + `setState` trong widgets) thay vì trong
/// package state-management, theo yêu cầu của lab là dùng StatefulWidget.
class GameState {
  /// Ví hiện tại của người chơi.
  int money;

  /// Các cược đang chờ cho cuộc đua sắp tới, được key theo id tay đua. Chỉ các
  /// cược dương được lưu; tay đua không có entry nghĩa là không được đặt cược.
  final Map<int, int> bets;

  /// Snapshot của các cược được đặt cho cuộc đua gần nhất đã giải quyết, được lấy trong
  /// [settleRace] trước [clearBets]. Cho phép "Play Again" khôi phục các cược trước.
  Map<int, int> lastBets = {};

  GameState({this.money = GameConfig.startingMoney}) : bets = {};

  /// Tổng của tất cả các cược hiện đang được đặt.
  int get totalBet => bets.values.fold(0, (sum, stake) => sum + stake);

  /// True khi ít nhất một cược được đặt và người chơi có thể chi trả.
  bool get canStartRace => totalBet > 0 && totalBet <= money;

  /// Thay thế cược trên [racerId]. Cược 0 (hoặc ít hơn) sẽ xóa cược.
  void setBet(int racerId, int stake) {
    if (stake <= 0) {
      bets.remove(racerId);
    } else {
      bets[racerId] = stake;
    }
  }

  /// Xóa tất cả các cược (dùng khi bắt đầu vòng mới).
  void clearBets() => bets.clear();

  /// True khi có snapshot cược trước đó mà ví vẫn có thể chi trả.
  bool get canRepeatLastBets =>
      lastBets.isNotEmpty &&
      lastBets.values.fold(0, (a, b) => a + b) <= money;

  /// Khôi phục các cược của cuộc đua trước vào [bets]. Caller phải guard với
  /// [canRepeatLastBets] — điều này tin rằng snapshot có thể chi trả được.
  void repeatLastBets() => bets
    ..clear()
    ..addAll(lastBets);

  /// Áp dụng kết quả của cuộc đua vào ví và trả về phân tích chi tiết.
  ///
  /// Mô hình kế toán: mọi cược được loại bỏ khỏi ví, sau đó cược
  /// đặt trên người thắng được trả lại với tỷ lệ [GameConfig.winMultiplier]x. Các
  /// cược thua không trả lại gì.
  ///
  ///   newMoney = money - totalBet + (stakeOnWinner * winMultiplier)
  ///
  /// [finishOrder] xếp hạng mọi id tay đua từ thứ nhất (index 0) đến cuối cùng và được
  /// đưa vào outcome để màn hình Result có thể hiển thị bảng xếp hạng đầy đủ.
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
    // Snapshot các cược trước khi xóa để "Play Again" có thể lặp lại chúng.
    lastBets = Map<int, int>.from(bets);
    clearBets();
    return outcome;
  }
}

/// Snapshot bất biến của một cuộc đua đã kết thúc, được dùng bởi màn hình Result.
class RaceOutcome {
  final Racer winner;

  /// Các cược đang trong cuộc chơi, được key theo id tay đua.
  final Map<int, int> bets;

  /// Tổng số tiền người chơi đặt cược trên tất cả tay đua.
  final int totalStaked;

  /// Số tiền trả lại vào ví (cược thắng x hệ số).
  final int payout;

  /// payout - totalStaked. Dương = lợi nhuận, âm = thua lỗ.
  final int netChange;

  /// Giá trị ví sau khi cuộc đua được giải quyết.
  final int moneyAfter;

  /// Ids tay đua được xếp hạng từ thứ nhất (index 0) đến cuối cùng, cho danh sách xếp hạng.
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

  /// True khi người chơi đặt cược (thắng) trên [winner].
  bool get didWin => (bets[winner.id] ?? 0) > 0;
}
