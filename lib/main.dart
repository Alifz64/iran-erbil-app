// نسخه: V_20260710_1144_MAIN_FIXED_RENDER
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
    
    // 💡 تایمر پشتیبان: اگر لود شدن به هر دلیلی بیشتر از ۱۵ ثانیه طول کشید، اسپلش را بردار تا ببینیم مشکل از چیست
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
            // 💡 جراحی زمان‌بندی: فقط زمانی اسپلش را مخفی کن که به آدرس نهایی حاوی اطلاعات رسیده باشیم
            if (url.contains('script.googleusercontent.com') || url.contains('exec')) {
              setState(() { _isLoading = false; });
              _timeoutTimer?.cancel();
            }

            // 💡 جراحی CSS: فقط و فقط کلاسِ اختصاصی بنر گوگل را مخفی کن، بدون دست زدن به قالب اصلی برنامه شما
            _controller.runJavaScript("""
              var style = document.createElement('style');
              style.innerHTML = '.apps-share-space-banner-table { display: none !important; } div[aria-label="This application was created by another user, not by Google."] { display: none !important; }';
              document.head.appendChild(style);
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
                          'ارتباط با سرور برقرار نشد!\\n$_errorMessage',
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