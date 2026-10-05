import 'package:flutter_test/flutter_test.dart';
import 'package:gemeye/config/app_config.dart';

void main() {
  test('normalise adds scheme and port', () {
    expect(AppConfig.normalise('192.168.1.195'), 'http://192.168.1.195:8000');
    expect(AppConfig.normalise(' http://10.0.0.5:9000/ '), 'http://10.0.0.5:9000');
    expect(AppConfig.normalise('https://api.example.com'), 'https://api.example.com');
  });

  test('normalise rejects bad input', () {
    expect(AppConfig.normalise(''), isNull);
    expect(AppConfig.normalise('http://'), isNull);
    expect(AppConfig.normalise('http://1.2.3.4:8000/grade'), isNull);
  });
}
