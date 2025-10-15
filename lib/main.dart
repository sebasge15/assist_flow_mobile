import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'features/company/company_selector_page.dart';
import 'features/auth/login_page.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const AssistFlowApp());
}

class AssistFlowApp extends StatelessWidget {
  const AssistFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AssistFlow',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      navigatorKey: navigatorKey, // 👈 importante
      home: CompanySelectorPage(
        onCompanySelected: (companyId, companyName) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (_) => LoginPage(
                companyId: companyId,
                companyName: companyName,
                onBack: () => navigatorKey.currentState!.pop(),
                onLogin: (userData) {
                  // TODO: navega a dashboard u otra pantalla
                  debugPrint('Login OK: $userData');
                },
              ),
            ),
          );
        },
        onAdminAccess: () {
          // TODO: ir a admin
          debugPrint('Acceso admin');
        },
      ),
    );
  }
}
