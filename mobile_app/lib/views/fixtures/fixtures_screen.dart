import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/match_model.dart';
import '../../models/team_model.dart';
import '../../models/tournament_config_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'fixture_generator_screen.dart';
import 'match_score_sheet.dart';

class FixturesScreen extends StatefulWidget {
  final List<MatchModel> matches;
  final List<TeamModel> teams;
  final TournamentConfigModel? config;
  final VoidCallback onMatchesUpdated;

  const FixturesScreen({
    super.key,
    required this.matches,
    required this.teams,
    this.config,
    required this.onMatchesUpdated,
  });

  @override
  State<FixturesScreen> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends State<FixturesScreen> {
  bool _hideFinished = false;
  final ScrollController _scrollController = ScrollController();

  // Fases colapsadas: key = nombre de fase
  final Set<String> _collapsedPhases = {};

  // ──────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────

  TeamModel? _getTeam(String teamId) {
    return widget.teams.firstWhere(
      (t) => t.idEquipo == teamId,
      orElse: () => TeamModel(idEquipo: teamId, nombre: teamId, grupo: '', colorHex: '#64748B'),
    );
  }

  /// Devuelve las fases de playoff disponibles según la cantidad de grupos
  /// detectada automáticamente a partir de los equipos registrados.
  List<String> _playoffPhases() {
    final numGrupos = widget.teams.map((t) => t.grupo).toSet().length;
    final clasifPorGrupo = widget.config?.clasificadosPorGrupo ?? 2;
    final totalClassified = numGrupos * clasifPorGrupo;

    final List<String> fases = [];
    if (totalClassified >= 16) fases.add('Octavos de Final');
    if (totalClassified >= 8 || numGrupos >= 4) fases.add('Cuartos de Final');
    if (totalClassified >= 4 || numGrupos >= 2) fases.add('Semifinal');
    fases.add('Gran Final');
    return fases;
  }

  /// Retorna el top-N de cada grupo (clasificados automáticos).
  List<TeamModel> _classifiedTeams() {
    final clasifPorGrupo = widget.config?.clasificadosPorGrupo ?? 2;
    final grupos = widget.teams.map((t) => t.grupo).toSet();

    final List<TeamModel> classified = [];
    for (final g in grupos) {
      final grupoTeams = widget.teams.where((t) => t.grupo == g).toList()
        ..sort((a, b) {
          final pointsDiff = b.puntos.compareTo(a.puntos);
          if (pointsDiff != 0) return pointsDiff;
          return b.dg.compareTo(a.dg); // desempate por diferencia de goles
        });
      classified.addAll(grupoTeams.take(clasifPorGrupo));
    }
    return classified;
  }

  /// Construye el mapa de fases → lista de partidos, ordenado lógicamente.
  Map<String, List<MatchModel>> _groupByPhase() {
    // Orden lógico de las fases
    const phaseOrder = [
      'grupo a', 'grupo b', 'grupo c', 'grupo d', 'grupo e', 'grupo f',
      'regular', 'jornada',
      'octavos', 'cuartos', 'semifinal', 'final',
    ];

    final Map<String, List<MatchModel>> grouped = {};
    for (final m in widget.matches) {
      final fase = m.fase.trim();
      grouped.putIfAbsent(fase, () => []).add(m);
    }

    // Ordenar partidos dentro de cada fase por fecha
    for (final faseMatches in grouped.values) {
      faseMatches.sort((a, b) {
        final da = DateTime.tryParse(a.fechaHora);
        final db = DateTime.tryParse(b.fechaHora);
        if (da == null || db == null) return 0;
        return da.compareTo(db);
      });
    }

    // Ordenar fases según phaseOrder
    final sortedKeys = grouped.keys.toList()..sort((a, b) {
      final ia = phaseOrder.indexWhere((p) => a.toLowerCase().contains(p));
      final ib = phaseOrder.indexWhere((p) => b.toLowerCase().contains(p));
      final ra = ia == -1 ? 999 : ia;
      final rb = ib == -1 ? 999 : ib;
      return ra.compareTo(rb);
    });

    final Map<String, List<MatchModel>> sorted = {};
    for (final k in sortedKeys) {
      sorted[k] = grouped[k]!;
    }
    return sorted;
  }

  // ──────────────────────────────────────────────────────────────
  // Dialogs
  // ──────────────────────────────────────────────────────────────

  void _showQuickScoreSheet(MatchModel match) {
    final loc = _getTeam(match.localId);
    final vis = _getTeam(match.visitaId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: MatchScoreBottomSheet(
          match: match,
          localNombre: loc?.nombre ?? match.localId,
          visitaNombre: vis?.nombre ?? match.visitaId,
          onUpdated: () {
            final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
            widget.onMatchesUpdated();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(offset.clamp(
                  0.0,
                  _scrollController.position.maxScrollExtent,
                ));
              }
            });
          },
        ),
      ),
    );
  }

  void _showAddMatchDialog([MatchModel? existingMatch]) {
    if (widget.teams.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe registrar al menos 2 equipos antes de programar partidos')),
      );
      return;
    }

    // Determinar si es partido de playoff según la fase actual del existente
    bool isPlayoff = existingMatch?.isPlayoff ?? false;

    // Fuentes de equipos: todos o solo clasificados si es playoff
    List<TeamModel> availableTeams() {
      if (!isPlayoff) return widget.teams;
      final classified = _classifiedTeams();
      return classified.isEmpty ? widget.teams : classified;
    }

    String localId = existingMatch?.localId ?? availableTeams().first.idEquipo;
    String visitaId = existingMatch?.visitaId ??
        (availableTeams().length > 1 ? availableTeams()[1].idEquipo : availableTeams().first.idEquipo);

    // Determinar lista de fases dinámica
    final gruposDisponibles = widget.teams.map((t) => t.grupo).toSet().toList()..sort();
    final groupPhases = gruposDisponibles.map((g) => 'Grupo $g').toList();
    final allPhases = [...groupPhases, ..._playoffPhases()];

    String fase = existingMatch?.fase ?? (allPhases.isNotEmpty ? allPhases.first : 'Grupo A');
    if (!allPhases.contains(fase)) fase = allPhases.first;

    final canchaCtrl = TextEditingController(text: existingMatch?.cancha ?? 'Cancha 1 (Principal)');
    final arbitroCtrl = TextEditingController(text: existingMatch?.arbitroAsignado ?? 'Por designar');
    DateTime matchDateTime = existingMatch != null
        ? (DateTime.tryParse(existingMatch.fechaHora) ?? DateTime.now())
        : DateTime.now().add(const Duration(hours: 2));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final teams = availableTeams();
          // Re-evaluar disponibilidad de equipos al cambiar fase
          void onFaseChanged(String newFase) {
            setDlgState(() {
              fase = newFase;
              isPlayoff = _playoffPhases().any((p) => p == newFase);
              final newTeams = availableTeams();
              if (!newTeams.any((t) => t.idEquipo == localId)) {
                localId = newTeams.first.idEquipo;
              }
              if (!newTeams.any((t) => t.idEquipo == visitaId)) {
                visitaId = newTeams.length > 1 ? newTeams[1].idEquipo : newTeams.first.idEquipo;
              }
            });
          }

          return AlertDialog(
            backgroundColor: AppTheme.stadiumCardBg,
            title: Row(
              children: [
                Icon(existingMatch != null ? Icons.edit_calendar : Icons.add_alarm, color: AppTheme.turfGreenLight),
                const SizedBox(width: 8),
                Text(
                  existingMatch != null ? 'Editar Partido' : 'Programar Partido',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fase / Etapa (primero para que el cambio afecte el dropdown de equipos)
                  const Text('Fase / Etapa:', style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: allPhases.contains(fase) ? fase : allPhases.first,
                    dropdownColor: AppTheme.stadiumElevatedBg,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: allPhases.map((f) {
                      final isPlayoffPhase = _playoffPhases().contains(f);
                      return DropdownMenuItem(
                        value: f,
                        child: Row(
                          children: [
                            Icon(
                              isPlayoffPhase ? Icons.emoji_events : Icons.group,
                              size: 14,
                              color: isPlayoffPhase ? AppTheme.trophyGold : AppTheme.turfGreenLight,
                            ),
                            const SizedBox(width: 8),
                            Text(f),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) onFaseChanged(val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Aviso clasificados si es playoff
                  if (isPlayoff && _classifiedTeams().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.trophyGold.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.trophyGold.withAlpha(80)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events, size: 14, color: AppTheme.trophyGold),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Mostrando solo equipos clasificados (top ${widget.config?.clasificadosPorGrupo ?? 2} por grupo)',
                              style: const TextStyle(color: AppTheme.trophyGold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Equipo Local
                  const Text('Equipo Local:', style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: teams.any((t) => t.idEquipo == localId) ? localId : teams.first.idEquipo,
                    dropdownColor: AppTheme.stadiumElevatedBg,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: teams.map((t) => DropdownMenuItem(value: t.idEquipo, child: Text(t.nombre))).toList(),
                    onChanged: (val) {
                      if (val != null) setDlgState(() => localId = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Equipo Visitante
                  const Text('Equipo Visitante:', style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: teams.any((t) => t.idEquipo == visitaId) ? visitaId : teams.first.idEquipo,
                    dropdownColor: AppTheme.stadiumElevatedBg,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: teams.map((t) => DropdownMenuItem(value: t.idEquipo, child: Text(t.nombre))).toList(),
                    onChanged: (val) {
                      if (val != null) setDlgState(() => visitaId = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Cancha
                  TextField(
                    controller: canchaCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Cancha / Campo Deportivo'),
                  ),
                  const SizedBox(height: 12),

                  // Árbitro
                  TextField(
                    controller: arbitroCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Árbitro Principal'),
                  ),
                  const SizedBox(height: 16),

                  // Selector de Fecha / Hora
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.turfGreen),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    ),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: matchDateTime,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null && ctx.mounted) {
                        final time = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay.fromDateTime(matchDateTime),
                        );
                        if (time != null) {
                          setDlgState(() {
                            matchDateTime = DateTime(
                              date.year, date.month, date.day,
                              time.hour, time.minute,
                            );
                          });
                        }
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16, color: AppTheme.turfGreen),
                    label: Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(matchDateTime),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar', style: TextStyle(color: AppTheme.slateTextSecondary)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (localId == visitaId) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('El equipo local y visitante no pueden ser el mismo')),
                    );
                    return;
                  }

                  final isDuplicate = widget.matches.any((m) {
                    if (existingMatch != null && m.idPartido == existingMatch.idPartido) return false;
                    return m.fase.trim().toUpperCase() == fase.trim().toUpperCase() &&
                           m.localId.trim() == localId.trim() &&
                           m.visitaId.trim() == visitaId.trim();
                  });

                  if (isDuplicate) {
                    messenger.showSnackBar(
                      const SnackBar(
                        backgroundColor: AppTheme.liveRed,
                        content: Text('⚠️ Ya existe un partido programado entre estos equipos en esta fase'),
                      ),
                    );
                    return;
                  }

                  final token = AuthService().currentUser?.token;
                  if (token == null) return;

                  final match = MatchModel(
                    idPartido: existingMatch?.idPartido ?? '',
                    fase: fase,
                    fechaHora: matchDateTime.toUtc().toIso8601String(),
                    cancha: canchaCtrl.text.trim(),
                    localId: localId,
                    visitaId: visitaId,
                    estado: existingMatch?.estado ?? AppConstants.stateProgramado,
                    arbitroAsignado: arbitroCtrl.text.trim(),
                  );

                  Navigator.pop(ctx);

                  messenger.showSnackBar(
                    const SnackBar(content: Text('Guardando partido en Google Sheets...')),
                  );

                  final res = await ApiService().saveMatch(token: token, match: match);
                  if (res.success && mounted) {
                    widget.onMatchesUpdated();
                    messenger.showSnackBar(
                      const SnackBar(backgroundColor: AppTheme.turfGreen, content: Text('Partido programado con éxito')),
                    );
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteMatch(MatchModel match) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.stadiumCardBg,
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: AppTheme.liveRed),
            SizedBox(width: 8),
            Text('Eliminar Partido', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(color: AppTheme.slateTextSecondary, fontSize: 14, height: 1.5),
                children: [
                  const TextSpan(text: '¿Eliminar el partido '),
                  TextSpan(
                    text: match.idPartido,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' de la fase '),
                  TextSpan(
                    text: match.fase,
                    style: const TextStyle(color: AppTheme.trophyGold, fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (match.isLive)
              _warningBox('Este partido está EN VIVO. El servidor bloqueará la eliminación.', AppTheme.liveRed)
            else
              _warningBox('Esta acción no se puede deshacer.', AppTheme.liveRed),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.slateTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.liveRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final token = AuthService().currentUser?.token;
    if (token == null) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Eliminando partido de Google Sheets...')));

    final res = await ApiService().deleteMatch(token: token, idPartido: match.idPartido);
    if (mounted) {
      if (res.success) {
        widget.onMatchesUpdated();
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.turfGreen,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.black),
                const SizedBox(width: 8),
                Text('${match.idPartido} eliminado', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(backgroundColor: AppTheme.liveRed, content: Text(res.error ?? 'Error al eliminar partido')),
        );
      }
    }
  }

  Widget _warningBox(String msg, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: TextStyle(color: color, fontSize: 12))),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByPhase();

    return Column(
      children: [
        // ── Barra de herramientas ──────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF0D1424),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.matches.length} partido${widget.matches.length != 1 ? 's' : ''} • ${grouped.length} fase${grouped.length != 1 ? 's' : ''}',
                  style: const TextStyle(color: AppTheme.slateTextSecondary, fontSize: 12),
                ),
              ),
              // Toggle ocultar finalizados
              GestureDetector(
                onTap: () => setState(() => _hideFinished = !_hideFinished),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _hideFinished ? AppTheme.turfGreen.withAlpha(30) : AppTheme.stadiumElevatedBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _hideFinished ? AppTheme.turfGreenLight : Colors.white12,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _hideFinished ? Icons.visibility_off : Icons.visibility,
                        size: 14,
                        color: _hideFinished ? AppTheme.turfGreenLight : AppTheme.slateTextSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _hideFinished ? 'Ver Finalizados' : 'Ocultar Finalizados',
                        style: TextStyle(
                          fontSize: 11,
                          color: _hideFinished ? AppTheme.turfGreenLight : AppTheme.slateTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Lista agrupada por fase ────────────────────────────
        Expanded(
          child: grouped.isEmpty
              ? const Center(
                  child: Text('No hay partidos registrados', style: TextStyle(color: AppTheme.slateTextSecondary)),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final fase = grouped.keys.elementAt(index);
                    var matches = grouped[fase]!;

                    // Aplicar filtro de finalizados
                    if (_hideFinished) {
                      matches = matches.where((m) => !m.isFinished).toList();
                    }

                    final isCollapsed = _collapsedPhases.contains(fase);
                    final isPlayoffPhase = _playoffPhases().contains(fase);
                    final finishedCount = grouped[fase]!.where((m) => m.isFinished).length;
                    final liveCount = grouped[fase]!.where((m) => m.isLive).length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado de sección (tap para colapsar)
                        GestureDetector(
                          onTap: () => setState(() {
                            if (isCollapsed) {
                              _collapsedPhases.remove(fase);
                            } else {
                              _collapsedPhases.add(fase);
                            }
                          }),
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isPlayoffPhase
                                    ? [AppTheme.trophyGold.withAlpha(30), AppTheme.trophyGold.withAlpha(10)]
                                    : [AppTheme.turfGreen.withAlpha(30), AppTheme.turfGreen.withAlpha(10)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isPlayoffPhase
                                    ? AppTheme.trophyGold.withAlpha(80)
                                    : AppTheme.turfGreen.withAlpha(80),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isPlayoffPhase ? Icons.emoji_events : Icons.group,
                                  size: 16,
                                  color: isPlayoffPhase ? AppTheme.trophyGold : AppTheme.turfGreenLight,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    fase,
                                    style: TextStyle(
                                      color: isPlayoffPhase ? AppTheme.trophyGold : AppTheme.turfGreenLight,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                // Indicadores rápidos
                                if (liveCount > 0)
                                  _phaseBadge('$liveCount EN VIVO', AppTheme.liveRed),
                                if (finishedCount > 0) ...[
                                  const SizedBox(width: 4),
                                  _phaseBadge('$finishedCount ✓', Colors.grey),
                                ],
                                const SizedBox(width: 8),
                                Icon(
                                  isCollapsed ? Icons.expand_more : Icons.expand_less,
                                  size: 18,
                                  color: AppTheme.slateTextSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Tarjetas de partidos (colapsable)
                        if (!isCollapsed)
                          if (matches.isEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: Center(
                                child: Text(
                                  _hideFinished ? 'Todos los partidos de esta fase están finalizados' : 'Sin partidos',
                                  style: const TextStyle(color: AppTheme.slateTextSecondary, fontSize: 12),
                                ),
                              ),
                            )
                          else
                            ...matches.map((m) => _buildMatchCard(m)),
                      ],
                    );
                  },
                ),
        ),

        // ── Botones de acción ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.trophyGold, width: 1.5),
                    foregroundColor: AppTheme.trophyGold,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FixtureGeneratorScreen(
                          teams: widget.teams,
                          existingMatches: widget.matches,
                          onGenerated: widget.onMatchesUpdated,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.casino, size: 18),
                  label: const Text('SORTEO / FIXTURE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.turfGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showAddMatchDialog(),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('PROGRAMAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _phaseBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMatchCard(MatchModel m) {
    final loc = _getTeam(m.localId);
    final vis = _getTeam(m.visitaId);

    DateTime? dt;
    try { dt = DateTime.parse(m.fechaHora).toLocal(); } catch (_) {}

    // Colores de estado
    Color estadoColor;
    if (m.isLive) {
      estadoColor = AppTheme.liveRed;
    } else if (m.isFinished) {
      estadoColor = Colors.grey;
    } else {
      estadoColor = AppTheme.slateTextSecondary;
    }

    return Dismissible(
      key: ValueKey(m.idPartido),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        decoration: BoxDecoration(
          color: AppTheme.liveRed.withAlpha(200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_forever, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Eliminar', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        await _confirmDeleteMatch(m);
        return false;
      },
      child: Card(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // Cabecera: fecha · estado · acciones
              Row(
                children: [
                  // Fecha y hora
                  Row(
                    children: [
                      const Icon(Icons.event, size: 13, color: AppTheme.trophyGold),
                      const SizedBox(width: 4),
                      Text(
                        dt != null ? DateFormat('dd/MM HH:mm').format(dt) : m.fechaHora,
                        style: const TextStyle(color: AppTheme.trophyGold, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Badge estado
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: estadoColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: estadoColor.withAlpha(100)),
                    ),
                    child: Text(
                      m.estado,
                      style: TextStyle(color: estadoColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Botón marcador rápido ⚽
                  if (!m.isFinished)
                    IconButton(
                      icon: const Text('⚽', style: TextStyle(fontSize: 14)),
                      tooltip: 'Actualizar marcador',
                      onPressed: () => _showQuickScoreSheet(m),
                      padding: const EdgeInsets.only(left: 4),
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  // Botón editar
                  IconButton(
                    icon: const Icon(Icons.edit, size: 15, color: AppTheme.slateTextSecondary),
                    tooltip: 'Editar partido',
                    onPressed: () => _showAddMatchDialog(m),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  // Botón eliminar
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 15, color: AppTheme.liveRed),
                    tooltip: 'Eliminar partido',
                    onPressed: () => _confirmDeleteMatch(m),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
              const Divider(height: 14),

              // Enfrentamiento y marcador
              Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            loc?.nombre ?? m.localId,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              color: m.isFinished && m.golesLocal > m.golesVisita
                                  ? AppTheme.turfGreenLight
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _teamDot(loc),
                      ],
                    ),
                  ),
                  // Marcador central
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: m.isLive ? AppTheme.liveRed.withAlpha(100) : Colors.white12),
                    ),
                    child: Text(
                      m.isScheduled ? 'VS' : '${m.golesLocal} - ${m.golesVisita}',
                      style: TextStyle(
                        color: m.isLive ? AppTheme.liveRed : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        _teamDot(vis),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            vis?.nombre ?? m.visitaId,
                            style: TextStyle(
                              color: m.isFinished && m.golesVisita > m.golesLocal
                                  ? AppTheme.turfGreenLight
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Penales (si existen)
              if (m.penalesLocal > 0 || m.penalesVisita > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Penales: ${m.penalesLocal} - ${m.penalesVisita}',
                    style: const TextStyle(color: AppTheme.trophyGold, fontSize: 11, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 8),

              // Cancha y árbitro
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 11, color: AppTheme.slateTextSecondary),
                      const SizedBox(width: 3),
                      Text(m.cancha, style: const TextStyle(color: AppTheme.slateTextSecondary, fontSize: 10)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.sports, size: 11, color: AppTheme.slateTextSecondary),
                      const SizedBox(width: 3),
                      Text(m.arbitroAsignado, style: const TextStyle(color: AppTheme.slateTextSecondary, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamDot(TeamModel? team) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(int.tryParse(team?.colorHex.replaceFirst('#', '0xFF') ?? '0xFF3B82F6') ?? 0xFF3B82F6),
        border: Border.all(color: Colors.white.withAlpha(50), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: (team != null && team.logoUrl.isNotEmpty)
          ? Image.network(
              team.logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const Icon(Icons.shield, size: 9, color: Colors.white),
            )
          : const Icon(Icons.shield, size: 9, color: Colors.white),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
