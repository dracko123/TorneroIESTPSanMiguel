import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/tournament_config_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'users_management_screen.dart';

class TournamentConfigScreen extends StatefulWidget {
  final TournamentConfigModel config;
  final VoidCallback onConfigSaved;

  const TournamentConfigScreen({
    super.key,
    required this.config,
    required this.onConfigSaved,
  });

  @override
  State<TournamentConfigScreen> createState() => _TournamentConfigScreenState();
}

class _TournamentConfigScreenState extends State<TournamentConfigScreen> {
  late TextEditingController _nameController;
  late TextEditingController _countdownTitleController;
  late TextEditingController _organizerNameController;
  late TextEditingController _organizerLogoController;
  late TextEditingController _bannerBgController;
  late TextEditingController _ptsVictoriaController;
  late TextEditingController _ptsEmpateController;
  late TextEditingController _ptsDerrotaController;
  late TextEditingController _ptsVictoriaWoController;
  late TextEditingController _ptsDerrotaWoController;
  late TextEditingController _golesWoFavorController;
  late TextEditingController _golesWoContraController;
  late String _faseActual;
  late int _clasificados;
  late DateTime _targetDateTime;
  bool _isSaving = false;

  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.config.nombreEvento);
    _countdownTitleController = TextEditingController(text: widget.config.countdownTitle);
    _organizerNameController = TextEditingController(text: widget.config.organizadorNombre);
    _organizerLogoController = TextEditingController(text: widget.config.organizadorLogoUrl);
    _bannerBgController = TextEditingController(text: widget.config.bannerBgUrl);
    _ptsVictoriaController = TextEditingController(text: widget.config.puntosVictoria.toString());
    _ptsEmpateController = TextEditingController(text: widget.config.puntosEmpate.toString());
    _ptsDerrotaController = TextEditingController(text: widget.config.puntosDerrota.toString());
    _ptsVictoriaWoController = TextEditingController(text: widget.config.puntosVictoriaWo.toString());
    _ptsDerrotaWoController = TextEditingController(text: widget.config.puntosDerrotaWo.toString());
    _golesWoFavorController = TextEditingController(text: widget.config.golesWoFavor.toString());
    _golesWoContraController = TextEditingController(text: widget.config.golesWoContra.toString());
    _faseActual = widget.config.faseActual;
    _clasificados = widget.config.clasificadosPorGrupo;

    try {
      _targetDateTime = DateTime.parse(widget.config.countdownTarget);
    } catch (_) {
      _targetDateTime = DateTime.now().add(const Duration(days: 5));
    }

    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculateTimeLeft());
  }

  @override
  void didUpdateWidget(covariant TournamentConfigScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSaving &&
        (oldWidget.config.nombreEvento != widget.config.nombreEvento ||
         oldWidget.config.organizadorNombre != widget.config.organizadorNombre ||
         oldWidget.config.organizadorLogoUrl != widget.config.organizadorLogoUrl ||
         oldWidget.config.bannerBgUrl != widget.config.bannerBgUrl ||
         oldWidget.config.countdownTitle != widget.config.countdownTitle ||
         oldWidget.config.faseActual != widget.config.faseActual ||
         oldWidget.config.clasificadosPorGrupo != widget.config.clasificadosPorGrupo ||
         oldWidget.config.puntosVictoria != widget.config.puntosVictoria ||
         oldWidget.config.puntosEmpate != widget.config.puntosEmpate ||
         oldWidget.config.puntosDerrota != widget.config.puntosDerrota ||
         oldWidget.config.puntosVictoriaWo != widget.config.puntosVictoriaWo ||
         oldWidget.config.puntosDerrotaWo != widget.config.puntosDerrotaWo ||
         oldWidget.config.golesWoFavor != widget.config.golesWoFavor ||
         oldWidget.config.golesWoContra != widget.config.golesWoContra ||
         oldWidget.config.countdownTarget != widget.config.countdownTarget)) {
      _nameController.text = widget.config.nombreEvento;
      _countdownTitleController.text = widget.config.countdownTitle;
      _organizerNameController.text = widget.config.organizadorNombre;
      _organizerLogoController.text = widget.config.organizadorLogoUrl;
      _bannerBgController.text = widget.config.bannerBgUrl;
      _ptsVictoriaController.text = widget.config.puntosVictoria.toString();
      _ptsEmpateController.text = widget.config.puntosEmpate.toString();
      _ptsDerrotaController.text = widget.config.puntosDerrota.toString();
      _ptsVictoriaWoController.text = widget.config.puntosVictoriaWo.toString();
      _ptsDerrotaWoController.text = widget.config.puntosDerrotaWo.toString();
      _golesWoFavorController.text = widget.config.golesWoFavor.toString();
      _golesWoContraController.text = widget.config.golesWoContra.toString();
      _faseActual = widget.config.faseActual;
      _clasificados = widget.config.clasificadosPorGrupo;
      try {
        _targetDateTime = DateTime.parse(widget.config.countdownTarget);
      } catch (_) {}
      _calculateTimeLeft();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    _countdownTitleController.dispose();
    _organizerNameController.dispose();
    _organizerLogoController.dispose();
    _bannerBgController.dispose();
    _ptsVictoriaController.dispose();
    _ptsEmpateController.dispose();
    _ptsDerrotaController.dispose();
    _ptsVictoriaWoController.dispose();
    _ptsDerrotaWoController.dispose();
    _golesWoFavorController.dispose();
    _golesWoContraController.dispose();
    super.dispose();
  }

  void _calculateTimeLeft() {
    final diff = _targetDateTime.difference(DateTime.now());
    if (mounted) {
      setState(() {
        _timeLeft = diff.isNegative ? Duration.zero : diff;
      });
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _targetDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.turfGreen,
            surface: AppTheme.stadiumCardBg,
          ),
        ),
        child: child!,
      ),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_targetDateTime),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.turfGreen,
              surface: AppTheme.stadiumCardBg,
            ),
          ),
          child: child!,
        ),
      );

      if (time != null && mounted) {
        setState(() {
          _targetDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
        _calculateTimeLeft();
      }
    }
  }

  Future<void> _saveConfig() async {
    final auth = AuthService();
    final token = auth.currentUser?.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión no autorizada')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final updated = TournamentConfigModel(
      nombreEvento: _nameController.text.trim(),
      disciplina: 'FUTBOL',
      countdownTarget: _targetDateTime.toUtc().toIso8601String(),
      countdownTitle: _countdownTitleController.text.trim(),
      faseActual: _faseActual,
      clasificadosPorGrupo: _clasificados,
      organizadorNombre: _organizerNameController.text.trim(),
      organizadorLogoUrl: _organizerLogoController.text.trim(),
      bannerBgUrl: _bannerBgController.text.trim(),
      puntosVictoria: int.tryParse(_ptsVictoriaController.text.trim()) ?? 3,
      puntosEmpate: int.tryParse(_ptsEmpateController.text.trim()) ?? 1,
      puntosDerrota: int.tryParse(_ptsDerrotaController.text.trim()) ?? 0,
      puntosVictoriaWo: int.tryParse(_ptsVictoriaWoController.text.trim()) ?? 3,
      puntosDerrotaWo: int.tryParse(_ptsDerrotaWoController.text.trim()) ?? -1,
      golesWoFavor: int.tryParse(_golesWoFavorController.text.trim()) ?? 3,
      golesWoContra: int.tryParse(_golesWoContraController.text.trim()) ?? 0,
    );

    final res = await ApiService().saveTournamentConfig(token: token, config: updated);

    setState(() => _isSaving = false);

    if (mounted) {
      if (res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.turfGreen,
            content: Text('Configuración y Cuenta Regresiva sincronizadas con Google Sheets', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        );
        widget.onConfigSaved();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.liveRed, content: Text(res.error ?? 'Error al guardar')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final minutes = _timeLeft.inMinutes % 60;
    final seconds = _timeLeft.inSeconds % 60;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner de Vista Previa del Reloj Regresivo (como se verá en el Portal Web)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.trophyGold.withAlpha(80)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, color: AppTheme.trophyGold, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _countdownTitleController.text.isEmpty
                          ? 'Cuenta Regresiva Oficial'
                          : _countdownTitleController.text,
                      style: const TextStyle(
                        color: AppTheme.trophyGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Reloj de Dígitos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTimeBox('$days', 'DÍAS'),
                    _buildColon(),
                    _buildTimeBox('$hours'.padLeft(2, '0'), 'HORAS'),
                    _buildColon(),
                    _buildTimeBox('$minutes'.padLeft(2, '0'), 'MIN'),
                    _buildColon(),
                    _buildTimeBox('$seconds'.padLeft(2, '0'), 'SEG'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Destino: ${DateFormat('dd/MM/yyyy HH:mm').format(_targetDateTime)} UTC',
                  style: const TextStyle(color: AppTheme.slateTextSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tarjeta de Parámetros del Torneo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Parámetros del Evento',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  // Nombre del Torneo
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nombre Oficial del Torneo',
                      prefixIcon: Icon(Icons.emoji_events, color: AppTheme.trophyGold),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Título de la Cuenta Regresiva
                  TextField(
                    controller: _countdownTitleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Título del Reloj en el Portal Web',
                      prefixIcon: Icon(Icons.alarm, color: AppTheme.turfGreenLight),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // Botón para seleccionar Fecha y Hora de la cuenta regresiva
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      side: const BorderSide(color: AppTheme.turfGreen),
                    ),
                    onPressed: _selectDateTime,
                    icon: const Icon(Icons.calendar_month, color: AppTheme.turfGreen),
                    label: Text(
                      'Cambiar Fecha Objetivo: ${DateFormat('dd/MM/yyyy - hh:mm a').format(_targetDateTime)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Selector de Fase Actual
                  const Text('Fase Actual del Torneo', style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _faseActual,
                    dropdownColor: AppTheme.stadiumElevatedBg,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.flag, color: AppTheme.turfGreenLight),
                    ),
                    items: const [
                      DropdownMenuItem(value: AppConstants.phaseGrupos, child: Text('FASE DE GRUPOS')),
                      DropdownMenuItem(value: AppConstants.phaseCuartos, child: Text('CUARTOS DE FINAL')),
                      DropdownMenuItem(value: AppConstants.phaseSemifinal, child: Text('SEMIFINALES')),
                      DropdownMenuItem(value: AppConstants.phaseFinal, child: Text('GRAN FINAL')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _faseActual = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Clasificados por grupo
                  const Text('Equipos clasificados a playoffs por grupo', style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [0, 1, 2, 3, 4].map((count) {
                      final isSelected = _clasificados == count;
                      final label = count == 0 ? 'Desactivado (0)' : '$count clasif.';
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: AppTheme.turfGreen,
                        backgroundColor: AppTheme.stadiumElevatedBg,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) => setState(() => _clasificados = count),
                      );
                    }).toList(),
                  ),
                  if (_clasificados == 0)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'ℹ️ La zona de clasificación estará oculta (ideal para todos contra todos)',
                        style: TextStyle(color: AppTheme.turfGreenLight, fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card de Sistema de Puntuación y Walkover (W.O.)
          Card(
            color: AppTheme.stadiumCardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.turfGreen.withAlpha(50)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.scoreboard_outlined, color: AppTheme.turfGreen, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Sistema de Puntuación y Walkover (W.O.)',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Define los puntos otorgados en partidos jugados y las sanciones reglamentarias por W.O.',
                    style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 12),
                  ),
                  const Divider(color: Colors.white10, height: 24),

                  // Fila Victoria, Empate, Derrota regular
                  const Text('Partidos Jugados Normalmente', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ptsVictoriaController,
                          keyboardType: const TextInputType.numberWithOptions(signed: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Victoria (PG)',
                            hintText: '3',
                            prefixIcon: Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _ptsEmpateController,
                          keyboardType: const TextInputType.numberWithOptions(signed: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Empate (PE)',
                            hintText: '1',
                            prefixIcon: Icon(Icons.horizontal_rule, color: Colors.amberAccent, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _ptsDerrotaController,
                          keyboardType: const TextInputType.numberWithOptions(signed: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Derrota (PP)',
                            hintText: '0',
                            prefixIcon: Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Fila Walkover (W.O.) Ganador y Sanción Perdedor
                  const Text('Reglas de Walkover (W.O. / Incomparecencia)', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                    'Ingresa un valor negativo (ej. -1 o -2) en la sanción para restar puntos reales en la tabla de posiciones.',
                    style: TextStyle(color: Colors.amber, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ptsVictoriaWoController,
                          keyboardType: const TextInputType.numberWithOptions(signed: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Puntos Ganador W.O.',
                            hintText: '3',
                            prefixIcon: Icon(Icons.military_tech_outlined, color: Colors.greenAccent, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _ptsDerrotaWoController,
                          keyboardType: const TextInputType.numberWithOptions(signed: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Sanción Perdedor W.O.',
                            hintText: '-1',
                            prefixIcon: Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Marcador reglamentario por W.O.
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _golesWoFavorController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Goles Ganador W.O.',
                            hintText: '3',
                            prefixIcon: Icon(Icons.sports_soccer, color: AppTheme.turfGreen, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _golesWoContraController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Goles Infractor W.O.',
                            hintText: '0',
                            prefixIcon: Icon(Icons.sports_soccer, color: Colors.white38, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card de Gestión de Usuarios y Mesas de Control
          Card(
            color: AppTheme.stadiumCardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.purpleAccent.withAlpha(60)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.manage_accounts, color: Colors.purpleAccent, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Mesas de Control y Anotadores',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Crea y administra cuentas exclusivas para los responsables de mesa. Solo podrán ingresar y registrar goles en sus partidos asignados.',
                    style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.purpleAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const UsersManagementScreen()),
                        );
                      },
                      icon: const Icon(Icons.people_outline, color: Colors.purpleAccent),
                      label: const Text(
                        'Gestionar Mesas y Usuarios',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card de Entidad Organizadora y Branding
          Card(
            color: AppTheme.stadiumCardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.trophyGold.withAlpha(50)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.business, color: AppTheme.trophyGold, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Entidad Organizadora y Banner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Personaliza el nombre y logo del comité organizador en la web.',
                    style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 12),
                  ),
                  const Divider(color: Colors.white10, height: 24),

                  // Nombre del Organizador
                  TextField(
                    controller: _organizerNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Organizador / Comité',
                      hintText: 'Ej. Comité Magisterial 2026',
                      prefixIcon: Icon(Icons.shield, color: AppTheme.trophyGold),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // URL del Logo del Organizador
                  TextField(
                    controller: _organizerLogoController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'URL del Logo del Organizador',
                      hintText: 'https://.../logo.png',
                      prefixIcon: Icon(Icons.image, color: AppTheme.turfGreenLight),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // URL de Banner de Fondo Deportivo
                  TextField(
                    controller: _bannerBgController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'URL de Imagen de Fondo (Opcional)',
                      hintText: 'https://.../estadio.jpg (Vacío = Estadio Nocturno HD)',
                      prefixIcon: Icon(Icons.wallpaper, color: AppTheme.slateTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Botón Guardar y Sincronizar
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveConfig,
              icon: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.black)))
                  : const Icon(Icons.cloud_sync, size: 22),
              label: Text(
                _isSaving ? 'SINCRONIZANDO...' : 'GUARDAR Y ACTUALIZAR PORTAL',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String value, String label) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(140),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.turfGreen.withAlpha(60)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.turfGreenLight,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppTheme.slateTextSecondary, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildColon() {
    return const Text(
      ':',
      style: TextStyle(color: AppTheme.turfGreen, fontSize: 20, fontWeight: FontWeight.bold),
    );
  }
}
