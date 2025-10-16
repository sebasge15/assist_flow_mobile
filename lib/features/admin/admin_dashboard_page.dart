import 'dart:math';
import 'package:flutter/material.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_input.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({
    super.key,
    required this.onLogout,
  });

  final VoidCallback onLogout;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // Profile / settings (mock)
  String companyId = 'comp_demo';
  Map<String, String> companySettings = {
    'expected_start_time': '09:00',
    'expected_end_time': '18:00',
  };

  // Employees
  final List<_Employee> _employees = [];
  bool _isAddingEmployee = false;
  _EmployeeSalaryEdit? _editingSalary;
  Map<String, String>? _newEmployeeCreds; // {pin, password, name}

  // Attendance
  final List<_AttendanceRecord> _records = [];
  String _selectedEmployeeId = 'all';
  String _dateFilter = '';

  // Late today (mock)
  final List<_AttendanceRecord> _lateEmployeesToday = [];

  // Forms
  final _newEmpName = TextEditingController();
  final _newEmpDni = TextEditingController();
  final _newEmpJob = TextEditingController();

  final _salaryCtrl = TextEditingController();
  final _deductionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 9, vsync: this);
    _seedMockData();
  }

  @override
  void dispose() {
    _tab.dispose();
    _newEmpName.dispose();
    _newEmpDni.dispose();
    _newEmpJob.dispose();
    _salaryCtrl.dispose();
    _deductionCtrl.dispose();
    super.dispose();
  }

  // -------------------- MOCK DATA --------------------
  void _seedMockData() {
    // Employees
    _employees.addAll([
      _Employee(id: 'e1', name: 'Ana Torres', dni: '12345678', job: 'Cajera', hourly: 15, deduction: 3),
      _Employee(id: 'e2', name: 'Luis Pérez', dni: '87654321', job: 'Cocinero', hourly: 18, deduction: 4),
      _Employee(id: 'e3', name: 'María Díaz', dni: '44556677', job: 'Mozo', hourly: 14, deduction: 2),
    ]);

    // Attendance (últimos 2 días)
    final now = DateTime.now();
    List<_AttendanceRecord> temp = [];
    for (final e in _employees) {
      for (int d = 0; d < 2; d++) {
        final day = now.subtract(Duration(days: d));
        final dateStr = _fmtDate(day);
        final inTime = DateTime(day.year, day.month, day.day, 9, Random().nextInt(20));
        final outTime = DateTime(day.year, day.month, day.day, 18, Random().nextInt(10));
        final late = inTime.hour > 9 || (inTime.hour == 9 && inTime.minute > 0);
        final lateMin = late ? max(1, inTime.minute) : 0;

        temp.add(_AttendanceRecord(
          id: 'r_${e.id}_${dateStr}_in',
          employeeId: e.id,
          employeeName: e.name,
          type: 'entrada',
          timestamp: inTime,
          recordDate: dateStr,
          isLate: late,
          minutesLate: lateMin,
        ));
        temp.add(_AttendanceRecord(
          id: 'r_${e.id}_${dateStr}_out',
          employeeId: e.id,
          employeeName: e.name,
          type: 'salida',
          timestamp: outTime,
          recordDate: dateStr,
        ));
      }
    }
    temp.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _records.addAll(temp);

    // Late today
    final today = _fmtDate(now);
    _lateEmployeesToday.addAll(_records.where((r) =>
    r.recordDate == today && r.type == 'entrada' && (r.isLate ?? false)));
    setState(() {});
  }

  // -------------------- HELPERS --------------------
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

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, int> _calcWorkedHours(List<_AttendanceRecord> recs) {
    // Suma muy simple: cada "entrada/salida" del mismo día suma ~8h
    final map = <String, int>{};
    for (final r in recs.where((r) => r.type == 'salida')) {
      final key = '${r.employeeId}-${r.recordDate}';
      map[key] = 8;
    }
    return map;
  }

  Map<String, int> get _workedHours => _calcWorkedHours(_records);

  // Export CSV (simulado)
  void _exportToCsv(List<_AttendanceRecord> filtered) {
    if (filtered.isEmpty) {
      _toast('No hay datos para exportar', error: true);
      return;
    }
    _toast('Reporte exportado', subtitle: 'CSV generado (simulado)');
  }

  // Stats de hoy
  _TodayStats _getTodayStats() {
    final today = _fmtDate(DateTime.now());
    final todayRecs = _records.where((r) => r.recordDate == today).toList();
    final entrances = todayRecs.where((r) => r.type == 'entrada').length;
    final exits = todayRecs.where((r) => r.type == 'salida').length;
    final lateCount = _lateEmployeesToday.length;
    return _TodayStats(entrances: entrances, exits: exits, total: todayRecs.length, lateCount: lateCount);
  }

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    final stats = _getTodayStats();
    final filtered = _records.where((r) {
      final byEmp = _selectedEmployeeId == 'all' || r.employeeId == _selectedEmployeeId;
      final byDate = _dateFilter.isEmpty || r.recordDate == _dateFilter;
      return byEmp && byDate;
    }).toList();

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: DefaultTabController(
            length: 9,
            child: Column(
              children: [
                // Header
                _buildHeader(),

                const SizedBox(height: 8),

                // Alert tardanzas
                if (_lateEmployeesToday.isNotEmpty) _buildLateAlert(),

                const SizedBox(height: 8),

                // Stats cards
                _buildStatsRow(stats),

                const SizedBox(height: 8),

                // Tabs
                TabBar(
                  controller: _tab,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  tabs: const [
                    Tab(text: 'Empleados', icon: Icon(Icons.group, size: 16)),
                    Tab(text: 'Asistencia', icon: Icon(Icons.access_time, size: 16)),
                    Tab(text: 'Reportes', icon: Icon(Icons.insert_drive_file, size: 16)),
                    Tab(text: 'Vacaciones', icon: Icon(Icons.calendar_month, size: 16)),
                    Tab(text: 'Evaluaciones', icon: Icon(Icons.trending_up, size: 16)),
                    Tab(text: 'Nómina', icon: Icon(Icons.attach_money, size: 16)),
                    Tab(text: 'Ubicaciones', icon: Icon(Icons.place, size: 16)),
                    Tab(text: 'Notificaciones', icon: Icon(Icons.notifications, size: 16)),
                    Tab(text: 'Config.', icon: Icon(Icons.settings, size: 16)),
                  ],
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _employeesTab(),
                      _attendanceTab(filtered),
                      _placeholderCard('Reportes (pendiente de backend)'),
                      _placeholderCard('Vacaciones (pendiente de backend)'),
                      _placeholderCard('Evaluaciones (pendiente de backend)'),
                      _placeholderCard('Nómina (pendiente de backend)'),
                      _placeholderCard('Ubicaciones (pendiente de backend)'),
                      _placeholderCard('Notificaciones (pendiente de backend)'),
                      _settingsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Header
  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.security, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text('Panel de Administración',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    )),
              ]),
              const SizedBox(height: 2),
              const Text('AsistControl - Gestión de Personal',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: widget.onLogout,
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Cerrar Sesión'),
        ),
      ],
    );
  }

  // Alert tardanzas
  Widget _buildLateAlert() {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.error),
        borderRadius: BorderRadius.circular(12),
      ),
      color: Theme.of(context).colorScheme.error.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(children: [
              Icon(Icons.warning_amber, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 6),
              Text('⚠️ Empleados Tarde Hoy (${_lateEmployeesToday.length})',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  )),
            ]),
            const SizedBox(height: 8),
            Column(
              children: _lateEmployeesToday.map((r) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.employeeName, style: const TextStyle(fontWeight: FontWeight.w500)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('${r.minutesLate ?? 0} min tarde',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Stats
  Widget _buildStatsRow(_TodayStats s) {
    Widget _stat(String title, int value, IconData icon, {Color? accent}) {
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
                '$value',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: accent ?? Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.4, crossAxisSpacing: 8, mainAxisSpacing: 8),
      children: [
        _stat('Empleados Registrados', _employees.length, Icons.group),
        _stat('Entradas Hoy', s.entrances, Icons.login, accent: Theme.of(context).colorScheme.secondary),
        _stat('Salidas Hoy', s.exits, Icons.logout),
        _stat('Tardanzas Hoy', s.lateCount, Icons.warning, accent: Theme.of(context).colorScheme.error),
        _stat('Total Marcaciones', s.total, Icons.receipt_long, accent: Colors.grey[700]),
      ],
    );
  }

  // Tab: Empleados
  Widget _employeesTab() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gestión de Empleados', style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(height: 2),
                      Text('Administra el personal registrado en el sistema', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                AppButton(
                  label: 'Agregar Empleado',
                  icon: Icons.person_add_alt_1,
                  onPressed: () => setState(() => _isAddingEmployee = true),
                  fullWidth: false,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_employees.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.group_off, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No hay empleados registrados', style: TextStyle(color: Colors.grey)),
                    Text('Agrega el primer empleado para comenzar', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _employees.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final e = _employees[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text('DNI: ${e.dni} • ${e.job}', style: const TextStyle(color: Colors.grey)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text('💰 Salario: S/. ${e.hourly.toStringAsFixed(2)}/hr',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(width: 12),
                                    Text('⚠️ Desc.: S/. ${e.deduction.toStringAsFixed(2)}/tardanza',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              _editingSalary = _EmployeeSalaryEdit(
                                id: e.id,
                                name: e.name,
                                hourly: e.hourly,
                                deduction: e.deduction,
                              );
                              _salaryCtrl.text = e.hourly.toStringAsFixed(2);
                              _deductionCtrl.text = e.deduction.toStringAsFixed(2);
                              setState(() {});
                              _openSalaryDialog();
                            },
                            icon: const Icon(Icons.attach_money, size: 16),
                            label: const Text('Editar Salario'),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: const Text('Activo'),
                            side: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            // Dialog crear empleado
            if (_isAddingEmployee) _newEmployeeDialog(),
          ],
        ),
      ),
    );
  }

  Widget _newEmployeeDialog() {
    return _DialogCard(
      title: 'Nuevo Empleado',
      description: 'Completa la información del nuevo empleado',
      onClose: () => setState(() => _isAddingEmployee = false),
      child: Column(
        children: [
          AppInput(label: 'Nombre Completo', hintText: 'Juan Pérez', controller: _newEmpName),
          const SizedBox(height: 10),
          AppInput(label: 'DNI', hintText: '12345678', controller: _newEmpDni, keyboardType: TextInputType.number),
          const SizedBox(height: 10),
          AppInput(label: 'Cargo', hintText: 'Mesero, Cocinero, etc.', controller: _newEmpJob),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Nota: El sistema generará automáticamente un PIN y contraseña seguros para este empleado.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Registrar Empleado',
            icon: Icons.person_add_alt_1,
            onPressed: _addEmployeeMock,
          ),
        ],
      ),
    );
  }

  void _addEmployeeMock() {
    if (_newEmpName.text.trim().isEmpty || _newEmpDni.text.trim().isEmpty || _newEmpJob.text.trim().isEmpty) {
      _toast('Error', subtitle: 'Por favor completa todos los campos', error: true);
      return;
    }
    final emp = _Employee(
      id: 'e_${DateTime.now().millisecondsSinceEpoch}',
      name: _newEmpName.text.trim(),
      dni: _newEmpDni.text.trim(),
      job: _newEmpJob.text.trim(),
      hourly: 15,
      deduction: 3,
    );
    _employees.insert(0, emp);
    // genera credenciales
    _newEmployeeCreds = {
      'name': emp.name,
      'pin': (1000 + Random().nextInt(9000)).toString(),
      'password': 'pw${Random().nextInt(999999)}',
    };
    _newEmpName.clear();
    _newEmpDni.clear();
    _newEmpJob.clear();
    _isAddingEmployee = false;
    setState(() {});
    // abre dialogo credenciales
    _openCredentialsDialog();
    _toast('Empleado creado exitosamente',
        subtitle: '${emp.name} ha sido registrado con credenciales automáticas');
  }

  void _openCredentialsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Credenciales del Empleado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _kv('PIN', _newEmployeeCreds?['pin'] ?? '-'),
            const SizedBox(height: 8),
            _kv('Contraseña', _newEmployeeCreds?['password'] ?? '-'),
            const SizedBox(height: 8),
            Text(
              'Importante: Estas credenciales solo se muestran una vez. Asegúrate de guardarlas en un lugar seguro.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Entendido')),
        ],
      ),
    );
  }

  void _openSalaryDialog() {
    final e = _editingSalary!;
    final hours8 = (double.tryParse(_salaryCtrl.text) ?? e.hourly) * 8;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.attach_money, color: Colors.green[600]),
            const SizedBox(width: 6),
            const Text('Configurar Salario'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Empleado: ${e.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            AppInput(
              label: 'Salario por Hora (S/.)',
              hintText: '15.00',
              controller: _salaryCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            AppInput(
              label: 'Descuento por Tardanza (S/.)',
              hintText: '5.00',
              controller: _deductionCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vista Previa:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('• Por 8 horas: S/. ${hours8.toStringAsFixed(2)}'),
                  Text('• Por 1 tardanza: -S/. ${(double.tryParse(_deductionCtrl.text) ?? e.deduction).toStringAsFixed(2)}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final h = double.tryParse(_salaryCtrl.text) ?? e.hourly;
              final d = double.tryParse(_deductionCtrl.text) ?? e.deduction;
              final idx = _employees.indexWhere((x) => x.id == e.id);
              if (idx != -1) {
                _employees[idx] = _employees[idx].copyWith(hourly: h, deduction: d);
              }
              Navigator.of(context).pop();
              setState(() => _editingSalary = null);
              _toast('Salario actualizado', subtitle: 'Se actualizó el salario de ${e.name}');
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$k:', style: const TextStyle(fontWeight: FontWeight.w600)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withOpacity(.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(v, style: const TextStyle(fontFamily: 'monospace')),
        ),
      ],
    );
  }

  // Tab: Asistencia
  Widget _attendanceTab(List<_AttendanceRecord> filtered) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Historial de Asistencia', style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(height: 2),
                      Text('Consulta y exporta los registros de marcación', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                AppButton(
                  label: 'Exportar CSV',
                  icon: Icons.download,
                  onPressed: () => _exportToCsv(filtered),
                  fullWidth: false,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Filtros
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Empleado', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedEmployeeId,
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('Todos los empleados')),
                          ..._employees.map((e) =>
                              DropdownMenuItem(value: e.id, child: Text(e.name))),
                        ],
                        onChanged: (v) => setState(() => _selectedEmployeeId = v ?? 'all'),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fecha', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextFormField(
                        decoration: const InputDecoration(
                          hintText: 'YYYY-MM-DD',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() => _dateFilter = v.trim()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Records
            if (filtered.isEmpty)
              const Expanded(
                child: Center(
                  child: Opacity(
                    opacity: .6,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 48),
                        SizedBox(height: 8),
                        Text('No se encontraron registros'),
                        Text('Ajusta los filtros o espera nuevas marcaciones', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = filtered[i];
                    final date = '${r.timestamp.day.toString().padLeft(2, '0')}/${r.timestamp.month.toString().padLeft(2, '0')}/${r.timestamp.year}';
                    final time = '${r.timestamp.hour.toString().padLeft(2, '0')}:${r.timestamp.minute.toString().padLeft(2, '0')}';
                    final key = '${r.employeeId}-${r.recordDate}';
                    final hoursWorked = _workedHours[key];

                    Color badgeColor;
                    if (r.type == 'entrada') {
                      badgeColor = Theme.of(context).colorScheme.primary;
                    } else if (r.type == 'salida') {
                      badgeColor = Theme.of(context).colorScheme.secondary;
                    } else {
                      badgeColor = Theme.of(context).dividerColor;
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(r.employeeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 6),
                                  if (r.isLate == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.error.withOpacity(.12),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '${r.minutesLate} min tarde',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.error,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ]),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 6,
                                  children: [
                                    _pill(icon: Icons.calendar_month, label: date),
                                    _pill(icon: Icons.schedule, label: time),
                                    if (hoursWorked != null)
                                      _pill(icon: Icons.bolt, label: '${hoursWorked}h trabajadas', color: Theme.of(context).colorScheme.primary),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _badge(r.type.toUpperCase(), badgeColor),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.adjust, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _pill({required IconData icon, required String label, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey[700]!).withOpacity(.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.grey[700]),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color ?? Colors.grey[700])),
        ],
      ),
    );
  }

  // Tab: Configuración (horarios)
  Widget _settingsTab() {
    final startCtrl = TextEditingController(text: companySettings['expected_start_time']);
    final endCtrl = TextEditingController(text: companySettings['expected_end_time']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Configuración de Horarios', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Establece los horarios de trabajo para la empresa', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppInput(
                    label: 'Hora de Entrada',
                    hintText: '09:00',
                    controller: startCtrl,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppInput(
                    label: 'Hora de Salida',
                    hintText: '18:00',
                    controller: endCtrl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Nota: Los empleados ahora manejan sus propios horarios de almuerzo marcando "Inicio Almuerzo" y "Fin Almuerzo".',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Guardar Configuración',
              onPressed: () {
                companySettings = {
                  'expected_start_time': startCtrl.text.trim(),
                  'expected_end_time': endCtrl.text.trim(),
                };
                setState(() {});
                _toast('Configuración actualizada',
                    subtitle: 'Los horarios de trabajo han sido actualizados');
              },
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder simple para tabs aún no implementadas
  Widget _placeholderCard(String message) {
    return Card(
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Opacity(
            opacity: .7,
            child: Center(
              child: Text(message, textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------- MODELOS SIMPLES --------------------
class _Employee {
  final String id;
  final String name;
  final String dni;
  final String job;
  final double hourly;
  final double deduction;

  _Employee({
    required this.id,
    required this.name,
    required this.dni,
    required this.job,
    required this.hourly,
    required this.deduction,
  });

  _Employee copyWith({double? hourly, double? deduction}) => _Employee(
    id: id,
    name: name,
    dni: dni,
    job: job,
    hourly: hourly ?? this.hourly,
    deduction: deduction ?? this.deduction,
  );
}

class _EmployeeSalaryEdit {
  final String id;
  final String name;
  final double hourly;
  final double deduction;

  _EmployeeSalaryEdit({
    required this.id,
    required this.name,
    required this.hourly,
    required this.deduction,
  });
}

class _AttendanceRecord {
  final String id;
  final String employeeId;
  final String employeeName;
  final String type; // entrada | salida | inicio_almuerzo | fin_almuerzo
  final DateTime timestamp;
  final String recordDate;
  final bool? isLate;
  final int? minutesLate;

  _AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.type,
    required this.timestamp,
    required this.recordDate,
    this.isLate,
    this.minutesLate,
  });
}

class _TodayStats {
  final int entrances;
  final int exits;
  final int total;
  final int lateCount;
  _TodayStats({required this.entrances, required this.exits, required this.total, required this.lateCount});
}

// -------------------- Dialog Card helper --------------------
class _DialogCard extends StatelessWidget {
  const _DialogCard({
    required this.title,
    required this.description,
    required this.child,
    required this.onClose,
  });

  final String title;
  final String description;
  final Widget child;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // backdrop
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: Container(color: Colors.black54),
          ),
        ),
        // card
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                            const SizedBox(height: 4),
                            Text(description, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
