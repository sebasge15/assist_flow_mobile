import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

// Páginas de tu app
import 'features/company/company_selector_page.dart';
import 'features/auth/login_page.dart';
import 'features/admin/admin_login_page.dart';
import 'features/company/company_setup_page.dart';
import 'features/admin/admin_dashboard_page.dart';
import 'features/attendance/employee_attendance_page.dart'; // ⬅️ NUEVO: asistencia empleado

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
      navigatorKey: navigatorKey,
      home: CompanySelectorPage(
        // Flujo empleado → Login → EmployeeAttendance
        onCompanySelected: (companyId, companyName) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (_) => LoginPage(
                companyId: companyId,
                companyName: companyName,
                onBack: () => navigatorKey.currentState!.pop(),
                onLogin: (userData) {
                  // userData proviene del LoginPage (mock o backend)
                  final employee = Employee.fromMap(userData);
                  navigatorKey.currentState!.pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => EmployeeAttendancePage(
                        employee: employee,
                        companyId: companyId,
                        companyName: companyName,
                        onLogout: () {
                          // Al cerrar sesión del empleado, vuelve al selector limpio
                          navigatorKey.currentState!.pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => AssistFlowRoot()),
                                (route) => false,
                          );
                        },
                      ),
                    ),
                        (route) => false,
                  );
                },
              ),
            ),
          );
        },

        // Flujo admin → AdminLogin → CompanySetup → AdminDashboard
        onAdminAccess: () {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (_) => AdminLoginPage(
                onLogin: () {
                  // Luego del primer login/registro, ir a configurar empresa
                  navigatorKey.currentState!.pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => CompanySetupPage(
                        onCompanyCreated: (companyId) {
                          // Empresa creada: ir al dashboard admin y limpiar stack
                          navigatorKey.currentState!.pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => AdminDashboardPage(
                                onLogout: () {
                                  // Al salir del admin dashboard, vuelve al selector
                                  navigatorKey.currentState!.pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => AssistFlowRoot()),
                                        (route) => false,
                                  );
                                },
                              ),
                            ),
                                (route) => false,
                          );
                        },
                        onBack: () => navigatorKey.currentState!.pop(),
                      ),
                    ),
                  );
                },
                onBack: () => navigatorKey.currentState!.pop(),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Wrapper simple para reconstruir el selector al desloguear.
/// (Puedes reemplazarlo por estado global más adelante).
class AssistFlowRoot extends StatelessWidget {
  AssistFlowRoot({super.key});

  final GlobalKey _rebuildKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _rebuildKey,
      child: CompanySelectorPage(
        onCompanySelected: (companyId, companyName) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (_) => LoginPage(
                companyId: companyId,
                companyName: companyName,
                onBack: () => navigatorKey.currentState!.pop(),
                onLogin: (userData) {
                  final employee = Employee.fromMap(userData);
                  navigatorKey.currentState!.pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => EmployeeAttendancePage(
                        employee: employee,
                        companyId: companyId,
                        companyName: companyName,
                        onLogout: () {
                          navigatorKey.currentState!.pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => AssistFlowRoot()),
                                (route) => false,
                          );
                        },
                      ),
                    ),
                        (route) => false,
                  );
                },
              ),
            ),
          );
        },
        onAdminAccess: () {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (_) => AdminLoginPage(
                onLogin: () {
                  navigatorKey.currentState!.pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => CompanySetupPage(
                        onCompanyCreated: (companyId) {
                          navigatorKey.currentState!.pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => AdminDashboardPage(
                                onLogout: () {
                                  navigatorKey.currentState!.pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => AssistFlowRoot()),
                                        (route) => false,
                                  );
                                },
                              ),
                            ),
                                (route) => false,
                          );
                        },
                        onBack: () => navigatorKey.currentState!.pop(),
                      ),
                    ),
                  );
                },
                onBack: () => navigatorKey.currentState!.pop(),
              ),
            ),
          );
        },
      ),
    );
  }
}
