import 'dart:async';
import 'package:flutter/material.dart';
import 'employee_attendance_page.dart' show Employee; // reutiliza el modelo Employee

class EmployeePersonalDashboardPage extends StatefulWidget {
  const EmployeePersonalDashboardPage({
    super.key,
    required this.employee,
    required this.companyId,
    required this.companyName,
    required this.onLogout,
    required this.onAttendance,
  });

  final Employee employee;
  final String companyId;
  final String companyName;
  final VoidCallback onLogout;
  final VoidCallback onAttendance;

  @override
  State<EmployeePersonalDashboardPage> createState() =>
      _EmployeePersonalDashboardPageState();
}

class _EmployeePersonalDashboardPageState extends State<EmployeePersonalDashboardPage> {
  late DateTime _now;
  Timer? _timer;
  String _selectedMonth = _yyyyMm(DateTime.now());

  // MOCK: registros diarios sencillos
  final List<_DailyRecord> _daily = [];

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    _seedMock();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static String _yyyyMm(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  void _seedMock() {
    // Crea 7 días con datos simples
    final today = DateTime.now();
    _daily.clear();
    for (int i = 0; i < 7; i++) {
      final day = today.subtract(Duration(days: i));
      _daily.add(_DailyRecord(
        date: DateTime(day.year, day.month, day.day),
        entrance: const TimeOfDay(hour: 9, minute: 5),  // 9:05
        exit: const TimeOfDay(hour: 18, minute: 10),    // 18:10
        lunchStart: const TimeOfDay(hour: 13, minute: 0),
        lunchEnd: const TimeOfDay(hour: 14, minute: 0),
        totalHours: 8.0,
        isLate: i % 3 == 0, // cada 3 días tarde
        minutesLate: i % 3 == 0 ? 5 : 0,
        overtimeHours: i % 4 == 0 ? 0.5 : 0.0,
        lunchExcessMinutes: 0,
      ));
    }
    setState(() {});
  }

  String _greeting() {
    final h = _now.hour;
    if (h < 12) return 'Buenos días';
    if (h < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _formatDateLong(DateTime d) {
    const weekdays = ['lunes','martes','miércoles','jueves','viernes','sábado','domingo'];
    const months = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
    final w = weekdays[(d.weekday - 1) % 7];
    final m = months[(d.month - 1) % 12];
    return '$w, ${d.day} de $m de ${d.year}';
  }

  String _hhmmss(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';

  String _formatTimeOfDay(TimeOfDay? t) {
    if (t == null) return '-';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatHours(double? hours) {
    final h = (hours ?? 0).floor();
    final m = (((hours ?? 0) - h) * 60).round();
    return '${h}h ${m}m';
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
              constraints: const BoxConstraints(maxWidth: 1000),
              child: ListView(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mi Panel Personal',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                              )),
                          Text(widget.companyName, style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: widget.onAttendance,
                            icon: const Icon(Icons.access_time, size: 18),
                            label: const Text('Ir a Marcación'),
                          ),
                          OutlinedButton.icon(
                            onPressed: widget.onLogout,
                            icon: const Icon(Icons.logout, size: 18),
                            label: const Text('Cerrar Sesión'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bienvenida + Reloj
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
                          Text(
                            '${widget.employee.jobPosition} • DNI: ${widget.employee.dni}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

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
                              Icon(Icons.calendar_month, size: 16, color: Colors.grey[700]),
                              const SizedBox(width: 6),
                              Text(_formatDateLong(_now), style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.access_time, size: 22, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                _hhmmss(_now),
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

                  // Selector de mes
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Seleccionar mes:', style: TextStyle(fontWeight: FontWeight.w600)),
                          SizedBox(
                            width: 160,
                            child: TextFormField(
                              initialValue: _selectedMonth,
                              decoration: const InputDecoration(
                                  hintText: 'YYYY-MM',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                              onChanged: (v) => setState(() => _selectedMonth = v.trim()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Stats mensuales (mock)
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.4,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _statCard(
                        title: 'Horas Trabajadas',
                        value: _formatHours(160),
                        icon: Icons.timer_outlined,
                        accent: Theme.of(context).colorScheme.primary,
                      ),
                      _statCard(
                        title: 'Días con Tardanza',
                        value: '3',
                        icon: Icons.warning_amber_rounded,
                        accent: Theme.of(context).colorScheme.error,
                      ),
                      _statCard(
                        title: 'Horas Extra',
                        value: _formatHours(6),
                        icon: Icons.trending_up,
                        accent: Colors.green[600],
                      ),
                      _statCard(
                        title: 'Exceso Almuerzo',
                        value: '15 min',
                        icon: Icons.free_breakfast,
                        accent: Colors.orange[700],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tabla de registros diarios (mock)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.bar_chart, size: 18, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 6),
                            const Text('Registro Diario de Asistencia',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ]),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Fecha')),
                                DataColumn(label: Text('Entrada')),
                                DataColumn(label: Text('Salida')),
                                DataColumn(label: Text('Almuerzo')),
                                DataColumn(label: Text('Horas')),
                                DataColumn(label: Text('Estado')),
                              ],
                              rows: _daily.map((r) {
                                final lunchStr = (r.lunchStart != null && r.lunchEnd != null)
                                    ? '${_formatTimeOfDay(r.lunchStart)} - ${_formatTimeOfDay(r.lunchEnd)}'
                                    : '-';
                                return DataRow(cells: [
                                  DataCell(Text('${r.date.day.toString().padLeft(2, '0')}/${r.date.month.toString().padLeft(2, '0')}')),
                                  DataCell(Text(_formatTimeOfDay(r.entrance))),
                                  DataCell(Text(_formatTimeOfDay(r.exit))),
                                  DataCell(Text(lunchStr)),
                                  DataCell(Text(_formatHours(r.totalHours))),
                                  DataCell(
                                    r.isLate
                                        ? _chip('Tarde (${r.minutesLate}m)', Theme.of(context).colorScheme.error)
                                        : _chip('A tiempo', Theme.of(context).colorScheme.secondary),
                                  ),
                                ]);
                              }).toList(),
                            ),
                          ),
                          if (_daily.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Center(
                                child: Opacity(
                                  opacity: .7,
                                  child: Text('No hay registros para el mes seleccionado'),
                                ),
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
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    Color? accent,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Icon(icon, size: 16, color: Colors.grey),
            ]),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: accent ?? Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ⬇️ AHORA devuelve un Widget (no DataCell)
  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.4)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _DailyRecord {
  final DateTime date;
  final TimeOfDay? entrance;
  final TimeOfDay? exit;
  final TimeOfDay? lunchStart;
  final TimeOfDay? lunchEnd;
  final double totalHours;
  final bool isLate;
  final int minutesLate;
  final double overtimeHours;
  final int lunchExcessMinutes;

  _DailyRecord({
    required this.date,
    this.entrance,
    this.exit,
    this.lunchStart,
    this.lunchEnd,
    required this.totalHours,
    required this.isLate,
    required this.minutesLate,
    required this.overtimeHours,
    required this.lunchExcessMinutes,
  });
}
