// نسخه: V_20260710_1910_IFRAME_FULLSCREEN_FIX
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
    // تایمر پشتیبان برای خروج از اسپلش در صورت کندی اینترنت
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
            _maximizeAppIframe(); 
          },
          onProgress: (int progress) {
            _maximizeAppIframe(); 
            if (progress > 90) {
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (mounted && _isLoading) {
                  setState(() { _isLoading = false; });
                  _timeoutTimer?.cancel();
                }
              });
            }
          },
          onPageFinished: (String url) {
            _maximizeAppIframe();
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

  // 💡 استراتژیِ طلایی: تمام‌صفحه کردنِ قابِ داده‌ها (Iframe) روی سایر اجزای گوگل
  // این روش ۱۰۰٪ ایمن است چون به جای پاک کردن چیزی، فقط برنامه شما را بزرگ می‌کند تا بنر زیر آن مخفی شود.
  void _maximizeAppIframe() {
    _controller.runJavaScript(r"""
      (function() {
        var maximizeData = function() {
          var iframes = document.getElementsByTagName('iframe');
          if (iframes.length > 0) {
            for (var i = 0; i < iframes.length; i++) {
              var frame = iframes[i];
              frame.style.setProperty('position', 'fixed', 'important');
              frame.style.setProperty('top', '0', 'important');
              frame.style.setProperty('left', '0', 'important');
              frame.style.setProperty('width', '100vw', 'important');
              frame.style.setProperty('height', '100vh', 'important');
              frame.style.setProperty('z-index', '999999', 'important');
              frame.style.setProperty('border', 'none', 'important');
              frame.style.setProperty('background-color', '#ffffff', 'important');
            }
          }
        };
        
        // اجرای فوری
        maximizeData();
        
        // اجرای مداوم در پس‌زمینه تا در صورت لود شدنِ تأخیریِ گوگل، فوراً قاب را بزرگ کند
        if (!window.iframeMaximizerInterval) {
          window.iframeMaximizerInterval = setInterval(maximizeData, 500);
        }
      })();
    """);
  }

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
    // لوگوی اسپلش دقیقاً ۷۵٪ عرض صفحه را پر می‌کند
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