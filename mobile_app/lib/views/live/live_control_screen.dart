import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/match_model.dart';
import '../../models/team_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

/// Pantalla de Mesa de Control en Vivo.
/// Diseñada para uso ergonómico a una mano en cancha, eliminando el scroll horizontal
/// y organizando los partidos en categorías claras (En Vivo, Por Jugar, Finalizados).
class LiveControlScreen extends StatefulWidget {
  final List<MatchModel> matches;
  final List<TeamModel> teams;
  final VoidCallback onRefreshRequested;

  const LiveControlScreen({
    super.key,
    required this.matches,
    required this.teams,
    required this.onRefreshRequested,
  });

  @override
  State<LiveControlScreen> createState() => _LiveControlScreenState();
}

class _LiveControlScreenState extends State<LiveControlScreen> {
  MatchModel? _selectedMatch;
  bool _isSaving = false;
  bool _skipFinishedInNav = true;

  /// Obtiene los partidos accesibles según el rol.
  /// Si es SUPER_ADMIN ve todos; si es MESA_CONTROL solo los asignados a su usuario o nombre.
  List<MatchModel> get _accessibleMatches {
    final auth = AuthService();
    if (auth.isSuperAdmin) {
      return widget.matches;
    }
    final user = auth.currentUser;
    if (user == null) return [];
    final nom = user.nombre.trim().toLowerCase();
    final usr = user.usuario.trim().toLowerCase();
    return widget.matches.where((m) {
      final arb = m.arbitroAsignado.trim().toLowerCase();
      return arb == nom || arb == usr;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _selectInitialMatch();
  }

  @override
  void didUpdateWidget(covariant LiveControlScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final matches = _accessibleMatches;
    if (_selectedMatch != null) {
      // Mantener SIEMPRE el partido que el usuario estaba editando
      final updated = matches.firstWhere(
        (m) => m.idPartido == _selectedMatch!.idPartido,
        orElse: () => matches.isNotEmpty ? matches.first : _selectedMatch!,
      );
      _selectedMatch = updated;
    } else {
      _selectInitialMatch();
    }
  }

  /// Selecciona el partido prioritario (primero uno EN_VIVO o ENTRETIEMPO, luego PROGRAMADO)
  void _selectInitialMatch() {
    final matches = _accessibleMatches;
    if (matches.isEmpty) {
      _selectedMatch = null;
      return;
    }

    final liveMatches = matches.where((m) => m.isLive).toList();
    if (liveMatches.isNotEmpty) {
      _selectedMatch = liveMatches.first;
      return;
    }

    final scheduled = matches.where((m) => m.isScheduled).toList();
    if (scheduled.isNotEmpty) {
      _selectedMatch = scheduled.first;
      return;
    }

    _selectedMatch = matches.first;
  }

  TeamModel? _getTeam(String teamId) {
    return widget.teams.firstWhere(
      (t) => t.idEquipo == teamId,
      orElse: () => TeamModel(idEquipo: teamId, nombre: teamId, grupo: '', colorHex: '#64748B'),
    );
  }

  Color _getStateColor(String state) {
    switch (state) {
      case AppConstants.stateEnVivo:
        return AppTheme.liveRed;
      case AppConstants.stateEntretiempo:
        return AppTheme.trophyGold;
      case AppConstants.stateFinalizado:
        return AppTheme.turfGreen;
      default:
        return AppTheme.slateTextSecondary;
    }
  }

  /// Lista navegable según la opción de saltar partidos finalizados
  List<MatchModel> get _navigableMatches {
    final list = _accessibleMatches;
    if (!_skipFinishedInNav) return list;
    final active = list.where((m) => m.estado != AppConstants.stateFinalizado).toList();
    // Si todos están finalizados, mostrar todos
    return active.isNotEmpty ? active : list;
  }

  int get _currentNavIndex {
    if (_selectedMatch == null) return 0;
    final list = _navigableMatches;
    final idx = list.indexWhere((m) => m.idPartido == _selectedMatch!.idPartido);
    return idx >= 0 ? idx : 0;
  }

  void _navigateToPreviousMatch() {
    final list = _navigableMatches;
    if (list.isEmpty) return;
    final currentIndex = _currentNavIndex;
    if (currentIndex > 0) {
      setState(() {
        _selectedMatch = list[currentIndex - 1];
      });
    }
  }

  void _navigateToNextMatch() {
    final list = _navigableMatches;
    if (list.isEmpty) return;
    final currentIndex = _currentNavIndex;
    if (currentIndex < list.length - 1) {
      setState(() {
        _selectedMatch = list[currentIndex + 1];
      });
    }
  }

  /// Despliega el BottomSheet con las pestañas de partidos organizados
  void _openMatchSelectorModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MatchSelectorBottomSheet(
        matches: _accessibleMatches,
        teams: widget.teams,
        selectedMatchId: _selectedMatch?.idPartido,
        onMatchSelected: (match) {
          setState(() {
            _selectedMatch = match;
          });
        },
      ),
    );
  }

  Future<void> _updateScoreOnServer() async {
    if (_selectedMatch == null) return;

    final auth = AuthService();
    final token = auth.currentUser?.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión expirada. Inicie sesión nuevamente.')),
      );
      return;
    }

    // Si es empate en fase eliminatoria y se quiere finalizar, pedir penales
    if (_selectedMatch!.estado == AppConstants.stateFinalizado &&
        _selectedMatch!.isPlayoff &&
        _selectedMatch!.isTie &&
        _selectedMatch!.penalesLocal == _selectedMatch!.penalesVisita) {
      _showPenaltiesDialog();
      return;
    }

    setState(() => _isSaving = true);

    final res = await ApiService().updateScore(
      token: token,
      partidoId: _selectedMatch!.idPartido,
      golesLocal: _selectedMatch!.golesLocal,
      golesVisita: _selectedMatch!.golesVisita,
      penalesLocal: _selectedMatch!.penalesLocal,
      penalesVisita: _selectedMatch!.penalesVisita,
      estado: _selectedMatch!.estado,
      walkover: _selectedMatch!.walkover,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.turfGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.black),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_selectedMatch!.idPartido}: Marcador publicado en Google Sheets y Portal Web',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
        widget.onRefreshRequested();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.liveRed,
            content: Text(res.error ?? 'Error al guardar marcador'),
          ),
        );
      }
    }
  }

  void _showPenaltiesDialog() {
    int pLoc = _selectedMatch!.penalesLocal;
    int pVis = _selectedMatch!.penalesVisita;

    final locTeam = _getTeam(_selectedMatch!.localId);
    final visTeam = _getTeam(_selectedMatch!.visitaId);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppTheme.stadiumCardBg,
          title: const Row(
            children: [
              Icon(Icons.sports_soccer, color: AppTheme.trophyGold),
              SizedBox(width: 8),
              Text('Definición por Penales', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'El partido eliminatorio finalizó en empate. Registre los penales convertidos:',
                style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Local
                  Column(
                    children: [
                      Text(locTeam?.nombre ?? 'Local', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: AppTheme.liveRed),
                            onPressed: pLoc > 0 ? () => setDlgState(() => pLoc--) : null,
                          ),
                          Text('$pLoc', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: AppTheme.turfGreen),
                            onPressed: () => setDlgState(() => pLoc++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Text('vs', style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 16)),
                  // Visitante
                  Column(
                    children: [
                      Text(visTeam?.nombre ?? 'Visita', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: AppTheme.liveRed),
                            onPressed: pVis > 0 ? () => setDlgState(() => pVis--) : null,
                          ),
                          Text('$pVis', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: AppTheme.turfGreen),
                            onPressed: () => setDlgState(() => pVis++),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (pLoc == pVis) ...[
                const SizedBox(height: 12),
                const Text(
                  'Debe haber un ganador en penales para avanzar de fase',
                  style: TextStyle(color: AppTheme.trophyGold, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.slateTextSecondary)),
            ),
            ElevatedButton(
              onPressed: pLoc == pVis
                  ? null
                  : () {
                      setState(() {
                        _selectedMatch!.penalesLocal = pLoc;
                        _selectedMatch!.penalesVisita = pVis;
                        _selectedMatch!.estado = AppConstants.stateFinalizado;
                      });
                      Navigator.pop(ctx);
                      _updateScoreOnServer();
                    },
              child: const Text('Confirmar y Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWalkoverDialog() {
    if (_selectedMatch == null) return;
    final match = _selectedMatch!;
    final localTeam = _getTeam(match.localId);
    final visitTeam = _getTeam(match.visitaId);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.stadiumCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.flag, color: AppTheme.liveRed),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Declarar Walkover (W.O.)',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Seleccione el resultado de W.O. para este encuentro. El partido se marcará automáticamente como FINALIZADO y se aplicará la tabla de puntos configurada:',
                style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: AppTheme.stadiumElevatedBg,
                leading: const Icon(Icons.emoji_events, color: AppTheme.turfGreen),
                title: Text(
                  'Gana ${localTeam?.nombre ?? match.localId} por W.O.',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Text(
                  'El equipo visitante (${visitTeam?.nombre ?? match.visitaId}) no se presentó.',
                  style: const TextStyle(color: AppTheme.slateTextSecondary, fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _applyWalkover('LOCAL');
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: AppTheme.stadiumElevatedBg,
                leading: const Icon(Icons.emoji_events, color: AppTheme.turfGreen),
                title: Text(
                  'Gana ${visitTeam?.nombre ?? match.visitaId} por W.O.',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Text(
                  'El equipo local (${localTeam?.nombre ?? match.localId}) no se presentó.',
                  style: const TextStyle(color: AppTheme.slateTextSecondary, fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _applyWalkover('VISITA');
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: AppTheme.stadiumElevatedBg,
                leading: const Icon(Icons.cancel, color: AppTheme.liveRed),
                title: const Text(
                  'Doble Walkover (Ninguno se presentó)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: const Text(
                  'Ambos equipos serán sancionados según la configuración de penalización.',
                  style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _applyWalkover('DOBLE');
                },
              ),
              if (match.isWalkover) ...[
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: AppTheme.stadiumElevatedBg.withAlpha(128),
                  leading: const Icon(Icons.restart_alt, color: AppTheme.trophyGold),
                  title: const Text(
                    'Anular Walkover',
                    style: TextStyle(color: AppTheme.trophyGold, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Restablecer partido a juego normal',
                    style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _applyWalkover('NO');
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.slateTextSecondary)),
          ),
        ],
      ),
    );
  }

  void _applyWalkover(String walkoverType) {
    if (_selectedMatch == null) return;
    setState(() {
      _selectedMatch!.walkover = walkoverType;
      if (walkoverType == 'LOCAL') {
        _selectedMatch!.golesLocal = 3;
        _selectedMatch!.golesVisita = 0;
        _selectedMatch!.estado = AppConstants.stateFinalizado;
      } else if (walkoverType == 'VISITA') {
        _selectedMatch!.golesLocal = 0;
        _selectedMatch!.golesVisita = 3;
        _selectedMatch!.estado = AppConstants.stateFinalizado;
      } else if (walkoverType == 'DOBLE') {
        _selectedMatch!.golesLocal = 0;
        _selectedMatch!.golesVisita = 0;
        _selectedMatch!.estado = AppConstants.stateFinalizado;
      }
    });
    _updateScoreOnServer();
  }

  @override
  Widget build(BuildContext context) {
    final accessible = _accessibleMatches;
    if (accessible.isEmpty) {
      final isMesa = AuthService().currentUser?.rol == 'MESA_CONTROL';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isMesa ? Icons.assignment_late_outlined : Icons.sports_soccer,
                size: 64,
                color: isMesa ? AppTheme.trophyGold : AppTheme.slateTextSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                isMesa
                    ? 'No tienes partidos asignados'
                    : 'No hay partidos cargados para este evento',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isMesa
                    ? 'Como personal de Mesa de Control, solo puedes gestionar los partidos donde figuras como árbitro/mesa asignada.\n\nSolicita al Administrador que te asigne a los partidos correspondientes.'
                    : 'Presione actualizar para sincronizar los partidos desde Google Sheets.',
                style: const TextStyle(color: AppTheme.slateTextSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: widget.onRefreshRequested,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar Datos'),
              ),
            ],
          ),
        ),
      );
    }

    final match = _selectedMatch ?? accessible.first;
    final locTeam = _getTeam(match.localId);
    final visTeam = _getTeam(match.visitaId);

    final liveCount = accessible.where((m) => m.isLive).length;
    final navList = _navigableMatches;
    final currentIdx = _currentNavIndex;

    return Column(
      children: [
        // ─── Tarjeta de Control Enfocado (Hero Match Header) ────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1222),
            border: Border(
              bottom: BorderSide(color: Colors.white.withAlpha(20)),
            ),
          ),
          child: Column(
            children: [
              // Fila Superior: Datos de Partido + Botón Selector Modal
              Row(
                children: [
                  // Badges de Cancha y Fase
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.stadiumCardBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withAlpha(20)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, size: 12, color: AppTheme.turfGreen),
                              const SizedBox(width: 4),
                              Text(
                                match.cancha,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.trophyGold.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.trophyGold.withAlpha(40)),
                            ),
                            child: Text(
                              match.fase,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.trophyGold,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Botón "Cambiar Partido" que abre el BottomSheet
                  InkWell(
                    onTap: _openMatchSelectorModal,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.turfGreen.withAlpha(40),
                            AppTheme.turfGreen.withAlpha(20),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.turfGreen.withAlpha(80)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (liveCount > 0) ...[
                            Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.liveRed,
                              ),
                            ),
                          ],
                          const Icon(Icons.view_list, size: 15, color: AppTheme.turfGreen),
                          const SizedBox(width: 5),
                          Text(
                            liveCount > 0 ? '$liveCount EN VIVO' : 'PARTIDOS',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Barra de Navegación Rápida [◀ Anterior] [Partido X de Y] [Siguiente ▶]
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón Anterior
                  OutlinedButton.icon(
                    onPressed: currentIdx > 0 ? _navigateToPreviousMatch : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(0, 32),
                      side: BorderSide(
                        color: currentIdx > 0 ? Colors.white.withAlpha(40) : Colors.white.withAlpha(10),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.chevron_left, size: 16),
                    label: const Text('Anterior', style: TextStyle(fontSize: 11)),
                  ),

                  // Indicador Central
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${match.idPartido} (${currentIdx + 1}/${navList.length})',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Tooltip o filtro rápido de finalizados
                      IconButton(
                        icon: Icon(
                          _skipFinishedInNav ? Icons.filter_alt : Icons.filter_alt_off,
                          size: 16,
                          color: _skipFinishedInNav ? AppTheme.turfGreen : AppTheme.slateTextSecondary,
                        ),
                        tooltip: _skipFinishedInNav
                            ? 'Omitiendo finalizados en navegación'
                            : 'Mostrando todos en navegación',
                        onPressed: () {
                          setState(() {
                            _skipFinishedInNav = !_skipFinishedInNav;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),

                  // Botón Siguiente
                  OutlinedButton.icon(
                    onPressed: currentIdx < navList.length - 1 ? _navigateToNextMatch : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(0, 32),
                      side: BorderSide(
                        color: currentIdx < navList.length - 1 ? Colors.white.withAlpha(40) : Colors.white.withAlpha(10),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    label: const Text('Siguiente', style: TextStyle(fontSize: 11)),
                    icon: const Icon(Icons.chevron_right, size: 16),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ─── Área Interactiva de Marcador Táctil ──────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Selector de Estado de Partido
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.stadiumCardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withAlpha(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            match.isLive ? Icons.radio_button_checked : Icons.timer_outlined,
                            size: 16,
                            color: _getStateColor(match.estado),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Estado del Partido:',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      // Dropdown de Estado
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStateColor(match.estado).withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _getStateColor(match.estado)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: match.estado,
                            dropdownColor: AppTheme.stadiumElevatedBg,
                            icon: Icon(Icons.arrow_drop_down, color: _getStateColor(match.estado)),
                            style: TextStyle(
                              color: _getStateColor(match.estado),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            items: const [
                              DropdownMenuItem(value: AppConstants.stateProgramado, child: Text('PROGRAMADO')),
                              DropdownMenuItem(value: AppConstants.stateEnVivo, child: Text('● EN VIVO')),
                              DropdownMenuItem(value: AppConstants.stateEntretiempo, child: Text('ENTRETIEMPO')),
                              DropdownMenuItem(value: AppConstants.stateFinalizado, child: Text('FINALIZADO')),
                            ],
                            onChanged: (newVal) {
                              if (newVal != null) {
                                setState(() {
                                  match.estado = newVal;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // MARCADOR TÁCTIL GIGANTE
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF131D31), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.turfGreen.withAlpha(60), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(120),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Panel Local
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(int.tryParse(locTeam?.colorHex.replaceFirst('#', '0xFF') ?? '0xFF3B82F6') ?? 0xFF3B82F6),
                                border: Border.all(color: Colors.white.withAlpha(60), width: 1.5),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: (locTeam != null && locTeam.logoUrl.isNotEmpty)
                                  ? Image.network(
                                      locTeam.logoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.shield, color: Colors.white, size: 26),
                                    )
                                  : const Icon(Icons.shield, color: Colors.white, size: 26),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              locTeam?.nombre ?? 'Local',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            // Número de Goles
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(120),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withAlpha(20)),
                              ),
                              child: Text(
                                '${match.golesLocal}',
                                style: const TextStyle(
                                  color: AppTheme.turfGreenLight,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Courier',
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Botones táctiles + / -
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildTactileButton(
                                  icon: Icons.remove,
                                  color: AppTheme.liveRed,
                                  onPressed: match.golesLocal > 0
                                      ? () => setState(() => match.golesLocal--)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                _buildTactileButton(
                                  icon: Icons.add,
                                  color: AppTheme.turfGreen,
                                  onPressed: () => setState(() => match.golesLocal++),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Separador VS
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: const Text(
                          ':',
                          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.slateTextSecondary),
                        ),
                      ),

                      // Panel Visitante
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(int.tryParse(visTeam?.colorHex.replaceFirst('#', '0xFF') ?? '0xFF10B981') ?? 0xFF10B981),
                                border: Border.all(color: Colors.white.withAlpha(60), width: 1.5),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: (visTeam != null && visTeam.logoUrl.isNotEmpty)
                                  ? Image.network(
                                      visTeam.logoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.shield, color: Colors.white, size: 26),
                                    )
                                  : const Icon(Icons.shield, color: Colors.white, size: 26),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              visTeam?.nombre ?? 'Visita',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            // Número de Goles
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(120),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withAlpha(20)),
                              ),
                              child: Text(
                                '${match.golesVisita}',
                                style: const TextStyle(
                                  color: AppTheme.turfGreenLight,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Courier',
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Botones táctiles + / -
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildTactileButton(
                                  icon: Icons.remove,
                                  color: AppTheme.liveRed,
                                  onPressed: match.golesVisita > 0
                                      ? () => setState(() => match.golesVisita--)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                _buildTactileButton(
                                  icon: Icons.add,
                                  color: AppTheme.turfGreen,
                                  onPressed: () => setState(() => match.golesVisita++),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Sección de Penales si aplica
                if (match.isPlayoff || match.penalesLocal > 0 || match.penalesVisita > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.stadiumCardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.trophyGold.withAlpha(50)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.sports_soccer, size: 18, color: AppTheme.trophyGold),
                            SizedBox(width: 8),
                            Text('Penales:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text(
                          '${match.penalesLocal} - ${match.penalesVisita}',
                          style: const TextStyle(color: AppTheme.trophyGold, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: _showPenaltiesDialog,
                          icon: const Icon(Icons.edit, size: 16, color: AppTheme.trophyGold),
                          label: const Text('Editar Penales', style: TextStyle(color: AppTheme.trophyGold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Banner Walkover si aplica
                if (match.isWalkover) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.liveRed.withAlpha(25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.liveRed.withAlpha(120)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flag, size: 22, color: AppTheme.liveRed),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                match.isWalkoverDoble
                                    ? 'PARTIDO CON DOBLE WALKOVER'
                                    : (match.isWalkoverLocal
                                        ? 'VICTORIA POR W.O.: ${locTeam?.nombre ?? match.localId}'
                                        : 'VICTORIA POR W.O.: ${visTeam?.nombre ?? match.visitaId}'),
                                style: const TextStyle(
                                  color: AppTheme.liveRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                match.isWalkoverDoble
                                    ? 'Ninguno de los dos equipos se presentó al partido.'
                                    : 'El rival no se presentó al encuentro programado.',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _showWalkoverDialog,
                          child: const Text('Cambiar', style: TextStyle(color: AppTheme.trophyGold, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Árbitro
                if (match.arbitroAsignado.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.sports, size: 16, color: AppTheme.slateTextSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Árbitro / Mesa: ${match.arbitroAsignado}',
                        style: const TextStyle(color: AppTheme.slateTextSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Botón para declarar o modificar Walkover
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showWalkoverDialog,
                    icon: Icon(
                      match.isWalkover ? Icons.edit_note : Icons.flag_outlined,
                      size: 18,
                      color: match.isWalkover ? AppTheme.trophyGold : AppTheme.slateTextSecondary,
                    ),
                    label: Text(
                      match.isWalkover ? 'MODIFICAR / ANULAR WALKOVER' : 'DECLARAR WALKOVER (W.O.)',
                      style: TextStyle(
                        color: match.isWalkover ? AppTheme.trophyGold : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: match.isWalkover ? AppTheme.trophyGold.withAlpha(150) : Colors.white.withAlpha(40),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // BOTÓN DE SINCRONIZACIÓN CON GOOGLE SHEETS
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _updateScoreOnServer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.turfGreen,
                      foregroundColor: Colors.black,
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSaving
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.black)),
                              ),
                              SizedBox(width: 12),
                              Text('GUARDANDO EN GOOGLE SHEETS...', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload, size: 22),
                              SizedBox(width: 10),
                              Text('PUBLICAR MARCADOR EN VIVO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Al publicar, la web y la tabla de posiciones se actualizan en tiempo real.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTactileButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: onPressed != null ? color.withAlpha(40) : Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: onPressed != null ? color : Colors.white.withAlpha(20),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            size: 28,
            color: onPressed != null ? color : Colors.white.withAlpha(30),
          ),
        ),
      ),
    );
  }
}

// ─── BottomSheet de Selección Rápida de Partidos ─────────────────────────────

class _MatchSelectorBottomSheet extends StatefulWidget {
  final List<MatchModel> matches;
  final List<TeamModel> teams;
  final String? selectedMatchId;
  final ValueChanged<MatchModel> onMatchSelected;

  const _MatchSelectorBottomSheet({
    required this.matches,
    required this.teams,
    required this.selectedMatchId,
    required this.onMatchSelected,
  });

  @override
  State<_MatchSelectorBottomSheet> createState() => _MatchSelectorBottomSheetState();
}

class _MatchSelectorBottomSheetState extends State<_MatchSelectorBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  TeamModel? _getTeam(String teamId) {
    return widget.teams.firstWhere(
      (t) => t.idEquipo == teamId,
      orElse: () => TeamModel(idEquipo: teamId, nombre: teamId, grupo: '', colorHex: '#64748B'),
    );
  }

  List<MatchModel> _filterMatches(List<MatchModel> source) {
    if (_searchQuery.trim().isEmpty) return source;
    final query = _searchQuery.toLowerCase();
    return source.where((m) {
      final tL = _getTeam(m.localId)?.nombre.toLowerCase() ?? '';
      final tV = _getTeam(m.visitaId)?.nombre.toLowerCase() ?? '';
      final id = m.idPartido.toLowerCase();
      final cancha = m.cancha.toLowerCase();
      final fase = m.fase.toLowerCase();
      return tL.contains(query) || tV.contains(query) || id.contains(query) || cancha.contains(query) || fase.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final liveMatches = widget.matches.where((m) => m.isLive).toList();
    final scheduledMatches = widget.matches.where((m) => m.isScheduled || m.estado == AppConstants.stateEntretiempo).toList();
    final finishedMatches = widget.matches.where((m) => m.isFinished).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -5)),
        ],
      ),
      child: Column(
        children: [
          // Barra de agarre superior
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Título y Contador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Seleccionar Partido de Mesa',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Campo de búsqueda rápida
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Buscar por equipo, cancha o fase...',
                hintStyle: const TextStyle(color: AppTheme.slateTextSecondary, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppTheme.slateTextSecondary, size: 18),
                filled: true,
                fillColor: AppTheme.stadiumCardBg,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),

          // Pestañas por estado
          TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.turfGreen,
            labelColor: AppTheme.turfGreen,
            unselectedLabelColor: AppTheme.slateTextSecondary,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (liveMatches.isNotEmpty) ...[
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.liveRed),
                      ),
                    ],
                    Text('En Vivo (${liveMatches.length})'),
                  ],
                ),
              ),
              Tab(text: 'Por Jugar (${scheduledMatches.length})'),
              Tab(text: 'Finalizados (${finishedMatches.length})'),
            ],
          ),

          // Lista de partidos por pestaña
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMatchList(_filterMatches(liveMatches), 'No hay partidos en vivo actualmente'),
                _buildMatchList(_filterMatches(scheduledMatches), 'No hay partidos pendientes de jugar'),
                _buildMatchList(_filterMatches(finishedMatches), 'No hay partidos finalizados'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchList(List<MatchModel> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_soccer, size: 40, color: AppTheme.slateTextSecondary),
              const SizedBox(height: 10),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.slateTextSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final m = list[index];
        final isCurrent = m.idPartido == widget.selectedMatchId;
        final tL = _getTeam(m.localId);
        final tV = _getTeam(m.visitaId);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              widget.onMatchSelected(m);
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrent ? AppTheme.turfGreen.withAlpha(20) : AppTheme.stadiumCardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCurrent ? AppTheme.turfGreen : Colors.white.withAlpha(15),
                  width: isCurrent ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Icono o Estado
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      m.isLive
                          ? Icons.play_circle_filled
                          : m.isFinished
                              ? Icons.check_circle
                              : Icons.schedule,
                      size: 20,
                      color: m.isLive
                          ? AppTheme.liveRed
                          : m.isFinished
                              ? AppTheme.turfGreen
                              : AppTheme.slateTextSecondary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Info de Equipos y Cancha
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              m.idPartido,
                              style: const TextStyle(
                                color: AppTheme.slateTextSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(10),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                m.cancha,
                                style: const TextStyle(color: Colors.white70, fontSize: 9),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              m.fase,
                              style: const TextStyle(color: AppTheme.trophyGold, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                            if (m.isWalkover) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.liveRed.withAlpha(40),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppTheme.liveRed.withAlpha(100)),
                                ),
                                child: const Text(
                                  'W.O.',
                                  style: TextStyle(color: AppTheme.liveRed, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${tL?.nombre ?? 'Local'} vs ${tV?.nombre ?? 'Visita'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Marcador actual
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${m.golesLocal} - ${m.golesVisita}',
                      style: TextStyle(
                        color: m.isLive ? AppTheme.liveRed : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ),

                  if (isCurrent) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check, color: AppTheme.turfGreen, size: 18),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
