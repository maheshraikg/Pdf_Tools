import 'dart:convert';
import 'dart:io';

/// Reads a JSON fixture saved from the real kspstadk.com REST API by
/// `tool/inspect_site.py`.
dynamic fixture(String name) => jsonDecode(File('test/fixtures/$name').readAsStringSync());

String fixtureContent(String name) {
  final j = fixture(name) as Map<String, dynamic>;
  final c = j['content'];
  return c is Map ? c['rendered'] as String : c as String;
}
