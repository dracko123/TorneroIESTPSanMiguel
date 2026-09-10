import 'dart:math';
import '../models/match_model.dart';
import '../models/team_model.dart';

/// Configuración de parámetros para la generación automática de fixtures
class FixtureGeneratorOptions {
  final DateTime startDateTime;
  final int matchIntervalMinutes;
  final List<String> canchas;
  final bool idaYVuelta;
  final int daysBetweenRounds;

  const FixtureGeneratorOptions({
    required this.startDateTime,
    this.matchIntervalMinutes = 60,
    this.canchas = const ['Cancha 1'],
    this.idaYVuelta = false,
    this.daysBetweenRounds = 0,
  });
}

/// Resultado de la generación de fixtures
class FixtureGenerationResult {
  final List<MatchModel> matches;
  final int totalMatches;
  final int totalRounds;
  final Map<String, int> matchesPerGroup;
  final List<String> restMessages; // Informa qué equipo descansa si el grupo es impar

  const FixtureGenerationResult({
    required this.matches,
    required this.totalMatches,
    required this.totalRounds,
    required this.matchesPerGroup,
    required this.restMessages,
  });
}

class FixtureGenerator {
  /// Sortea aleatoriamente los equipos distribuyéndolos de forma balanceada
  /// entre los grupos especificados (ej. ['A', 'B']).
  static List<TeamModel> shuffleAndDistributeTeams({
    required List<TeamModel> teams,
    required List<String> targetGroups,
  }) {
    if (teams.isEmpty || targetGroups.isEmpty) return teams;

    // Copiar y mezclar aleatoriamente con Fisher-Yates
    final shuffled = List<TeamModel>.from(teams)..shuffle(Random());
    final List<TeamModel> updatedTeams = [];

    for (int i = 0; i < shuffled.length; i++) {
      final groupName = targetGroups[i % targetGroups.length];
      final original = shuffled[i];

      updatedTeams.add(TeamModel(
        idEquipo: original.idEquipo,
        nombre: original.nombre,
        grupo: groupName,
        colorHex: original.colorHex,
        logoUrl: original.logoUrl,
        pj: original.pj,
        pg: original.pg,
        pe: original.pe,
        pp: original.pp,
        gf: original.gf,
        gc: original.gc,
        dg: original.dg,
        puntos: original.puntos,
      ));
    }

    return updatedTeams;
  }

  /// Genera el fixture Round-Robin (Sistema Berger) para cada grupo
  /// garantizando que NO existan partidos duplicados entre los mismos equipos.
  static FixtureGenerationResult generateGroupStageFixture({
    required List<TeamModel> allTeams,
    required FixtureGeneratorOptions options,
    List<MatchModel> existingMatches = const [],
  }) {
    // 1. Agrupar equipos por grupo
    final Map<String, List<TeamModel>> teamsByGroup = {};
    for (final t in allTeams) {
      final g = t.grupo.toUpperCase().trim();
      if (g.isNotEmpty) {
        teamsByGroup.putIfAbsent(g, () => []).add(t);
      }
    }

    final List<MatchModel> generatedMatches = [];
    final Map<String, int> matchesPerGroup = {};
    final List<String> restMessages = [];
    int maxRoundsAcrossGroups = 0;

    // Conjunto de claves para validación estricta anti-duplicados
    // Clave: FASE__LOCAL__VISITA
    final Set<String> uniquePairings = {};

    // Registrar partidos existentes para jamás duplicar
    for (final em in existingMatches) {
      final f = em.fase.toUpperCase().trim();
      final loc = em.localId.trim();
      final vis = em.visitaId.trim();
      if (loc.isNotEmpty && vis.isNotEmpty) {
        uniquePairings.add('${f}__${loc}__$vis');
      }
    }

    final canchas = options.canchas.isNotEmpty ? options.canchas : ['Cancha 1'];
    int canchaIndex = 0;
    DateTime currentMatchTime = options.startDateTime;

    final sortedGroups = teamsByGroup.keys.toList()..sort();

    for (final groupName in sortedGroups) {
      final groupTeams = teamsByGroup[groupName]!;
      if (groupTeams.length < 2) continue;

      final faseName = 'Grupo $groupName';
      int groupMatchCount = 0;

      // Algoritmo de Berger para Round-Robin:
      // Si el número de equipos es impar, se añade un elemento null ("descansa")
      final List<TeamModel?> roundRobinList = List<TeamModel?>.from(groupTeams);
      final bool hasBye = roundRobinList.length.isOdd;
      if (hasBye) {
        roundRobinList.add(null);
      }

      final int totalTeams = roundRobinList.length;
      final int roundsCount = totalTeams - 1;
      if (roundsCount > maxRoundsAcrossGroups) {
        maxRoundsAcrossGroups = roundsCount;
      }

      final int matchesPerRound = totalTeams ~/ 2;

      // Rueda 1: Ida
      for (int round = 0; round < roundsCount; round++) {
        final roundDate = options.daysBetweenRounds > 0
            ? options.startDateTime.add(Duration(days: round * options.daysBetweenRounds))
            : currentMatchTime;

        for (int m = 0; m < matchesPerRound; m++) {
          final int t1Idx = (round + m) % (totalTeams - 1);
          int t2Idx = (totalTeams - 1 - m + round) % (totalTeams - 1);

          if (m == 0) {
            t2Idx = totalTeams - 1;
          }

          final TeamModel? team1 = roundRobinList[t1Idx];
          final TeamModel? team2 = roundRobinList[t2Idx];

          // Si uno es null, el otro equipo descansa en esta fecha
          if (team1 == null || team2 == null) {
            final restingTeam = team1 ?? team2;
            if (restingTeam != null) {
              restMessages.add('Jornada ${round + 1} ($faseName): Descansa ${restingTeam.nombre}');
            }
            continue;
          }

          // Alternar local / visita para equilibrio de campo
          final bool alternate = (round + m).isOdd;
          final local = alternate ? team2 : team1;
          final visita = alternate ? team1 : team2;

          final pairKey = '${faseName}__${local.idEquipo}__${visita.idEquipo}';

          // Verificación ESTRICTA anti-duplicados
          if (uniquePairings.contains(pairKey)) {
            continue; // Evitar duplicar
          }
          uniquePairings.add(pairKey);

          final cancha = canchas[canchaIndex % canchas.length];
          canchaIndex++;

          generatedMatches.add(MatchModel(
            idPartido: '', // El backend le asignará ID secuencial
            fase: faseName,
            fechaHora: roundDate.toUtc().toIso8601String(),
            cancha: cancha,
            localId: local.idEquipo,
            visitaId: visita.idEquipo,
            estado: 'PROGRAMADO',
            arbitroAsignado: 'Por designar',
          ));

          groupMatchCount++;

          if (options.daysBetweenRounds == 0) {
            currentMatchTime = currentMatchTime.add(Duration(minutes: options.matchIntervalMinutes));
          }
        }
      }

      // Rueda 2: Vuelta (si se solicitó Ida y Vuelta)
      if (options.idaYVuelta) {
        final vueltaMatches = <MatchModel>[];
        for (final idaMatch in generatedMatches.where((m) => m.fase == faseName)) {
          // Invierte local y visitante
          final pairKey = '${faseName}__${idaMatch.visitaId}__${idaMatch.localId}';
          if (uniquePairings.contains(pairKey)) {
            continue;
          }
          uniquePairings.add(pairKey);

          currentMatchTime = currentMatchTime.add(Duration(minutes: options.matchIntervalMinutes));
          final cancha = canchas[canchaIndex % canchas.length];
          canchaIndex++;

          vueltaMatches.add(MatchModel(
            idPartido: '',
            fase: faseName,
            fechaHora: currentMatchTime.toUtc().toIso8601String(),
            cancha: cancha,
            localId: idaMatch.visitaId,
            visitaId: idaMatch.localId,
            estado: 'PROGRAMADO',
            arbitroAsignado: 'Por designar',
          ));
          groupMatchCount++;
        }
        generatedMatches.addAll(vueltaMatches);
      }

      matchesPerGroup[groupName] = groupMatchCount;
    }

    return FixtureGenerationResult(
      matches: generatedMatches,
      totalMatches: generatedMatches.length,
      totalRounds: options.idaYVuelta ? maxRoundsAcrossGroups * 2 : maxRoundsAcrossGroups,
      matchesPerGroup: matchesPerGroup,
      restMessages: restMessages,
    );
  }
}
