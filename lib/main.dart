import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

const String kTargetUrl = 'https://dbm.caritukang.pro';
const String kAppName = 'Dewa Bangun Mandiri';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations and status bar style
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF002299),
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const DbmApp());
}

class DbmApp extends StatelessWidget {
  const DbmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF002299),
          primary: const Color(0xFF002299),
          secondary: const Color(0xFFE60000),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  String _statusMessage = 'Mempersiapkan izin Kamera & Lokasi...';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      await _requestInitialPermissions();
    } catch (e) {
      debugPrint('Permission init error: $e');
    }

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const WebViewScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Future<void> _requestInitialPermissions() async {
    // Request Camera, Microphone (for video capture if needed), Location, and Storage/Photos
    await [
      Permission.camera,
      Permission.microphone,
      Permission.locationWhenInUse,
      Permission.photos,
    ].request();

    // Ensure GPS service is checked
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      setState(() {
        _statusMessage = 'Pastikan GPS/Lokasi aktif untuk fitur absensi & peta';
      });
    } else if (mounted) {
      setState(() {
        _statusMessage = 'Menghubungkan ke dbm.caritukang.pro...';
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 190,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'DEWA BANGUN MANDIRI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF002299),
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'dbm.caritukang.pro',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 36),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xFFE60000),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  final GlobalKey _webViewKey = GlobalKey();
  InAppWebViewController? _webViewController;
  PullToRefreshController? _pullToRefreshController;

  double _progress = 0;
  bool _hasError = false;
  String _errorMessage = '';

  final InAppWebViewSettings _settings = InAppWebViewSettings(
    isInspectable: kDebugMode,
    javaScriptEnabled: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    geolocationEnabled: true,
    allowFileAccessFromFileURLs: true,
    allowUniversalAccessFromFileURLs: true,
    allowFileAccess: true,
    allowContentAccess: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    useOnDownloadStart: true,
    useShouldOverrideUrlLoading: true,
    supportMultipleWindows: true,
    javaScriptCanOpenWindowsAutomatically: true,
    mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
    userAgent:
        'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36 DBMApp/1.0',
  );

  @override
  void initState() {
    super.initState();
    _pullToRefreshController = kIsWeb
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(
              color: const Color(0xFF002299),
            ),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                _webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                final url = await _webViewController?.getUrl();
                if (url != null) {
                  _webViewController?.loadUrl(
                    urlRequest: URLRequest(url: url),
                  );
                }
              }
            },
          );
  }

  /// Ensures Camera and Location permissions are granted at runtime when requested by WebView.
  Future<bool> _ensureLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      status = await Permission.locationWhenInUse.request();
    }
    if (!status.isGranted) {
      if (mounted) {
        _showPermissionSnackBar(
          'Izin Lokasi diperlukan untuk fitur absensi/peta. Silakan aktifkan di Pengaturan.',
        );
      }
      return false;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('GPS belum aktif. Mohon nyalakan Lokasi/GPS Anda.'),
          action: SnackBarAction(
            label: 'Buka GPS',
            onPressed: () => Geolocator.openLocationSettings(),
          ),
        ),
      );
    }
    return true;
  }

  Future<bool> _ensureCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    if (!status.isGranted && mounted) {
      _showPermissionSnackBar(
        'Izin Kamera diperlukan untuk mengambil foto. Silakan aktifkan di Pengaturan.',
      );
      return false;
    }
    return true;
  }

  void _showPermissionSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Pengaturan',
          onPressed: openAppSettings,
        ),
      ),
    );
  }

  bool _isExternalUrl(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();

    // Non-http schemes (tel:, mailto:, whatsapp:, intent:, geo:, etc.)
    if (!['http', 'https', 'file', 'chrome', 'data', 'javascript', 'about']
        .contains(scheme)) {
      return true;
    }

    // Common external deep links (WhatsApp, Google Maps)
    if (host.contains('wa.me') ||
        host.contains('api.whatsapp.com') ||
        host.contains('maps.app.goo.gl') ||
        host.contains('maps.google.com') ||
        (host.contains('google.com') && uri.path.startsWith('/maps'))) {
      return true;
    }

    return false;
  }

  Future<void> _launchExternal(Uri uri) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka link: ${uri.toString()}')),
        );
      }
    } catch (e) {
      debugPrint('Failed to launch $uri: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_webViewController != null && await _webViewController!.canGoBack()) {
          await _webViewController!.goBack();
        } else if (context.mounted) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Keluar Aplikasi?'),
              content: const Text(
                'Apakah Anda yakin ingin keluar dari aplikasi Dewa Bangun Mandiri?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Keluar'),
                ),
              ],
            ),
          );
          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                key: _webViewKey,
                initialUrlRequest: URLRequest(url: WebUri(kTargetUrl)),
                initialSettings: _settings,
                pullToRefreshController: _pullToRefreshController,
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    _hasError = false;
                  });
                },
                onProgressChanged: (controller, progress) {
                  if (progress == 100) {
                    _pullToRefreshController?.endRefreshing();
                  }
                  setState(() {
                    _progress = progress / 100;
                  });
                },
                onLoadStop: (controller, url) async {
                  _pullToRefreshController?.endRefreshing();
                },
                onReceivedError: (controller, request, error) {
                  _pullToRefreshController?.endRefreshing();
                  // Only show full-page error if the main frame failed to load
                  if (request.isForMainFrame == true) {
                    setState(() {
                      _hasError = true;
                      _errorMessage = error.description;
                    });
                  }
                },
                // Grant Camera / Microphone permissions requested by WebRTC / getUserMedia
                onPermissionRequest: (controller, request) async {
                  final resources = request.resources;
                  if (resources.contains(PermissionResourceType.CAMERA) ||
                      resources.contains(
                          PermissionResourceType.CAMERA_AND_MICROPHONE)) {
                    await _ensureCameraPermission();
                  }
                  if (resources.contains(PermissionResourceType.MICROPHONE)) {
                    await Permission.microphone.request();
                  }
                  return PermissionResponse(
                    resources: resources,
                    action: PermissionResponseAction.GRANT,
                  );
                },
                // Grant HTML5 Geolocation permission (navigator.geolocation)
                onGeolocationPermissionsShowPrompt: (controller, origin) async {
                  final granted = await _ensureLocationPermission();
                  return GeolocationPermissionShowPromptResponse(
                    origin: origin,
                    allow: granted,
                    retain: true,
                  );
                },
                // Handle external links (WhatsApp, Maps, Tel, Mailto, etc.)
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final uri = navigationAction.request.url;
                  if (uri != null && _isExternalUrl(uri)) {
                    await _launchExternal(uri);
                    return NavigationActionPolicy.CANCEL;
                  }
                  return NavigationActionPolicy.ALLOW;
                },
                // Handle file downloads (PDF, Excel, Images, etc.)
                onDownloadStartRequest: (controller, downloadRequest) async {
                  final url = downloadRequest.url;
                  await _launchExternal(url);
                },
              ),

              // Top loading progress bar
              if (_progress < 1.0 && !_hasError)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 3,
                    backgroundColor: Colors.transparent,
                    color: const Color(0xFFE60000),
                  ),
                ),

              // Offline / Error Fallback Screen
              if (_hasError)
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  height: double.infinity,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 140,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Gagal Memuat Halaman',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF002299),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Pastikan koneksi internet Anda aktif untuk mengakses dbm.caritukang.pro.\n($_errorMessage)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF002299),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                          });
                          _webViewController?.loadUrl(
                            urlRequest: URLRequest(url: WebUri(kTargetUrl)),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Muat Ulang'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
