import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/match_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

/// Bottom sheet ligero para actualizar rápidamente el marcador de un partido.
/// Muestra controles de goles y selector de estado sin necesidad de abrir
/// el diálogo completo de edición.
class MatchScoreBottomSheet extends StatefulWidget {
  final MatchModel match;
  final String localNombre;
  final String visitaNombre;
  final VoidCallback onUpdated;

  const MatchScoreBottomSheet({
    super.key,
    required this.match,
    required this.localNombre,
    required this.visitaNombre,
    required this.onUpdated,
  });

  @override
  State<MatchScoreBottomSheet> createState() => _MatchScoreBottomSheetState();
}

class _MatchScoreBottomSheetState extends State<MatchScoreBottomSheet> {
  late int _golesLocal;
  late int _golesVisita;
  late int _penalesLocal;
  late int _penalesVisita;
  late String _estado;
  late String _walkover;
  bool _isSaving = false;
  bool _showPenales = false;

  static const _estados = [
    (AppConstants.stateProgramado, 'Programado', Icons.schedule, Colors.grey),
    (AppConstants.stateEnVivo, 'En Vivo 🔴', Icons.sports_soccer, AppTheme.liveRed),
    (AppConstants.stateEntretiempo, 'Entretiempo', Icons.timer_outlined, Colors.orange),
    (AppConstants.stateFinalizado, 'Finalizado', Icons.check_circle, AppTheme.turfGreenLight),
  ];

  @override
  void initState() {
    super.initState();
    _golesLocal = widget.match.golesLocal;
    _golesVisita = widget.match.golesVisita;
    _penalesLocal = widget.match.penalesLocal;
    _penalesVisita = widget.match.penalesVisita;
    _estado = widget.match.estado;
    _walkover = widget.match.walkover;
    _showPenales = widget.match.penalesLocal > 0 || widget.match.penalesVisita > 0;
  }

  Widget _scoreCounter({
    required String label,
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    Color color = Colors.white,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.slateTextSecondary, fontSize: 11),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _circleButton(icon: Icons.remove, onTap: onMinus, enabled: value > 0),
            Container(
              width: 52,
              alignment: Alignment.center,
              child: Text(
                '$value',
                style: TextStyle(
                  color: color,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            _circleButton(icon: Icons.add, onTap: onPlus),
          ],
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? AppTheme.turfGreen.withAlpha(200)
              : AppTheme.stadiumElevatedBg,
          border: Border.all(
            color: enabled ? AppTheme.turfGreenLight : Colors.white12,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Colors.black : Colors.white24,
        ),
      ),
    );
  }

  Widget _buildWoChip(String code, String label, IconData icon, Color color) {
    final isSelected = _walkover == code;
    return GestureDetector(
      onTap: () {
        setState(() {
          _walkover = code;
          if (code == 'LOCAL') {
            _golesLocal = 3;
            _golesVisita = 0;
            _estado = AppConstants.stateFinalizado;
          } else if (code == 'VISITA') {
            _golesLocal = 0;
            _golesVisita = 3;
            _estado = AppConstants.stateFinalizado;
          } else if (code == 'DOBLE') {
            _golesLocal = 0;
            _golesVisita = 0;
            _estado = AppConstants.stateFinalizado;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(40) : AppTheme.stadiumElevatedBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSelected ? color : AppTheme.slateTextSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppTheme.slateTextSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final token = AuthService().currentUser?.token;
    if (token == null) return;

    setState(() => _isSaving = true);

    final res = await ApiService().updateScore(
      token: token,
      partidoId: widget.match.idPartido,
      golesLocal: _golesLocal,
      golesVisita: _golesVisita,
      penalesLocal: _showPenales ? _penalesLocal : 0,
      penalesVisita: _showPenales ? _penalesVisita : 0,
      estado: _estado,
      walkover: _walkover,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res.success) {
      widget.onUpdated();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.turfGreen,
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                '${widget.match.idPartido} · Marcador actualizado',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.liveRed,
          content: Text(res.error ?? 'Error al actualizar marcador'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTie = _golesLocal == _golesVisita;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.stadiumCardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.turfGreen.withAlpha(80), width: 2)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),

              // Partido info
              Row(
                children: [
                  const Icon(Icons.sports_soccer, size: 16, color: AppTheme.trophyGold),
                  const SizedBox(width: 6),
                  Text(
                    widget.match.idPartido,
                    style: const TextStyle(color: AppTheme.trophyGold, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  Text('• ${widget.match.fase}', style: const TextStyle(color: AppTheme.slateTextSecondary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 20),

              // Marcador principal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Local
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          widget.localNombre,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        _scoreCounter(
                          label: 'Goles',
                          value: _golesLocal,
                          color: _golesLocal > _golesVisita ? AppTheme.turfGreenLight : Colors.white,
                          onMinus: () => setState(() { if (_golesLocal > 0) _golesLocal--; }),
                          onPlus: () => setState(() => _golesLocal++),
                        ),
                      ],
                    ),
                  ),

                  // Divider VS
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isTie && (_golesLocal > 0 || _golesVisita > 0) ? '=' : 'VS',
                      style: const TextStyle(color: AppTheme.slateTextSecondary, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),

                  // Visita
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          widget.visitaNombre,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        _scoreCounter(
                          label: 'Goles',
                          value: _golesVisita,
                          color: _golesVisita > _golesLocal ? AppTheme.turfGreenLight : Colors.white,
                          onMinus: () => setState(() { if (_golesVisita > 0) _golesVisita--; }),
                          onPlus: () => setState(() => _golesVisita++),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Penales (expandible, solo si hay empate o ya tenían penales)
              if (isTie || _showPenales) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setState(() => _showPenales = !_showPenales),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showPenales ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: AppTheme.trophyGold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showPenales ? 'Ocultar Penales' : 'Agregar Penales',
                        style: const TextStyle(color: AppTheme.trophyGold, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (_showPenales) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _scoreCounter(
                          label: 'Penales Local',
                          value: _penalesLocal,
                          color: _penalesLocal > _penalesVisita ? AppTheme.trophyGold : Colors.white,
                          onMinus: () => setState(() { if (_penalesLocal > 0) _penalesLocal--; }),
                          onPlus: () => setState(() => _penalesLocal++),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _scoreCounter(
                          label: 'Penales Visita',
                          value: _penalesVisita,
                          color: _penalesVisita > _penalesLocal ? AppTheme.trophyGold : Colors.white,
                          onMinus: () => setState(() { if (_penalesVisita > 0) _penalesVisita--; }),
                          onPlus: () => setState(() => _penalesVisita++),
                        ),
                      ),
                    ],
                  ),
                ],
              ],

              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 10),

              // Selector de Walkover (W.O.)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Condición de Walkover (W.O.):', style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 12)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildWoChip('NO', 'Sin W.O.', Icons.sports_soccer, Colors.grey),
                  _buildWoChip('LOCAL', 'Gana Local W.O.', Icons.emoji_events, AppTheme.turfGreenLight),
                  _buildWoChip('VISITA', 'Gana Visita W.O.', Icons.emoji_events, AppTheme.turfGreenLight),
                  _buildWoChip('DOBLE', 'Doble W.O.', Icons.cancel, AppTheme.liveRed),
                ],
              ),
              const SizedBox(height: 14),

              // Selector de estado
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Estado del partido:', style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 12)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _estados.map((entry) {
                  final (value, label, icon, color) = entry;
                  final isSelected = _estado == value;
                  return GestureDetector(
                    onTap: () => setState(() => _estado = value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withAlpha(40) : AppTheme.stadiumElevatedBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? color : Colors.white12,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 14, color: isSelected ? color : AppTheme.slateTextSecondary),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? color : AppTheme.slateTextSecondary,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Botón Guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.turfGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
                        )
                      : const Icon(Icons.save_rounded, size: 20),
                  label: Text(
                    _isSaving ? 'Guardando...' : 'Guardar Marcador',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
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
