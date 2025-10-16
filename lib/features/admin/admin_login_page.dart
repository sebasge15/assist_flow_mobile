import 'package:flutter/material.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_input.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({
    super.key,
    required this.onLogin,
    this.onBack,
  });

  final VoidCallback onLogin;
  final VoidCallback? onBack;

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Login
  final _loginFormKey = GlobalKey<FormState>();
  final _emailLoginCtrl = TextEditingController();
  final _passwordLoginCtrl = TextEditingController();

  // Register
  final _registerFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailRegCtrl = TextEditingController();
  final _passRegCtrl = TextEditingController();
  final _confirmRegCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailLoginCtrl.dispose();
    _passwordLoginCtrl.dispose();
    _nameCtrl.dispose();
    _emailRegCtrl.dispose();
    _passRegCtrl.dispose();
    _confirmRegCtrl.dispose();
    super.dispose();
  }

  void _toast(String title, {String? subtitle, bool error = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
            if (subtitle != null) Text(subtitle, style: const TextStyle(color: Colors.white70)),
          ],
        ),
        backgroundColor: error ? theme.colorScheme.error : theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!(_loginFormKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      // Mock de login exitoso si hay email+password
      await Future.delayed(const Duration(milliseconds: 600));
      _toast('Bienvenido', subtitle: 'Inicio de sesión exitoso');
      widget.onLogin();
    } catch (_) {
      _toast('Error de autenticación', subtitle: 'Error inesperado al iniciar sesión', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!(_registerFormKey.currentState?.validate() ?? false)) return;

    if (_passRegCtrl.text != _confirmRegCtrl.text) {
      _toast('Error', subtitle: 'Las contraseñas no coinciden', error: true);
      return;
    }
    if (_passRegCtrl.text.length < 6) {
      _toast('Error', subtitle: 'La contraseña debe tener al menos 6 caracteres', error: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Mock de registro: “crea” usuario y no inicia sesión automáticamente
      await Future.delayed(const Duration(milliseconds: 700));
      _toast(
        'Registro exitoso',
        subtitle: 'Por favor verifica tu email para completar el registro. Puedes iniciar sesión.',
      );

      // Limpia y cambia a la pestaña de login
      _nameCtrl.clear();
      _emailRegCtrl.clear();
      _passRegCtrl.clear();
      _confirmRegCtrl.clear();
      _tabController.animateTo(0);
    } catch (_) {
      _toast('Error de registro', subtitle: 'Error inesperado al registrarse', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.08),
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.secondary.withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            shrinkWrap: true,
            children: [
              if (widget.onBack != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _isLoading ? null : widget.onBack,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Volver'),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.security,
                            size: 28, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Panel Administrativo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'AsistControl - Acceso para administradores',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),

                      // Tabs
                      TabBar(
                        controller: _tabController,
                        labelColor: Theme.of(context).colorScheme.onSurface,
                        indicatorColor: Theme.of(context).colorScheme.primary,
                        tabs: const [
                          Tab(text: 'Iniciar Sesión'),
                          Tab(text: 'Registrarse'),
                        ],
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        height: 380, // altura razonable para el contenido
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // --------- LOGIN ---------
                            Form(
                              key: _loginFormKey,
                              child: Column(
                                children: [
                                  AppInput(
                                    label: 'Email',
                                    hintText: 'admin@empresa.com',
                                    controller: _emailLoginCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Por favor completa todos los campos';
                                      }
                                      if (!v.contains('@')) return 'Email inválido';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  AppInput(
                                    label: 'Contraseña',
                                    hintText: '••••••••',
                                    controller: _passwordLoginCtrl,
                                    obscureText: true,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Por favor completa todos los campos';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  AppButton(
                                    label: _isLoading ? 'Iniciando sesión...' : 'Iniciar Sesión',
                                    icon: Icons.lock,
                                    isLoading: _isLoading,
                                    onPressed: _handleLogin,
                                  ),
                                ],
                              ),
                            ),

                            // --------- REGISTER ---------
                            Form(
                              key: _registerFormKey,
                              child: Column(
                                children: [
                                  AppInput(
                                    label: 'Nombre Completo',
                                    hintText: 'Juan Pérez',
                                    controller: _nameCtrl,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Por favor completa todos los campos';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  AppInput(
                                    label: 'Email',
                                    hintText: 'admin@empresa.com',
                                    controller: _emailRegCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Por favor completa todos los campos';
                                      }
                                      if (!v.contains('@')) return 'Email inválido';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  AppInput(
                                    label: 'Contraseña',
                                    hintText: '••••••••',
                                    controller: _passRegCtrl,
                                    obscureText: true,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Por favor completa todos los campos';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  AppInput(
                                    label: 'Confirmar Contraseña',
                                    hintText: '••••••••',
                                    controller: _confirmRegCtrl,
                                    obscureText: true,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Por favor completa todos los campos';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  AppButton(
                                    label: _isLoading ? 'Registrando...' : 'Crear Cuenta de Administrador',
                                    icon: Icons.person_add_alt_1,
                                    isLoading: _isLoading,
                                    onPressed: _handleRegister,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
