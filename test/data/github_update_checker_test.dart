import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:alifit/data/updates/github_update_checker.dart';
import 'package:alifit/domain/updates/app_release.dart';

void main() {
  test('compara versiones número por número, con o sin "v" y compilación', () {
    expect(isNewerVersion('1.2.0', '1.1.0'), isTrue);
    expect(isNewerVersion('v1.10.0', '1.9.3'), isTrue);
    expect(isNewerVersion('2.0', '1.9.9'), isTrue);
    expect(isNewerVersion('1.1.0', '1.1.0+2'), isFalse);
    expect(isNewerVersion('1.0.9', '1.1.0'), isFalse);
  });

  test('lee la versión y el enlace del APK de la última release', () async {
    final checker = GithubUpdateChecker(
      client: MockClient((request) async {
        expect(
          request.url.toString(),
          'https://api.github.com/repos/lecocubon/alifit/releases/latest',
        );
        return http.Response(
          jsonEncode({
            'tag_name': 'v1.2.0',
            'body': 'Arreglos varios.',
            'assets': [
              {'name': 'notas.txt', 'browser_download_url': 'https://x/notas'},
              {'name': 'AliFit.apk', 'browser_download_url': 'https://x/apk'},
            ],
          }),
          200,
        );
      }),
    );

    final release = await checker.fetchLatest();

    expect(release!.version, '1.2.0');
    expect(release.apkUrl, 'https://x/apk');
    expect(release.notes, 'Arreglos varios.');
  });

  test('sin releases publicadas no hay actualización', () async {
    final checker = GithubUpdateChecker(
      client: MockClient((_) async => http.Response('{}', 404)),
    );
    expect(await checker.fetchLatest(), isNull);
  });

  test('un error de GitHub se informa como excepción', () async {
    final checker = GithubUpdateChecker(
      client: MockClient((_) async => http.Response('limite', 403)),
    );
    expect(checker.fetchLatest(), throwsA(isA<http.ClientException>()));
  });
}
