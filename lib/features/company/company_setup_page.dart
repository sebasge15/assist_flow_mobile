import 'package:flutter/material.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_input.dart';

class CompanySetupPage extends StatefulWidget {
  const CompanySetupPage({
    super.key,
    required this.onCompanyCreated,
    this.onBack,
  });

  final void Function(String companyId) onCompanyCreated;
  final VoidCallback? onBack;

  @override
  State<CompanySetupPage> createState() => _CompanySetupPageState();
}

class _CompanySetupPageState extends State<CompanySetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _companyCtrl.dispose();
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
            if (subtitle != null) Text(subtitle, style: const TextStyle(color: Colors.white70)),
          ],
        ),
        backgroundColor: error ? theme.colorScheme.error : theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      // 🔁 Mock: simula creación de empresa (reemplaza con tu backend/API cuando corresponda)
      await Future.delayed(const Duration(milliseconds: 700));
      final createdCompanyId = 'comp_${DateTime.now().millisecondsSinceEpoch}';

      _toast('¡Empresa creada exitosamente!',
          subtitle: 'Tu empresa ha sido configurada correctamente');
      widget.onCompanyCreated(createdCompanyId);
    } catch (_) {
      _toast('Error', subtitle: 'Error al crear la empresa', error: true);
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
          constraints: const BoxConstraints(maxWidth: 720),
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
                      // Header icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.apartment,
                            size: 28, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Configuración de Empresa',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Configura tu empresa para empezar a gestionar la asistencia de empleados',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            AppInput(
                              label: 'Nombre de la Empresa',
                              hintText: 'Ingresa el nombre de tu empresa',
                              controller: _companyCtrl,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'El nombre de la empresa es requerido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Nota informativa
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.access_time,
                                      size: 18,
                                      color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Nota: Los horarios de trabajo se configurarán desde el panel de administración después de crear la empresa.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            AppButton(
                              label: _isLoading ? 'Creando empresa...' : 'Crear Empresa',
                              isLoading: _isLoading,
                              onPressed: _handleSubmit,
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
