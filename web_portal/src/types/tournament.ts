export interface TournamentConfig {
  nombre_evento: string;
  disciplina: string;
  countdown_target: string;
  countdown_title: string;
  fase_actual: 'GRUPOS' | 'TREINTAIDOSAVOS' | 'DIECISEISAVOS' | 'OCTAVOS' | 'CUARTOS' | 'SEMIFINAL' | 'FINAL' | string;
  clasificados_por_grupo: number;
  organizador_nombre?: string;
  organizador_logo_url?: string;
  banner_bg_url?: string;
  puntos_victoria?: number;
  puntos_empate?: number;
  puntos_derrota?: number;
  puntos_victoria_wo?: number;
  puntos_derrota_wo?: number;
  goles_wo_favor?: number;
  goles_wo_contra?: number;
  plan_max_equipos?: number;
  fase_max_eliminatoria?: string;
  acumulacion_amarillas_activa?: boolean | string;
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

export interface MatchEventItem {
  id: string;
  tipo: 'GOL' | 'AMARILLA' | 'ROJA_ACUMULADA' | 'ROJA_DIRECTA' | 'CAMBIO' | string;
  equipo?: string;
  id_equipo?: string;
  id_jugador?: string;
  dorsal?: number;
  nombre?: string;
  id_jugador_sale?: string;
  dorsal_sale?: number;
  nombre_sale?: string;
  id_jugador_entra?: string;
  dorsal_entra?: number;
  nombre_entra?: string;
  periodo?: string;
  hora?: string;
}

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
  walkover?: 'NO' | 'LOCAL' | 'VISITA' | 'DOBLE';
  tiempo_en_vivo?: string;
  tarjetas_amarillas_local?: number;
  tarjetas_rojas_local?: number;
  tarjetas_amarillas_visita?: number;
  tarjetas_rojas_visita?: number;
  eventos_partido?: string;
  llave_origen?: string;
}

export interface Player {
  id_jugador: string;
  id_equipo: string;
  dni?: string;
  nombres_apellidos: string;
  apelativo?: string;
  dorsal: number;
  goles?: number;
  goles_totales?: number;
  amarillas_total?: number;
  amarillas_totales?: number;
  amarillas_fase_actual?: number;
  rojas_total?: number;
  rojas_totales?: number;
  estado_disciplinario: string;
  partidos_suspendido_restantes?: number;
  motivo_suspension?: string;
  historial_fases_json?: string;
}

export interface BracketMatch {
  cruce_id: string;
  ronda: 'TREINTAIDOSAVOS' | 'DIECISEISAVOS' | 'OCTAVOS' | 'CUARTOS' | 'SEMIFINAL' | 'TERCER_PUESTO' | 'FINAL' | string;
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
  players?: Player[];
}
