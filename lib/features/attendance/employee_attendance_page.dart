import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/app_button.dart';
import 'employee_personal_dashboard_page.dart';


class Employee {
  final String id;
  final String name;
  final String jobPosition;
  final String dni;
  final String? pin;
  final String? password;

  const Employee({
    required this.id,
    required this.name,
    required this.jobPosition,
    required this.dni,
    this.pin,
    this.password,
  });

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      jobPosition: map['job_position'] ?? map['jobPosition'] ?? '',
      dni: map['dni'] ?? '',
      pin: map['pin'],
      password: map['password'],
    );
  }
}

class EmployeeAttendancePage extends StatefulWidget {
  const EmployeeAttendancePage({
    super.key,
    required this.employee,
    required this.companyId,
    required this.companyName,
    required this.onLogout,
  });

  final Employee employee;
  final String companyId;
  final String companyName;
  final VoidCallback onLogout;

  @override
  State<EmployeeAttendancePage> createState() => _EmployeeAttendancePageState();
}

class _EmployeeAttendancePageState extends State<EmployeeAttendancePage> {
  late DateTime _currentTime;
  Timer? _timer;

  _LastAction? _lastAction;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _greeting() {
    final h = _currentTime.hour;
    if (h < 12) return 'Buenos días';
    if (h < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  void _toast(String title, {String? subtitle, bool error = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? theme.colorScheme.error : theme.colorScheme.primary,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            if (subtitle != null)
              Text(subtitle, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  /// Frontend-only: simula registro de asistencia y tardanza.
  Future<void> _recordAttendance(String type) async {
    await Future.delayed(const Duration(milliseconds: 250));

    bool isLate = false;
    int minutesLate = 0;
    if (type == 'entrada') {
      final start = DateTime(_currentTime.year, _currentTime.month, _currentTime.day, 9, 0);
      if (_currentTime.isAfter(start)) {
        final diff = _currentTime.difference(start);
        isLate = diff.inMinutes > 0;
        minutesLate = diff.inMinutes;
      }
    }

    setState(() {
      _lastAction = _LastAction(
        type: type,
        time: _formatTime(_currentTime),
        isLate: isLate,
        minutesLate: minutesLate,
      );
    });

    if (isLate && type == 'entrada') {
      _toast('⚠️ Llegada tarde registrada',
          subtitle: 'Marcación a las ${_formatTime(_currentTime)}. Llegaste $minutesLate min tarde.',
          error: true);
    } else {
      final labels = {
        'entrada': 'Entrada',
        'salida': 'Salida',
        'inicio_almuerzo': 'Inicio de Almuerzo',
        'fin_almuerzo': 'Fin de Almuerzo',
      };
      _toast('${labels[type] ?? type} registrada',
          subtitle: 'Marcación exitosa a las ${_formatTime(_currentTime)}');
    }
  }

  String _formatDateLong(DateTime d) {
    // Simple formato local (puedes usar intl si quieres):
    const weekdays = ['lunes','martes','miércoles','jueves','viernes','sábado','domingo'];
    const months = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
    final w = weekdays[(d.weekday - 1) % 7];
    final m = months[(d.month - 1) % 12];
    return '$w, ${d.day} de $m de ${d.year}';
  }

  String _formatTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    final s = d.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16),
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
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Header
                  // Header (reemplaza todo tu Row actual por este)
                  // Header (reemplaza tu Row actual completo por este widget)
                  // Header centrado con botones debajo y responsivos
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Título centrado
                        Text(
                          'AsistControl',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Subtítulo (empresa) centrado
                        Text(
                          widget.companyName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 10),

                        // Botones debajo del título, responsivos (Wrap)
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,     // centra horizontalmente
                            spacing: 8,                           // separación horizontal entre botones
                            runSpacing: 8,                        // separación vertical cuando “salte” a otra fila
                            children: [
                              // Botón Tablero de Asistencia
                              FilledButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => EmployeePersonalDashboardPage(
                                        employee: widget.employee,
                                        companyId: widget.companyId,
                                        companyName: widget.companyName,
                                        onLogout: widget.onLogout,
                                        onAttendance: () => Navigator.of(context).pop(),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.analytics_outlined, size: 18),
                                label: const Text('Tablero de Asistencia'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  minimumSize: const Size(0, 36),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),

                              // Botón Cerrar sesión
                              OutlinedButton(
                                onPressed: widget.onLogout,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  minimumSize: const Size(0, 36),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Cerrar Sesión'),
                              ),

                              // (Opcional) Botón extra — ejemplo
                              // OutlinedButton.icon(
                              //   onPressed: () {},
                              //   icon: const Icon(Icons.history, size: 18),
                              //   label: const Text('Historial'),
                              // ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),


                  const SizedBox(height: 12),

                  // Bienvenida
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person,
                                size: 28, color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${_greeting()}, ${widget.employee.name}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          const Text('Listo para marcar tu asistencia', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Fecha y hora actual
                  Card(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(.2)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey[700]),
                              const SizedBox(width: 6),
                              Text(_formatDateLong(_currentTime), style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.access_time, size: 22, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                _formatTime(_currentTime),
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 28,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Botones Entrada/Salida
                  GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 1.6,
                    shrinkWrap: true,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      Card(
                        elevation: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: AppButton(
                            label: 'ENTRADA',
                            icon: Icons.login,
                            onPressed: () => _recordAttendance('entrada'),
                          ),
                        ),
                      ),
                      Card(
                        elevation: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: AppButton(
                            label: 'SALIDA',
                            icon: Icons.logout,
                            onPressed: () => _recordAttendance('salida'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Botones de almuerzo
                  GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 2.1,
                    shrinkWrap: true,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      Card(
                        elevation: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: AppButton(
                            label: 'INICIO ALMUERZO',
                            icon: Icons.free_breakfast,
                            onPressed: () => _recordAttendance('inicio_almuerzo'),
                          ),
                        ),
                      ),
                      Card(
                        elevation: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: AppButton(
                            label: 'FIN ALMUERZO',
                            icon: Icons.emoji_food_beverage,
                            onPressed: () => _recordAttendance('fin_almuerzo'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Última acción
                  if (_lastAction != null)
                    Card(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(.08),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Theme.of(context).colorScheme.secondary),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary.withOpacity(.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Última marcación: ${_lastAction!.type.toUpperCase()}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Registrado correctamente a las ${_lastAction!.time}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Instrucciones
                  Card(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Theme.of(context).dividerColor, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Theme.of(context).colorScheme.surface.withOpacity(.6),
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Column(
                        children: [
                          Text('Instrucciones:', style: TextStyle(fontWeight: FontWeight.w600)),
                          SizedBox(height: 6),
                          Text('• Presiona ENTRADA al llegar al trabajo', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                          Text('• Presiona SALIDA al terminar tu jornada', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                          Text('• Cada marcación se registra automáticamente', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LastAction {
  final String type; // entrada | salida | inicio_almuerzo | fin_almuerzo
  final String time;
  final bool? isLate;
  final int? minutesLate;
  _LastAction({required this.type, required this.time, this.isLate, this.minutesLate});
}
