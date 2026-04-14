import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

class VersionCheckService {
  // Update this to match  current app version
  final String currentVersion = "1.0.1"; 
  
  // The URL to your version.json on GitHub Pages
  final String versionUrl = "https://leelemon0.github.io/rcts-27-pwa-app/version.json";

  Future<void> checkForUpdate() async {
    try {
      // Add a timestamp to the URL to prevent the browser from caching the JSON itself
      final response = await http.get(Uri.parse('$versionUrl?t=${DateTime.now().millisecondsSinceEpoch}'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String newVersion = data['version'];

        if (newVersion != currentVersion) {
          // Version mismatch detected! 
          web.window.location.reload();
        }
      }
    } catch (e) {
      // fail silently if there's an error fetching the version (e.g., offline)
    }
  }
}