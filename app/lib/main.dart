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
import 'package:workmanager/workmanager.dart' hide TaskStatus;
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
  await notificationsPlugin.initialize(settings: initSettings);

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'brombrom_updates',
    'BromBrom Kaartmeldingen',
    channelDescription: 'Meldingen wanneer er een nieuwe BromBrom-kaart klaarstaat',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/launcher_icon',
  );

  const NotificationDetails platformDetails =
      NotificationDetails(android: androidDetails);

  await notificationsPlugin.show(
    id: 0,
    title: 'BromBrom: Nieuwe kaart beschikbaar! 🗺️',
    body: 'Open de app om je routekaart bij te werken.',
    notificationDetails: platformDetails,
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
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Slate 50
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE65100), // Deep warm orange
          primary: const Color(0xFFE65100),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A), // Slate 900
        ),
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
  String _statusMessage = '';
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Slate 100
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _saveLocale(isNL ? 'en' : 'nl'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isNL ? "🇳🇱" : "🇬🇧",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 4),
              Text(
                isNL ? "NL" : "EN",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
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
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
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
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED), // Orange 50
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              wasUpdate ? Icons.update : Icons.map_outlined,
                              color: const Color(0xFFE65100),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              wasUpdate ? _t('osf_dialog_title_update') : _t('osf_dialog_title'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                                fontSize: 19,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _t(wasUpdate ? 'osf_dialog_p1_update' : 'osf_dialog_p1'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...(() {
                        final steps = wasUpdate
                            ? ['osf_dialog_step1_update', 'osf_dialog_step2_update', 'osf_dialog_step3_update', 'osf_dialog_step4_update']
                            : ['osf_dialog_step1', 'osf_dialog_step2', 'osf_dialog_step3', 'osf_dialog_step4', 'osf_dialog_step5', 'osf_dialog_step6', 'osf_dialog_step7'];
                        return <Widget>[
                          for (int i = 0; i < steps.length; i++) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Text(
                                      "${i + 1}",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _t(steps[i]).replaceFirst(RegExp(r'^\d+\.\s*'), ''),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF334155),
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (!wasUpdate) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFFEDD5)),
                              ),
                              child: Text(
                                _t('osf_dialog_warning'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFC2410C),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ];
                      })(),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE65100),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(
                          _t('osf_dialog_btn'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openOsfInOsmAnd(filePath);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () => _launchUrl('https://brombrom.bulligan.com/#visual-guide'),
                        icon: const Icon(Icons.menu_book_outlined, size: 18, color: Color(0xFF1D4ED8)),
                        label: Text(
                          _t('visit_website'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D4ED8),
                            fontSize: 13,
                          ),
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
  
  void _showHelpModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.support_agent_outlined,
                              color: Color(0xFFE65100),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _t('help_dialog_title'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Card 1: OsmAnd profile check
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFEDD5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _t('troubleshoot_title'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFFC2410C),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _t('troubleshoot_desc'),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'assets/images/brombrom_osmand_profile.webp',
                                  fit: BoxFit.contain,
                                  height: 170,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_osmandInstalled) ...[
                        const SizedBox(height: 14),
                        // Reinstall action
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            foregroundColor: const Color(0xFF475569),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            backgroundColor: const Color(0xFFF8FAFC),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _forceReinstall();
                          },
                          icon: const Icon(Icons.build_circle_outlined, size: 18, color: Color(0xFF475569)),
                          label: Text(
                            _t('btn_reinstall_help'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      // Card 2: Visual Guide Link (Vertical item with distinct styling)
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _launchUrl('https://brombrom.bulligan.com/#visual-guide'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF), // Blue 50
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.menu_book_outlined, color: Color(0xFF1D4ED8), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _t('visit_website'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1D4ED8),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Color(0xFF1D4ED8), size: 13),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Card 3: FAQ Link (Vertical item with distinct styling)
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _launchUrl('https://brombrom.bulligan.com/#faq'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4), // Green 50
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFDCFCE7)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.question_answer_outlined, color: Color(0xFF15803D), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _t('faq_title'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF15803D),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Color(0xFF15803D), size: 13),
                            ],
                          ),
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
            padding: const EdgeInsets.symmetric(vertical: 22),
            backgroundColor: const Color(0xFFE65100),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            shadowColor: const Color(0xFFE65100).withOpacity(0.3),
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
          icon: const Icon(Icons.download_rounded, size: 26),
          label: Text(
            _t('install_osmand'),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFEDD5)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFFE65100), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _t('osmand_required_desc'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9A3412),
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
          child: Text(
            _t('app_name'),
            style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
        ),
        actions: [
          _buildLanguageSwitcher(),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFE65100),
        onRefresh: _checkVersions,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                (() {
                  if (_isDownloading) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(color: Color(0xFFE65100), strokeWidth: 3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _statusMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _progress,
                                backgroundColor: const Color(0xFFFFEDD5),
                                color: const Color(0xFFE65100),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${(_progress * 100).toStringAsFixed(1)}%",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (_isChecking) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: Color(0xFFE65100), strokeWidth: 3),
                            const SizedBox(height: 16),
                            Text(
                              _t('status_checking'),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF475569)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (_checkError != null) {
                    return ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: const Color(0xFFFFF7ED),
                        foregroundColor: const Color(0xFFC2410C),
                        side: const BorderSide(color: Color(0xFFFFEDD5), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: _checkVersions,
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        _t('check_failed_retry'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (!_osmandInstalled) {
                    return _buildInstallOsmAndAction();
                  }

                  // Hero primary Navigate action (Big, bold, inviting)
                  return ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      backgroundColor: const Color(0xFFE65100), // Rich warm orange
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      shadowColor: const Color(0xFFE65100).withOpacity(0.4),
                    ),
                    onPressed: () => _openOsmAnd(),
                    icon: const Icon(Icons.navigation_rounded, size: 26),
                    label: Text(
                      _t('btn_navigate'), // "Navigeren" / "Navigate"
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                  );
                })(),
                const SizedBox(height: 14),
                // Dedicated Secondary Troubleshooting action
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _showHelpModal,
                  icon: const Icon(Icons.help_outline_rounded, color: Color(0xFFE65100), size: 20),
                  label: Text(
                    _t('help_dialog_title'),
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Happy path support: Buy Me A Coffee card
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB), // Amber 50
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _launchUrl('https://buymeacoffee.com/brombrom'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.coffee_rounded, color: Color(0xFF92400E), size: 22),
                          const SizedBox(width: 10),
                          Text(
                            _t('buy_coffee'),
                            style: const TextStyle(
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Calm, quiet status reassurance at bottom (No duplicate external links)
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _t('map_uptodate'),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
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
          ),
        ),
      ),
    );
  }
}
