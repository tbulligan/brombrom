import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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

  /* New State Variables */
  bool _osmandInstalled = true;

  @override
  void initState() {
    super.initState();
    _checkSystemState();
  }

  Future<void> _checkSystemState() async {
    await _checkForUpdates();
    await _checkOsmAndInstalled();
  }

  Future<void> _checkOsmAndInstalled() async {
    // Basic check using package manager via intent
    // Note: On Android 11+ this requires <queries> in AndroidManifest (which we added)
    try {
      final AndroidIntent intent = AndroidIntent(
        action: 'action_view',
        package: 'net.osmand',
        componentName: 'net.osmand.plus.MainActivity'
      );
      // We can't easily check 'isInstalled' with android_intent_plus directly without a plugin like device_apps
      // But we can try to launch a query or just assume true for MVP. 
      // BETTER MVP: Just provide a link to Play Store if the user says "Help"
      // For now, let's keep it simple: Add a button to "Get OsmAnd"
    } catch (_) {}
  }
  
  void _launchOsmAndStore() {
    const intent = AndroidIntent(
      action: 'action_view',
      data: 'market://details?id=net.osmand',
    );
    intent.launch();
  }

  /* ... Keep existing methods (_checkForUpdates, _downloadAndInstall, _openInOsmAnd) ... */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Cleaner background
      appBar: AppBar(
        title: const Text('BromBrom Manager'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Logo Section
              Center(
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
                    image: DecorationImage(
                      image: AssetImage('assets/logos/brombrom-logo.jpg'), // We will move the logo here
                      fit: BoxFit.cover
                    )
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 2. Status Card (Cleaner Typography)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        _updateAvailable ? "Nieuwe update beschikbaar" : "Je bent helemaal bij",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _updateAvailable ? Colors.orange[800] : Colors.green[700],
                        ),
                      ),
                      Text(
                        _updateAvailable ? "New update available" : "System up to date",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic
                        ),
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildVersionInfo("Geïnstalleerd", _localVersion ?? "-"),
                          _buildVersionInfo("Nieuwste", _latestVersion ?? "..."),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 3. Action Buttons
              if (_isDownloading)
                Column(
                  children: [
                    LinearProgressIndicator(value: _progress, minHeight: 8),
                    const SizedBox(height: 8),
                    Text("${(_progress * 100).toInt()}%", style: TextStyle(color: Colors.grey[700])),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: _updateAvailable ? _downloadAndInstall : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 3,
                  ),
                  child: const Text(
                    "UPDATE KAART  /  BIJWERKEN",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                ),
                
              const SizedBox(height: 16),
              
              // Secondary Options
              if (!_updateAvailable && !_isDownloading)
                OutlinedButton(
                  onPressed: _downloadAndInstall,
                  child: const Text("Herinstalleer (Force Re-install)"),
                ),
                
              const SizedBox(height: 24),
              TextButton.icon(
                icon: const Icon(Icons.download),
                label: const Text("Download OsmAnd (Play Store)"),
                onPressed: _launchOsmAndStore,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionInfo(String label, String version) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(version, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
