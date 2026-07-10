// Version: V_20260710_1041_MAIN_OFFICIAL
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

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // 💡 هویت‌سازی مرورگر: معرفی اپلیکیشن به عنوان نسخه رسمی گوگل کروم برای لود بدون مشکل صفحات گوگل
      ..setUserAgent("Mozilla/5.0 (Linux; Android 13; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // 💡 حذف بنر آبی گوگل بلافاصله پس از پایان بارگذاری صفحه
            _controller.runJavaScript("""
              var style = document.createElement('style');
              style.innerHTML = '.apps-share-space-banner-table, td[style*="background-color: #e2eaf8"], body > table:first-child { display: none !important; } html, body { margin: 0 !important; padding: 0 !important; top: 0 !important; }';
              document.head.appendChild(style);
            """);
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            // مدیریت لینک‌های غیر وب (مثل تلگرام، واتساپ، تماس تلفنی)
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
            // ارجاع مستقیم شبکه‌های اجتماعی به اپلیکیشن بومی گوشی
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}ش// نسخه: V_20260710_1100_MAIN_WITH_INAPP_SPLASH
// ========================================================
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
  
  // 💡 متغیرهای کنترل وضعیت برای جلوگیری از صفحه سفید
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("Mozilla/5.0 (Linux; Android 13; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() { _isLoading = true; _errorMessage = ''; });
          },
          onPageFinished: (String url) {
            // 💡 پایان اسپلش و حذف بنر گوگل
            setState(() { _isLoading = false; });
            _controller.runJavaScript("""
              var style = document.createElement('style');
              style.innerHTML = '.apps-share-space-banner-table, td[style*="background-color: #e2eaf8"], body > table:first-child { display: none !important; } html, body { margin: 0 !important; padding: 0 !important; top: 0 !important; }';
              document.head.appendChild(style);
            """);
          },
          onWebResourceError: (WebResourceError error) {
            // 💡 شکارچی خطا: نمایش دلیل قطعی به جای صفحه سفید
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ۱. لایه زیرین: مرورگر که اطلاعات را لود می‌کند
            WebViewWidget(controller: _controller),
            
            // ۲. لایه میانی: اسپلش اسکرین داخلی (جلوگیری از صفحه سفید)
            if (_isLoading)
              Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // نمایش لوگوی شما که در پوشه assets قرار دارد
                      Image.asset('assets/splash.png', width: 180),
                      const SizedBox(height: 30),
                      const CircularProgressIndicator(color: Colors.blue),
                      const SizedBox(height: 20),
                      const Text(
                        'در حال دریافت اطلاعات...',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              ),
              
            // ۳. لایه بالایی: نمایش دقیق خطا در صورت خرابی اینترنت
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