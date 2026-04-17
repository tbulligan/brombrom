import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:background_downloader/background_downloader.dart';

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
  static const String MAP_FILENAME = "NL_BromBrom_tagged.obf";
  static const String XML_FILENAME = "routing.xml";
  static const String APK_FILENAME = "BromBrom.apk";
  
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
  DateTime? _remoteXmlDate;
  DateTime? _remoteApkDate;
  DateTime? _localMapDate;
  DateTime? _localXmlDate;
  DateTime? _localApkDate;
  String? _localAppVersion;
  bool _mapUpdateAvailable = false;
  bool _xmlUpdateAvailable = false;
  bool _apkUpdateAvailable = false;
  bool _showLogs = false;
  String _locale = 'nl';
  
  // CACHED URLs
  final Map<String, String> _downloadUrls = {};

  final Map<String, Map<String, String>> _translations = {
    'nl': {
      'app_name': 'BromBrom Manager',
      'access_required': 'Toegang Vereist',
      'access_desc': 'Om bestanden te downloaden naar je Downloads-map en versies te controleren, hebben we \'Toegang tot alle bestanden\' nodig.',
      'allow_access': 'TOEGANG TOEGESTAAN',
      'status_permissions': 'Permissies controleren...',
      'status_checking': 'GitHub & lokale bestanden controleren...',
      'status_updates': 'Updates beschikbaar!',
      'status_uptodate_brief': 'Jouw systeem is up-to-date.',
      'status_error': 'Verbindings-/API-fout',
      'status_dl': 'Bezig met downloaden...',
      'status_dl_done': 'Klaar, openen in OsmAnd!',
      'status_dl_error': 'Fout bij downloaden',
      'latest_release': 'Laatste Cloud Update',
      'btn_apk_update': 'BromBrom App BIJWERKEN',
      'btn_apk_download': 'App OPNIEUW DOWNLOADEN',
      'installed_version': 'Geïnstalleerd',
      'version_old': 'Oude versie',
      'version_current': 'Huidig',
      'btn_map_update': 'Stap 1: KAART Importeren',
      'btn_map_download': 'Stap 1: KAART Opnieuw Importeren',
      'btn_xml_update': 'Stap 2: REGELS Importeren',
      'btn_xml_download': 'Stap 2: REGELS Opnieuw Importeren',
      'help': 'Help',
      'buy_coffee': 'Trakteer me op een koffie',
      'show_logs': 'Logboeken tonen',
      'hide_logs': 'Logboeken verbergen',
      'osmand_tip': 'Zodra je importeert, opent OsmAnd de bestanden direct.'
    },
    'en': {
      'app_name': 'BromBrom Manager',
      'access_required': 'Access Required',
      'access_desc': 'To download files to your Downloads folder and check versions, we need \'All Files Access\'.',
      'allow_access': 'ALLOW ACCESS',
      'status_permissions': 'Checking permissions...',
      'status_checking': 'Checking APIs...',
      'status_updates': 'Updates Available!',
      'status_uptodate_brief': 'Your system is completely up to date.',
      'status_error': 'Connection Error',
      'status_dl': 'Downloading...',
      'status_dl_done': 'Done. Opening in OsmAnd...',
      'status_dl_error': 'Error during download',
      'latest_release': 'Latest Cloud Update',
      'btn_apk_update': 'UPDATE BromBrom App',
      'btn_apk_download': 'RE-DOWNLOAD App',
      'installed_version': 'Installed',
      'version_old': 'Old Version',
      'version_current': 'Current',
      'btn_map_update': 'Step 1: Import MAP',
      'btn_map_download': 'Step 1: Re-import MAP',
      'btn_xml_update': 'Step 2: Import ROUTING RULES',
      'btn_xml_download': 'Step 2: Re-import ROUTING RULES',
      'help': 'Help',
      'buy_coffee': 'Buy me a coffee',
      'show_logs': 'Show Debug Logs',
      'hide_logs': 'Hide Debug Logs',
      'osmand_tip': 'When you press import, OsmAnd will open the file automatically.'
    }
  };

  String _t(String key) => _translations[_locale]?[key] ?? key;

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    String? saved = prefs.getString('language_code');
    if (saved == null) {
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
    _checkVersions();
  }

  Widget _buildLanguageSwitcher() {
    final bool isNL = _locale == 'nl';
    return TextButton(
      key: const Key('language_switcher'),
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
      final response = await http.get(Uri.parse(RELEASE_API));
      if (response.statusCode != 200) throw Exception("API Error ${response.statusCode}");
      
      final data = jsonDecode(response.body);
      
      DateTime latestDate = DateTime.parse(data['published_at']);
      DateTime? remoteMapDate;
      DateTime? remoteXmlDate;
      DateTime? remoteApkDate;

      final List assets = data['assets'] ?? [];
      for (var asset in assets) {
        final String name = asset['name'];
        final DateTime updatedAt = DateTime.parse(asset['updated_at']);
        
        if (asset['browser_download_url'] != null) {
          _downloadUrls[name] = asset['browser_download_url'];
        }
        
        if (updatedAt.isAfter(latestDate)) {
          latestDate = updatedAt;
        }

        if (name == MAP_FILENAME) {
          remoteMapDate = updatedAt;
        } else if (name == XML_FILENAME) {
          remoteXmlDate = updatedAt;
        } else if (name == APK_FILENAME) {
          remoteApkDate = updatedAt;
        }
      }
      
      _latestReleaseDate = latestDate;
      _remoteMapDate = remoteMapDate;
      _remoteXmlDate = remoteXmlDate;
      _remoteApkDate = remoteApkDate;
      
      // Local version check
      final File mapFile = File('$_targetDir/$MAP_FILENAME');
      _localMapDate = await mapFile.exists() ? await mapFile.lastModified() : null;

      final File xmlFile = File('$_targetDir/$XML_FILENAME');
      _localXmlDate = await xmlFile.exists() ? await xmlFile.lastModified() : null;

      final File apkFile = File('$_targetDir/$APK_FILENAME');
      _localApkDate = await apkFile.exists() ? await apkFile.lastModified() : null;

      final packageInfo = await PackageInfo.fromPlatform();
      _localAppVersion = "${packageInfo.version}+${packageInfo.buildNumber}";
      
      _mapUpdateAvailable = _localMapDate == null || _localMapDate!.isBefore(_remoteMapDate ?? _latestReleaseDate!);
      _xmlUpdateAvailable = _localXmlDate == null || _localXmlDate!.isBefore(_remoteXmlDate ?? _latestReleaseDate!);
      _apkUpdateAvailable = _localApkDate == null || _localApkDate!.isBefore(_remoteApkDate ?? _latestReleaseDate!);

      setState(() {
        _statusMessage = (_mapUpdateAvailable || _xmlUpdateAvailable || _apkUpdateAvailable) 
            ? _t('status_updates') 
            : _t('status_uptodate_brief');
      });

    } catch (e) {
      _log("Check Error: $e");
      setState(() => _statusMessage = _t('status_error'));
    }
  }

  Future<void> _downloadAndLaunchFile(String fileName, String mimeType) async {
    setState(() {
      _isDownloading = true;
      _statusMessage = _t('status_dl');
      _progress = 0.0;
    });

    try {
      final String? dlUrl = _downloadUrls[fileName];
      if (dlUrl == null) {
         throw Exception("File '$fileName' download URL not found. API Mismatch.");
      }

      final task = DownloadTask(
        url: dlUrl,
        filename: fileName,
        displayName: fileName,
        updates: Updates.statusAndProgress,
        allowPause: true,
      );

      final result = await FileDownloader().download(
        task,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _progress = progress);
          }
        },
      );

      if (result.status == TaskStatus.complete) {
        final File file = File('$_targetDir/$fileName');
        if (await file.exists()) await file.delete();
        
        final filePath = await task.filePath();
        final downloadedFile = File(filePath);
        await downloadedFile.copy(file.path);
        await downloadedFile.delete();

        _log("Saved to public storage: ${file.path}");
        
        await _checkVersions();

        setState(() {
          _isDownloading = false;
          _progress = 1.0;
          _statusMessage = _t('status_dl_done');
        });

        // Fire native OsmAnd import Intent!
        _fireImportIntent(file.path, mimeType);
        
      } else {
        throw Exception("Download failed with status: ${result.status}");
      }

    } catch (e) {
      _log("DL Error: $e");
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusMessage = _t('status_dl_error');
        });
      }
    }
  }

  Future<void> _fireImportIntent(String path, String mimeType) async {
    final fileName = path.split('/').last;
    final contentUri = "content://com.brombrom.app.fileprovider/external_files/Download/$fileName";
    
    _log("Firing Intent: $contentUri ($mimeType)");

    try {
      final AndroidIntent intent = AndroidIntent(
        action: 'action_view',
        data: contentUri,
        type: mimeType,
        flags: <int>[
          0x00000001, // FLAG_GRANT_READ_URI_PERMISSION
          0x10000000, // FLAG_ACTIVITY_NEW_TASK
        ],
      );
      await intent.launch();
    } catch (e) {
      _log("Launch Error: $e");
    }
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
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (!_mapUpdateAvailable && !_xmlUpdateAvailable && !_apkUpdateAvailable)
                           Row(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               const Icon(Icons.check_circle, color: Colors.green),
                               const SizedBox(width: 8),
                               Expanded(child: Text(_t('status_uptodate_brief'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                             ],
                           )
                        else 
                           Text(_statusMessage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    
                        const SizedBox(height: 8),
                        if (_latestReleaseDate != null)
                          Text("${_t('latest_release')}: ${DateFormat('yyyy-MM-dd').format(_latestReleaseDate!)}"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                if (_isDownloading) ...[
                   LinearProgressIndicator(value: _progress),
                   Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                     child: Text("${(_progress * 100).toStringAsFixed(1)}%", textAlign: TextAlign.center),
                   )
                ],
    
                if (!_isDownloading) ...[
                    // STEP 1: IMPORT MAP
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        backgroundColor: _mapUpdateAvailable ? Colors.green[700] : Colors.blueGrey,
                        foregroundColor: Colors.white,
                        elevation: _mapUpdateAvailable ? 8 : 2,
                      ),
                      onPressed: () => _downloadAndLaunchFile(MAP_FILENAME, 'application/octet-stream'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_mapUpdateAvailable ? Icons.download : Icons.map, size: 24),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              _mapUpdateAvailable ? _t('btn_map_update') : _t('btn_map_download'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // STEP 2: IMPORT ROUTING XML
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        backgroundColor: _xmlUpdateAvailable ? Colors.orange[800] : Colors.blueGrey,
                        foregroundColor: Colors.white,
                        elevation: _xmlUpdateAvailable ? 8 : 2,
                      ),
                      onPressed: () => _downloadAndLaunchFile(XML_FILENAME, 'application/xml'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_xmlUpdateAvailable ? Icons.system_update_alt : Icons.rule, size: 24),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              _xmlUpdateAvailable ? _t('btn_xml_update') : _t('btn_xml_download'),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
                      child: Text(
                        _t('osmand_tip'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.blueGrey, fontStyle: FontStyle.italic, fontSize: 13),
                      ),
                    ),

                    const Divider(),
                    const SizedBox(height: 16),

                    // APP UPDATE
                    ElevatedButton(
                      onPressed: () => _downloadAndLaunchFile(APK_FILENAME, 'application/vnd.android.package-archive'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _apkUpdateAvailable ? Colors.blue[900] : Colors.grey[200],
                        foregroundColor: _apkUpdateAvailable ? Colors.white : Colors.black87,
                      ),
                      child: Column(
                        children: [
                          Text(_apkUpdateAvailable ? _t('btn_apk_update') : _t('btn_apk_download')),
                          Text("${_t('installed_version')}: ${_localAppVersion ?? 'Unknown'}", style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                        ],
                      ),
                    ),
                ],
                
                const SizedBox(height: 24),
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
                       physics: const NeverScrollableScrollPhysics(),
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
