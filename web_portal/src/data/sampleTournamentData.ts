import type { TournamentData } from '../types/tournament';

export const sampleTournamentData: TournamentData = {
  success: true,
  sheetId: 'DEMO_SPREADSHEET_ID_2026',
  timestamp: new Date().toISOString(),
  config: {
    nombre_evento: 'Juegos Magisteriales 2026',
    disciplina: 'FÚTBOL 11',
    countdown_target: new Date(Date.now() + 1000 * 60 * 60 * 28).toISOString(), // 28 horas en el futuro
    countdown_title: 'Gran Inauguración y Partido Inicial',
    fase_actual: 'GRUPOS',
    clasificados_por_grupo: 2
  },
  teams: [
    {
      id_equipo: 'EQP-01',
      nombre: 'Magisterio Cusco',
      grupo: 'A',
      color_hex: '#DC2626',
      logo_url: '',
      pj: 2,
      pg: 2,
      pe: 0,
      pp: 0,
      gf: 5,
      gc: 1,
      dg: 4,
      puntos: 6
    },
    {
      id_equipo: 'EQP-02',
      nombre: 'Docentes Arequipa',
      grupo: 'A',
      color_hex: '#2563EB',
      logo_url: '',
      pj: 2,
      pg: 1,
      pe: 0,
      pp: 1,
      gf: 3,
      gc: 2,
      dg: 1,
      puntos: 3
    },
    {
      id_equipo: 'EQP-03',
      nombre: 'Educadores Puno',
      grupo: 'A',
      color_hex: '#16A34A',
      logo_url: '',
      pj: 2,
      pg: 0,
      pe: 1,
      pp: 1,
      gf: 2,
      gc: 4,
      dg: -2,
      puntos: 1
    },
    {
      id_equipo: 'EQP-04',
      nombre: 'Colegio Abancay',
      grupo: 'A',
      color_hex: '#CA8A04',
      logo_url: '',
      pj: 2,
      pg: 0,
      pe: 1,
      pp: 1,
      gf: 1,
      gc: 4,
      dg: -3,
      puntos: 1
    },
    {
      id_equipo: 'EQP-05',
      nombre: 'Pedagógico Lima',
      grupo: 'B',
      color_hex: '#9333EA',
      logo_url: '',
      pj: 2,
      pg: 1,
      pe: 1,
      pp: 0,
      gf: 4,
      gc: 2,
      dg: 2,
      puntos: 4
    },
    {
      id_equipo: 'EQP-06',
      nombre: 'I.E. Trujillo Norte',
      grupo: 'B',
      color_hex: '#0D9488',
      logo_url: '',
      pj: 2,
      pg: 1,
      pe: 1,
      pp: 0,
      gf: 3,
      gc: 1,
      dg: 2,
      puntos: 4
    },
    {
      id_equipo: 'EQP-07',
      nombre: 'Profesores Piura',
      grupo: 'B',
      color_hex: '#EA580C',
      logo_url: '',
      pj: 2,
      pg: 0,
      pe: 1,
      pp: 1,
      gf: 1,
      gc: 2,
      dg: -1,
      puntos: 1
    },
    {
      id_equipo: 'EQP-08',
      nombre: 'Magisterio Huancayo',
      grupo: 'B',
      color_hex: '#4F46E5',
      logo_url: '',
      pj: 2,
      pg: 0,
      pe: 1,
      pp: 1,
      gf: 0,
      gc: 3,
      dg: -3,
      puntos: 1
    }
  ],
  matches: [
    {
      id_partido: 'MAT-01',
      fase: 'Grupo A',
      fecha_hora: new Date(Date.now() - 1000 * 60 * 45).toISOString(), // En vivo ahora
      cancha: 'Estadio Olímpico - Cancha 1',
      local_id: 'EQP-01',
      visita_id: 'EQP-02',
      goles_local: 2,
      goles_visita: 1,
      estado: 'EN_VIVO',
      arbitro_asignado: 'Carlos Silva (FIFA)'
    },
    {
      id_partido: 'MAT-02',
      fase: 'Grupo A',
      fecha_hora: new Date(Date.now() + 1000 * 60 * 90).toISOString(),
      cancha: 'Cancha Sintética 2',
      local_id: 'EQP-03',
      visita_id: 'EQP-04',
      goles_local: 0,
      goles_visita: 0,
      estado: 'PROGRAMADO',
      arbitro_asignado: 'Mario Ramos'
    },
    {
      id_partido: 'MAT-03',
      fase: 'Grupo B',
      fecha_hora: new Date(Date.now() - 1000 * 60 * 180).toISOString(),
      cancha: 'Estadio Olímpico - Cancha 1',
      local_id: 'EQP-05',
      visita_id: 'EQP-06',
      goles_local: 2,
      goles_visita: 2,
      estado: 'FINALIZADO',
      arbitro_asignado: 'Roberto Quispe'
    },
    {
      id_partido: 'MAT-04',
      fase: 'Grupo B',
      fecha_hora: new Date(Date.now() + 1000 * 60 * 240).toISOString(),
      cancha: 'Cancha Sintética 2',
      local_id: 'EQP-07',
      visita_id: 'EQP-08',
      goles_local: 0,
      goles_visita: 0,
      estado: 'PROGRAMADO',
      arbitro_asignado: 'Esteban Torres'
    },
    {
      id_partido: 'MAT-05',
      fase: 'Cuartos de Final',
      fecha_hora: new Date(Date.now() + 1000 * 60 * 60 * 48).toISOString(),
      cancha: 'Estadio Principal',
      local_id: 'EQP-01',
      visita_id: 'EQP-06',
      goles_local: 0,
      goles_visita: 0,
      estado: 'PROGRAMADO',
      arbitro_asignado: 'Por designar'
    }
  ],
  bracket: [
    {
      cruce_id: 'C-01',
      ronda: 'CUARTOS',
      equipo_1_id: 'EQP-01',
      equipo_2_id: 'EQP-06',
      ganador_id: 'EQP-01',
      siguiente_cruce_id: 'S-01'
    },
    {
      cruce_id: 'C-02',
      ronda: 'CUARTOS',
      equipo_1_id: 'EQP-05',
      equipo_2_id: 'EQP-02',
      ganador_id: 'EQP-05',
      siguiente_cruce_id: 'S-01'
    },
    {
      cruce_id: 'C-03',
      ronda: 'CUARTOS',
      equipo_1_id: 'EQP-03',
      equipo_2_id: 'EQP-08',
      ganador_id: 'EQP-03',
      siguiente_cruce_id: 'S-02'
    },
    {
      cruce_id: 'C-04',
      ronda: 'CUARTOS',
      equipo_1_id: 'EQP-07',
      equipo_2_id: 'EQP-04',
      ganador_id: 'EQP-07',
      siguiente_cruce_id: 'S-02'
    },
    {
      cruce_id: 'S-01',
      ronda: 'SEMIFINAL',
      equipo_1_id: 'EQP-01',
      equipo_2_id: 'EQP-05',
      ganador_id: 'EQP-01',
      siguiente_cruce_id: 'F-01'
    },
    {
      cruce_id: 'S-02',
      ronda: 'SEMIFINAL',
      equipo_1_id: 'EQP-03',
      equipo_2_id: 'EQP-07',
      ganador_id: 'EQP-07',
      siguiente_cruce_id: 'F-01'
    },
    {
      cruce_id: 'F-01',
      ronda: 'FINAL',
      equipo_1_id: 'EQP-01',
      equipo_2_id: 'EQP-07',
      ganador_id: 'EQP-01',
      siguiente_cruce_id: ''
    }
  ]
};
