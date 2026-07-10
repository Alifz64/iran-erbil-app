// نسخه: V_20260710_1422_FINAL_PERFECTION
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
    // تایمر پشتیبان برای جلوگیری از معطلی کاربر در اینترنت‌های بسیار ضعیف
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
            _injectBannerKiller(); 
          },
          onProgress: (int progress) {
            _injectBannerKiller(); 
            // اگر صفحه اصلی شما بالای ۹۰ درصد لود شد، اسپلش را بردار
            if (progress > 90 && _isLoading) {
              setState(() { _isLoading = false; });
              _timeoutTimer?.cancel();
            }
          },
          onPageFinished: (String url) {
            // 💡 حل قطعی صفحه سفید: برداشتن اسپلش تنها پس از رسیدن به دامنه محتوایی نهایی گوگل
            if (url.contains('script.googleusercontent.com')) {
              setState(() { _isLoading = false; });
              _timeoutTimer?.cancel();
            }
            _injectBannerKiller(); 
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

  // 💡 ابزار فوق پیشرفته MutationObserver برای ریشه‌کن کردن بنر به محض ساخته شدن در صفحه
  void _injectBannerKiller() {
    _controller.runJavaScript(r"""
      (function() {
        var styleId = 'anti-google-banner-style';
        if (!document.getElementById(styleId)) {
          var style = document.createElement('style');
          style.id = styleId;
          style.innerHTML = `
            .apps-share-space-banner-table, 
            .apps-share-space-banner,
            div[aria-label*="This application was created"], 
            div[aria-label*="not by Google"],
            iframe~table,
            body > table:first-child { 
              display: none !important; 
              visibility: hidden !important;
              height: 0 !important;
              opacity: 0 !important;
              pointer-events: none !important;
            }
            html, body { 
              margin: 0 !important; 
              padding: 0 !important; 
              top: 0 !important; 
            }
          `;
          (document.head || document.documentElement).appendChild(style);
        }
        
        var kill = function() {
          var target = document.querySelector('.apps-share-space-banner-table, .apps-share-space-banner, body > table:first-child');
          if (target) target.style.setProperty('display', 'none', 'important');
        };
        kill();
        
        if (window.BannerObserver) window.BannerObserver.disconnect();
        window.BannerObserver = new MutationObserver(kill);
        window.BannerObserver.observe(document.body || document.documentElement, { childList: true, subtree: true });
      })();
    """);
  }

  void _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _controller.loadRequest(initialUri);
      }
      _appLinks.uriLinkStream.listen((uri) {
        _controller.loadRequest(uri);
      });
    } catch (e) {
      debugPrint("Deep Link Error: $e");
    }
  }
  
  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 💡 محاسبه داینامیک برای تنظیم اندازه لوگوی اسپلش روی ۷۵٪ عرض صفحه
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
                      // اعمال اندازه جدید لوگو
                      Image.asset('assets/splash.png', width: splashWidth),
                      const SizedBox(height: 40),
                      const CircularProgressIndicator(color: Colors.blue),
                      const SizedBox(height: 25),
                      const Text(
                        'در حال دریافت و آماده‌سازی اطلاعات...',
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