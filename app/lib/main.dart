import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Add to pubspec if missing, or use manual parsing
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const BromBromApp());
}

class BromBromApp extends StatelessWidget {
  const BromBromApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BromBrom Installer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const InstallerScreen(),
    );
  }
}

class InstallerScreen extends StatefulWidget {
  const InstallerScreen({super.key});

  @override
  State<InstallerScreen> createState() => _InstallerScreenState();
}

class _InstallerScreenState extends State<InstallerScreen> {
  // CONFIG
  static const String RELEASE_API = "https://api.github.com/repos/tbulligan/brombrom/releases/latest";
  static const String OBF_FILENAME = "NL_BromBrom_tagged.obf";
  static const String XML_FILENAME = "routing.xml";
  static const String APK_FILENAME = "BromBrom.apk"; // Standard artifact name
  
  // PATHS (Public Downloads)
  final String _targetDir = "/storage/emulated/0/Download";
  
  // STATE
  bool _hasPermission = false;
  String _statusMessage = 'Checking permissions...';
  bool _isDownloading = false;
  double _progress = 0.0;
  
  // VERSION INFO
  DateTime? _latestReleaseDate;
  DateTime? _remoteMapDate;
  DateTime? _remoteRoutingDate;
  DateTime? _remoteApkDate;
  DateTime? _localMapDate;
  DateTime? _localRoutingDate;
  DateTime? _localApkDate;
  String? _localAppVersion;
  bool _mapUpdateAvailable = false;
  bool _routingUpdateAvailable = false;
  bool _apkUpdateAvailable = false;
  bool _showLogs = false;
  String _locale = 'nl';

  final Map<String, Map<String, String>> _translations = {
    'nl': {
      'app_name': 'BromBrom Manager',
      'access_required': 'Toegang Vereist',
      'access_desc': 'Om bestanden te downloaden naar je Downloads-map en versies te controleren, hebben we \'Toegang tot alle bestanden\' nodig.',
      'allow_access': 'TOEGANG TOEGESTAAN',
      'status_permissions': 'Permissies controleren...',
      'status_checking': 'GitHub & lokale bestanden controleren...',
      'status_updates': 'Updates beschikbaar!',
      'status_uptodate_brief': 'Bestanden zijn up-to-date.',
      'status_uptodate_full': 'Alle navigatiebestanden zijn up-to-date',
      'status_error': 'Verbindings-/API-fout',
      'status_dl': 'Bezig met downloaden van {file}...',
      'status_dl_done': 'Download voltooid!',
      'status_dl_error': 'Fout: {error}',
      'latest_release': 'Laatste release',
      'btn_apk_update': 'BromBrom App BIJWERKEN',
      'btn_apk_download': 'App OPNIEUW DOWNLOADEN',
      'installed_version': 'Geïnstalleerd',
      'in_downloads': 'In Downloads',
      'version_old': 'Oude versie',
      'version_current': 'Huidige',
      'btn_map_update': 'BromBrom Kaart BIJWERKEN',
      'btn_map_download': 'Kaart OPNIEUW DOWNLOADEN',
      'on_disk': 'In Downloads',
      'map_tip': '⚠️ Tip: Als de import mislukt, verwijder dan eerst de oude kaart in OsmAnd.',
      'help': 'Help',
      'btn_routing_update': 'BromBrom Routing BIJWERKEN',
      'btn_routing_download': 'Routing OPNIEUW DOWNLOADEN',
      'essential_logic': 'Essentieel voor correcte navigatie logica!',
      'buy_coffee': 'Trakteer me op een koffie',
      'show_logs': 'Logboeken tonen',
      'hide_logs': 'Logboeken verbergen',
      'routing_dl_title': 'Routing-bestand gedownload',
      'routing_dl_desc': 'Bestand opgeslagen in \'Downloads\'.\n\nHOE TE INSTALLEREN:\n1. Open OsmAnd en zorg dat je een BromBrom-profiel hebt (indien niet: Settings → App Profiles → New → Driving → BromBrom).\n2. Selecteer je BromBrom-profiel.\n3. Ga naar Navigation Settings (Navigatie-instellingen) → Navigation Type (Navigatietype).\n4. Tik op \'Import routing file\' (Navigatiebestand importeren) en selecteer \'routing.xml\'.\n5. Kies indien gevraagd voor Replace (Vervangen).\n6. Zorg dat BromBrom is geselecteerd als het actieve type.',
      'map_del_title': 'Oude kaart verwijderen',
      'map_del_desc': 'Als het importeren van de nieuwe kaart mislukt, volg dan deze stappen in OsmAnd:',
      'step_1': '1. Open OsmAnd Settings (Instellingen)',
      'step_2': '2. Maps & Resources (Kaarten & bronnen)',
      'step_3': '3. Tik op de tab \'Local\' (Lokaal)',
      'step_4': '4. Open \'Standard maps\' (Standaard kaarten)',
      'step_5': '5. Zoek naar \'NL_BromBrom_tagged\'',
      'step_6': '6. Tik erop en kies \'Remove\' (Verwijderen)',
    },
    'en': {
      'app_name': 'BromBrom Manager',
      'access_required': 'Access Required',
      'access_desc': 'To download files to your Downloads folder and check versions, we need \'All Files Access\'.',
      'allow_access': 'ALLOW ACCESS',
      'status_permissions': 'Checking permissions...',
      'status_checking': 'Checking GitHub & Local files...',
      'status_updates': 'Updates Available!',
      'status_uptodate_brief': 'Files are up to date.',
      'status_uptodate_full': 'All navigation files are up to date',
      'status_error': 'Connection/API Error',
      'status_dl': 'Downloading {file}...',
      'status_dl_done': 'Download Complete!',
      'status_dl_error': 'Error: {error}',
      'latest_release': 'Latest Release',
      'btn_apk_update': 'UPDATE BromBrom App',
      'btn_apk_download': 'RE-DOWNLOAD App',
      'installed_version': 'Installed',
      'in_downloads': 'In Downloads',
      'version_old': 'Old Version',
      'version_current': 'Current',
      'btn_map_update': 'UPDATE BromBrom Map',
      'btn_map_download': 'RE-DOWNLOAD Map',
      'on_disk': 'In Downloads',
      'map_tip': '⚠️ Tip: If import fails, delete the old map in OsmAnd first.',
      'help': 'Help',
      'btn_routing_update': 'UPDATE BromBrom Routing',
      'btn_routing_download': 'RE-DOWNLOAD Routing',
      'essential_logic': 'Essential for correct navigation logic!',
      'buy_coffee': 'Buy me a coffee',
      'show_logs': 'Show Debug Logs',
      'hide_logs': 'Hide Debug Logs',
      'routing_dl_title': 'Routing File Downloaded',
      'routing_dl_desc': 'File saved to \'Downloads\'.\n\nHOW TO INSTALL:\n1. Open OsmAnd and ensure you have a BromBrom profile (if not: Settings → App Profiles → New → Driving → BromBrom).\n2. Select your BromBrom profile.\n3. Go to Navigation Settings → Navigation Type.\n4. Tap \'Import routing file\' and select \'routing.xml\'.\n5. If prompted, choose Replace.\n6. Ensure BromBrom is selected as active.',
      'map_del_title': 'Delete Old Map',
      'map_del_desc': 'If importing the new map fails, follow these steps in OsmAnd:',
      'step_1': '1. Open OsmAnd Settings',
      'step_2': '2. Maps & Resources',
      'step_3': '3. Tap the \'Local\' tab',
      'step_4': '4. Open \'Standard maps\'',
      'step_5': '5. Find \'NL_BromBrom_tagged\'',
      'step_6': '6. Tap it and select \'Remove\'',
    }
  };

  String _t(String key) => _translations[_locale]?[key] ?? key;

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    String? saved = prefs.getString('language_code');
    if (saved == null) {
      // Automatic detection: if system is NL, use NL, else EN
      final String systemLoc = Platform.localeName.split('_')[0];
      saved = (systemLoc == 'nl') ? 'nl' : 'en';
    }
    setState(() => _locale = saved!);
  }

  Future<void> _saveLocale(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
    setState(() {
      _locale = code;
    });
    // Refresh versions to update the status message localization
    _checkVersions();
  }

  Widget _buildLanguageSwitcher() {
    final bool isNL = _locale == 'nl';
    return TextButton(
      onPressed: () => _saveLocale(isNL ? 'en' : 'nl'),
      child: Text(
        isNL ? "🇬🇧" : "🇳🇱",
        style: const TextStyle(fontSize: 24),
      ),
    );
  }

  final List<String> _logs = [];
  void _log(String msg) {
    print(msg);
    setState(() {
      _logs.add("${DateFormat('HH:mm:ss').format(DateTime.now())} - $msg");
    });
  }

  @override
  void initState() {
    super.initState();
    _loadLocale().then((_) => _checkPermissions());
  }

  Future<void> _checkPermissions() async {
    // Check MANAGE_EXTERNAL_STORAGE for Android 11+ functionality
    // This allows us to read/write Downloads freely and check timestamps
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      setState(() {
         _hasPermission = false;
         _statusMessage = _t('access_desc');
      });
    } else {
      setState(() => _hasPermission = true);
      _checkVersions();
    }
  }

  Future<void> _requestPermission() async {
    await Permission.manageExternalStorage.request();
    _checkPermissions();
  }

  Future<void> _checkVersions() async {
    setState(() => _statusMessage = _t('status_checking'));
    
    try {
      // 1. Get GitHub Info
      final response = await http.get(Uri.parse(RELEASE_API));
      if (response.statusCode != 200) throw Exception("API Error ${response.statusCode}");
      
      final data = jsonDecode(response.body);
      
      // Use the actual asset update times if available, otherwise fallback to published_at
      DateTime latestDate = DateTime.parse(data['published_at']);
      DateTime? remoteMapDate;
      DateTime? remoteRoutingDate;
      DateTime? remoteApkDate;

      final List assets = data['assets'] ?? [];
      for (var asset in assets) {
        final String name = asset['name'];
        final DateTime updatedAt = DateTime.parse(asset['updated_at']);
        
        // Track the overall latest date for display
        if (updatedAt.isAfter(latestDate)) {
          latestDate = updatedAt;
        }

        if (name == OBF_FILENAME) {
          remoteMapDate = updatedAt;
        } else if (name == XML_FILENAME) {
          remoteRoutingDate = updatedAt;
        } else if (name == APK_FILENAME) {
          remoteApkDate = updatedAt;
        }
      }
      
      _latestReleaseDate = latestDate;
      _remoteMapDate = remoteMapDate;
      _remoteRoutingDate = remoteRoutingDate;
      _remoteApkDate = remoteApkDate;
      _log("Latest Release: $_latestReleaseDate");

      // 2. Check Local Files
      final File mapFile = File('$_targetDir/$OBF_FILENAME');
      _localMapDate = await mapFile.exists() ? await mapFile.lastModified() : null;

      final File xmlFile = File('$_targetDir/$XML_FILENAME');
      _localRoutingDate = await xmlFile.exists() ? await xmlFile.lastModified() : null;
      
      final File apkFile = File('$_targetDir/$APK_FILENAME');
      _localApkDate = await apkFile.exists() ? await apkFile.lastModified() : null;

      // 3. Get Internal App Version
      final packageInfo = await PackageInfo.fromPlatform();
      _localAppVersion = "${packageInfo.version}+${packageInfo.buildNumber}";

      // 4. Compare (If local is older than remote asset OR missing, update needed)
      // We use the specific asset date if found, falling back to the release date.
      
      _mapUpdateAvailable = _localMapDate == null || 
          _localMapDate!.isBefore(remoteMapDate ?? _latestReleaseDate!);
          
      _routingUpdateAvailable = _localRoutingDate == null || 
          _localRoutingDate!.isBefore(remoteRoutingDate ?? _latestReleaseDate!);

      _apkUpdateAvailable = _localApkDate == null || 
          _localApkDate!.isBefore(_remoteApkDate ?? _latestReleaseDate!);

      setState(() {
        _statusMessage = (_mapUpdateAvailable || _routingUpdateAvailable || _apkUpdateAvailable) 
            ? _t('status_updates') 
            : _t('status_uptodate_brief');
      });

    } catch (e) {
      _log("Check Error: $e");
      setState(() => _statusMessage = _t('status_error'));
    }
  }

  Future<void> _downloadFile(String fileName, {bool isMap = true}) async {
    setState(() {
      _isDownloading = true;
      _statusMessage = _t('status_dl').replaceFirst('{file}', fileName);
      _progress = 0.0;
    });

    try {
      // 1. Get URL
      final response = await http.get(Uri.parse(RELEASE_API));
      if (response.statusCode != 200) throw Exception("API Error ${response.statusCode}");
      
      final data = jsonDecode(response.body);
      String? dlUrl;
      final List assets = data['assets'] ?? [];
      for (var asset in assets) {
        if (asset['name'] == fileName) dlUrl = asset['browser_download_url'];
      }
      if (dlUrl == null) throw Exception("File '$fileName' not found in release");

      // 2. Download to Public Downloads
      final File file = File('$_targetDir/$fileName');
      if (await file.exists()) await file.delete();

      _log("DL Start: $dlUrl");
      
      // Use Client to handle potential redirects manually if needed, or set headers
      final client = http.Client();
      var request = http.Request('GET', Uri.parse(dlUrl!));
      request.headers['User-Agent'] = 'BromBromApp/1.0';
      request.followRedirects = true; // Ensure redirects are followed
      
      final streamedResponse = await client.send(request);
      
      if (streamedResponse.statusCode != 200) {
         // Read error
         final body = await streamedResponse.stream.bytesToString();
         throw Exception("HTTP ${streamedResponse.statusCode}: $body");
      }

      final contentLength = streamedResponse.contentLength ?? 1;
      int received = 0;
      
      final sink = file.openWrite();
      await streamedResponse.stream.listen((chunk) {
        sink.add(chunk);
        received += chunk.length;
        setState(() => _progress = received / contentLength);
      }).asFuture();
      await sink.close();
      client.close();
      
      // 3. Post-Download: Media Scan
      _log("Saved: ${file.path} ($received bytes)");
      if (received < 1000) {
        _log("WARNING: File is tiny! Check GitHub Assets.");
      }
      _scanFile(file.path);
      
      // Update check state immediately
      await _checkVersions();

      setState(() {
        _isDownloading = false;
        _progress = 1.0;
        _statusMessage = _t('status_dl_done');
      });

      // 4. Trigger Handoff
      if (fileName.endsWith(".apk")) { // APP UPDATE
        _installApk(file.path);
      } else if (isMap) {
        _openMapInOsmAnd(file.path);
      } else {
        _showRoutingInstructions(file.path);
      }

    } catch (e) {
      _log("DL Error: $e");
      setState(() {
        _isDownloading = false;
        _statusMessage = _t('status_dl_error').replaceFirst('{error}', e.toString());
      });
    }
  }
  
  void _scanFile(String path) {
    // Notify MediaScanner so it shows up in Google Files
    try {
      final AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
        data: Uri.parse("file://$path").toString(),
      );
      intent.launch();
    } catch (e) {
      _log("Scan Error: $e");
    }
  }

  Future<void> _openMapInOsmAnd(String path) async {
    // Open using View Intent with FileProvider URI
    // Path: /storage/emulated/0/Download/filename.obf
    // XML: <external-path name="external_files" path="." />
    // URI: content://com.brombrom.app.fileprovider/external_files/Download/filename.obf
    
    final fileName = path.split('/').last;
    final contentUri = "content://com.brombrom.app.fileprovider/external_files/Download/$fileName";
    
    _log("Opening Intent: $contentUri");

    try {
      final AndroidIntent intent = AndroidIntent(
        action: 'action_view',
        data: contentUri,
        type: 'application/octet-stream',
        flags: <int>[
          0x00000001, // FLAG_GRANT_READ_URI_PERMISSION
          0x10000000, // FLAG_ACTIVITY_NEW_TASK
        ],
      );
      await intent.launch();
    } catch (e) {
      _log("Launch Error: $e. Using Share Sheet.");
      _shareFile(path);
    }
  }
  
  Future<void> _installApk(String path) async {
    // Trigger APK install
    final fileName = path.split('/').last;
    final contentUri = "content://com.brombrom.app.fileprovider/external_files/Download/$fileName";
    
    _log("Installing APK: $contentUri");
    
    try {
       final AndroidIntent intent = AndroidIntent(
        action: 'action_view',
        data: contentUri,
        type: 'application/vnd.android.package-archive',
        flags: <int>[
          0x00000001, // FLAG_GRANT_READ_URI_PERMISSION
          0x10000000, // FLAG_ACTIVITY_NEW_TASK
        ],
      );
      await intent.launch();
    } catch (e) {
      _log("Install Error: $e");
      // Fallback?
    }
  }

  void _showRoutingInstructions(String path) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('routing_dl_title')),
        content: Text(_t('routing_dl_desc')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
        ],
      )
    );
  }

  void _showMapDeleteInstructions() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('map_del_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_t('map_del_desc')),
              const SizedBox(height: 16),
              Text(_t('step_1')),
              Text(_t('step_2')),
              Text(_t('step_3')),
              Text(_t('step_4')),
              Text(_t('step_5')),
              Text(_t('step_6')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
  
  Future<void> _shareFile(String path) async {
    final xFile = XFile(path);
    await Share.shareXFiles([xFile]);
  }

  void _launchCoffeeUrl() async {
    const url = "https://buymeacoffee.com/brombrom";
    try {
      final AndroidIntent intent = AndroidIntent(
        action: 'action_view',
        data: url,
      );
      await intent.launch();
    } catch (e) {
      _log("Could not launch coffee link: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_t('app_name')),
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
          actions: [_buildLanguageSwitcher()],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_shared, size: 64, color: Colors.blue[800]),
                const SizedBox(height: 24),
                Text(
                  _t('access_required'),
                  key: const Key('onboarding_title'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  _t('access_desc'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  key: const Key('allow_access_button'),
                  onPressed: _requestPermission,
                  child: Text(_t('allow_access')),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
          title: Text(_t('app_name')), 
          backgroundColor: Colors.blue[800], 
          foregroundColor: Colors.white,
          actions: [
            _buildLanguageSwitcher(),
            const SizedBox(width: 8),
          ],
      ),
      body: RefreshIndicator(
        onRefresh: _checkVersions,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // STATUS
                // STATUS
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (!_mapUpdateAvailable && !_routingUpdateAvailable && !_apkUpdateAvailable)
                           Row(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               const Icon(Icons.check_circle, color: Colors.green),
                               const SizedBox(width: 8),
                               Expanded(child: Text(_t('status_uptodate_full'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                             ],
                           )
                        else 
                           Text(_statusMessage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    
                        const SizedBox(height: 8),
                        if (_latestReleaseDate != null)
                          Text("${_t('latest_release')}: ${DateFormat('yyyy-MM-dd HH:mm').format(_latestReleaseDate!)}"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // DOWNLOADERS
                if (_isDownloading) ...[
                   LinearProgressIndicator(value: _progress),
                   Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                     child: Text("${(_progress * 100).toStringAsFixed(1)}%", textAlign: TextAlign.center),
                   )
                ],
    
                if (!_isDownloading) ...[
                    // APP UPDATE
                    ElevatedButton(
                      onPressed: () => _downloadFile(APK_FILENAME, isMap: false),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: _apkUpdateAvailable ? Colors.orange[800] : Colors.grey[300],
                        foregroundColor: _apkUpdateAvailable ? Colors.white : Colors.black87,
                      ),
                      child: Column(
                        children: [
                          Text(_apkUpdateAvailable ? _t('btn_apk_update') : _t('btn_apk_download')),
                          Text("${_t('installed_version')}: ${_localAppVersion ?? 'Unknown'}", style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                          if (_localApkDate != null)
                            Text("${_t('in_downloads')}: ${(_localApkDate!.isBefore(_remoteApkDate ?? _latestReleaseDate ?? DateTime(0))) ? _t('version_old') : _t('version_current')}", 
                              style: TextStyle(fontSize: 10, color: _apkUpdateAvailable ? Colors.white70 : Colors.black54)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
    
                    // MAP
                    ElevatedButton(
                      onPressed: () => _downloadFile(OBF_FILENAME, isMap: true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: _mapUpdateAvailable ? Colors.orange[800] : Colors.grey[300],
                        foregroundColor: _mapUpdateAvailable ? Colors.white : Colors.black87,
                      ),
                      child: Column(
                        children: [
                          Text(_mapUpdateAvailable ? _t('btn_map_update') : _t('btn_map_download')),
                          if (_localMapDate != null)
                            Text("${_t('on_disk')}: ${(_localMapDate!.isBefore(_remoteMapDate ?? _latestReleaseDate ?? DateTime(0))) ? _t('version_old') : _t('version_current')}", style: TextStyle(fontSize: 10, color: _mapUpdateAvailable ? Colors.white70 : Colors.black54)),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: _showMapDeleteInstructions,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                _t('map_tip'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.orange, fontStyle: FontStyle.italic, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                                Text(_t('help'), style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // ROUTING
                    ElevatedButton(
                      onPressed: () => _downloadFile(XML_FILENAME, isMap: false),
                       style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: _routingUpdateAvailable ? Colors.orange[800] : Colors.grey[300],
                        foregroundColor: _routingUpdateAvailable ? Colors.white : Colors.black87,
                      ),
                      child: Column(
                        children: [
                          Text(_routingUpdateAvailable ? _t('btn_routing_update') : _t('btn_routing_download')),
                          if (_localRoutingDate != null)
                            Text("${_t('on_disk')}: ${(_localRoutingDate!.isBefore(_remoteRoutingDate ?? _latestReleaseDate ?? DateTime(0))) ? _t('version_old') : _t('version_current')}", style: TextStyle(fontSize: 10, color: _routingUpdateAvailable ? Colors.white70 : Colors.black54)),
                        ],
                      ),
                    ),
                    
                    // Only show essential warning if update available or first install (local is null)
                    if (_routingUpdateAvailable || _localRoutingDate == null)
                      Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                              const SizedBox(width: 4),
                                Text(
                                _t('essential_logic'),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red[800], fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                      ),
                ],
                
                const SizedBox(height: 16),
                // Support Project
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _launchCoffeeUrl,
                      icon: const Icon(Icons.coffee, color: Colors.brown, size: 20),
                      label: Text(
                          _t('buy_coffee'), 
                          style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ],
                ),
    
                const SizedBox(height: 32),
                
                // LOGS TOGGLE
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _showLogs = !_showLogs),
                    child: Text(_showLogs ? _t('hide_logs') : _t('show_logs'), 
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                ),

                if (_showLogs)
                  Container(
                    height: 150,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    color: Colors.black12,
                    child: ListView.builder(
                       shrinkWrap: true,
                       physics: const NeverScrollableScrollPhysics(), // Scroll handled by main view
                       itemCount: _logs.length,
                       itemBuilder: (ctx, i) => Text(_logs[i], style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                    ),
                  )
              ],
            ),
          ),
        ),
      )
    );
  }
}
