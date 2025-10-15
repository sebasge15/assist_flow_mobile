import 'package:flutter/material.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_input.dart';
import '../../widgets/instructions_card.dart'; // tu widget de instrucciones

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onLogin,
    this.onBack,
    this.companyId,
    this.companyName,
  });

  final void Function(Map<String, dynamic> userData) onLogin;
  final VoidCallback? onBack;
  final String? companyId;
  final String? companyName;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _pinCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _toast(String title, {String? subtitle, bool error = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (subtitle != null)
              Text(subtitle, style: const TextStyle(color: Colors.white70)),
          ],
        ),
        backgroundColor:
        error ? theme.colorScheme.error : theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<Map<String, dynamic>?> _authenticateEmployee({
    required String pin,
    required String password,
    required String companyId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (pin == '1234' && password.isNotEmpty) {
      return {
        'id': 'user_1',
        'name': 'Empleado Demo',
        'companyId': companyId,
      };
    }
    return null;
  }

  Future<void> _handleEmployeeLogin() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk) return;

    if (widget.companyId == null || widget.companyId!.isEmpty) {
      _toast('Error', subtitle: 'No se ha seleccionado una empresa', error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final data = await _authenticateEmployee(
        pin: _pinCtrl.text.trim(),
        password: _passCtrl.text,
        companyId: widget.companyId!,
      );

      if (data == null) {
        _toast('Credenciales incorrectas',
            subtitle: 'El PIN o contraseña ingresados no son válidos', error: true);
        return;
      }

      _toast('¡Bienvenido!', subtitle: 'Hola ${data['name']}');
      widget.onLogin({
        ...data,
        'pin': _pinCtrl.text,
        'password': _passCtrl.text,
      });
    } catch (e) {
      _toast('Error de autenticación',
          subtitle: 'Ocurrió un error al verificar las credenciales', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyCard = (widget.onBack != null && (widget.companyName ?? '').isNotEmpty)
        ? Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
          style: BorderStyle.solid,
        ),
      ),
      color: Theme.of(context).colorScheme.surface.withOpacity(.6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: _loading ? null : widget.onBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Cambiar Empresa'),
            ),
            const Spacer(),
            const Icon(Icons.apartment, size: 18, color: Colors.grey),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                widget.companyName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    )
        : const SizedBox.shrink();

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
              companyCard,
              const SizedBox(height: 12),

              /// Logo + branding
              Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 80,
                  ),
                  const SizedBox(height: 10),
                  ShaderMask(
                    shaderCallback: (rect) => LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primaryContainer,
                      ],
                    ).createShader(rect),
                    child: const Text(
                      'AsistControl',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Sistema de Control de Asistencia',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 16),

              /// Card principal de login
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: Column(
                    children: [
                      const Text(
                        'Marcación de Empleados',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Ingresa tu PIN y contraseña para marcar asistencia',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            AppInput(
                              label: 'PIN de Empleado',
                              hintText: 'Ingresa tu PIN',
                              controller: _pinCtrl,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              textAlign: TextAlign.center,
                              obscureText: true,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Por favor ingresa tu PIN';
                                }
                                if (v.trim().length < 4) {
                                  return 'El PIN debe tener al menos 4 dígitos';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            AppInput(
                              label: 'Contraseña',
                              hintText: 'Ingresa tu contraseña',
                              controller: _passCtrl,
                              obscureText: true,
                              textAlign: TextAlign.center,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Por favor ingresa tu contraseña';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppButton(
                              label: 'Acceder a Marcación',
                              icon: Icons.access_time,
                              isLoading: _loading,
                              onPressed: _handleEmployeeLogin,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              /// Instrucciones (nueva sección)
              const InstructionsCard(),
            ],
          ),
        ),
      ),
    );
  }
}
