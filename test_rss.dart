// ignore_for_file: avoid_print, unused_local_variable
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'dart:convert';

void main() async {
  final url = 'https://www.spreaker.com/show/6864279/episodes/feed';
  try {
    print('Fetching \$url...');
    final response = await http.get(Uri.parse(url));
    print('Status code: \${response.statusCode}');
    if (response.statusCode == 200) {
      final doc = XmlDocument.parse(utf8.decode(response.bodyBytes));
      final items = doc.findAllElements('item');
      print('Found \${items.length} items.');
      for (var item in items.take(2)) {
        print("Title: \${item.findElements('title').first.innerText}");
      }
    } else {
      print('Failed to load: \${response.body}');
    }
  } catch (e) {
    print('Error: \$e');
  }
}
