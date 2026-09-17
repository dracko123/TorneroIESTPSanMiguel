import type { TournamentData } from '../types/tournament';

/**
 * Datos iniciales vacíos que se usan mientras se obtienen los datos reales del API.
 * NO contienen equipos ni partidos de prueba para evitar confusión.
 * La pantalla de carga (LoadingScreen) se muestra durante este período.
 */
export const sampleTournamentData: TournamentData = {
  success: true,
  sheetId: '',
  timestamp: new Date().toISOString(),
  config: {
    nombre_evento: '',
    disciplina: 'FÚTBOL',
    countdown_target: '',
    countdown_title: '',
    fase_actual: 'GRUPOS',
    clasificados_por_grupo: 2
  },
  teams: [],
  matches: [],
  bracket: []
};
