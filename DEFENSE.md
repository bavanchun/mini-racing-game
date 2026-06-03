# 🐎 DEFENSE.md — Tài liệu bảo vệ Mini Racing Game (PRM393)

> Tài liệu này giúp **cả 4 thành viên** nắm **toàn bộ logic** của app: phần đó **nằm đâu trong code** và **chạy như thế nào**. Mỗi người phụ trách 1 mảng nhưng **ai cũng nên đọc hết** để mentor hỏi bất kỳ ai cũng trả lời được.
>
> Cách dùng: đọc phần **CHUNG** trước (ai cũng phải thuộc), rồi đọc kỹ phần mảng mình phụ trách, lướt qua 3 phần còn lại. Cuối file có mục **"Câu hỏi tủ"** tổng hợp.

---

## 0. CHUNG — Ai cũng phải thuộc

### 0.1. App này là gì?

Game **cá cược đua ngựa** (horse-racing betting). Người chơi có 1 ví tiền (bắt đầu **$100**), đặt cược lên 3 con ngựa, xem chúng đua với tốc độ ngẫu nhiên, rồi thắng/thua theo con về nhất.

Đây là project **UI + logic game thuần** — **không** dùng game engine, **không** vật lý/va chạm. Chuyển động ngựa là **"thanh trượt giả" (fake slider)** ghép từ `Container` + `AnimatedPositioned` (đây là **yêu cầu cốt lõi của lab**, nhớ kỹ).

### 0.2. Luật cá cược (học thuộc bảng này)

| Luật | Giá trị / Hành vi | Định nghĩa ở đâu |
|------|-------------------|------------------|
| Ví ban đầu | `$100` | `constants.dart:13` (`startingMoney`) |
| Điều kiện bắt đầu đua | Đặt ít nhất 1 cược, và tổng cược ≤ ví | `game_state.dart:30` (`canStartRace`) |
| Chặn cược quá tay | Tổng cược **không vượt** số tiền trong ví | `home_betting_screen.dart` (`_headroom`) |
| Tỉ lệ thắng | Cược trúng con về nhất được trả lại **×3** | `constants.dart:17` (`winMultiplier`) |
| Công thức ví mới | `ví − tổng_cược + (cược_lên_con_thắng × 3)` | `game_state.dart:71` (`settleRace`) |
| Hết tiền | Hiện màn "out of money" + nút Reset về $100 | `home_betting_screen.dart` (`_buildBrokeState`) |

### 0.3. Kiến trúc tổng thể

```
main.dart  (tạo GameState DUY NHẤT, nạp ví đã lưu)
   │  truyền cùng 1 instance GameState xuống mọi màn
   ▼
HomeBettingScreen  ──Navigator.push──▶  RaceScreen  ──pushReplacement──▶  ResultScreen
        ▲                                                                      │
        └──────────────── popUntil(isFirst) "Play Again / Back to Home" ◀──────┘
```

**4 tầng (layer) code:**

```
lib/
├── main.dart                  ← khởi tạo app + GameState gốc      [TV2/TV3]
├── models/                    ← DỮ LIỆU + LOGIC nghiệp vụ          [TV1]
│   ├── game_state.dart            ví, cược, settleRace (bộ não)
│   └── racer.dart                 mô tả 1 con ngựa (immutable)
├── screens/                   ← 3 MÀN HÌNH + điều hướng            [TV2]
│   ├── home_betting_screen.dart   đặt cược
│   ├── race_screen.dart           đua (Timer + ngẫu nhiên)
│   └── result_screen.dart         kết quả + payout
├── services/                  ← DỊCH VỤ ngoài (lưu trữ, âm thanh)  [TV3]
│   ├── wallet_storage.dart        SharedPreferences (lưu ví)
│   └── sound_service.dart         audioplayers (start/win/lose)
├── widgets/                   ← THÀNH PHẦN UI tái sử dụng          [TV4]
│   ├── race_track.dart            "fake slider" đường đua
│   ├── bet_row.dart               1 dòng đặt cược
│   ├── result_bet_table.dart      bảng kết quả cược
│   └── app_background.dart        nền gradient + GradientScaffold
├── theme/app_theme.dart       ← màu sắc, ThemeData                 [TV4]
└── utils/                     ← hằng số + helper                   [TV1/TV4]
    ├── constants.dart             GameConfig, RaceConfig, roster
    ├── formatting.dart            formatMoney / formatSigned
    └── route_observer.dart        RouteObserver toàn app           [TV2]
```

### 0.4. ⭐ Câu hỏi LỚN NHẤT: vì sao không dùng Provider / Bloc / Riverpod?

> **Trả lời:** Yêu cầu của lab là dùng **`StatefulWidget` + `setState`**. Nên app giữ state trong **một object `GameState` thường**, tạo ở `main.dart` và **truyền cùng một tham chiếu (by reference)** xuống cả 3 màn. Khi dữ liệu đổi, widget gọi `setState(() {})` để vẽ lại. Vì là cùng 1 object nên màn nào sửa `money`/`bets` thì màn khác đọc ra giá trị mới ngay. → Đơn giản, đúng yêu cầu, không cần package ngoài.

### 0.5. Thư viện ngoài (dependencies)

| Package | Dùng làm gì | File |
|---------|-------------|------|
| `shared_preferences: ^2.3.2` | Lưu ví giữa các lần mở app (tính năng bonus) | `wallet_storage.dart` |
| `audioplayers: ^6.1.0` | Phát tiếng start/win/lose (bonus) | `sound_service.dart` |
| `cupertino_icons` | Icon mặc định | — |

---

# 👤 THÀNH VIÊN 1 — Models & Logic nghiệp vụ (bộ não)

**File phụ trách:** `lib/models/game_state.dart`, `lib/models/racer.dart`, `lib/utils/constants.dart`

> Đây là phần **logic thuần Dart, không có UI**. Mentor hỏi về *"tiền được tính thế nào"*, *"khi nào được đua"*, *"cấu trúc dữ liệu"* → là phần này. **Quan trọng nhất để bảo vệ.**

## 1.1. `GameState` — trạng thái game dùng chung (`game_state.dart`)

### Nằm đâu
`lib/models/game_state.dart:12` — class `GameState`.

### Logic

Đây là object **mutable** (có thể thay đổi) giữ toàn bộ trạng thái 1 phiên chơi:

```dart
class GameState {
  int money;                       // ví hiện tại
  final Map<int, int> bets;        // cược đang đặt: { racerId: stake }
  Map<int, int> lastBets = {};     // snapshot cược ván trước (cho "Play Again")

  GameState({this.money = GameConfig.startingMoney}) : bets = {};
```

- `money`: số tiền trong ví.
- `bets`: **Map** với key = id ngựa (0,1,2), value = số tiền cược. Ngựa nào không có trong map = chưa cược. Chỉ lưu cược **dương**.
- `lastBets`: lưu lại cược ván vừa rồi để nút **"Play Again"** đặt lại y hệt.

### Các getter logic (tính toán phái sinh)

```dart
int get totalBet => bets.values.fold(0, (sum, stake) => sum + stake);   // line 27
bool get canStartRace => totalBet > 0 && totalBet <= money;             // line 30
```

- **`totalBet`**: cộng tất cả giá trị trong map = tổng tiền đang cược. `fold(0, ...)` là cách Dart cộng dồn 1 list (bắt đầu từ 0).
- **`canStartRace`**: chỉ cho đua khi **có cược** (`> 0`) **và** đủ tiền (`<= money`). Đây là điều kiện bật/tắt nút "Start Race".

### Đặt / xoá cược

```dart
void setBet(int racerId, int stake) {        // line 33
  if (stake <= 0) {
    bets.remove(racerId);   // cược 0 = bỏ cược con đó
  } else {
    bets[racerId] = stake;
  }
}
void clearBets() => bets.clear();             // line 42
```

### ⭐ `settleRace` — hàm TÍNH TIỀN quan trọng nhất

### Nằm đâu
`game_state.dart:65`.

```dart
RaceOutcome settleRace(Racer winner, List<int> finishOrder) {
  final int staked = totalBet;                    // tổng đã cược
  final int winningStake = bets[winner.id] ?? 0;  // cược lên con THẮNG (0 nếu ko cược)
  final int payout = winningStake * GameConfig.winMultiplier;  // trả lại = cược×3
  final int net = payout - staked;                // lời/lỗ ròng

  money = money - staked + payout;                // ⭐ cập nhật ví

  final outcome = RaceOutcome( ... );             // gói kết quả lại (immutable)
  lastBets = Map<int, int>.from(bets);            // snapshot để Play Again
  clearBets();                                    // xoá cược, chuẩn bị ván mới
  return outcome;
}
```

**Mô hình kế toán (giải thích cho mentor):** *Mọi* tiền cược bị trừ khỏi ví trước, sau đó tiền cược đặt lên **con thắng** được trả lại ×3. Cược lên con thua → mất trắng.

> **Công thức:** `ví_mới = ví − tổng_cược + (cược_lên_con_thắng × 3)`

**Ví dụ:** ví $100, cược $30 lên Thunder + $20 lên Blaze. Thunder thắng.
`100 − 50 + (30×3=90) = $140`. Net = `90 − 50 = +$40`.

## 1.2. `RaceOutcome` — kết quả 1 ván (immutable)

### Nằm đâu
`game_state.dart:90`.

Là **snapshot bất biến** (`final` hết, constructor `const`) của 1 ván đã xong, để màn Result hiển thị. Khác với `GameState` (mutable, sống cả phiên), `RaceOutcome` chỉ mô tả **1 ván** và không đổi nữa.

Chứa: `winner`, `bets` (bản sao), `totalStaked`, `payout`, `netChange`, `moneyAfter`, `finishOrder` (thứ tự về đích).

```dart
bool get didWin => (bets[winner.id] ?? 0) > 0;   // line 122 — người chơi có cược con thắng không?
```

## 1.3. `Racer` — mô tả 1 con ngựa (`racer.dart`)

### Nằm đâu
`lib/models/racer.dart:7`.

**Immutable** (`const` constructor). Chỉ mô tả *"con ngựa là ai"*: `id` (0/1/2 — dùng làm key cho cược & kết quả), `name`, `emoji` (🐎), `color`.

> **Vì sao tách `Racer` ra immutable?** Vị trí ngựa lúc đua (`progress`) được theo dõi **riêng** ở `RaceScreen`, nên cùng 1 danh sách ngựa được tái dùng mọi ván mà không cần tạo lại. "Ai đua" (cố định) tách khỏi "đang ở đâu" (thay đổi).

## 1.4. `GameConfig` & roster (`constants.dart`)

### Nằm đâu
`lib/utils/constants.dart:9`.

```dart
static const int startingMoney = 100;   // ví đầu
static const int winMultiplier = 3;     // tỉ lệ trả thưởng
static const List<Racer> racers = [     // 3 con ngựa cố định
  Racer(id: 0, name: 'Thunder', emoji: '🐎', color: Color(0xFFE53935)), // đỏ
  Racer(id: 1, name: 'Blaze',   emoji: '🐎', color: Color(0xFF1E88E5)), // xanh dương
  Racer(id: 2, name: 'Shadow',  emoji: '🐎', color: Color(0xFF43A047)), // xanh lá
];
```

> Mọi luật chơi gom 1 chỗ → dễ chỉnh, mọi màn dùng chung đúng 1 roster.

## 1.5. ❓ Mentor có thể hỏi (TV1)

- **"Tiền thắng tính sao?"** → công thức `ví − tổng_cược + cược_con_thắng×3`, ở `settleRace` (`game_state.dart:71`). Cho ví dụ số.
- **"Vì sao dùng `Map<int,int>` cho cược?"** → key = id ngựa, value = tiền cược; tra cứu O(1), ngựa không cược thì không có key, gọn hơn list.
- **"`canStartRace` để làm gì?"** → vừa chặn đua khi chưa cược, vừa chặn cược quá ví; dùng để enable/disable nút Start.
- **"`lastBets` là gì?"** → snapshot cược ván trước, chụp **trước khi** `clearBets`, để "Play Again" đặt lại y hệt.
- **"Khác nhau `GameState` vs `RaceOutcome`?"** → `GameState` mutable, sống cả phiên; `RaceOutcome` immutable, là kết quả của đúng 1 ván.

---

# 👤 THÀNH VIÊN 2 — Screens & Navigation (luồng màn hình)

**File phụ trách:** `lib/main.dart`, `lib/screens/home_betting_screen.dart`, `lib/screens/race_screen.dart`, `lib/screens/result_screen.dart`, `lib/utils/route_observer.dart`

> Phần **khó & nhiều câu hỏi nhất**: vòng đời `StatefulWidget`, `Navigator`, `Timer`, và đặc biệt **`RouteAware`/`didPopNext`**. Đọc thật kỹ.

## 2.1. `main.dart` — gốc app

### Nằm đâu
`lib/main.dart:10` (`main`), `:31` (`MiniRacingGameApp`).

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();   // bắt buộc trước khi dùng SharedPreferences trước runApp
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);  // vẽ tràn nền sau nav bar
  final savedMoney = await WalletStorage.loadMoney();  // nạp ví đã lưu
  runApp(MiniRacingGameApp(initialMoney: savedMoney));
}
```

```dart
class _MiniRacingGameAppState extends State<MiniRacingGameApp> {
  late final GameState _game = GameState(money: widget.initialMoney);  // line 42 — TẠO 1 LẦN
  // ...
  return MaterialApp(
    navigatorObservers: [appRouteObserver],   // đăng ký observer điều hướng
    home: HomeBettingScreen(game: _game),     // truyền GameState xuống
  );
}
```

> **Điểm cốt lõi:** `GameState` được tạo **một lần** ở gốc và truyền xuống. Giữ ở gốc giúp **ví sống xuyên suốt** vòng Home → Race → Result → Home.

## 2.2. `HomeBettingScreen` — đặt cược

### Nằm đâu
`lib/screens/home_betting_screen.dart:24`.

### Logic đặt cược (clamp chống cược quá tay)

```dart
void _increment(int racerId) {                 // line 74
  final headroom = _headroom();                 // tiền còn được cược = money − totalBet
  if (headroom <= 0) { _showOverBetSnackBar(); return; }   // chạm trần → cảnh báo
  final added = headroom < _step ? headroom : _step;       // không vượt trần
  setState(() {
    widget.game.setBet(racerId, _stakeFor(racerId) + added);
  });
}
int _headroom() => widget.game.money - widget.game.totalBet;   // line 111
```

> `_increment`, `_quickBet` (+50), `_decrement` (−, clamp ≥0) đều gọi qua `_headroom()` để **tổng cược không bao giờ vượt ví**. Validation gom ở màn (screen), widget con chỉ gọi callback.

### ⭐ `_startRace` + vì sao cần RouteAware

```dart
Future<void> _startRace() async {              // line 127
  SoundService.playStart();                     // tiếng còi (fire-and-forget)
  await Navigator.push(context,
    MaterialPageRoute(builder: (_) => RaceScreen(game: widget.game)));
  if (mounted) setState(() {});                 // refresh ví khi quay về
  WalletStorage.saveMoney(widget.game.money);   // lưu ví
}
```

**Vấn đề tinh tế (mentor rất hay soi):** `RaceScreen` dùng `pushReplacement` để **thay** chính nó bằng `ResultScreen`. Khi đó cái `await Navigator.push` ở trên **resolve SỚM** (ngay lúc Race bị thay), *trước khi* người chơi bấm Play Again ở Result. → Nếu chỉ dựa vào `await`, ví/cược lặp lại có thể vẽ không kịp.

**Giải pháp:** dùng `RouteAware` + `RouteObserver`:

```dart
class _HomeBettingScreenState extends State<HomeBettingScreen> with RouteAware {
  @override
  void didChangeDependencies() {                // line 43
    super.didChangeDependencies();
    appRouteObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }
  @override
  void didPopNext() => setState(() {});         // line 59 — màn trên POP về Home → vẽ lại
  @override
  void dispose() { appRouteObserver.unsubscribe(this); super.dispose(); }
}
```

> **`didPopNext()`** được gọi khi 1 màn nằm **trên** Home bị pop ra (Result `popUntil` về Home). Lúc đó Home **chắc chắn** vẽ lại → ví mới + cược "Play Again" hiện đúng, **bất kể** `await` đã resolve lúc nào. `route_observer.dart` chỉ là 1 dòng tạo `RouteObserver<PageRoute>` dùng chung toàn app.

## 2.3. ⭐ `RaceScreen` — logic đua ngựa

### Nằm đâu
`lib/screens/race_screen.dart:18`.

### Cơ chế đua bằng `Timer.periodic` + random

```dart
late List<double> _progress;   // vị trí mỗi ngựa, 0.0 → 1.0
bool _finished = false;        // guard: chỉ kết thúc 1 lần
Timer? _timer;
final Random _rng = Random();

@override
void initState() {
  super.initState();
  _progress = List<double>.filled(GameConfig.racers.length, 0.0);  // xuất phát = 0
  Future.delayed(RaceConfig.countdown, _startRace);   // đếm ngược ~0.6s
}

void _onTick(Timer _) {                          // line 70 — chạy mỗi 80ms
  if (_finished) return;
  setState(() {
    for (int i = 0; i < _progress.length; i++) {
      final step = RaceConfig.minStep + _rng.nextDouble() *
                   (RaceConfig.maxStep - RaceConfig.minStep);   // bước NGẪU NHIÊN
      _progress[i] = (_progress[i] + step).clamp(0.0, 1.0);
    }
  });
  _checkForWinner();
}
```

> **Tốc độ ngẫu nhiên** chính là `step` mỗi tick (mỗi ngựa rút 1 số khác nhau trong khoảng `minStep..maxStep`). Mỗi tick 80ms, trung bình ~83 tick ≈ đua ~6.6 giây. `clamp(0,1)` để không vượt vạch đích.

### Tìm người thắng + chống đếm 2 lần

```dart
void _checkForWinner() {                         // line 88
  if (_finished) return;
  final finishers = <int>[];
  for (int i = 0; i < _progress.length; i++) {
    if (_progress[i] >= 1.0) finishers.add(i);   // ai đã chạm đích tick này
  }
  if (finishers.isEmpty) return;
  finishers.sort((a, b) {                         // tie-break:
    final cmp = _progress[b].compareTo(_progress[a]); // progress cao hơn thắng
    return cmp != 0 ? cmp : a.compareTo(b);           // bằng nhau → id nhỏ thắng
  });
  _onRaceFinished(finishers.first);
}
```

> **Vì sao kiểm tra sau khi MỌI ngựa đã chạy trong 1 tick?** Để xử lý trường hợp **nhiều ngựa chạm đích cùng tick** một cách công bằng, thay vì dừng con đầu tiên giữa chừng. **Luật hoà:** progress cao hơn thắng; nếu bằng → id nhỏ thắng (deterministic).

### Kết thúc đua

```dart
Future<void> _onRaceFinished(int winnerId) async {   // line 116
  _finished = true;                 // ⭐ guard chống chạy 2 lần
  _timer?.cancel(); _timer = null;
  setState(() => _winnerId = winnerId);     // highlight con thắng
  final order = List<int>.generate(...)..sort(...);   // thứ tự về đích đầy đủ
  final outcome = widget.game.settleRace(GameConfig.racers[winnerId], order);  // TÍNH TIỀN
  await Future.delayed(RaceConfig.photoFinishDelay);  // dừng ~1.1s xem "photo finish"
  if (!mounted) return;             // ⭐ luôn check mounted sau await
  Navigator.pushReplacement(context,    // THAY Race bằng Result (ko quay lại đua được)
    MaterialPageRoute(builder: (_) => ResultScreen(game: widget.game, outcome: outcome)));
}

@override
void dispose() { _timer?.cancel(); super.dispose(); }   // line 150 — huỷ timer khi out
```

> **`_finished` guard:** vì 2 ngựa có thể chạm đích cùng tick, hoặc timer fire thêm giữa `cancel()` và dispose → guard đảm bảo `settleRace` + điều hướng chạy **đúng 1 lần**. **`mounted` check** sau `await`: tránh dùng `context` của widget đã bị huỷ.

## 2.4. `ResultScreen` — kết quả + 2 nút

### Nằm đâu
`lib/screens/result_screen.dart:18`.

- Là `StatefulWidget` **chỉ để** phát tiếng thắng/thua **1 lần** trong `initState` (`:34`).
- Nhận `RaceOutcome` **đã settle sẵn** từ Race → màn này **không bao giờ** gọi `settleRace` (tránh tính tiền 2 lần).

```dart
void _playAgain(BuildContext context) {          // line 47
  if (widget.game.canRepeatLastBets) widget.game.repeatLastBets();  // đặt lại cược cũ nếu đủ tiền
  Navigator.popUntil(context, (route) => route.isFirst);            // về Home
}
void _backToHome(BuildContext context) {          // line 57
  Navigator.popUntil(context, (route) => route.isFirst);            // về Home, KHÔNG đặt lại cược
}
```

> **Khác biệt 2 nút:** *Play Again* khôi phục cược ván trước (nếu ví đủ); *Back to Home* về trang trắng. Cả hai dùng `popUntil(isFirst)` để **xoá sạch stack** về đúng màn Home gốc (vì Race đã bị `pushReplacement` nên stack chỉ còn Home + Result).

## 2.5. ❓ Mentor có thể hỏi (TV2)

- **"Ngựa di chuyển ngẫu nhiên thế nào?"** → `Timer.periodic` 80ms, mỗi tick cộng `step` random trong `minStep..maxStep` (`_onTick`).
- **"Vì sao có `_finished`?"** → chống `settleRace`/điều hướng chạy 2 lần khi nhiều ngựa về cùng tick. (`race_screen.dart:33,71,89,117`)
- **"`push` vs `pushReplacement` vs `popUntil` khác gì?"** → Home `push` Race (quay lại được); Race `pushReplacement` Result (không quay lại đua); Result `popUntil(isFirst)` xoá stack về Home.
- **"`didPopNext` là gì, vì sao cần?"** → callback của `RouteAware` khi màn trên pop về; cần vì `await` ở Home resolve sớm do `pushReplacement`. (Phần 2.2)
- **"Vì sao check `mounted`?"** → sau `await` widget có thể đã dispose, dùng `context` lúc đó sẽ lỗi.
- **"Vì sao huỷ timer trong `dispose`?"** → tránh callback chạy trên widget đã chết → memory leak / lỗi setState.

---

# 👤 THÀNH VIÊN 3 — Services & Persistence (lưu trữ + âm thanh)

**File phụ trách:** `lib/services/wallet_storage.dart`, `lib/services/sound_service.dart`, phần khởi tạo async trong `lib/main.dart`

> Phần về **`async/await`, lưu dữ liệu, xử lý lỗi mềm (fail-soft)**. Ít code nhưng nhiều khái niệm Flutter quan trọng.

## 3.1. `WalletStorage` — lưu ví bằng SharedPreferences

### Nằm đâu
`lib/services/wallet_storage.dart:9`.

```dart
class WalletStorage {
  WalletStorage._();                              // private constructor → không tạo instance
  static const String _moneyKey = 'wallet_money'; // key lưu trong storage

  static Future<int> loadMoney() async {          // line 15
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_moneyKey) ?? GameConfig.startingMoney;  // chưa có → $100
    } catch (_) {
      return GameConfig.startingMoney;            // lỗi storage → vẫn chơi được với $100
    }
  }

  static Future<void> saveMoney(int money) async {  // line 25
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_moneyKey, money);
    } catch (_) { /* nuốt lỗi: lưu chỉ là bonus, không chặn game */ }
  }
}
```

> **Giải thích:**
> - **SharedPreferences** = bộ nhớ key-value nhỏ trên máy (lưu kiểu số/chuỗi đơn giản), tồn tại qua các lần mở app.
> - Tất cả method là **`static`** + constructor private `_()` → dùng như tiện ích `WalletStorage.loadMoney()`, không cần `new`.
> - **Fail-soft:** mọi thứ bọc `try/catch`. Nếu storage lỗi, game vẫn chạy, chỉ là không nhớ tiền giữa các phiên. Persistence là **bonus**, không được làm crash game.

### Ai gọi?
- `loadMoney()`: gọi trong `main()` **trước `runApp`** để khôi phục ví.
- `saveMoney()`: gọi sau mỗi ván (`_startRace` ở Home) và khi Reset ví.

## 3.2. ⭐ Vì sao `WidgetsFlutterBinding.ensureInitialized()`?

### Nằm đâu
`lib/main.dart:12`.

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();   // ⭐
  // ...
  final savedMoney = await WalletStorage.loadMoney();  // dùng plugin TRƯỚC runApp
  runApp(...);
}
```

> **Trả lời:** Mình gọi plugin (`SharedPreferences`) **trước `runApp`**. Plugin giao tiếp với native qua "platform channels", mà channel chỉ sẵn sàng sau khi binding của Flutter được khởi tạo. Nếu không gọi dòng này, `await SharedPreferences.getInstance()` sẽ lỗi. Đây là lý do `main` phải `async`.

## 3.3. `SoundService` — phát âm thanh

### Nằm đâu
`lib/services/sound_service.dart:7`.

```dart
class SoundService {
  SoundService._();
  static final AudioPlayer _player = AudioPlayer();   // 1 player dùng chung

  static Future<void> _play(String asset) async {
    try {
      await _player.stop();                  // dừng tiếng cũ trước
      await _player.play(AssetSource(asset)); // phát từ assets/sounds/
    } catch (_) { /* nuốt lỗi: vd trình duyệt chặn autoplay */ }
  }

  static Future<void> playStart() => _play('sounds/start.wav');
  static Future<void> playWin()   => _play('sounds/win.wav');
  static Future<void> playLose()  => _play('sounds/lose.wav');
}
```

> File WAV nằm trong `assets/sounds/` (khai báo ở `pubspec.yaml`). Playback **best-effort**: lỗi (vd trình duyệt chặn tự phát) bị nuốt để **không bao giờ làm hỏng game**.

### Ai gọi?
- `playStart()`: lúc bấm Start (Home `_startRace`).
- `playWin()` / `playLose()`: trong `ResultScreen.initState`, tuỳ `outcome.didWin`.

## 3.4. ❓ Mentor có thể hỏi (TV3)

- **"SharedPreferences là gì, lưu được gì?"** → key-value store trên máy, lưu kiểu đơn giản (int/string/bool); ở đây lưu `wallet_money`.
- **"Vì sao `main` phải `async` + `ensureInitialized`?"** → vì gọi plugin trước `runApp`; binding phải sẵn sàng để platform channel hoạt động (Phần 3.2).
- **"`async/await` nghĩa là gì?"** → `Future` = giá trị sẽ có trong tương lai; `await` chờ nó xong mà không block UI; hàm chứa `await` phải đánh dấu `async`.
- **"Vì sao bọc `try/catch` rồi nuốt lỗi?"** → lưu trữ & âm thanh là bonus; thà mất tính năng phụ còn hơn crash game (fail-soft).
- **"Vì sao method `static` + constructor `_()`?"** → đây là lớp tiện ích, không cần state riêng; gọi trực tiếp `WalletStorage.saveMoney(...)`.

---

# 👤 THÀNH VIÊN 4 — Widgets, Theme & Rendering (giao diện)

**File phụ trách:** `lib/widgets/race_track.dart`, `lib/widgets/bet_row.dart`, `lib/widgets/result_bet_table.dart`, `lib/widgets/app_background.dart`, `lib/theme/app_theme.dart`, `lib/utils/formatting.dart`

> Phần **UI tái sử dụng + "fake slider"** (yêu cầu cốt lõi của lab). Mentor hỏi *"sao ngựa chạy được"*, *"vẽ vạch đích thế nào"* → là phần này.

## 4.1. ⭐⭐ `RaceTrack` — "FAKE SLIDER" (quan trọng nhất TV4)

### Nằm đâu
`lib/widgets/race_track.dart:14`.

> **Yêu cầu lab:** chuyển động ngựa **KHÔNG dùng widget `Slider`**. Thay vào đó tự ghép "thanh trượt giả" bằng `Stack` + `AnimatedPositioned`. Con ngựa chính là "thumb (núm trượt) giả".

### Logic tính vị trí ngựa

```dart
LayoutBuilder(builder: (context, constraints) {
  final laneWidth = constraints.maxWidth;
  // Quãng đường ngựa được chạy: trừ padding trái, vạch đích, và bề ngang ngựa
  final travelWidth = laneWidth - _sidePadding - _finishWidth - _horseSize;  // line 90
  final horseLeft = _sidePadding + (progress.clamp(0.0, 1.0) * travelWidth); // line 92
  // progress 0.0 → ngựa ở vạch xuất phát; 1.0 → ngựa đúng ngay vạch đích
```

> **Cốt lõi:** `progress` (0→1) do `RaceScreen` truyền vào được **quy đổi thành toạ độ pixel** `horseLeft`. Đó là toàn bộ "fake slider": không có Slider, chỉ là phép nhân `progress × quãng_đường`.

### Con ngựa di chuyển mượt bằng `AnimatedPositioned`

```dart
AnimatedPositioned(                  // line 155 — chính là "thumb"
  duration: animationDuration,       // = RaceConfig.tick (80ms)
  curve: Curves.linear,
  left: horseLeft,                   // toạ độ tính ở trên
  top: (_laneHeight - _horseSize) / 2,
  width: _horseSize, height: _horseSize,
  child: Semantics(label: racer.name,
    child: Center(child: Text(racer.emoji, style: TextStyle(fontSize: 28)))),
),
```

> **Vì sao mượt?** Mỗi tick `progress` nhảy 1 nấc, nhưng `AnimatedPositioned` **nội suy** vị trí trong đúng 80ms → ngựa **lướt** thay vì giật cục. `duration` khớp đúng nhịp tick nên chuyển động liền mạch.

### Vẽ tay (CustomPainter)

- **`_DirtStripePainter`** (`:186`): vẽ vân ngang nền đất.
- **`_CheckeredPainter`** (`:202`): vẽ cột caro đen-trắng vạch đích, dùng `(row + col) % 2 == 0` để xen kẽ ô đen/trắng.
- Cả hai `shouldRepaint => false` (hình tĩnh, không cần vẽ lại).

## 4.2. `BetRow` — 1 dòng đặt cược (`bet_row.dart`)

### Nằm đâu
`lib/widgets/bet_row.dart:15`.

- Hiển thị: emoji + tên ngựa (màu riêng) + tiền cược + nút `−` / `+` / `+50`.
- **`StatelessWidget`** — không tự giữ state. Mọi thao tác bắn callback (`onDecrement`/`onIncrement`/`onQuickBet`) lên **màn cha**; cha mới quyết định hợp lệ rồi `setState`.

> **Vì sao đẩy logic lên cha?** Giữ toàn bộ validation (clamp, chống cược quá ví) ở **một chỗ** (screen), tránh lặp logic ở từng row → đúng nguyên tắc DRY. Nút `−` tự mờ khi `stake == 0` (`onTap: stake > 0 ? onDecrement : null`).

## 4.3. `ResultBetTable` — bảng kết quả cược (`result_bet_table.dart`)

### Nằm đâu
`lib/widgets/result_bet_table.dart:13`.

- Duyệt `outcome.bets`, mỗi cược 1 dòng: ngựa | tiền cược | **WIN/LOSE**.
- `isWin = racer.id == winner.id` → dòng thắng nền xanh, thua nền đỏ.
- Có guard `if (entry.key < 0 || entry.key >= racers.length) return SizedBox.shrink()` chống id sai.

## 4.4. `AppBackground` + `GradientScaffold` (`app_background.dart`)

### Nằm đâu
`lib/widgets/app_background.dart:8` và `:35`.

- `AppBackground`: nền gradient dọc (trời → cỏ → kem) cho mọi màn.
- `GradientScaffold`: `Scaffold` với `backgroundColor: transparent` để thấy gradient → mọi màn dùng nó cho đồng bộ, gọn code.

## 4.5. `AppTheme` + `formatting.dart`

### Nằm đâu
`lib/theme/app_theme.dart:19`, `lib/utils/formatting.dart`.

- `AppTheme.light`: `ThemeData` dùng Material 3, `ColorScheme.fromSeed`, style nút/card chung. `AppColors` gom mã màu.
- `formatting.dart`: 1 nguồn duy nhất cho định dạng tiền:
  ```dart
  String formatMoney(int v) => '\$$v';                              // 50 → "$50"
  String formatSigned(int v) => v < 0 ? '-\$${-v}' : '+\$$v';       // -50 → "-$50", 30 → "+$30"
  ```
  > `formatSigned` đặt dấu trước `$` cho đúng (sửa lỗi hiển thị "$-50").

## 4.6. ❓ Mentor có thể hỏi (TV4)

- **⭐ "Ngựa chạy bằng gì? Có dùng Slider không?"** → KHÔNG. "Fake slider": `progress` (0→1) × quãng đường = `horseLeft`, đặt vào `AnimatedPositioned` trong `Stack`. (`race_track.dart:90,155`)
- **"Sao ngựa lướt mượt mà không giật?"** → `AnimatedPositioned` nội suy vị trí trong `duration` = 80ms = đúng nhịp tick.
- **"Vạch đích caro vẽ sao?"** → `CustomPainter` `_CheckeredPainter`, xen kẽ ô bằng `(row+col)%2`.
- **"Vì sao `BetRow` không tự giữ state?"** → StatelessWidget, đẩy callback lên màn cha để gom validation 1 chỗ (DRY).
- **"`StatelessWidget` vs `StatefulWidget` khác gì?"** → Stateless không có state nội bộ, vẽ theo input; Stateful có `State` thay đổi theo thời gian + `setState`.

---

# 🎯 CÂU HỎI TỦ (tổng hợp — ai cũng nên thuộc)

1. **App quản lý state thế nào?** → 1 `GameState` tạo ở `main.dart`, truyền by-reference xuống 3 màn, đổi thì `setState`. Không dùng Provider/Bloc vì lab yêu cầu StatefulWidget. *(0.4)*
2. **Tiền thắng/thua tính ra sao?** → `ví − tổng_cược + cược_con_thắng × 3`, ở `settleRace` (`game_state.dart:71`). *(TV1)*
3. **Ngựa di chuyển bằng cơ chế gì?** → `Timer.periodic` 80ms cộng bước random vào `progress`; UI quy đổi `progress` → pixel qua `AnimatedPositioned` ("fake slider", không dùng Slider). *(TV2 + TV4)*
4. **Làm sao chống tính tiền / kết thúc 2 lần?** → cờ `_finished` trong `RaceScreen`. *(TV2)*
5. **Điều hướng 3 màn ra sao?** → Home `push` Race → Race `pushReplacement` Result → Result `popUntil(isFirst)` về Home. *(TV2)*
6. **`didPopNext`/`RouteAware` để làm gì?** → refresh Home khi Result pop về, vì `await` resolve sớm do `pushReplacement`. *(TV2)*
7. **Ví được lưu thế nào?** → SharedPreferences trong `WalletStorage`, fail-soft; `main` `async` + `ensureInitialized` để dùng plugin trước `runApp`. *(TV3)*
8. **3 nguyên tắc thiết kế thấy ở đâu?** → DRY (validation gom ở screen, `formatMoney` 1 chỗ), KISS (state object thường + setState), tách lớp models/screens/services/widgets.

---

# ▶️ Chạy app & test

```bash
cd mini-racing-game
flutter pub get          # cài dependencies
flutter run              # chạy app

flutter test             # chạy unit + widget test
```

**Test có sẵn:** `test/game_state_test.dart` (kiểm logic cược/payout — TV1), `test/widget_test.dart` (kiểm UI cơ bản).

---

## ❓ Câu hỏi còn bỏ ngỏ (cần nhóm tự quyết)

- Chưa gán **tên thật** 4 thành viên vào TV1–TV4 (đang để chung). Nếu cần, thay "THÀNH VIÊN 1/2/3/4" bằng tên cụ thể.
- Chưa rõ mentor có yêu cầu **demo trực tiếp** không — nếu có, mỗi người nên tự `flutter run` thử phần mình ít nhất 1 lần trước buổi bảo vệ.
