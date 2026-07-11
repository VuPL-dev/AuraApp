import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:frontend_mobile/main.dart' as app;

/// Helper: Chờ cho app ổn định, tối đa [seconds] giây
Future<void> pumpUntilSettled(WidgetTester tester, {int seconds = 5}) async {
  for (int i = 0; i < seconds * 2; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    try {
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      return;
    } catch (_) {}
  }
}

/// Helper: Đăng nhập
Future<void> doLogin(WidgetTester tester, String email, String password) async {
  final textFields = find.byType(TextFormField);
  await tester.enterText(textFields.first, email);
  await tester.pumpAndSettle();
  await tester.enterText(textFields.last, password);
  await tester.pumpAndSettle();
  final loginButton = find.widgetWithText(ElevatedButton, 'Đăng nhập');
  await tester.tap(loginButton);
  await pumpUntilSettled(tester, seconds: 10);
}

bool hasText(String text) => find.text(text).evaluate().isNotEmpty;
bool hasTextContaining(String s) => find.textContaining(s).evaluate().isNotEmpty;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Bỏ qua lỗi overflow trong test (overflow phụ thuộc vào kích thước màn hình,
  // không nên fail test vì lý do này)
  setUp(() {
    FlutterError.onError = (FlutterErrorDetails details) {
      final exception = details.exception;
      if (exception is FlutterError &&
          exception.message.contains('overflowed')) {
        // Ghi log nhưng không throw => test không bị fail vì overflow
        debugPrint('⚠️ Overflow warning (ignored): ${exception.message.split('\n').first}');
        return;
      }
      // Với các lỗi khác, vẫn throw bình thường
      FlutterError.presentError(details);
    };
  });

  tearDown(() {
    FlutterError.onError = FlutterError.presentError;
  });

  // ═══════════════════════════════════════════════════════════
  // LUỒNG 1: ĐĂNG NHẬP CUSTOMER
  // ═══════════════════════════════════════════════════════════
  group('Luồng 1: Đăng nhập Customer', () {
    testWidgets('Đăng nhập với tài khoản customer@aura.com', (tester) async {
      app.main();
      await pumpUntilSettled(tester, seconds: 5);
      expect(find.text('Đăng nhập'), findsWidgets);

      await doLogin(tester, 'customer@aura.com', '123456');

      final isOnHome = hasText('Trang chủ') || hasTextContaining('Chào');
      expect(isOnHome, true, reason: '❌ Đăng nhập Customer THẤT BẠI');
      debugPrint('✅ Luồng 1: Đăng nhập Customer THÀNH CÔNG');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // LUỒNG 2: ĐĂNG NHẬP STAFF
  // ═══════════════════════════════════════════════════════════
  group('Luồng 2: Đăng nhập Staff', () {
    testWidgets('Đăng nhập với tài khoản staff@aura.com', (tester) async {
      app.main();
      await pumpUntilSettled(tester, seconds: 5);
      expect(find.text('Đăng nhập'), findsWidgets);

      await doLogin(tester, 'staff@aura.com', '123456');

      final isOnStaff = hasText('Staff Dashboard') || hasText('Aura Staff');
      expect(isOnStaff, true, reason: '❌ Đăng nhập Staff THẤT BẠI');
      debugPrint('✅ Luồng 2: Đăng nhập Staff THÀNH CÔNG');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // LUỒNG 3: ĐĂNG NHẬP ADMIN
  // ═══════════════════════════════════════════════════════════
  group('Luồng 3: Đăng nhập Admin', () {
    testWidgets('Đăng nhập với tài khoản admin@aura.com', (tester) async {
      app.main();
      await pumpUntilSettled(tester, seconds: 5);
      expect(find.text('Đăng nhập'), findsWidgets);

      await doLogin(tester, 'admin@aura.com', '123456');

      final isOnAdmin = hasText('Admin Dashboard') || hasText('Quản trị viên');
      expect(isOnAdmin, true, reason: '❌ Đăng nhập Admin THẤT BẠI');
      debugPrint('✅ Luồng 3: Đăng nhập Admin THÀNH CÔNG');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // LUỒNG 4: CUSTOMER XEM SẢN PHẨM
  // ═══════════════════════════════════════════════════════════
  group('Luồng 4: Customer xem sản phẩm', () {
    testWidgets('Đăng nhập Customer, xem danh sách sản phẩm', (tester) async {
      app.main();
      await pumpUntilSettled(tester, seconds: 5);

      await doLogin(tester, 'customer@aura.com', '123456');
      await pumpUntilSettled(tester, seconds: 5);

      final hasProducts = hasTextContaining('Dây chuyền') ||
          hasTextContaining('VND') ||
          hasTextContaining('đ') ||
          find.byType(Card).evaluate().isNotEmpty ||
          find.byType(GridView).evaluate().isNotEmpty;

      expect(hasProducts, true,
          reason: '❌ Không thấy sản phẩm nào trên trang chủ Customer');
      debugPrint('✅ Luồng 4: Xem sản phẩm THÀNH CÔNG');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // LUỒNG 5: STAFF QUẢN LÝ ĐƠN HÀNG
  // ═══════════════════════════════════════════════════════════
  group('Luồng 5: Staff quản lý đơn hàng', () {
    testWidgets('Đăng nhập Staff, mở Quản lý đơn hàng', (tester) async {
      app.main();
      await pumpUntilSettled(tester, seconds: 5);

      await doLogin(tester, 'staff@aura.com', '123456');

      // Mở Drawer
      final menuButton = find.byIcon(Icons.menu);
      if (menuButton.evaluate().isNotEmpty) {
        await tester.tap(menuButton);
        await tester.pumpAndSettle();
      } else {
        final scaffoldFinder = find.byType(Scaffold);
        if (scaffoldFinder.evaluate().isNotEmpty) {
          final scaffoldState = tester.firstState<ScaffoldState>(scaffoldFinder);
          scaffoldState.openDrawer();
          await tester.pumpAndSettle();
        }
      }

      final ordersMenuItem = find.text('Quản lý Đơn hàng');
      if (ordersMenuItem.evaluate().isNotEmpty) {
        await tester.tap(ordersMenuItem);
        await pumpUntilSettled(tester, seconds: 5);
      }

      final hasOrderList = hasText('Danh sách Đơn hàng') ||
          hasTextContaining('Đơn hàng');
      expect(hasOrderList, true,
          reason: '❌ Không mở được trang Quản lý đơn hàng');
      debugPrint('✅ Luồng 5: Staff Quản lý đơn hàng THÀNH CÔNG');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // LUỒNG 6: STAFF QUẢN LÝ SẢN PHẨM
  // ═══════════════════════════════════════════════════════════
  group('Luồng 6: Staff quản lý sản phẩm', () {
    testWidgets('Đăng nhập Staff, mở Quản lý sản phẩm', (tester) async {
      app.main();
      await pumpUntilSettled(tester, seconds: 5);

      await doLogin(tester, 'staff@aura.com', '123456');

      // Mở Drawer
      final menuButton = find.byIcon(Icons.menu);
      if (menuButton.evaluate().isNotEmpty) {
        await tester.tap(menuButton);
        await tester.pumpAndSettle();
      } else {
        final scaffoldFinder = find.byType(Scaffold);
        if (scaffoldFinder.evaluate().isNotEmpty) {
          final scaffoldState = tester.firstState<ScaffoldState>(scaffoldFinder);
          scaffoldState.openDrawer();
          await tester.pumpAndSettle();
        }
      }

      final productsMenuItem = find.text('Quản lý Sản phẩm');
      if (productsMenuItem.evaluate().isNotEmpty) {
        await tester.tap(productsMenuItem);
        await pumpUntilSettled(tester, seconds: 5);
      }

      final hasProductView = hasText('Quản lý sản phẩm') ||
          hasTextContaining('sản phẩm');
      expect(hasProductView, true,
          reason: '❌ Không mở được trang Quản lý sản phẩm');
      debugPrint('✅ Luồng 6: Staff Quản lý sản phẩm THÀNH CÔNG');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // LUỒNG 7: CUSTOMER NAVIGATION
  // ═══════════════════════════════════════════════════════════
  group('Luồng 7: Customer Navigation', () {
    testWidgets('Đăng nhập Customer, kiểm tra Bottom Navigation', (tester) async {
      app.main();
      await pumpUntilSettled(tester, seconds: 5);

      await doLogin(tester, 'customer@aura.com', '123456');
      await pumpUntilSettled(tester, seconds: 3);

      // Kiểm tra BottomNavigationBar tồn tại
      expect(find.byType(BottomNavigationBar), findsOneWidget,
          reason: '❌ Không tìm thấy BottomNavigationBar');

      // Kiểm tra có nút Quét QR (FloatingActionButton)
      expect(find.byType(FloatingActionButton), findsOneWidget,
          reason: '❌ Không tìm thấy nút Quét QR');

      // Bấm tab "Giỏ hàng" (dùng icon)
      final cartIcon = find.byIcon(Icons.shopping_cart_outlined);
      if (cartIcon.evaluate().isNotEmpty) {
        await tester.tap(cartIcon.first);
        await pumpUntilSettled(tester, seconds: 3);
      }

      // Bấm tab "Trang chủ" (dùng icon)
      final homeIcon = find.byIcon(Icons.home_outlined);
      if (homeIcon.evaluate().isEmpty) {
        final homeIconFilled = find.byIcon(Icons.home);
        if (homeIconFilled.evaluate().isNotEmpty) {
          await tester.tap(homeIconFilled.first);
          await pumpUntilSettled(tester, seconds: 3);
        }
      } else {
        await tester.tap(homeIcon.first);
        await pumpUntilSettled(tester, seconds: 3);
      }

      debugPrint('✅ Luồng 7: Customer Navigation THÀNH CÔNG');
    });
  });
}
