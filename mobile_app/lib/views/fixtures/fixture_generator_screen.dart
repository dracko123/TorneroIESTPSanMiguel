import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/match_model.dart';
import '../../models/team_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/fixture_generator.dart';

class FixtureGeneratorScreen extends StatefulWidget {
  final List<TeamModel> teams;
  final List<MatchModel> existingMatches;
  final VoidCallback onGenerated;

  const FixtureGeneratorScreen({
    super.key,
    required this.teams,
    required this.existingMatches,
    required this.onGenerated,
  });

  @override
  State<FixtureGeneratorScreen> createState() => _FixtureGeneratorScreenState();
}

class _FixtureGeneratorScreenState extends State<FixtureGeneratorScreen> {
  DateTime _startDateTime = DateTime.now().add(const Duration(hours: 2));
  int _intervalMinutes = 60;
  bool _idaYVuelta = false;
  final TextEditingController _canchasController = TextEditingController(text: 'Cancha 1, Cancha 2');

  List<TeamModel> _currentTeams = [];
  List<MatchModel> _previewMatches = [];
  FixtureGenerationResult? _result;
  bool _isSaving = false;
  bool _hasShuffled = false;

  @override
  void initState() {
    super.initState();
    _currentTeams = List<TeamModel>.from(widget.teams);
    _generatePreview();
  }

  @override
  void dispose() {
    _canchasController.dispose();
    super.dispose();
  }

  void _generatePreview() {
    final canchas = _canchasController.text
        .split(',')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    final options = FixtureGeneratorOptions(
      startDateTime: _startDateTime,
      matchIntervalMinutes: _intervalMinutes,
      canchas: canchas.isNotEmpty ? canchas : ['Cancha 1'],
      idaYVuelta: _idaYVuelta,
    );

    final res = FixtureGenerator.generateGroupStageFixture(
      allTeams: _currentTeams,
      options: options,
      existingMatches: widget.existingMatches,
    );

    setState(() {
      _result = res;
      _previewMatches = res.matches;
    });
  }

  void _performDraw() {
    // Obtener lista de grupos existentes
    final groups = _currentTeams.map((t) => t.grupo.toUpperCase()).toSet().toList()..sort();
    final targetGroups = groups.isNotEmpty ? groups : ['A', 'B'];

    final shuffled = FixtureGenerator.shuffleAndDistributeTeams(
      teams: _currentTeams,
      targetGroups: targetGroups,
    );

    setState(() {
      _currentTeams = shuffled;
      _hasShuffled = true;
    });

    _generatePreview();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎲 ¡Sorteo realizado! Equipos redistribuidos equitativamente en los grupos.'),
        backgroundColor: AppTheme.turfGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
        initialTime: TimeOfDay.fromDateTime(_startDateTime),
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
          _startDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
        _generatePreview();
      }
    }
  }

  Future<void> _saveGeneratedFixture() async {
    if (_previewMatches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay partidos para guardar')),
      );
      return;
    }

    final token = AuthService().currentUser?.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión no autorizada')),
      );
      return;
    }

    // Si se realizó sorteo, guardar primero los equipos con sus nuevos grupos
    setState(() => _isSaving = true);
    final api = ApiService();

    try {
      if (_hasShuffled) {
        for (final t in _currentTeams) {
          await api.saveTeam(token: token, team: t);
        }
      }

      final res = await api.batchSaveMatches(
        token: token,
        matches: _previewMatches,
      );

      setState(() => _isSaving = false);

      if (res.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.data ?? 'Fixture guardado exitosamente'),
              backgroundColor: AppTheme.turfGreen,
            ),
          );
          widget.onGenerated();
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.error ?? 'Error al guardar fixture'),
              backgroundColor: AppTheme.liveRed,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.liveRed),
        );
      }
    }
  }

  String _getTeamName(String id) {
    final team = _currentTeams.firstWhere(
      (t) => t.idEquipo == id,
      orElse: () => TeamModel(idEquipo: id, nombre: id, grupo: '', colorHex: '#3B82F6'),
    );
    return team.nombre;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _currentTeams.map((t) => t.grupo.toUpperCase()).toSet().toList()..sort();

    return Scaffold(
      backgroundColor: AppTheme.stadiumDarkBg,
      appBar: AppBar(
        title: const Text('Generador de Fixture y Sorteo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.turfGreenLight),
            tooltip: 'Regenerar vista previa',
            onPressed: _generatePreview,
          ),
        ],
      ),
      body: _isSaving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.turfGreen),
                  SizedBox(height: 16),
                  Text('Guardando partidos en Google Sheets...', style: TextStyle(color: Colors.white)),
                  SizedBox(height: 8),
                  Text('Verificando anti-duplicados...', style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 12)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // TARJETA 1: SORTEO DE EQUIPOS EN GRUPOS
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.casino, color: AppTheme.trophyGold, size: 22),
                            const SizedBox(width: 8),
                            const Text('Sorteo de Grupos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const Spacer(),
                            if (_hasShuffled)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.turfGreen.withAlpha(40),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.turfGreen),
                                ),
                                child: const Text('Sorteado', style: TextStyle(color: AppTheme.turfGreenLight, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Equipos registrados: ${_currentTeams.length} en ${groups.length} grupos (${groups.join(", ")}). '
                          'Puedes mezclar y sortear los equipos en los grupos de forma aleatoria.',
                          style: const TextStyle(color: AppTheme.slateTextSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.trophyGold),
                              foregroundColor: AppTheme.trophyGold,
                            ),
                            onPressed: _performDraw,
                            icon: const Icon(Icons.shuffle, size: 18),
                            label: const Text('REALIZAR SORTEO ALEATORIO'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // TARJETA 2: PARÁMETROS DEL FIXTURE (ALGORITMO ROUND-ROBIN)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.tune, color: AppTheme.turfGreenLight, size: 22),
                            SizedBox(width: 8),
                            Text('Parámetros del Fixture', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Fecha y hora base
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Fecha y Hora Inicial', style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 13)),
                          subtitle: Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(_startDateTime),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_calendar, color: AppTheme.turfGreen),
                            onPressed: _selectDateTime,
                          ),
                        ),
                        const Divider(color: Colors.white10),

                        // Intervalo entre partidos
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Tiempo entre partidos:', style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 13)),
                            ),
                            DropdownButton<int>(
                              value: _intervalMinutes,
                              dropdownColor: AppTheme.stadiumElevatedBg,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              items: const [
                                DropdownMenuItem(value: 30, child: Text('30 min')),
                                DropdownMenuItem(value: 45, child: Text('45 min')),
                                DropdownMenuItem(value: 60, child: Text('60 min (1h)')),
                                DropdownMenuItem(value: 90, child: Text('90 min')),
                                DropdownMenuItem(value: 120, child: Text('120 min (2h)')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _intervalMinutes = val);
                                  _generatePreview();
                                }
                              },
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white10),

                        // Modalidad Solo Ida vs Ida y Vuelta
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppTheme.turfGreen,
                          title: const Text('Modalidad Ida y Vuelta', style: TextStyle(color: Colors.white, fontSize: 14)),
                          subtitle: Text(
                            _idaYVuelta
                                ? '2 ruedas: Cada cruce se juega de local y de visita.'
                                : '1 sola rueda (todos contra todos solo ida).',
                            style: const TextStyle(color: AppTheme.slateTextSecondary, fontSize: 12),
                          ),
                          value: _idaYVuelta,
                          onChanged: (val) {
                            setState(() => _idaYVuelta = val);
                            _generatePreview();
                          },
                        ),
                        const Divider(color: Colors.white10),

                        // Canchas
                        TextField(
                          controller: _canchasController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Canchas / Sedes (separadas por coma)',
                            helperText: 'El algoritmo alternará los partidos entre las canchas ingresadas.',
                            helperStyle: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 11),
                          ),
                          onChanged: (_) => _generatePreview(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // TARJETA 3: RESUMEN Y VISTA PREVIA DEL ALGORITMO
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.checklist, color: AppTheme.turfGreenLight, size: 22),
                            const SizedBox(width: 8),
                            const Text('Resumen del Algoritmo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.turfGreen.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.turfGreen.withAlpha(100)),
                              ),
                              child: const Text('🛡️ 0 Duplicados', style: TextStyle(color: AppTheme.turfGreenLight, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Partidos a crear', '${_previewMatches.length}'),
                            _buildStatItem('Jornadas/Ruedas', '${_result?.totalRounds ?? 0}'),
                            _buildStatItem('Grupos', '${_result?.matchesPerGroup.length ?? 0}'),
                          ],
                        ),
                        if (_result != null && _result!.restMessages.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _result!.restMessages.take(4).map((msg) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text('ℹ️ $msg', style: const TextStyle(color: AppTheme.slateTextSecondary, fontSize: 11)),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // LISTA DE PARTIDOS GENERADOS (VISTA PREVIA)
                const Text('Partidos Generados (Vista Previa):', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),

                if (_previewMatches.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: const Text(
                      'No se generaron partidos. Verifica que haya al menos 2 equipos por grupo.',
                      style: TextStyle(color: AppTheme.slateTextSecondary),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...List.generate(_previewMatches.length, (idx) {
                    final m = _previewMatches[idx];
                    final localName = _getTeamName(m.localId);
                    final visitaName = _getTeamName(m.visitaId);
                    final dt = DateTime.tryParse(m.fechaHora)?.toLocal();
                    final timeStr = dt != null ? DateFormat('dd/MM HH:mm').format(dt) : m.fechaHora;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.turfGreen.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                m.fase,
                                style: const TextStyle(color: AppTheme.turfGreenLight, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$localName  vs  $visitaName',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$timeStr • ${m.cancha}',
                                    style: const TextStyle(color: AppTheme.slateTextSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.check_circle_outline, color: AppTheme.turfGreen, size: 18),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 24),

                // BOTÓN DE CONFIRMACIÓN
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.turfGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _previewMatches.isEmpty || _isSaving ? null : _saveGeneratedFixture,
                    icon: const Icon(Icons.cloud_upload, size: 22),
                    label: Text(
                      'CONFIRMAR Y GUARDAR (${_previewMatches.length} PARTIDOS)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: AppTheme.turfGreenLight, fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.slateTextSecondary, fontSize: 11)),
      ],
    );
  }
}
