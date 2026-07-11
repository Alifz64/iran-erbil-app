// نسخه: V_20260711_2020_FLUTTER_ERR_RESOLVER
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
            // 💡 جراحی هوشمند: به جای فیلتر کردن متنی، وضعیت فریم اصلی بررسی می‌شود
            // این کار باعث صید قطعی تمامی خطاهای عدم اتصال از جمله ERR_NAME_NOT_RESOLVED می‌شود
            if (error.isForMainFrame ?? true) {
              setState(() {
                _isLoading = false;
                _errorMessage = "اتصال اینترنت خود را بررسی کنید.";
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
  void _maximizeAppIframe() {
    _controller.runJavaScript(r"""
      (function() {
        var maximizeData = function() {
          var iframes = document.getElementsByTagName('iframe');
          if (iframes.length > 0) {
            for (var i = 0; i < iframes.length; i++) {
              var frame = iframes[i];
              frame.style.setProperty('position', 'fixed', 'important'); frame.style.setProperty('top', '0', 'important'); frame.style.setProperty('left', '0', 'important'); frame.style.setProperty('width', '100vw', 'important'); frame.style.setProperty('height', '100vh', 'important'); frame.style.setProperty('z-index', '999999', 'important'); frame.style.setProperty('border', 'none', 'important'); frame.style.setProperty('background-color', '#ffffff', 'important');
            }
          }
        };
        maximizeData();
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
                        const Icon(Icons.wifi_off, size: 70, color: Colors.orangeRed),
                        const SizedBox(height: 20),
                        const Text(
                          'ارتباط با سرور برقرار نشد!',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.blackd8),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 35),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            setState(() { _isLoading = true; _errorMessage = ''; });
                            _controller.loadRequest(Uri.parse(_defaultUrl));
                          },
                          child: const Text('تلاش مجدد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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