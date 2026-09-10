export interface TournamentConfig {
  nombre_evento: string;
  disciplina: string;
  countdown_target: string;
  countdown_title: string;
  fase_actual: 'GRUPOS' | 'CUARTOS' | 'SEMIFINAL' | 'FINAL' | string;
  clasificados_por_grupo: number;
  organizador_nombre?: string;
  organizador_logo_url?: string;
  banner_bg_url?: string;
}

export interface Team {
  id_equipo: string;
  nombre: string;
  grupo: string;
  color_hex: string;
  logo_url?: string;
  pj: number;
  pg: number;
  pe: number;
  pp: number;
  gf: number;
  gc: number;
  dg: number;
  puntos: number;
}

export type MatchStatus = 'PROGRAMADO' | 'EN_VIVO' | 'ENTRETIEMPO' | 'FINALIZADO';

export interface Match {
  id_partido: string;
  fase: string;
  fecha_hora: string;
  cancha: string;
  local_id: string;
  visita_id: string;
  goles_local: number;
  goles_visita: number;
  penales_local?: number;
  penales_visita?: number;
  estado: MatchStatus;
  arbitro_asignado: string;
}

export interface BracketMatch {
  cruce_id: string;
  ronda: 'CUARTOS' | 'SEMIFINAL' | 'FINAL' | string;
  equipo_1_id: string;
  equipo_2_id: string;
  ganador_id?: string;
  siguiente_cruce_id?: string;
}

export interface TournamentData {
  success: boolean;
  sheetId: string;
  timestamp: string;
  config: TournamentConfig;
  teams: Team[];
  matches: Match[];
  bracket: BracketMatch[];
}
