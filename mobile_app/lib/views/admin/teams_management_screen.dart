import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../models/team_model.dart';
import '../../models/tournament_config_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class TeamsManagementScreen extends StatefulWidget {
  final List<TeamModel> teams;
  final TournamentConfigModel? config;
  final VoidCallback onTeamsUpdated;

  const TeamsManagementScreen({
    super.key,
    required this.teams,
    this.config,
    required this.onTeamsUpdated,
  });

  @override
  State<TeamsManagementScreen> createState() => _TeamsManagementScreenState();
}

class _TeamsManagementScreenState extends State<TeamsManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// Grupos personalizados creados por el usuario en esta sesión
  final Set<String> _customGroups = {};

  /// Grupos derivados dinámicamente de los equipos + grupos creados por el admin
  List<String> get _groups {
    final fromTeams = widget.teams
        .map((t) => t.grupo.toUpperCase().trim())
        .where((g) => g.isNotEmpty)
        .toSet();
    final all = {...fromTeams, ..._customGroups}.toList()..sort();
    if (all.isEmpty) return ['A'];
    return all;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _groups.length, vsync: this);
  }

  @override
  void didUpdateWidget(covariant TeamsManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reconstruir el TabController si los grupos cambian
    final newGroups = _groups;
    if (newGroups.length != _tabController.length) {
      _tabController.dispose();
      _tabController = TabController(length: newGroups.length, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DIÁLOGO: Crear Nuevo Grupo Dinámico
  // ─────────────────────────────────────────────────────────────────────────
  void _showCreateGroupDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.stadiumCardBg,
        title: const Row(
          children: [
            Icon(Icons.add_circle, color: AppTheme.turfGreenLight),
            SizedBox(width: 8),
            Text('Crear Nuevo Grupo', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingresa la letra o nombre del grupo (ej. C, D, Serie 1):',
                style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Identificador del Grupo',
                hintText: 'Ej: C',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.slateTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = ctrl.text.trim().toUpperCase();
              if (val.isNotEmpty) {
                setState(() {
                  _customGroups.add(val);
                  _tabController.dispose();
                  _tabController = TabController(length: _groups.length, vsync: this);
                  _tabController.animateTo(_groups.indexOf(val));
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Grupo $val creado. Ahora puedes asignarle equipos.'),
                    backgroundColor: AppTheme.turfGreen,
                  ),
                );
              }
            },
            child: const Text('Crear Grupo'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DIÁLOGO: Eliminar Grupo
  // ─────────────────────────────────────────────────────────────────────────
  void _confirmDeleteGroup(String groupName) {
    final groupTeams = widget.teams.where((t) => t.grupo.toUpperCase().trim() == groupName).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.stadiumCardBg,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.liveRed),
            const SizedBox(width: 8),
            Text('Eliminar Grupo $groupName', style: const TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Text(
          groupTeams.isEmpty
              ? '¿Deseas eliminar la pestaña del Grupo $groupName? Está vacío y no contiene equipos.'
              : 'El Grupo $groupName contiene ${groupTeams.length} equipo(s). Para eliminar el grupo, debes eliminar o reasignar primero sus equipos.',
          style: const TextStyle(color: AppTheme.slateTextSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: AppTheme.slateTextSecondary)),
          ),
          if (groupTeams.isEmpty)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.liveRed),
              onPressed: () {
                setState(() {
                  _customGroups.remove(groupName);
                  _tabController.dispose();
                  _tabController = TabController(length: _groups.length, vsync: this);
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Grupo $groupName eliminado.')),
                );
              },
              child: const Text('Eliminar Grupo', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DIÁLOGO: Agregar / Editar Equipo
  // ─────────────────────────────────────────────────────────────────────────
  void _showAddTeamDialog([TeamModel? existingTeam, String? defaultGroup]) {
    final nameCtrl = TextEditingController(text: existingTeam?.nombre ?? '');
    String selectedGroup = existingTeam?.grupo ?? defaultGroup ?? (_groups.isNotEmpty ? _groups.first : 'A');
    String selectedColor = existingTeam?.colorHex ?? '#2563EB';
    final String currentLogoUrl = existingTeam?.logoUrl ?? '';

    Uint8List? pickedImageBytes;
    String? pickedImageName;
    String? pickedMimeType;

    final List<String> presetColors = [
      '#DC2626', '#2563EB', '#16A34A', '#CA8A04',
      '#9333EA', '#0D9488', '#EA580C', '#4F46E5',
      '#E11D48', '#475569',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final colorVal = int.tryParse(selectedColor.replaceFirst('#', '0xFF')) ?? 0xFF2563EB;
          final colorObj = Color(colorVal);

          return AlertDialog(
            backgroundColor: AppTheme.stadiumCardBg,
            title: Row(
              children: [
                Icon(existingTeam != null ? Icons.edit : Icons.group_add,
                    color: AppTheme.turfGreenLight),
                const SizedBox(width: 8),
                Text(
                  existingTeam != null ? 'Editar Equipo' : 'Nuevo Equipo',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview del logo/escudo
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: colorObj,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(100),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: pickedImageBytes != null
                              ? Image.memory(pickedImageBytes!, fit: BoxFit.cover)
                              : (currentLogoUrl.isNotEmpty
                                  ? Image.network(
                                      currentLogoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.shield, color: Colors.white, size: 36),
                                    )
                                  : const Icon(Icons.shield, color: Colors.white, size: 36)),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final XFile? photo = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 512,
                              maxHeight: 512,
                              imageQuality: 85,
                            );
                            if (photo != null) {
                              final bytes = await photo.readAsBytes();
                              setDlgState(() {
                                pickedImageBytes = bytes;
                                pickedImageName = photo.name;
                                pickedMimeType = photo.mimeType ?? 'image/png';
                              });
                            }
                          },
                          icon: const Icon(Icons.cloud_upload, size: 18, color: AppTheme.turfGreenLight),
                          label: Text(
                            pickedImageBytes != null
                                ? 'Cambiar Logo'
                                : (currentLogoUrl.isNotEmpty ? 'Cambiar Logo' : 'Subir Escudo a Drive'),
                            style: const TextStyle(color: AppTheme.turfGreenLight, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Equipo',
                      prefixIcon: Icon(Icons.shield, color: AppTheme.turfGreenLight),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Asignar Grupo:', style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _groups.map((g) {
                      final isSel = selectedGroup == g;
                      return ChoiceChip(
                        label: Text('Grupo $g'),
                        selected: isSel,
                        selectedColor: AppTheme.turfGreen,
                        backgroundColor: AppTheme.stadiumElevatedBg,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) => setDlgState(() => selectedGroup = g),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Color del Uniforme:', style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presetColors.map((hex) {
                      final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                      final isSel = selectedColor == hex;
                      return GestureDetector(
                        onTap: () => setDlgState(() => selectedColor = hex),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSel
                                ? Border.all(color: Colors.white, width: 3)
                                : Border.all(color: Colors.white.withAlpha(40), width: 1),
                          ),
                          child: isSel ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                        ),
                      );
                    }).toList(),
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
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;

                  final token = AuthService().currentUser?.token;
                  if (token == null) return;

                  final team = TeamModel(
                    idEquipo: existingTeam?.idEquipo ?? '',
                    nombre: name,
                    grupo: selectedGroup,
                    colorHex: selectedColor,
                    logoUrl: currentLogoUrl,
                  );

                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);

                  messenger.showSnackBar(
                    const SnackBar(content: Text('Guardando equipo en Google Sheets...')),
                  );

                  final res = await ApiService().saveTeam(token: token, team: team);
                  if (res.success) {
                    final assignedId = res.data ?? team.idEquipo;

                    if (pickedImageBytes != null) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Subiendo escudo a Google Drive...')),
                      );
                      final base64Str = base64Encode(pickedImageBytes!);
                      await ApiService().uploadTeamLogo(
                        token: token,
                        idEquipo: assignedId,
                        imageBase64: base64Str,
                        mimeType: pickedMimeType ?? 'image/png',
                        fileName: pickedImageName,
                      );
                    }

                    if (mounted) {
                      widget.onTeamsUpdated();
                      messenger.showSnackBar(
                        const SnackBar(
                          backgroundColor: AppTheme.turfGreen,
                          content: Text('Equipo guardado correctamente'),
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          backgroundColor: AppTheme.liveRed,
                          content: Text(res.error ?? 'Error al guardar equipo'),
                        ),
                      );
                    }
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

  // ─────────────────────────────────────────────────────────────────────────
  // CONFIRMAR Y EJECUTAR: Eliminar Equipo
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _confirmDeleteTeam(TeamModel team) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.stadiumCardBg,
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: AppTheme.liveRed),
            SizedBox(width: 8),
            Text('Eliminar Equipo', style: TextStyle(color: Colors.white, fontSize: 18)),
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
                  const TextSpan(text: '¿Eliminar definitivamente al equipo '),
                  TextSpan(
                    text: team.nombre,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' del Grupo '),
                  TextSpan(
                    text: team.grupo,
                    style: const TextStyle(color: AppTheme.turfGreenLight, fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.liveRed.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.liveRed.withAlpha(80)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppTheme.liveRed, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer. Los partidos del equipo no se eliminarán.',
                      style: TextStyle(color: AppTheme.liveRed, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.slateTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.liveRed,
              foregroundColor: Colors.white,
            ),
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
    messenger.showSnackBar(
      const SnackBar(content: Text('Eliminando equipo de Google Sheets...')),
    );

    final res = await ApiService().deleteTeam(token: token, idEquipo: team.idEquipo);
    if (mounted) {
      if (res.success) {
        widget.onTeamsUpdated();
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.turfGreen,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.black),
                const SizedBox(width: 8),
                Text(
                  '${team.nombre} eliminado del torneo',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.liveRed,
            content: Text(res.error ?? 'Error al eliminar equipo'),
          ),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final groups = _groups;

    return Column(
      children: [
        // Barra de control de grupos (Crear / info)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF0B101E),
          child: Row(
            children: [
              const Icon(Icons.grid_view, size: 16, color: AppTheme.turfGreenLight),
              const SizedBox(width: 6),
              Text(
                'Grupos (${groups.length})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  foregroundColor: AppTheme.turfGreenLight,
                ),
                onPressed: _showCreateGroupDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nuevo Grupo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        // Selector de Pestañas de Grupo (dinámico)
        Container(
          color: const Color(0xFF0D1424),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.turfGreen,
            labelColor: AppTheme.turfGreen,
            unselectedLabelColor: AppTheme.slateTextSecondary,
            isScrollable: groups.length > 4,
            tabs: groups.map((g) => Tab(text: 'GRUPO $g')).toList(),
          ),
        ),

        // Lista de equipos por grupo
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: groups.map((g) {
              final groupTeams = widget.teams
                  .where((t) => t.grupo.toUpperCase() == g)
                  .toList()
                ..sort((a, b) {
                  if (b.puntos != a.puntos) return b.puntos.compareTo(a.puntos);
                  return b.dg.compareTo(a.dg);
                });

              if (groupTeams.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.groups_outlined, size: 54, color: AppTheme.slateTextSecondary),
                      const SizedBox(height: 12),
                      Text(
                        'No hay equipos en el Grupo $g',
                        style: const TextStyle(color: AppTheme.slateTextSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAddTeamDialog(null, g),
                        icon: const Icon(Icons.add),
                        label: Text('Agregar Equipo al Grupo $g'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.liveRedGlow,
                          side: const BorderSide(color: AppTheme.liveRedGlow),
                        ),
                        onPressed: () => _confirmDeleteGroup(g),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: Text('Eliminar Grupo $g'),
                      ),
                    ],
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Encabezado con instrucción de swipe
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.stadiumCardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withAlpha(20)),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 24, child: Text('#', style: TextStyle(color: AppTheme.slateTextSecondary, fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(child: Text('EQUIPO', style: TextStyle(color: AppTheme.slateTextSecondary, fontWeight: FontWeight.bold, fontSize: 12))),
                        SizedBox(width: 28, child: Text('PJ', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 12))),
                        SizedBox(width: 28, child: Text('DG', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 12))),
                        SizedBox(width: 32, child: Text('PTS', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.turfGreenLight, fontWeight: FontWeight.bold, fontSize: 12))),
                        SizedBox(width: 36), // espacio para el icono de eliminar
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Pista visual: deslizar para eliminar
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.swipe_left, size: 14, color: AppTheme.slateTextSecondary),
                        SizedBox(width: 4),
                        Text(
                          'Desliza ← para eliminar · Toca para editar',
                          style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),

                  // Filas de equipos con Dismissible (swipe-to-delete)
                  ...List.generate(groupTeams.length, (idx) {
                    final t = groupTeams[idx];
                    final qualifiers = widget.config?.clasificadosPorGrupo ?? 2;
                    final isQualified = qualifiers > 0 && idx < qualifiers;

                    return Dismissible(
                      key: ValueKey(t.idEquipo),
                      direction: DismissDirection.endToStart,
                      // Fondo rojo con ícono de basura al deslizar
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 8),
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
                      // Confirmar antes de eliminar (el swipe no elimina solo)
                      confirmDismiss: (direction) async {
                        await _confirmDeleteTeam(t);
                        return false; // siempre false: el callback maneja la actualización
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isQualified
                                ? AppTheme.turfGreen.withAlpha(120)
                                : Colors.white.withAlpha(15),
                            width: isQualified ? 1.5 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showAddTeamDialog(t),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  child: Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                      color: isQualified ? AppTheme.turfGreen : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Escudo
                                Container(
                                  width: 26,
                                  height: 26,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(int.tryParse(t.colorHex.replaceFirst('#', '0xFF')) ?? 0xFF3B82F6),
                                    border: Border.all(color: Colors.white.withAlpha(60), width: 1),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: t.logoUrl.isNotEmpty
                                      ? Image.network(
                                          t.logoUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.shield, color: Colors.white, size: 14),
                                        )
                                      : const Icon(Icons.shield, color: Colors.white, size: 14),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.nombre,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      if (isQualified)
                                        const Text(
                                          'Puesto de Avance',
                                          style: TextStyle(color: AppTheme.turfGreenLight, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 28,
                                  child: Text('${t.pj}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                ),
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    '${t.dg >= 0 ? "+${t.dg}" : t.dg}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: t.dg > 0 ? AppTheme.turfGreenLight : (t.dg < 0 ? AppTheme.liveRedGlow : Colors.white),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    '${t.puntos}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppTheme.turfGreenLight,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                // Botón explícito de eliminar (alternativa al swipe)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.slateTextSecondary),
                                  tooltip: 'Eliminar equipo',
                                  onPressed: () => _confirmDeleteTeam(t),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
          ),
        ),

        // Botón para agregar nuevo equipo
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddTeamDialog(),
              icon: const Icon(Icons.add_circle, size: 20),
              label: const Text('REGISTRAR NUEVO EQUIPO'),
            ),
          ),
        ),
      ],
    );
  }
}
