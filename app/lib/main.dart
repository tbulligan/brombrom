import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

// ── Background Task Constants ──
const String _bgTaskName = "com.brombrom.updateCheck";
const String _bgTaskTag = "brombrom_update_check";
const String _releaseApiUrl = "https://api.github.com/repos/tbulligan/brombrom/releases/latest";
const String _prefLastKnownRelease = "last_known_release_date";
const String _prefBgScheduled = "bg_task_scheduled";

// ── Background Task Handler (runs in a separate isolate) ──
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // 1. Fetch latest release date from GitHub
      final response = await http.get(Uri.parse(_releaseApiUrl));
      if (response.statusCode != 200) return Future.value(false);

      final data = jsonDecode(response.body);
      final String publishedAt = data['published_at'] ?? '';
      if (publishedAt.isEmpty) return Future.value(true);

      // 2. Compare with last known release date
      final prefs = await SharedPreferences.getInstance();
      final String? lastKnown = prefs.getString(_prefLastKnownRelease);

      if (lastKnown != null && publishedAt != lastKnown) {
        // New release detected! Fire a notification.
        final remoteDate = DateTime.tryParse(publishedAt);
        final localDate = DateTime.tryParse(lastKnown);

        if (remoteDate != null && localDate != null && remoteDate.isAfter(localDate)) {
          await _showUpdateNotification();
        }
      }

      // 3. Persist the latest known date (even on first run)
      await prefs.setString(_prefLastKnownRelease, publishedAt);

      return Future.value(true);
    } catch (e) {
      print("BG Task Error: $e");
      return Future.value(false); // retry
    }
  });
}

/// Show a native Android notification for a new map update.
Future<void> _showUpdateNotification() async {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/launcher_icon');
  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);
  await notificationsPlugin.initialize(initSettings);

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'brombrom_updates',
    'BromBrom Updates',
    channelDescription: 'Notifications when new BromBrom map data is available',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/launcher_icon',
  );

  const NotificationDetails platformDetails =
      NotificationDetails(android: androidDetails);

  await notificationsPlugin.show(
    0,
    'BromBrom: Nieuwe kaartdata beschikbaar! 🗺️',
    'Open BromBrom Manager om je navigatie bij te werken.',
    platformDetails,
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  runApp(const BromBromApp());
}

class BromBromApp extends StatelessWidget {
  const BromBromApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BromBrom Installer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
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

class _InstallerScreenState extends State<InstallerScreen> with WidgetsBindingObserver {
  // CONFIG
  static const String RELEASE_API = "https://api.github.com/repos/tbulligan/brombrom/releases/latest";
  static const String OSF_FILENAME = "BromBrom.osf";
  
  // PATHS (App Specific, No permissions needed)
  String? _targetDir;
  
  // STATE
  String _statusMessage = 'Checking configuration...';
  bool _isDownloading = false;
  double _progress = 0.0;
  
  // VERSION INFO
  DateTime? _latestReleaseDate;
  DateTime? _remoteOsfDate;
  DateTime? _localOsfDate;
  bool _osfUpdateAvailable = false;
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
      'status_uptodate_brief': 'Alles is up-to-date.',
      'status_uptodate_full': 'Jouw navigatie is helemaal up-to-date',
      'status_error': 'Verbindings-/API-fout',
      'status_dl': 'Bezig met downloaden van {file}...',
      'status_dl_done': 'Download voltooid!',
      'status_dl_error': 'Fout: {error}',
      'latest_release': 'Laatste release',
      'btn_osf_update': 'BromBrom Navigatie INSTALLEREN / BIJWERKEN',
      'btn_osf_download': 'BromBrom Navigatie OPNIEUW DOWNLOADEN',
      'on_disk': 'Lokaal aanwezig',
      'osf_dialog_title': 'Activering Vereist',
      'osf_dialog_p1': 'OsmAnd zal nu openen. Tik op "Toepassen" of "Alles vervangen" en wacht tot de import voltooid is.',
      'osf_dialog_p2': '⚠️ Bij het "Import voltooid" scherm:',
      'osf_dialog_step1': '1. Tik direct op "Instellingen"',
      'osf_dialog_step2': '2. Scroll naar beneden naar "BromBrom"',
      'osf_dialog_step3': '3. Zet de schakelaar op INGESCHAKELD',
      'osf_dialog_btn': 'BEGREPEN, OPEN OSMAND',
      'btn_get_osmand': 'Download OsmAnd App',
      'help': 'Help',
      'buy_coffee': 'Trakteer me op een koffie',
      'show_logs': 'Logboeken tonen',
      'hide_logs': 'Logboeken verbergen',
    },
    'en': {
      'app_name': 'BromBrom Manager',
      'access_required': 'Access Required',
      'access_desc': 'To download files to your Downloads folder and check versions, we need \'All Files Access\'.',
      'allow_access': 'ALLOW ACCESS',
      'status_permissions': 'Checking permissions...',
      'status_checking': 'Checking GitHub & Local files...',
      'status_updates': 'Updates Available!',
      'status_uptodate_brief': 'Everything is up to date.',
      'status_uptodate_full': 'Your navigation is completely up to date',
      'status_error': 'Connection/API Error',
      'status_dl': 'Downloading {file}...',
      'status_dl_done': 'Download Complete!',
      'status_dl_error': 'Error: {error}',
      'latest_release': 'Latest Release',
      'btn_osf_update': 'INSTALL / UPDATE BromBrom Navigation',
      'btn_osf_download': 'RE-DOWNLOAD BromBrom Navigation',
      'on_disk': 'On device',
      'osf_dialog_title': 'Activation Required',
      'osf_dialog_p1': 'OsmAnd will now open. Tap "Apply" or "Replace all" and wait for the import to finish.',
      'osf_dialog_p2': '⚠️ On the "Import complete" screen:',
      'osf_dialog_step1': '1. Tap "Settings"',
      'osf_dialog_step2': '2. Scroll down to "BromBrom"',
      'osf_dialog_step3': '3. Set its switch to ENABLED',
      'osf_dialog_btn': 'UNDERSTOOD, OPEN OSMAND',
      'btn_get_osmand': 'Download OsmAnd App',
      'help': 'Help',
      'buy_coffee': 'Buy me a coffee',
      'show_logs': 'Show Debug Logs',
      'hide_logs': 'Hide Debug Logs',
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
    WidgetsBinding.instance.addObserver(this);
    _loadLocale().then((_) async {
      await _initTargetDir();
      await _requestNotificationPermission();
      await _scheduleBackgroundUpdateCheck();
      _checkVersions();
    });
  }

  Future<void> _initTargetDir() async {
    if (!Platform.isAndroid) return;
    try {
      final dir = await getExternalStorageDirectory();
      _targetDir = dir?.path;
    } catch(e) {
      _log("Failed to get external storage dir: $e");
      _targetDir = "/storage/emulated/0/Download";
    }
  }

  /// Request POST_NOTIFICATIONS permission on Android 13+.
  Future<void> _requestNotificationPermission() async {
    if (!Platform.isAndroid) return;
    try {
      final FlutterLocalNotificationsPlugin notificationsPlugin =
          FlutterLocalNotificationsPlugin();
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        _log("Notification permission requested.");
      }
    } catch (e) {
      _log("Notification permission error: $e");
    }
  }

  /// Schedule a weekly background task to check for updates.
  /// Only registers once (persisted via SharedPreferences).
  Future<void> _scheduleBackgroundUpdateCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final bool alreadyScheduled = prefs.getBool(_prefBgScheduled) ?? false;
    if (alreadyScheduled) {
      _log("Background update check already scheduled.");
      return;
    }

    try {
      await Workmanager().registerPeriodicTask(
        _bgTaskTag,
        _bgTaskName,
        frequency: const Duration(hours: 24),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingWorkPolicy.keep,
      );
      await prefs.setBool(_prefBgScheduled, true);
      _log("Background update check scheduled (every 24h).");
    } catch (e) {
      _log("Failed to schedule background task: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkVersions();
    }
  }

  Future<void> _checkVersions() async {
    setState(() => _statusMessage = _t('status_checking'));
    
    try {
      final response = await http.get(Uri.parse(RELEASE_API));
      if (response.statusCode != 200) throw Exception("API Error ${response.statusCode}");
      
      final data = jsonDecode(response.body);
      
      DateTime latestDate = DateTime.parse(data['published_at']);
      DateTime? remoteOsfDate;
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

        if (name == OSF_FILENAME) {
          remoteOsfDate = updatedAt;
        }
      }
      
      _latestReleaseDate = latestDate;
      _remoteOsfDate = remoteOsfDate;
      _log("Latest Release: $_latestReleaseDate");

      // Persist for background task comparison
      final String publishedAt = data['published_at'] ?? '';
      if (publishedAt.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefLastKnownRelease, publishedAt);
      }

      final File osfFile = File('$_targetDir/$OSF_FILENAME');
      _localOsfDate = await osfFile.exists() ? await osfFile.lastModified() : null;

      _osfUpdateAvailable = _localOsfDate == null || 
          _localOsfDate!.isBefore(_remoteOsfDate ?? _latestReleaseDate!);

      setState(() {
        _statusMessage = _osfUpdateAvailable 
            ? _t('status_updates') 
            : _t('status_uptodate_brief');
      });

    } catch (e) {
      _log("Check Error: $e");
      setState(() => _statusMessage = _t('status_error'));
    }
  }

  Future<void> _downloadFile(String fileName) async {
    setState(() {
      _isDownloading = true;
      _statusMessage = _t('status_dl').replaceFirst('{file}', fileName);
      _progress = 0.0;
    });

    try {
      final String? dlUrl = _downloadUrls[fileName];
      if (dlUrl == null) {
         throw Exception("File '$fileName' download URL not found. Details: Make sure the release has the file attached.");
      }

      _log("Starting background download: $fileName");

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
        onStatus: (status) {
          _log("Download status: $status");
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
        _scanFile(file.path);
        
        await _checkVersions();

        setState(() {
          _isDownloading = false;
          _progress = 1.0;
          _statusMessage = _t('status_dl_done');
        });

        if (fileName.endsWith(".osf")) {
          _showOsfInstructionsDialog(file.path);
        }
      } else {
        throw Exception("Download failed with status: ${result.status}");
      }

    } catch (e) {
      _log("DL Error: $e");
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusMessage = _t('status_dl_error').replaceFirst('{error}', e.toString());
        });
      }
    }
  }

  Future<void> _showOsfInstructionsDialog(String filePath) async {
    if (!mounted) return;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_t('osf_dialog_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(_t('osf_dialog_p1')),
                const SizedBox(height: 16),
                Text(_t('osf_dialog_p2'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 8),
                Text(_t('osf_dialog_step1'), style: const TextStyle(fontSize: 15)),
                Text(_t('osf_dialog_step2'), style: const TextStyle(fontSize: 15)),
                Text(_t('osf_dialog_step3'), style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue[800],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(_t('osf_dialog_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
                _openOsfInOsmAnd(filePath);
              },
            ),
          ],
        );
      },
    );
  }
  
  void _scanFile(String path) {
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

  Future<void> _openOsfInOsmAnd(String path) async {
    final fileName = path.split('/').last;
    final contentUri = "content://com.brombrom.app.fileprovider/map_imports_ext/$fileName";
    
    _log("Opening OSF Intent: $contentUri");

    try {
      final AndroidIntent intent = AndroidIntent(
        action: 'action_view',
        data: contentUri,
        type: '*/*',
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
    return Scaffold(
      appBar: AppBar(
          title: Text(_t('app_name')), 
          backgroundColor: Colors.orange[800], 
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
                        if (!_osfUpdateAvailable)
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
                
                if (!_isDownloading) ...[
                    // OSF BUNDLE UPDATE
                    if (_osfUpdateAvailable)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          backgroundColor: Colors.orange[800],
                          foregroundColor: Colors.white,
                          elevation: 8,
                        ),
                        onPressed: () => _downloadFile(OSF_FILENAME),
                        child: Column(
                          children: [
                            Text(
                              _t('btn_osf_update'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          side: BorderSide(color: Colors.orange[800]!, width: 2),
                          backgroundColor: Colors.orange[50],
                          foregroundColor: Colors.orange[800],
                        ),
                        onPressed: () => _downloadFile(OSF_FILENAME),
                        child: Column(
                          children: [
                            Text(
                              _t('btn_osf_download'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            if (_localOsfDate != null) ...[
                              const SizedBox(height: 8),
                              Text("${_t('on_disk')}: ${_t('version_current')}", 
                                 style: const TextStyle(fontSize: 12)),
                            ]
                          ],
                        ),
                      ),

                ],
                const SizedBox(height: 24),
                // Support Project & OsmAnd Link
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        AndroidIntent(
                          action: 'action_view',
                          data: 'market://details?id=net.osmand',
                          flags: <int>[0x10000000],
                        ).launch();
                      },
                      icon: Icon(Icons.get_app, size: 20, color: Colors.blueGrey[600]),
                      label: Text(_t('btn_get_osmand'), style: TextStyle(color: Colors.blueGrey[600], fontSize: 13, decoration: TextDecoration.underline)),
                    ),
                    const SizedBox(height: 8),
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
