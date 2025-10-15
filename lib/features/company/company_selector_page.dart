import 'package:flutter/material.dart';
import '../../widgets/app_button.dart';

class Company {
  final String id;
  final String name;
  const Company({required this.id, required this.name});
}

class CompanySelectorPage extends StatefulWidget {
  const CompanySelectorPage({
    super.key,
    required this.onCompanySelected,
    required this.onAdminAccess,
  });

  final void Function(String companyId, String companyName) onCompanySelected;
  final VoidCallback onAdminAccess;

  @override
  State<CompanySelectorPage> createState() => _CompanySelectorPageState();
}

class _CompanySelectorPageState extends State<CompanySelectorPage> {
  final _formKey = GlobalKey<FormState>();

  List<Company> _companies = const [];
  String? _selectedCompanyId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  void _toast(String msg, {bool error = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? theme.colorScheme.error : theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadCompanies() async {
    try {
      // 🔁 Mock: simula carga remota (reemplazar por tu fuente real cuando tengas backend)
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        _companies = const [
          Company(id: 'c1', name: 'Acme S.A.C.'),
          Company(id: 'c2', name: 'InterAndes S.R.L.'),
          Company(id: 'c3', name: 'Tech Lima S.A.'),
        ];
      });
    } catch (e) {
      _toast('Error al cargar las empresas disponibles', error: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleContinue() {
    if (_selectedCompanyId == null) {
      _toast('Por favor selecciona una empresa', error: true);
      return;
    }
    final company = _companies.firstWhere((c) => c.id == _selectedCompanyId);
    widget.onCompanySelected(company.id, company.name);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 32, height: 32,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    const SizedBox(height: 12),
                    Text('Cargando empresas...',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

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
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: Column(
                    children: [
                      // Icono de header
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.apartment,
                            size: 28,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Seleccionar Empresa',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Elige tu empresa para marcar asistencia',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),

                      // Form con dropdown
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Empresa', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _selectedCompanyId,
                              items: _companies.map((c) {
                                return DropdownMenuItem<String>(
                                  value: c.id,
                                  child: Text(c.name),
                                );
                              }).toList(),
                              decoration: const InputDecoration(
                                hintText: 'Selecciona tu empresa',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) => setState(() => _selectedCompanyId = value),
                            ),
                            const SizedBox(height: 16),

                            AppButton(
                              label: 'Continuar',
                              icon: Icons.arrow_forward,
                              isLoading: false,
                              onPressed: _handleContinue,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Card para acceso admin (outlined-like)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.6),
                  ),
                ),
                color: Theme.of(context).colorScheme.surface.withOpacity(.6),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: AppButton(
                    label: '¿Eres Administrador?',
                    icon: Icons.security,
                    onPressed: widget.onAdminAccess,
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
