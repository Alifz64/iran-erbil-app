// نسخه: V_20260710_1215_BANNER_PERMANENT_REMOVAL
// ========================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ایران اربیل',
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
  
  bool _isLoading = true;
  String _errorMessage = '';
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    
    _timeoutTimer = Timer(const Duration(seconds: 15), () {
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
            setState(() { _isLoading = true; _errorMessage = ''; });
          },
          onPageFinished: (String url) {
            if (url.contains('script.googleusercontent.com') || url.contains('exec')) {
              setState(() { _isLoading = false; });
              _timeoutTimer?.cancel();
            }

            // 💡 جراحی طلایی: اجرای لوپ مداوم برای شکار و حذف بنر گوگل به محض زاییده شدن در DOM
            _controller.runJavaScript(r"""
              (function() {
                function killGoogleBanner() {
                  // ۱. حذف بر اساس کلاس‌های معروف بنر گوگل
                  var elements = document.querySelectorAll('.apps-share-space-banner-table, .apps-share-space-banner');
                  elements.forEach(function(el) {
                    if (el) el.style.setProperty('display', 'none', 'important');
                  });

                  // ۲. حذف بر اساس ویژگی aria-label بنر
                  var ariaElements = document.querySelectorAll('div[aria-label*="This application was created"], div[aria-label*="not by Google"]');
                  ariaElements.forEach(function(el) {
                    if (el) el.style.setProperty('display', 'none', 'important');
                  });

                  // ۳. جراحی لایه اول بدنه (گوگل گاهی بنر را به عنوان اولین جدول بادی می‌گذارد)
                  if (document.body && document.body.firstChild && document.body.firstChild.tagName === 'TABLE') {
                    document.body.firstChild.style.setProperty('display', 'none', 'important');
                  }

                  // ۴. صفر کردن حاشیه‌ها برای پر شدن تمام صفحه
                  if (document.body) {
                    document.body.style.setProperty('margin', '0', 'important');
                    document.body.style.setProperty('padding', '0', 'important');
                    document.body.style.setProperty('top', '0', 'important');
                  }
                }

                // اجرای فوری
                killGoogleBanner();

                // اجرای متناوب هر ۱۰۰ میلی‌ثانیه تا ۷ ثانیه اول لود صفحه (برای مچ‌گیری تزریق‌های تأخیری گوگل)
                var runCount = 0;
                var bannerKillerInterval = setInterval(function() {
                  killGoogleBanner();
                  runCount++;
                  if (runCount > 70) {
                    clearInterval(bannerKillerInterval);
                  }
                }, 100);
              })();
            """);
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _errorMessage = error.description;
            });
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
      ..loadRequest(Uri.parse("https://script.google.com/macros/s/AKfycbyC4r6ETL4TpC3FQIMjDd2gJoTB5mijctOcHXLbkCV68aeCb0EKr5QHpzbJpcqE3BQv/exec"));
  }
  
  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      Image.asset('assets/splash.png', width: 180),
                      const SizedBox(height: 30),
                      const CircularProgressIndicator(color: Colors.blue),
                      const SizedBox(height: 20),
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