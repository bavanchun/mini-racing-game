// Các helper định dạng tiền được chia sẻ qua các màn hình để tiền tệ hiển thị
// nhất quán (nguồn sự thật duy nhất cho tiền tố `$` và quy tắc dấu).

/// Định dạng số tiền ví/cược, ví dụ `formatMoney(50)` → `"$50"`.
String formatMoney(int v) => '\$$v';

/// Định dạng thay đổi ròng với dấu rõ ràng và `$` sau nó, ví dụ
/// `formatSigned(30)` → `"+$30"`, `formatSigned(-50)` → `"-$50"`.
String formatSigned(int v) => v < 0 ? '-\$${-v}' : '+\$$v';
