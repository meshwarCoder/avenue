import 'package:flutter_test/flutter_test.dart';
import 'package:avenue/main.dart';
import 'package:avenue/features/schdules/presentation/views/schedule_view.dart';

void main() {
  testWidgets('HomeView smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const Avenue());

    // Verify that HomeView is present
    expect(find.byType(HomeView), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });
}
