import 'package:flutter_test/flutter_test.dart';
import 'package:kolkatafish/main.dart';
import 'package:kolkatafish/providers/cart_provider.dart';
import 'package:kolkatafish/providers/auth_provider.dart';
import 'package:kolkatafish/providers/connectivity_provider.dart';
import 'package:provider/provider.dart';

import 'package:kolkatafish/services/connectivity_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final connectivityService = ConnectivityService(enablePolling: false);
    final connectivityProvider = ConnectivityProvider(service: connectivityService);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider.value(value: connectivityProvider),
        ],
        child: const KolkataFishApp(),
      ),
    );
    expect(find.byType(KolkataFishApp), findsOneWidget);
    // Let splash screen timer elapse and navigate to HomeScreen
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    connectivityProvider.dispose();
  });
}
