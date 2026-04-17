// ignore_for_file: avoid_print
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'dart:convert';

void main() async {
  final url = 'https://www.spreaker.com/show/6864279/episodes/feed';
  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'},
    );
    print('Code: ${response.statusCode}');
    if (response.statusCode == 200) {
      final doc = XmlDocument.parse(utf8.decode(response.bodyBytes));
      final items = doc.findAllElements('item');
      print('Parsed ${items.length} items from feed.');
      if (items.isNotEmpty) {
        final title = items.first.findElements('title').first.innerText;
        print('First item title: $title');
      }
    } else {
      print('Failed to load: ${response.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
