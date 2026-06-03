import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:background_downloader/background_downloader.dart' hide PermissionStatus;
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:permission_handler/permission_handler.dart';

// ── Background Task Constants ──
const String _bgTaskName = "com.brombrom.updateCheck";
const String _bgTaskTag = "brombrom_update_check";
const String _releaseApiUrl = "https://api.github.com/repos/tbulligan/brombrom/releases/latest";
const String _prefLastKnownRelease = "last_known_release_date";
const String _prefBgScheduled = "bg_task_scheduled";
const String _prefOnboardingSeen = "onboarding_seen";

// ── Background Task Handler (runs in a separate isolate) ──
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // 1. Fetch latest release date from GitHub
      final response = await http.get(
        Uri.parse(_releaseApiUrl),
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );
      if (response.statusCode != 200) return Future.value(false);

      final data = jsonDecode(response.body);
      final String publishedAt = data['published_at'] ?? '';
      if (publishedAt.isEmpty) return Future.value(true);

      DateTime latestDate = DateTime.parse(publishedAt);
      final List assets = data['assets'] ?? [];
      for (var asset in assets) {
        final DateTime updatedAt = DateTime.parse(asset['updated_at']);
        if (updatedAt.isAfter(latestDate)) {
          latestDate = updatedAt;
        }
      }
      final String latestDateStr = latestDate.toIso8601String();

      // 2. Compare with last known release date
      final prefs = await SharedPreferences.getInstance();
      final String? lastKnown = prefs.getString(_prefLastKnownRelease);

      if (lastKnown != null && latestDateStr != lastKnown) {
        // New release detected! Fire a notification.
        final remoteDate = latestDate;
        final localDate = DateTime.tryParse(lastKnown);

        if (localDate != null && remoteDate.isAfter(localDate)) {
          await _showUpdateNotification();
        }
      }

      // 3. Persist the latest known date (even on first run)
      await prefs.setString(_prefLastKnownRelease, latestDateStr);

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
  bool _isChecking = true;
  String? _checkError;
  
  // VERSION INFO
  DateTime? _latestReleaseDate;
  DateTime? _remoteOsfDate;
  DateTime? _localOsfDate;
  bool _osfUpdateAvailable = false;
  bool _showLogs = false;
  int _devTapCount = 0;
  DateTime? _lastTapTime;
  String _locale = 'nl';
  bool _showOnboarding = false;
  late PageController _onboardingPageController;
  int _onboardingCurrentPage = 0;
  
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
      'osf_dialog_title': 'Openen in OsmAnd',
      'osf_dialog_p1': 'OsmAnd opent nu. Volg deze stappen precies:',
      'osf_dialog_step1': '1. Tik op "Alle instellingen en bronnen" → "Doorgaan"',
      'osf_dialog_step2': '2. Tik op "Alles vervangen" (update) of "Toepassen" (eerste keer)',
      'osf_dialog_step3': '3. Wacht tot de import klaar is',
      'osf_dialog_step4': '4. Tik op het "Import voltooid" scherm op "Instellingen"',
      'osf_dialog_step5': '5. Scroll naar beneden naar "BromBrom" en zet de schakelaar AAN',
      'osf_dialog_step6': '6. Je kunt BromBrom nu selecteren in het Navigatiemenu (oranje auto-icoon)',
      'osf_dialog_warning': '⚠️ Sla stap 4–6 niet over — OsmAnd verbergt en activeert nieuwe profielen niet automatisch.',
      'osf_dialog_btn': 'BEGREPEN, OPEN OSMAND',
      'btn_get_osmand': 'Download OsmAnd App',
      'help': 'Help',
      'buy_coffee': 'Trakteer me op een koffie',
      'visit_website': 'Website bezoeken (Visuele Handleiding)',
      'show_logs': 'Logboeken tonen',
      'hide_logs': 'Logboeken verbergen',
      'ob_slide1_title': 'Navigeer veilig met je Brommobiel',
      'ob_slide1_body': 'BromBrom voegt een speciaal navigatieprofiel toe aan OsmAnd. Je vermijdt automatisch snelwegen en C9-wegen.',
      'ob_slide2_title': 'Je hebt OsmAnd nodig',
      'ob_slide2_body': 'BromBrom werkt binnen de gratis OsmAnd app. Als je OsmAnd nog niet hebt, download het dan nu vóórdat je verdergaat.',
      'ob_slide2_btn': 'Download OsmAnd',
      'ob_slide3_title': 'Altijd de nieuwste kaart',
      'ob_slide3_body': 'BromBrom controleert elke dag op nieuwe kaarten. Zet meldingen aan en je krijgt automatisch een seintje wanneer er een update klaarstaat.',
      'ob_slide3_btn': 'Meldingen inschakelen',
      'ob_notifications_enabled': 'Meldingen aan ✓',
      'ob_skip': 'Niet nu',
      'ob_next': 'Volgende',
      'ob_finish': 'Aan de slag!',
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
      'osf_dialog_title': 'Open in OsmAnd',
      'osf_dialog_p1': 'OsmAnd will now open. Follow these steps exactly:',
      'osf_dialog_step1': '1. Tap "All Settings and Resources" → "Continue"',
      'osf_dialog_step2': '2. Tap "Replace all" (update) or "Apply" (first time)',
      'osf_dialog_step3': '3. Wait for the import to complete',
      'osf_dialog_step4': '4. On the "Import complete" screen, tap "Settings"',
      'osf_dialog_step5': '5. Scroll down to "BromBrom" and toggle it ON',
      'osf_dialog_step6': '6. You can now select BromBrom from the Navigation menu (orange car icon)',
      'osf_dialog_warning': '⚠️ Do not skip steps 4–6 — OsmAnd does not enable or activate new profiles automatically.',
      'osf_dialog_btn': 'UNDERSTOOD, OPEN OSMAND',
      'btn_get_osmand': 'Download OsmAnd App',
      'help': 'Help',
      'buy_coffee': 'Buy me a coffee',
      'visit_website': 'Visit website (Visual Setup Guide)',
      'show_logs': 'Show Debug Logs',
      'hide_logs': 'Hide Debug Logs',
      'ob_slide1_title': 'Navigate Safely in Your Microcar',
      'ob_slide1_body': 'BromBrom adds a dedicated navigation profile to OsmAnd that automatically avoids motorways and C9-restricted roads.',
      'ob_slide2_title': 'You need OsmAnd',
      'ob_slide2_body': 'BromBrom works inside the free OsmAnd app. If you don\'t have OsmAnd yet, download it now before continuing.',
      'ob_slide2_btn': 'Download OsmAnd',
      'ob_slide3_title': 'Always the Latest Map',
      'ob_slide3_body': 'BromBrom checks daily for new maps. Enable notifications and you\'ll automatically be notified when an update is ready.',
      'ob_slide3_btn': 'Enable Notifications',
      'ob_notifications_enabled': 'Notifications enabled ✓',
      'ob_skip': 'Not now',
      'ob_next': 'Next',
      'ob_finish': 'Let\'s go!',
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
    _onboardingPageController = PageController();
    _loadLocale().then((_) async {
      await _initTargetDir();
      // NOTE: Notification permission is now requested via the onboarding carousel or manually, not on start.
      await _scheduleBackgroundUpdateCheck();
      _checkVersions();
      // Show onboarding carousel on first launch
      final prefs = await SharedPreferences.getInstance();
      final bool seen = prefs.getBool(_prefOnboardingSeen) ?? false;
      if (!seen && mounted) {
        setState(() => _showOnboarding = true);
      }
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
    _onboardingPageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkVersions();
    }
  }

  Future<void> _checkVersions() async {
    setState(() {
      _isChecking = true;
      _checkError = null;
      _statusMessage = _t('status_checking');
    });
    
    try {
      final response = await http.get(
        Uri.parse(RELEASE_API),
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );
      if (response.statusCode != 200) throw Exception("API Error ${response.statusCode}");
      
      final data = jsonDecode(response.body);
      
      DateTime latestDate = DateTime.parse(data['published_at']);
      DateTime? remoteOsfDate;

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
      if (_latestReleaseDate != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefLastKnownRelease, _latestReleaseDate!.toIso8601String());
      }

      final File osfFile = File('$_targetDir/$OSF_FILENAME');
      _localOsfDate = await osfFile.exists() ? await osfFile.lastModified() : null;

      _osfUpdateAvailable = _localOsfDate == null || 
          _localOsfDate!.isBefore(_remoteOsfDate ?? _latestReleaseDate!);

      setState(() {
        _isChecking = false;
        _checkError = null;
        _statusMessage = _osfUpdateAvailable 
            ? _t('status_updates') 
            : _t('status_uptodate_brief');
      });

    } catch (e) {
      _log("Check Error: $e");
      setState(() {
        _isChecking = false;
        _checkError = e.toString();
        _statusMessage = _t('status_error');
      });
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
          content: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(_t('osf_dialog_p1'), style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Text(_t('osf_dialog_step1'), style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(_t('osf_dialog_step2'), style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(_t('osf_dialog_step3'), style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(_t('osf_dialog_step4'), style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(_t('osf_dialog_step5'), style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(_t('osf_dialog_step6'), style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Text(
                      _t('osf_dialog_warning'),
                      style: TextStyle(fontSize: 13, color: Colors.orange[900], fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.orange[800],
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
  
  void _handleTitleTap() {
    final now = DateTime.now();
    if (_lastTapTime == null || now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _devTapCount = 1;
    } else {
      _devTapCount++;
    }
    _lastTapTime = now;

    if (_devTapCount >= 5) {
      setState(() {
        _showLogs = !_showLogs;
        _devTapCount = 0;
      });
      _log(_showLogs ? "Developer mode enabled" : "Developer mode disabled");
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

  void _launchWebsiteUrl() async {
    const url = "https://brombrom.bulligan.com/";
    try {
      final AndroidIntent intent = AndroidIntent(
        action: 'action_view',
        data: url,
      );
      await intent.launch();
    } catch (e) {
      _log("Could not launch website link: $e");
    }
  }

  Future<void> _dismissOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefOnboardingSeen, true);
    if (mounted) setState(() => _showOnboarding = false);
  }

  Widget _buildOnboardingCarousel() {
    final Color orange = Colors.orange[800]!;

    return StatefulBuilder(
      builder: (context, setPageState) {
        // Slides evaluated inside the builder so _t() re-reads _locale on every rebuild.
        final List<Map<String, String>> slides = [
          {
            'icon': '\ud83d\ude97',
            'title': _t('ob_slide1_title'),
            'body': _t('ob_slide1_body'),
          },
          {
            'icon': '\ud83d\uddfa\ufe0f',
            'title': _t('ob_slide2_title'),
            'body': _t('ob_slide2_body'),
            'btn': _t('ob_slide2_btn'),
          },
          {
            'icon': '\ud83d\udd14',
            'title': _t('ob_slide3_title'),
            'body': _t('ob_slide3_body'),
            'btn': _t('ob_slide3_btn'),
          },
        ];

        void toggleLanguage() {
          final newLang = _locale == 'nl' ? 'en' : 'nl';
          // Update parent locale state so _t() returns new language immediately.
          setState(() => _locale = newLang);
          // Rebuild the carousel subtree.
          setPageState(() {});
          // Persist so main app inherits the choice after onboarding is dismissed.
          SharedPreferences.getInstance().then((p) => p.setString('language_code', newLang));
        }

        return Material(
          color: Colors.black.withOpacity(0.92),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  // Top bar: language toggle (left) + skip (right)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: toggleLanguage,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white12,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text(
                          _locale == 'nl' ? '\ud83c\uddec\ud83c\udde7  EN' : '\ud83c\uddf3\ud83c\uddf1  NL',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: _dismissOnboarding,
                        child: Text(_t('ob_skip'), style: const TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _onboardingPageController,
                      itemCount: slides.length,
                      onPageChanged: (i) => setPageState(() => _onboardingCurrentPage = i),
                      itemBuilder: (context, index) {
                        final slide = slides[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(slide['icon']!, style: const TextStyle(fontSize: 64)),
                            const SizedBox(height: 32),
                            Text(
                              slide['title']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              slide['body']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                            ),
                            if (slide.containsKey('btn')) ...[
                              const SizedBox(height: 28),
                              FutureBuilder<PermissionStatus>(
                                future: index == 2 ? Permission.notification.status : Future.value(PermissionStatus.denied),
                                builder: (context, snapshot) {
                                  final isGranted = snapshot.data?.isGranted ?? false;
                                  return OutlinedButton(
                                    onPressed: isGranted ? null : () async {
                                      if (index == 1) {
                                        AndroidIntent(
                                          action: 'action_view',
                                          data: 'https://play.google.com/store/apps/details?id=net.osmand',
                                        ).launch();
                                      } else if (index == 2) {
                                        await _requestNotificationPermission();
                                        setPageState(() {}); // Rebuild carousel slide to show updated status
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      disabledForegroundColor: Colors.greenAccent,
                                      side: BorderSide(color: isGranted ? Colors.greenAccent : Colors.white54),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    ),
                                    child: Text(index == 2 && isGranted ? _t('ob_notifications_enabled') : slide['btn']!),
                                  );
                                }
                              ),
                            ]
                          ],
                        );
                      },
                    ),
                  ),
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(slides.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _onboardingCurrentPage == i ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _onboardingCurrentPage == i ? orange : Colors.white38,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (_onboardingCurrentPage < slides.length - 1) {
                          _onboardingPageController.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _dismissOnboarding();
                        }
                      },
                      child: Text(
                        _onboardingCurrentPage == slides.length - 1 ? _t('ob_finish') : _t('ob_next'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildMainScaffold(),
        if (_showOnboarding) _buildOnboardingCarousel(),
      ],
    );
  }

  Widget _buildMainScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _handleTitleTap,
          child: Text(_t('app_name'), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
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
                        if (_isChecking)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _statusMessage,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else if (_checkError != null)
                          InkWell(
                            onTap: _checkVersions,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _statusMessage,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.red,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _locale == 'nl' 
                                              ? 'Tik om opnieuw te proberen' 
                                              : 'Tap to retry',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.refresh, color: Colors.red),
                                ],
                              ),
                            ),
                          )
                        else if (_osfUpdateAvailable)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange[800]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _statusMessage,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _t('status_uptodate_full'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
    
                        if (_latestReleaseDate != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            "${_t('latest_release')}: ${DateFormat('yyyy-MM-dd HH:mm').format(_latestReleaseDate!)}",
                            style: TextStyle(color: Colors.grey[700], fontSize: 13),
                          ),
                        ],
                        
                        if (_isDownloading) ...[
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _progress,
                              backgroundColor: Colors.orange[100],
                              color: Colors.orange[800],
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text("${(_progress * 100).toStringAsFixed(1)}%", 
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800])),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                if (!_isDownloading) ...[
                    if (_isChecking)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          side: const BorderSide(color: Colors.grey, width: 2),
                          foregroundColor: Colors.grey,
                        ),
                        onPressed: null,
                        child: Text(
                          _locale == 'nl' ? 'Controleren op updates...' : 'Checking for updates...',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      )
                    else if (_checkError != null)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          side: const BorderSide(color: Colors.grey, width: 2),
                          foregroundColor: Colors.grey,
                        ),
                        onPressed: null,
                        child: Text(
                          _locale == 'nl' ? 'Fout bij update-controle' : 'Update check failed',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      )
                    else if (_osfUpdateAvailable)
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
                              Text("${_t('on_disk')}: ${DateFormat('yyyy-MM-dd HH:mm').format(_localOsfDate!)}", 
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
                      onPressed: _launchWebsiteUrl,
                      icon: const Icon(Icons.language, color: Colors.blue, size: 20),
                      label: Text(
                          _t('visit_website'), 
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)
                      ),
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
                    if (_showLogs)
                  Container(
                    margin: const EdgeInsets.only(top: 24),
                    padding: const EdgeInsets.all(16),
                    color: Colors.black.withOpacity(0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text("DEVELOPER TOOLS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove(_prefLastKnownRelease);
                            await prefs.remove(_prefBgScheduled);
                            _log("Update cache cleared.");
                            _checkVersions();
                          },
                          child: const Text("Clear Update Cache"),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () async {
                             try {
                               final file = File('$_targetDir/$OSF_FILENAME');
                               if (await file.exists()) {
                                 await file.delete();
                                 _log("Local OSF deleted.");
                                 _checkVersions();
                               } else {
                                 _log("No local OSF found to delete.");
                               }
                             } catch (e) {
                               _log("Delete error: $e");
                             }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], foregroundColor: Colors.red[900]),
                          child: const Text("Delete Local OSF (Force Update)"),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () async {
                             _log("Forcing notification...");
                             await _showUpdateNotification();
                          },
                          child: const Text("Force Notification (Test UI)"),
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 150,
                          child: ListView.builder(
                             itemCount: _logs.length,
                             itemBuilder: (ctx, i) => Text(_logs[i], style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
