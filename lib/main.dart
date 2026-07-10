// نسخه: V_20260710_1835_FINAL_SAFE_PREVENT_WHITE_SCREEN
// ========================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ایران‌اربیل IranErbil',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WebViewScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({Key? key}) : super(key: key);

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  final _appLinks = AppLinks(); 
  
  bool _isLoading = true;
  String _errorMessage = '';
  Timer? _timeoutTimer;
  
  final String _defaultUrl = "https://script.google.com/macros/s/AKfycbyC4r6ETL4TpC3FQIMjDd2gJoTB5mijctOcHXLbkCV68aeCb0EKr5QHpzbJpcqE3BQv/exec";

  @override
  void initState() {
    super.initState();
    _initWebView();
    _initDeepLinks();
  }

  void _initWebView() {
    _timeoutTimer = Timer(const Duration(seconds: 14), () {
      if (mounted && _isLoading) {
        setState(() { _isLoading = false; });
      }
    });

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("Mozilla/5.0 (Linux; Android 13; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (!url.contains('script.googleusercontent.com')) {
              setState(() { _isLoading = true; _errorMessage = ''; });
            }
            _injectPerfectBannerKiller(); 
          },
          onProgress: (int progress) {
            _injectPerfectBannerKiller(); 
            // باز شدن اسپلش به محض رسیدن به لود نهایی فرانت‌آند شما
            if (progress == 100) {
              Future.delayed(const Duration(milliseconds: 600), () {
                if (mounted && _isLoading) {
                  setState(() { _isLoading = false; });
                  _timeoutTimer?.cancel();
                }
              });
            }
          },
          onPageFinished: (String url) {
            _injectPerfectBannerKiller();
            if (url.contains('script.googleusercontent.com')) {
              setState(() { _isLoading = false; });
              _timeoutTimer?.cancel();
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (error.description.contains('ERR_CONNECTION_REFUSED') || error.description.contains('Internet')) {
              setState(() {
                _isLoading = false;
                _errorMessage = error.description;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
            if (url.contains('t.me') || url.contains('wa.me') || url.contains('instagram.com')) {
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_defaultUrl));
  }

  // 💡 جراحی نهایی بنر: استفاده از پنهان‌سازی مطلق شیوه CSS بجای حذف فیزیکی المنت‌ها
  // این متد ۱۰۰٪ گارانتی می‌کند که هیچ داده‌ای از برنامه شما آسیب نخواهد دید.
  void _injectPerfectBannerKiller() {
    _controller.runJavaScript(r"""
      (function() {
        var styleId = 'perfect-nuke-google-banner-style';
        if (document.getElementById(styleId)) return;
        
        var style = document.createElement('style');
        style.id = styleId;
        style.innerHTML = `
          /* هدف‌گیری لیزری بنرهای فارسی و انگلیسی بدون اثر منفی روی داده‌های شیت */
          .apps-share-space-banner, 
          .apps-share-space-banner-table, 
          .apps-share-space-banner-container,
          body > table:first-of-type,
          div[aria-label*="This application was created"], 
          div[aria-label*="not by Google"],
          div[aria-label*="این برنامه را کاربر"],
          div[aria-label*="Google Apps Script"],
          td[style*="background-color: #e2eaf8"],
          td[style*="background-color:#e2eaf8"] { 
            display: none !important; 
            visibility: hidden !important;
            opacity: 0 !important;
            height: 0 !important;
            max-height: 0 !important;
            margin: 0 !important;
            padding: 0 !important;
            pointer-events: none !important;
            overflow: hidden !important;
          }
          html, body { 
            margin: 0 !important; 
            padding: 0 !important; 
            top: 0 !important; 
          }
        `;
        (document.head || document.documentElement).appendChild(style);
      })();
    """);
  }

  // 💡 مدیریت هوشمند و کاملاً مستقل پیوندهای عمیق (Deep Linking) تلگرام
  void _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingLink(initialUri);
      }
      _appLinks.uriLinkStream.listen((uri) {
        _handleIncomingLink(uri);
      });
    } catch (e) {
      debugPrint("Deep Link Error: $e");
    }
  }

  void _handleIncomingLink(Uri uri) {
    if (uri.scheme == 'iranerbil') {
      final token = uri.queryParameters['token'];
      if (token != null) {
        final targetUrl = "$_defaultUrl?token=$token";
        _controller.loadRequest(Uri.parse(targetUrl));
      } else {
        _controller.loadRequest(Uri.parse(_defaultUrl));
      }
    }
  }
  
  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // تنظیم دقیق سایز اسپلش روی ۷۵٪ عرض صفحه گوشی کاربر
    double splashWidth = MediaQuery.of(context).size.width * 0.75;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            
            if (_isLoading)
              Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/splash.png', width: splashWidth),
                      const SizedBox(height: 40),
                      const CircularProgressIndicator(color: Colors.blue),
                      const SizedBox(height: 25),
                      const Text(
                        'در حال دریافت اطلاعات...',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              ),
              
            if (_errorMessage.isNotEmpty)
              Container(
                color: Colors.white,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, size: 60, color: Colors.red),
                        const SizedBox(height: 20),
                        Text(
                          'ارتباط با سرور برقرار نشد!\n$_errorMessage',
                          style: const TextStyle(fontSize: 16, color: Colors.red),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.ltr,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() { _isLoading = true; _errorMessage = ''; });
                            _controller.reload();
                          },
                          child: const Text('تلاش مجدد'),
                        )
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}