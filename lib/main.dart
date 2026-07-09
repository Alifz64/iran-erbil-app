// Version: v5.25-20260709-1932_Flutter_Core
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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
  InAppWebViewController? webViewController;

  // آدرس اصلی وب‌اپلیکیشن گوگل اسکریپت شما
  final String webAppUrl = "https://script.google.com/macros/s/AKfycbyC4r6ETL4TpC3FQIMjDd2gJoTB5mijctOcHXLbkCV68aeCb0EKr5QHpzbJpcqE3BQv/exec";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(webAppUrl)),
          initialSettings: InAppWebViewSettings(
            useShouldOverrideUrlLoading: true,
            mediaPlaybackRequiresUserGesture: false,
            javaScriptEnabled: true,
            domStorageEnabled: true,
            supportZoom: false,
          ),
          onWebViewCreated: (controller) {
            webViewController = controller;
          },
          // 💡 جراحی بزرگ: حذف بنر آبی گوگل به محض لود شدن صفحات
          onLoadStop: (controller, url) async {
            // تزریق استایل به بالاترین لایه‌ برای مخفی کردن بنر پیش‌فرض گوگل اسکریپت
            await controller.injectCSSCode(source: """
              .apps-share-space-banner-table, 
              td[style*="background-color: #e2eaf8"], 
              body > table:first-child { 
                display: none !important; 
              }
              html, body {
                margin: 0 !important;
                padding: 0 !important;
                top: 0 !important;
              }
            """);
          },
          // 💡 مدیریت هوشمند لینک‌ها: باز کردن تلگرام و واتساپ در اپلیکیشن بومی گوشی
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            var uri = navigationAction.request.url;
            if (uri != null && !["http", "https", "file", "chrome", "data", "javascript", "about"].contains(uri.scheme)) {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                return NavigationActionPolicy.CANCEL;
              }
            }
            return NavigationActionPolicy.ALLOW;
          },
        ),
      ),
    );
  }
}