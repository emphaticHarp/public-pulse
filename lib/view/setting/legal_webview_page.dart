import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:public_pulse/core/theme/app_colors.dart';

class LegalWebViewPage extends StatefulWidget {
  final String title;
  final String url;

  const LegalWebViewPage({super.key, required this.title, required this.url});

  @override
  State<LegalWebViewPage> createState() => _LegalWebViewPageState();
}

class _LegalWebViewPageState extends State<LegalWebViewPage> {
  late final WebViewController _webViewController;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _webViewController = WebViewController()
      ..setBackgroundColor(AppColors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,

      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),

        title: Text(
          widget.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        centerTitle: false,
      ),

      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),

          if (_isLoading)
            const LinearProgressIndicator(
              color: AppColors.loginAccentRed,
              backgroundColor: AppColors.gray100,
            ),
        ],
      ),
    );
  }
}
