import 'dart:async';
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
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'translations.dart';

// ── Background Task Constants ──
const String _bgTaskName = "com.brombrom.updateCheck";
const String _bgTaskTag = "brombrom_update_check";
const String _releaseApiUrl = "https://api.github.com/repos/tbulligan/brombrom/releases/latest";
const String _prefLastKnownRelease = "last_known_release_date";
const String _prefBgScheduled = "bg_task_scheduled";
const String _prefOnboardingSeen = "onboarding_seen";

// ── Shared Release Metadata Helper Class ──
class GithubReleaseInfo {
  final DateTime latestDate;
  final DateTime? remoteOsfDate;
  final Map<String, String> downloadUrls;

  GithubReleaseInfo({
    required this.latestDate,
    required this.remoteOsfDate,
    required this.downloadUrls,
  });

  static Future<GithubReleaseInfo> fetch(String apiUrl) async {
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
    );
    if (response.statusCode != 200) {
      throw Exception("API Error ${response.statusCode}");
    }

    final data = jsonDecode(response.body);
    final String publishedAt = data['published_at'] ?? '';
    if (publishedAt.isEmpty) {
      throw Exception("Missing published_at");
    }

    DateTime latestDate = DateTime.parse(publishedAt);
    DateTime? remoteOsfDate;
    final Map<String, String> downloadUrls = {};

    final List assets = data['assets'] ?? [];
    for (var asset in assets) {
      final String name = asset['name'] ?? '';
      final String? updatedAtStr = asset['updated_at'];
      if (updatedAtStr == null || name.isEmpty) continue;
      final DateTime updatedAt = DateTime.parse(updatedAtStr);

      if (asset['browser_download_url'] != null) {
        downloadUrls[name] = asset['browser_download_url'];
      }

      if (updatedAt.isAfter(latestDate)) {
        latestDate = updatedAt;
      }

      if (name == "BromBrom.osf") {
        remoteOsfDate = updatedAt;
      }
    }

    return GithubReleaseInfo(
      latestDate: latestDate,
      remoteOsfDate: remoteOsfDate,
      downloadUrls: downloadUrls,
    );
  }
}

// ── Background Task Handler (runs in a separate isolate) ──
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // 1. Fetch latest release info from GitHub
      final release = await GithubReleaseInfo.fetch(_releaseApiUrl);
      final String latestDateStr = release.latestDate.toIso8601String();

      // 2. Compare with last known release date
      final prefs = await SharedPreferences.getInstance();
      final String? lastKnown = prefs.getString(_prefLastKnownRelease);

      if (lastKnown != null && latestDateStr != lastKnown) {
        // New release detected! Fire a notification.
        final remoteDate = release.latestDate;
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
  String? _pendingImportFilePath;
  bool _pendingImportWasUpdate = false;
  
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
  
  // PACKAGE CHECK METHOD CHANNEL
  static const platform = MethodChannel('com.brombrom.app/package_check');
  bool _osmandInstalled = false;
  bool _notificationPermissionGranted = false;
  
  // CACHED URLs
  final Map<String, String> _downloadUrls = {};

  String _t(String key) => translations[_locale]?[key] ?? key;

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
      await _checkOnboardingRequirements();
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
    }

    if (_targetDir == null) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        _targetDir = dir.path;
      } catch (e) {
        _log("Failed to get app documents dir: $e");
      }
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

  /// Schedule a daily background task to check for updates.
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

  Future<bool> _isOsmAndInstalled() async {
    if (!Platform.isAndroid) return true;
    try {
      final bool isOsmAnd = await platform.invokeMethod('isPackageInstalled', {'packageName': 'net.osmand'});
      if (isOsmAnd) return true;
      final bool isOsmAndPlus = await platform.invokeMethod('isPackageInstalled', {'packageName': 'net.osmand.plus'});
      return isOsmAndPlus;
    } catch (e) {
      _log("Error checking package: $e");
      return false;
    }
  }

  Future<void> _checkOnboardingRequirements() async {
    final osmandInstalled = await _isOsmAndInstalled();
    final notificationGranted = await Permission.notification.isGranted;
    if (mounted) {
      final bool wasNotInstalled = !_osmandInstalled;
      setState(() {
        _osmandInstalled = osmandInstalled;
        _notificationPermissionGranted = notificationGranted;
      });
      if (wasNotInstalled && osmandInstalled && _showOnboarding && _onboardingCurrentPage == 1) {
        _onboardingPageController.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
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
      _checkOnboardingRequirements().then((_) {
        _checkVersions();
      });
    }
  }

  Future<void> _checkVersions() async {
    await _checkOnboardingRequirements();
    setState(() {
      _isChecking = true;
      _checkError = null;
      _statusMessage = _t('status_checking');
    });
    
    try {
      final release = await GithubReleaseInfo.fetch(RELEASE_API);
      
      _downloadUrls.clear();
      _downloadUrls.addAll(release.downloadUrls);
      
      _latestReleaseDate = release.latestDate;
      _remoteOsfDate = release.remoteOsfDate;
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

      if (_osfUpdateAvailable && _osmandInstalled && !_isDownloading) {
        _log("Auto-starting download of $OSF_FILENAME");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _downloadFile(OSF_FILENAME);
        });
      }

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
    final bool wasUpdate = _localOsfDate != null;
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
          if (_showOnboarding) {
            _pendingImportFilePath = file.path;
            _pendingImportWasUpdate = wasUpdate;
            _log("Onboarding is active, deferred OSF instructions dialog show.");
          } else {
            _showOsfInstructionsDialog(file.path, wasUpdate);
          }
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

  Future<void> _showOsfInstructionsDialog(String filePath, bool wasUpdate) async {
    if (!mounted) return;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            wasUpdate ? Icons.update : Icons.cloud_download,
                            color: Colors.orange[800],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              wasUpdate ? _t('osf_dialog_title_update') : _t('osf_dialog_title'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[850],
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...(() {
                        final stepStyle = TextStyle(fontSize: 14, color: Colors.grey[800]);
                        final steps = wasUpdate
                            ? ['osf_dialog_step1_update', 'osf_dialog_step2_update', 'osf_dialog_step3_update', 'osf_dialog_step4_update']
                            : ['osf_dialog_step1', 'osf_dialog_step2', 'osf_dialog_step3', 'osf_dialog_step4', 'osf_dialog_step5', 'osf_dialog_step6', 'osf_dialog_step7'];
                        return <Widget>[
                          Text(_t(wasUpdate ? 'osf_dialog_p1_update' : 'osf_dialog_p1'), style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800], fontSize: 15)),
                          const SizedBox(height: 12),
                          for (final key in steps) ...[
                            Text(_t(key), style: stepStyle),
                            const SizedBox(height: 6),
                          ],
                          if (!wasUpdate) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Text(
                                _t('osf_dialog_warning'),
                                style: TextStyle(fontSize: 13, color: Colors.orange[900], fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ];
                      })(),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 2,
                        ),
                        child: Text(_t('osf_dialog_btn'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openOsfInOsmAnd(filePath);
                        },
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _launchUrl('https://brombrom.bulligan.com/#visual-guide'),
                        icon: const Icon(Icons.menu_book, size: 18, color: Colors.blue),
                        label: Text(
                          _locale == 'nl' ? 'Visuele Gids' : 'Visual Guide',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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

  Future<void> _openOsmAnd() async {
    try {
      final isOsmAndPlus = await platform.invokeMethod('isPackageInstalled', {'packageName': 'net.osmand.plus'});
      final packageName = isOsmAndPlus ? 'net.osmand.plus' : 'net.osmand';
      await platform.invokeMethod('openPackage', {'packageName': packageName});
    } catch (e) {
      _log("Could not open OsmAnd: $e");
    }
  }

  Future<void> _forceReinstall() async {
    try {
      final File osfFile = File('$_targetDir/$OSF_FILENAME');
      if (await osfFile.exists()) {
        await osfFile.delete();
        _log("Local OSF file deleted for force reinstall.");
      }
      setState(() {
        _localOsfDate = null;
        _osfUpdateAvailable = true;
      });
      await _checkVersions();
    } catch (e) {
      _log("Error during force reinstall: $e");
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

  void _launchUrl(String url) async {
    try {
      await AndroidIntent(action: 'action_view', data: url).launch();
    } catch (e) {
      _log("Could not launch $url: $e");
    }
  }

  Widget _buildInstallOsmAndAction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 24),
            backgroundColor: Colors.orange[800],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
          ),
          onPressed: () async {
            try {
              final AndroidIntent intent = AndroidIntent(
                action: 'action_view',
                data: 'https://play.google.com/store/apps/details?id=net.osmand',
              );
              await intent.launch();
            } catch (e) {
              _log("Could not launch Play Store: $e");
            }
          },
          icon: const Icon(Icons.download_outlined, size: 24),
          label: Text(
            _t('install_osmand'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.orange[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orange[200]!, width: 1.5),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[800]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _t('osmand_required_desc'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _dismissOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefOnboardingSeen, true);
    if (mounted) {
      setState(() => _showOnboarding = false);
      if (_pendingImportFilePath != null) {
        final path = _pendingImportFilePath!;
        final wasUpdate = _pendingImportWasUpdate;
        _pendingImportFilePath = null;
        Future.delayed(const Duration(milliseconds: 300), () {
          _showOsfInstructionsDialog(path, wasUpdate);
        });
      }
    }
  }



  Widget _buildOnboardingCarousel() {
    final Color orange = Colors.orange[800]!;

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
      setState(() => _locale = newLang);
      SharedPreferences.getInstance().then((p) => p.setString('language_code', newLang));
    }

    return Material(
      color: Colors.black.withOpacity(0.92),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // Top bar: language toggle (left)
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
                      _locale == 'nl' ? '🇬🇧  EN' : '🇳🇱  NL',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  // Skip ("Not now") button removed to make onboarding compulsory
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _onboardingPageController,
                  physics: const PageScrollPhysics(),
                  itemCount: _osmandInstalled ? slides.length : 2,
                  onPageChanged: (i) {
                    setState(() => _onboardingCurrentPage = i);
                  },
                  itemBuilder: (context, index) {
                    final slide = slides[index];
                    return Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
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
                                (() {
                                  if (index == 1) {
                                    final bool isInstalled = _osmandInstalled;
                                    return OutlinedButton(
                                      onPressed: isInstalled ? null : () async {
                                        AndroidIntent(
                                          action: 'action_view',
                                          data: 'https://play.google.com/store/apps/details?id=net.osmand',
                                        ).launch();
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        disabledForegroundColor: Colors.greenAccent,
                                        side: BorderSide(color: isInstalled ? Colors.greenAccent : Colors.white54),
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      ),
                                      child: Text(isInstalled ? _t('ob_osmand_installed_checkmark') : slide['btn']!),
                                    );
                                  } else if (index == 2) {
                                    final bool isGranted = _notificationPermissionGranted;
                                    return OutlinedButton(
                                      onPressed: isGranted ? null : () async {
                                        await _requestNotificationPermission();
                                        await _checkOnboardingRequirements();
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        disabledForegroundColor: Colors.greenAccent,
                                        side: BorderSide(color: isGranted ? Colors.greenAccent : Colors.white54),
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      ),
                                      child: Text(isGranted ? _t('ob_notifications_enabled') : slide['btn']!),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                })(),
                              ]
                            ],
                          ),
                        ),
                      ),
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
                    disabledBackgroundColor: Colors.white24,
                    disabledForegroundColor: Colors.white54,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (() {
                    if (_onboardingCurrentPage == 0) {
                      return () {
                        _onboardingPageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      };
                    } else if (_onboardingCurrentPage == 1) {
                      return _osmandInstalled ? () {
                        _onboardingPageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      } : null;
                    } else if (_onboardingCurrentPage == 2) {
                      return _notificationPermissionGranted ? () {
                        _dismissOnboarding();
                      } : null;
                    }
                    return null;
                  })(),
                  child: Text(
                    (() {
                      if (_onboardingCurrentPage == 2) {
                        return _notificationPermissionGranted 
                            ? _t('ob_finish') 
                            : _t('ob_notification_permission_required');
                      } else if (_onboardingCurrentPage == 1) {
                        return _osmandInstalled 
                            ? _t('ob_next') 
                            : _t('ob_install_osmand_required');
                      }
                      return _t('ob_next');
                    })(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
                (() {
                  if (_isDownloading) {
                    return Card(
                      color: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(color: Colors.orange),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _statusMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _progress,
                                backgroundColor: Colors.orange[100],
                                color: Colors.orange[800],
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${(_progress * 100).toStringAsFixed(1)}%",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (_isChecking) {
                    return Card(
                      color: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: Colors.orange),
                            const SizedBox(height: 16),
                            Text(
                              _locale == 'nl' ? 'Controleren op updates...' : 'Checking for updates...',
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (_checkError != null) {
                    return ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        backgroundColor: Colors.orange[50],
                        foregroundColor: Colors.orange[800],
                        side: BorderSide(color: Colors.orange[200]!, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _checkVersions,
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        _locale == 'nl' ? 'Fout bij controle (Tik om te herstarten)' : 'Check failed (Tap to retry)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (!_osmandInstalled) {
                    return _buildInstallOsmAndAction();
                  }

                  // Show single Navigate button
                  return ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      backgroundColor: Colors.orange[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    onPressed: () => _openOsmAnd(),
                    icon: const Icon(Icons.navigation_outlined, size: 24),
                    label: Text(
                      _t('btn_navigate'), // "Navigeren" / "Navigate"
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  );
                })(),
                const SizedBox(height: 24),
                if (_osmandInstalled) ...[
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: const Icon(Icons.help_outline, color: Colors.orange),
                        title: Text(
                          _t('troubleshoot_title'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _t('troubleshoot_desc'),
                                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'assets/images/brombrom_osmand_profile.webp',
                                      fit: BoxFit.contain,
                                      height: 220,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Support Project & Website Links
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_osmandInstalled) ...[
                      TextButton(
                        onPressed: _forceReinstall,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Icon(Icons.build_outlined, color: Colors.grey, size: 20),
                              ),
                              const WidgetSpan(child: SizedBox(width: 8)),
                              TextSpan(
                                text: _t('btn_reinstall_help'),
                                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextButton(
                      onPressed: () => _launchUrl('https://brombrom.bulligan.com/#visual-guide'),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Icon(Icons.language, color: Colors.blue, size: 20),
                            ),
                            const WidgetSpan(child: SizedBox(width: 8)),
                            TextSpan(
                              text: _t('visit_website'),
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _launchUrl('https://brombrom.bulligan.com/#faq'),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Icon(Icons.help_outline, color: Colors.blue, size: 20),
                            ),
                            const WidgetSpan(child: SizedBox(width: 8)),
                            TextSpan(
                              text: _t('faq_title'),
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _launchUrl('https://buymeacoffee.com/brombrom'),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Icon(Icons.coffee, color: Colors.brown, size: 20),
                            ),
                            const WidgetSpan(child: SizedBox(width: 8)),
                            TextSpan(
                              text: _t('buy_coffee'),
                              style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
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
                  ),
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
