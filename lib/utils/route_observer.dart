import 'package:flutter/widgets.dart';

/// Route observer toàn app để màn hình có thể refresh khi route được đẩy lên
/// trên nó pop back. Home đăng ký và rebuild trong `didPopNext()` — đây là
/// điều vẽ lại đáng tin cậy ví và bất kỳ cược lặp lại "Play Again" khi
/// màn hình Result pop back, vì `await Navigator.push` của Home hoàn thành sớm
/// (khi Race được *thay thế* bởi Result, trước khi lặp chạy).
final RouteObserver<PageRoute> appRouteObserver = RouteObserver<PageRoute>();
