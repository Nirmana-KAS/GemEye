import 'dart:math' as math;

/// A CIELAB colour (D65).
class Lab {
  final double l;
  final double a;
  final double b;

  const Lab(this.l, this.a, this.b);
}

/// Colour difference helpers.
class ColourMath {
  ColourMath._();

  /// Display label for the CIEDE2000 colour difference.
  static const String deltaELabel = 'Delta E (ΔE₀₀)';

  /// CIEDE2000 colour difference (kL = kC = kH = 1), per
  /// Sharma, Wu and Dalal (2005).
  static double deltaE2000(Lab lab1, Lab lab2) {
    const kL = 1.0, kC = 1.0, kH = 1.0;
    double deg(double r) => r * 180 / math.pi;
    double rad(double d) => d * math.pi / 180;

    final c1 = math.sqrt(lab1.a * lab1.a + lab1.b * lab1.b);
    final c2 = math.sqrt(lab2.a * lab2.a + lab2.b * lab2.b);
    final cBar = (c1 + c2) / 2;
    final cBar7 = math.pow(cBar, 7).toDouble();
    final g = 0.5 * (1 - math.sqrt(cBar7 / (cBar7 + math.pow(25, 7))));

    final a1p = (1 + g) * lab1.a;
    final a2p = (1 + g) * lab2.a;
    final c1p = math.sqrt(a1p * a1p + lab1.b * lab1.b);
    final c2p = math.sqrt(a2p * a2p + lab2.b * lab2.b);

    double hueAngle(double b, double ap) {
      if (b == 0 && ap == 0) return 0;
      final h = deg(math.atan2(b, ap));
      return h < 0 ? h + 360 : h;
    }

    final h1p = hueAngle(lab1.b, a1p);
    final h2p = hueAngle(lab2.b, a2p);

    final dLp = lab2.l - lab1.l;
    final dCp = c2p - c1p;

    double dhp;
    if (c1p * c2p == 0) {
      dhp = 0;
    } else if ((h2p - h1p).abs() <= 180) {
      dhp = h2p - h1p;
    } else if (h2p - h1p > 180) {
      dhp = h2p - h1p - 360;
    } else {
      dhp = h2p - h1p + 360;
    }
    final dHp = 2 * math.sqrt(c1p * c2p) * math.sin(rad(dhp / 2));

    final lBarP = (lab1.l + lab2.l) / 2;
    final cBarP = (c1p + c2p) / 2;

    double hBarP;
    if (c1p * c2p == 0) {
      hBarP = h1p + h2p;
    } else if ((h1p - h2p).abs() <= 180) {
      hBarP = (h1p + h2p) / 2;
    } else if (h1p + h2p < 360) {
      hBarP = (h1p + h2p + 360) / 2;
    } else {
      hBarP = (h1p + h2p - 360) / 2;
    }

    final t = 1 -
        0.17 * math.cos(rad(hBarP - 30)) +
        0.24 * math.cos(rad(2 * hBarP)) +
        0.32 * math.cos(rad(3 * hBarP + 6)) -
        0.20 * math.cos(rad(4 * hBarP - 63));
    final dTheta = 30 * math.exp(-math.pow((hBarP - 275) / 25, 2));
    final cBarP7 = math.pow(cBarP, 7).toDouble();
    final rC = 2 * math.sqrt(cBarP7 / (cBarP7 + math.pow(25, 7)));
    final lBarP50 = (lBarP - 50) * (lBarP - 50);
    final sL = 1 + 0.015 * lBarP50 / math.sqrt(20 + lBarP50);
    final sC = 1 + 0.045 * cBarP;
    final sH = 1 + 0.015 * cBarP * t;
    final rT = -math.sin(rad(2 * dTheta)) * rC;

    final fL = dLp / (kL * sL);
    final fC = dCp / (kC * sC);
    final fH = dHp / (kH * sH);
    return math.sqrt(fL * fL + fC * fC + fH * fH + rT * fC * fH);
  }
}
