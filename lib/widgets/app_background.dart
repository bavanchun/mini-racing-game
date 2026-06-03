import 'package:flutter/material.dart';

/// Gradient dọc mềm "ngày đua" (trời → cỏ → kem) dùng phía sau mọi
/// màn hình để có backdrop nhất quán, bóng bẩy.
///
/// Bọc body của màn hình với cái này và giữ [Scaffold.backgroundColor]
/// trong suốt để gradient hiển thị qua.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // SizedBox.expand buộc gradient điền tất cả không gian có sẵn ngay cả khi
    // con ngắn hơn màn hình, để backdrop đạt tới cạnh-đến-cạnh
    // (bao gồm cả phía sau thanh điều hướng hệ thống trong suốt — không có dải đen).
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7EC8E3), // sky
              Color(0xFFBFE3A0), // light turf
              Color(0xFFEFE7D3), // cream
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Tiện lợi: một [Scaffold] được hỗ trợ bởi [AppBackground] với bề mặt
/// trong suốt để gradient hiển thị. Giữ code màn hình gọn gàng.
class GradientScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;

  const GradientScaffold({super.key, this.appBar, required this.body});

  @override
  Widget build(BuildContext context) {
    // Gradient nằm PHÍA SAU một Scaffold trong suốt (thay vì bên trong body của nó)
    // để nó che toàn bộ cửa sổ — bao gồm vùng phía sau thanh điều hướng hệ thống dưới cùng.
    // extendBody cho phép body vẽ vào vùng đó nữa,
    // để gradient kem hiển thị thay vì dải đen.
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: appBar,
        body: body,
      ),
    );
  }
}
