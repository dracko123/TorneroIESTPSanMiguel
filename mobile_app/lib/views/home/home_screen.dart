import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/team_model.dart';
import '../../models/match_model.dart';
import '../../models/tournament_config_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../live/live_control_screen.dart';
import '../fixtures/fixtures_screen.dart';
import '../admin/teams_management_screen.dart';
import '../admin/tournament_config_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  TournamentConfigModel _config = TournamentConfigModel(
    nombreEvento: 'Torneo Deportivo',
    countdownTarget: DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    countdownTitle: 'Inauguración Oficial',
  );
  List<TeamModel> _teams = [];
  List<MatchModel> _matches = [];

  @override
  void initState() {
    super.initState();
    _fetchTournamentData();
  }

  Future<void> _fetchTournamentData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService().getPublicData();

    if (mounted) {
      if (res.success && res.data != null) {
        setState(() {
          _config = res.data!.config;
          _teams = res.data!.teams;
          _matches = res.data!.matches;
          _isLoading = false;
        });
      } else {
        // Si no hay conexión al backend en la nube, cargar datos locales de plantilla
        setState(() {
          _errorMessage = res.error;
          _isLoading = false;
          _loadFallbackTemplateData();
        });
      }
    }
  }

  void _loadFallbackTemplateData() {
    // Datos de plantilla mientras se vincula con el Google Sheet
    _config = TournamentConfigModel(
      nombreEvento: 'Juegos Magisteriales 2026',
      countdownTarget: '2026-10-15T09:00:00Z',
      countdownTitle: 'Inauguración y Partido Inicial',
      faseActual: 'GRUPOS',
      clasificadosPorGrupo: 2,
    );
    _teams = [
      TeamModel(idEquipo: 'EQP-01', nombre: 'Magisterio Cusco', grupo: 'A', colorHex: '#DC2626', pj: 2, pg: 2, pe: 0, pp: 0, gf: 5, gc: 1, dg: 4, puntos: 6),
      TeamModel(idEquipo: 'EQP-02', nombre: 'Docentes Arequipa', grupo: 'A', colorHex: '#2563EB', pj: 2, pg: 1, pe: 0, pp: 1, gf: 3, gc: 2, dg: 1, puntos: 3),
      TeamModel(idEquipo: 'EQP-03', nombre: 'Educadores Puno', grupo: 'A', colorHex: '#16A34A', pj: 2, pg: 0, pe: 1, pp: 1, gf: 2, gc: 4, dg: -2, puntos: 1),
      TeamModel(idEquipo: 'EQP-04', nombre: 'Colegio Abancay', grupo: 'A', colorHex: '#CA8A04', pj: 2, pg: 0, pe: 1, pp: 1, gf: 1, gc: 4, dg: -3, puntos: 1),
      TeamModel(idEquipo: 'EQP-05', nombre: 'Pedagógico Lima', grupo: 'B', colorHex: '#9333EA', pj: 2, pg: 1, pe: 1, pp: 0, gf: 4, gc: 2, dg: 2, puntos: 4),
      TeamModel(idEquipo: 'EQP-06', nombre: 'I.E. Trujillo Norte', grupo: 'B', colorHex: '#0D9488', pj: 2, pg: 1, pe: 1, pp: 0, gf: 3, gc: 1, dg: 2, puntos: 4),
      TeamModel(idEquipo: 'EQP-07', nombre: 'Profesores Piura', grupo: 'B', colorHex: '#EA580C', pj: 2, pg: 0, pe: 1, pp: 1, gf: 1, gc: 2, dg: -1, puntos: 1),
      TeamModel(idEquipo: 'EQP-08', nombre: 'Magisterio Huancayo', grupo: 'B', colorHex: '#4F46E5', pj: 2, pg: 0, pe: 1, pp: 1, gf: 0, gc: 3, dg: -3, puntos: 1),
    ];
    _matches = [
      MatchModel(idPartido: 'MAT-01', fase: 'Grupo A', fechaHora: '2026-10-15T09:00:00Z', cancha: 'Cancha 1 (Principal)', localId: 'EQP-01', visitaId: 'EQP-02', golesLocal: 2, golesVisita: 1, estado: 'FINALIZADO', arbitroAsignado: 'Carlos Morales'),
      MatchModel(idPartido: 'MAT-02', fase: 'Grupo A', fechaHora: '2026-10-15T10:30:00Z', cancha: 'Cancha 2', localId: 'EQP-03', visitaId: 'EQP-04', golesLocal: 1, golesVisita: 1, estado: 'FINALIZADO', arbitroAsignado: 'Luis Rojas'),
      MatchModel(idPartido: 'MAT-03', fase: 'Grupo B', fechaHora: '2026-10-15T12:00:00Z', cancha: 'Cancha 1 (Principal)', localId: 'EQP-05', visitaId: 'EQP-06', golesLocal: 2, golesVisita: 1, estado: 'EN_VIVO', arbitroAsignado: 'Miguel Soto'),
      MatchModel(idPartido: 'MAT-04', fase: 'Grupo B', fechaHora: '2026-10-15T13:30:00Z', cancha: 'Cancha 2', localId: 'EQP-07', visitaId: 'EQP-08', golesLocal: 0, golesVisita: 0, estado: 'PROGRAMADO', arbitroAsignado: 'Carlos Morales'),
    ];
  }

  void _handleLogout() async {
    await AuthService().logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final user = auth.currentUser;
    final isSuperAdmin = auth.isSuperAdmin;

    // Si es MESA_CONTROL, solo tiene acceso a la pantalla de Mesa en Vivo
    final List<Widget> pages = isSuperAdmin
        ? [
            LiveControlScreen(
              matches: _matches,
              teams: _teams,
              onRefreshRequested: _fetchTournamentData,
            ),
            FixturesScreen(
              matches: _matches,
              teams: _teams,
              config: _config,
              onMatchesUpdated: _fetchTournamentData,
            ),
            TeamsManagementScreen(
              teams: _teams,
              config: _config,
              onTeamsUpdated: _fetchTournamentData,
            ),
            TournamentConfigScreen(
              config: _config,
              onConfigSaved: _fetchTournamentData,
            ),
          ]
        : [
            LiveControlScreen(
              matches: _matches,
              teams: _teams,
              onRefreshRequested: _fetchTournamentData,
            ),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(_config.nombreEvento),
            Text(
              user != null ? '${user.nombre} (${user.rol})' : 'Mesa Operativa',
              style: const TextStyle(fontSize: 11, color: AppTheme.trophyGold, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.turfGreen),
            tooltip: 'Sincronizar con Google Sheets',
            onPressed: _fetchTournamentData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.slateTextSecondary),
            tooltip: 'Cerrar Sesión',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.turfGreen),
                  SizedBox(height: 16),
                  Text('Sincronizando con Google Sheets...', style: TextStyle(color: Colors.white)),
                ],
              ),
            )
          : Column(
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    color: AppTheme.trophyGold.withAlpha(40),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppTheme.trophyGold, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Modo Offline / Plantilla activa. ($_errorMessage)',
                            style: const TextStyle(color: AppTheme.trophyGold, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Expanded(child: pages[_currentIndex >= pages.length ? 0 : _currentIndex]),
              ],
            ),
      bottomNavigationBar: isSuperAdmin
          ? NavigationBar(
              backgroundColor: AppTheme.stadiumCardBg,
              indicatorColor: AppTheme.turfGreen.withAlpha(50),
              selectedIndex: _currentIndex,
              onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.sports_soccer, color: AppTheme.slateTextSecondary),
                  selectedIcon: Icon(Icons.sports_soccer, color: AppTheme.turfGreen),
                  label: 'Mesa en Vivo',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month, color: AppTheme.slateTextSecondary),
                  selectedIcon: Icon(Icons.calendar_month, color: AppTheme.turfGreen),
                  label: 'Partidos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups, color: AppTheme.slateTextSecondary),
                  selectedIcon: Icon(Icons.groups, color: AppTheme.turfGreen),
                  label: 'Equipos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings, color: AppTheme.slateTextSecondary),
                  selectedIcon: Icon(Icons.settings, color: AppTheme.turfGreen),
                  label: 'Configuración',
                ),
              ],
            )
          : null, // Si es mesa de control, no requiere barra inferior ya que opera únicamente en vivo
    );
  }
}
