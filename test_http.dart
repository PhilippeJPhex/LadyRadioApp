// ignore_for_file: avoid_print, unused_local_variable
import 'dart:io';

void main() async {
  print('Testing HTTP connection to ladyradio.it...');
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('https://ladyradio.it/wp-json/ladyapp/v1/active-banner'));
    final response = await request.close();
    print('Status Code: \${response.statusCode}');
    client.close();
  } catch (e) {
    print('ERROR: \$e');
  }
}
