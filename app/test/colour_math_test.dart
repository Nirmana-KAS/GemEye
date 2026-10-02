import 'package:flutter_test/flutter_test.dart';
import 'package:gemeye/utils/colour_math.dart';

void main() {
  group('deltaE2000 (Sharma et al. 2005 reference pairs)', () {
    test('pair 1', () {
      final d = ColourMath.deltaE2000(
        const Lab(50.0000, 2.6772, -79.7751),
        const Lab(50.0000, 0.0000, -82.7485),
      );
      expect(d, closeTo(2.0425, 0.0001));
    });

    test('pair 17', () {
      final d = ColourMath.deltaE2000(
        const Lab(50.0000, 2.5000, 0.0000),
        const Lab(73.0000, 25.0000, -18.0000),
      );
      expect(d, closeTo(27.1492, 0.0001));
    });

    test('identical colours give zero', () {
      expect(ColourMath.deltaE2000(const Lab(40, 5, -30), const Lab(40, 5, -30)), 0);
    });
  });
}
