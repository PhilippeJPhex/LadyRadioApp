// ignore_for_file: avoid_print
import 'package:http/http.dart' as http;

void main() async {
  try {
    final response = await http.get(Uri.parse('https://ladyradio.it/'));
    final body = response.body;
    
    // Look for anything containing "song", "title", "api", "xdevel", "icecast"
    final lines = body.split('\n');
    for (var line in lines) {
      if (line.contains('ajax') || line.contains('api') || line.contains('song') || line.contains('now-playing') || line.contains('xdevel')) {
        print(line.trim());
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
