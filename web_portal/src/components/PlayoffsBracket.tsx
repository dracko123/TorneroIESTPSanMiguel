import React, { useMemo } from 'react';
import type { BracketMatch, Match, Team, TournamentConfig } from '../types/tournament';
import { TeamBadge } from './TeamBadge';
import { Trophy, Crown, Sparkles, Radio, ArrowRight, Shield } from 'lucide-react';
import confetti from 'canvas-confetti';

interface PlayoffsBracketProps {
  bracket: BracketMatch[];
  teams: Team[];
  matches: Match[];
  config?: TournamentConfig;
}

// ─── Dimensiones del Árbol ───────────────────────────────────────────────────

const MATCH_H = 152;  // Altura cómoda y calibrada de cada tarjeta de partido (px)
const MATCH_W = 295;  // Ancho generoso de cada tarjeta para evitar nombres cortados (px)
const BASE_GAP = 32;  // Separación base equilibrada entre partidos (px)
const CONN_W = 64;    // Ancho suave de la zona de conectores SVG (px)
const HEADER_H = 48;  // Altura del encabezado de ronda (px)

// ─── Orden y Etiquetas de Rondas ─────────────────────────────────────────────

const ROUND_ORDER = ['OCTAVOS', 'CUARTOS', 'SEMIFINAL', 'FINAL'] as const;

const ROUND_LABELS: Record<string, string> = {
  OCTAVOS: 'Octavos de Final',
  CUARTOS: 'Cuartos de Final',
  SEMIFINAL: 'Semifinales',
  FINAL: 'Gran Final',
};

const ROUND_THEMES: Record<string, { text: string; badgeBg: string; border: string; glow: string; connColor: string }> = {
  OCTAVOS:   { text: 'text-sky-400',     badgeBg: 'bg-sky-500/10',     border: 'border-sky-500/30',     glow: '#38bdf8', connColor: '#38bdf8' },
  CUARTOS:   { text: 'text-indigo-400',  badgeBg: 'bg-indigo-500/10',  border: 'border-indigo-500/30',  glow: '#818cf8', connColor: '#818cf8' },
  SEMIFINAL: { text: 'text-emerald-400', badgeBg: 'bg-emerald-500/10', border: 'border-emerald-500/30', glow: '#10b981', connColor: '#10b981' },
  FINAL:     { text: 'text-amber-400',   badgeBg: 'bg-amber-500/15',   border: 'border-amber-500/50',   glow: '#f59e0b', connColor: '#f59e0b' },
};

// ─── Helpers de Normalización y Árbol ─────────────────────────────────────────

function normalizeRound(ronda: string): string {
  const r = (ronda || '').toUpperCase().trim();
  if (r.includes('OCTAVO')) return 'OCTAVOS';
  if (r.includes('CUARTO')) return 'CUARTOS';
  if (r.includes('SEMI')) return 'SEMIFINAL';
  if (r.includes('FINAL') && !r.includes('TERCER') && !r.includes('3')) return 'FINAL';
  return r;
}

function getMatchWinnerId(m: Match): string {
  if (m.estado !== 'FINALIZADO') return '';
  const gl = Number(m.goles_local) || 0;
  const gv = Number(m.goles_visita) || 0;
  const pl = Number(m.penales_local) || 0;
  const pv = Number(m.penales_visita) || 0;
  if (gl > gv) return m.local_id;
  if (gv > gl) return m.visita_id;
  if (pl > pv) return m.local_id;
  if (pv > pl) return m.visita_id;
  return '';
}

function isPlayoffMatch(m: Match): boolean {
  const f = (m.fase || '').toUpperCase();
  return !f.includes('GRUPO') && (f.includes('OCTAVO') || f.includes('CUARTO') || f.includes('SEMI') || f.includes('FINAL'));
}

/**
 * Genera el árbol de llaves efectivo y sincronizado.
 * Si existen partidos de playoffs en `matches` (registrados desde la app en PARTIDOS_FUTBOL),
 * estos tienen máxima prioridad para reflejar la realidad del torneo, enlazando rondas
 * y proyectando la siguiente fase si aún no se ha programado.
 */
function computeEffectiveBracket(rawBracket: BracketMatch[], matches: Match[]): BracketMatch[] {
  const playoffMatches = matches.filter(isPlayoffMatch);

  // Si no hay partidos de playoffs en `matches`, usamos directamente `rawBracket`
  if (playoffMatches.length === 0) {
    return rawBracket;
  }

  // Agrupar los partidos de playoff por ronda normalizada
  const matchesByRound = new Map<string, Match[]>();
  playoffMatches.forEach(m => {
    const rnd = normalizeRound(m.fase);
    if (!matchesByRound.has(rnd)) matchesByRound.set(rnd, []);
    matchesByRound.get(rnd)!.push(m);
  });

  // Detectar rondas reales que tienen partidos en `matches`
  const activeRounds = ROUND_ORDER.filter(r => matchesByRound.has(r));

  // Si la última ronda con partidos no es FINAL (por ejemplo sólo se han jugado Semifinales)
  // proyectamos el cruce de la siguiente ronda con los equipos clasificados
  const lastRound = activeRounds[activeRounds.length - 1];
  const lastRoundMatches = matchesByRound.get(lastRound) || [];
  const projectedNodes: BracketMatch[] = [];

  if (lastRound !== 'FINAL' && lastRoundMatches.length >= 2) {
    const nextRoundIndex = ROUND_ORDER.indexOf(lastRound as any) + 1;
    if (nextRoundIndex < ROUND_ORDER.length) {
      const projectedRound = ROUND_ORDER[nextRoundIndex];
      const projectedCount = Math.ceil(lastRoundMatches.length / 2);
      for (let i = 0; i < projectedCount; i++) {
        const m1 = lastRoundMatches[i * 2];
        const m2 = lastRoundMatches[i * 2 + 1];
        const w1 = m1 ? getMatchWinnerId(m1) : '';
        const w2 = m2 ? getMatchWinnerId(m2) : '';
        const projId = `PROJ-${projectedRound.slice(0, 3)}-${i + 1}`;
        projectedNodes.push({
          cruce_id: projId,
          ronda: projectedRound,
          equipo_1_id: w1 || '',
          equipo_2_id: w2 || '',
          ganador_id: '',
          siguiente_cruce_id: ''
        });
      }
      activeRounds.push(projectedRound);
    }
  }

  const result: BracketMatch[] = [];

  for (let ri = 0; ri < activeRounds.length; ri++) {
    const round = activeRounds[ri];
    const rMatches = matchesByRound.get(round) || [];
    const nextRound = activeRounds[ri + 1];
    const nextMatches = nextRound ? (matchesByRound.get(nextRound) || []) : [];
    const nextProjected = nextRound ? projectedNodes.filter(p => p.ronda === nextRound) : [];

    rMatches.forEach((m, idx) => {
      const winner = getMatchWinnerId(m);
      let siguienteId = '';

      if (nextMatches.length > 0) {
        if (winner) {
          const foundNext = nextMatches.find(nm => nm.local_id === winner || nm.visita_id === winner);
          if (foundNext) siguienteId = foundNext.id_partido;
        }
        if (!siguienteId) {
          const nextIdx = Math.floor(idx / 2);
          if (nextMatches[nextIdx]) siguienteId = nextMatches[nextIdx].id_partido;
        }
      } else if (nextProjected.length > 0) {
        const nextIdx = Math.floor(idx / 2);
        if (nextProjected[nextIdx]) siguienteId = nextProjected[nextIdx].cruce_id;
      }

      result.push({
        cruce_id: m.id_partido,
        ronda: round,
        equipo_1_id: m.local_id || '',
        equipo_2_id: m.visita_id || '',
        ganador_id: winner,
        siguiente_cruce_id: siguienteId
      });
    });
  }

  projectedNodes.forEach(pn => result.push(pn));
  return result;
}

function detectActiveRounds(bracket: BracketMatch[]): string[] {
  const present = new Set(bracket.map(b => normalizeRound(b.ronda)));
  return ROUND_ORDER.filter(r => present.has(r));
}

/**
 * Ordena los partidos de cada ronda mediante DFS desde la Gran Final hacia atrás.
 * Garantiza que cada par de partidos de la ronda N-1 quede colocado exactamente
 * junto al partido que alimenta en la ronda N.
 */
function buildOrderedRoundMap(bracket: BracketMatch[]): Map<string, BracketMatch[]> {
  const feeders = new Map<string, BracketMatch[]>();
  bracket.forEach(b => {
    if (b.siguiente_cruce_id) {
      const arr = feeders.get(b.siguiente_cruce_id) ?? [];
      arr.push(b);
      feeders.set(b.siguiente_cruce_id, arr);
    }
  });

  // Raíces: Partidos que convergen (la Gran Final o cruces que no alimentan a otro)
  const roots = bracket.filter(
    b => !b.siguiente_cruce_id || !bracket.some(x => x.cruce_id === b.siguiente_cruce_id)
  );

  const result = new Map<string, BracketMatch[]>();
  const visited = new Set<string>();

  function dfs(m: BracketMatch) {
    if (visited.has(m.cruce_id)) return;
    visited.add(m.cruce_id);

    const children = feeders.get(m.cruce_id) ?? [];
    children.forEach(dfs);

    const round = normalizeRound(m.ronda);
    if (!result.has(round)) result.set(round, []);
    result.get(round)!.push(m);
  }

  roots.forEach(dfs);

  // Asegurar que partidos no enlazados no queden fuera
  bracket.forEach(b => {
    if (!visited.has(b.cruce_id)) {
      const round = normalizeRound(b.ronda);
      if (!result.has(round)) result.set(round, []);
      result.get(round)!.push(b);
    }
  });

  return result;
}

/**
 * Calcula las posiciones verticales (Y) para cada partido.
 * Cada partido en la ronda N se posiciona en el punto medio exacto de sus dos
 * partidos alimentadores en la ronda N-1.
 */
function computeCenters(
  activeRounds: string[],
  orderedMap: Map<string, BracketMatch[]>
): { centersByRound: Map<string, number[]>; totalH: number } {
  if (activeRounds.length === 0) {
    return { centersByRound: new Map(), totalH: 400 };
  }

  const maxMatchCount = Math.max(1, ...activeRounds.map(r => orderedMap.get(r)?.length ?? 0));
  const totalH = Math.max(400, maxMatchCount * MATCH_H + Math.max(0, maxMatchCount - 1) * BASE_GAP);
  const centersByRound = new Map<string, number[]>();

  // Primera ronda: distribución uniforme
  const firstRound = activeRounds[0];
  const firstCount = orderedMap.get(firstRound)?.length ?? 0;
  const initialOffset = (totalH - (firstCount * MATCH_H + Math.max(0, firstCount - 1) * BASE_GAP)) / 2;

  let prevCenters = Array.from({ length: firstCount }, (_, i) =>
    initialOffset + i * (MATCH_H + BASE_GAP) + MATCH_H / 2
  );
  centersByRound.set(firstRound, prevCenters);

  // Rondas siguientes: centrados entre sus dos alimentadores
  for (let r = 1; r < activeRounds.length; r++) {
    const round = activeRounds[r];
    const matchCount = orderedMap.get(round)?.length ?? 0;
    const newCenters: number[] = [];

    for (let i = 0; i < matchCount; i++) {
      const topCenter = prevCenters[i * 2] ?? (prevCenters.length > 0 ? prevCenters[prevCenters.length - 1] : MATCH_H / 2);
      const bottomCenter = prevCenters[i * 2 + 1] ?? topCenter;
      newCenters.push((topCenter + bottomCenter) / 2);
    }

    centersByRound.set(round, newCenters);
    prevCenters = newCenters;
  }

  return { centersByRound, totalH };
}

// ─── Tarjeta de Partido del Árbol (TreeCard) ─────────────────────────────────

interface TreeCardProps {
  bracketMatch: BracketMatch;
  teamsMap: Map<string, Team>;
  linkedMatch?: Match;
  isFinal: boolean;
}

const TreeCard: React.FC<TreeCardProps> = ({ bracketMatch, teamsMap, linkedMatch, isFinal }) => {
  const team1 = teamsMap.get(bracketMatch.equipo_1_id);
  const team2 = teamsMap.get(bracketMatch.equipo_2_id);

  const team1Name = team1?.nombre ?? (bracketMatch.equipo_1_id ? bracketMatch.equipo_1_id : 'Por Definir');
  const team2Name = team2?.nombre ?? (bracketMatch.equipo_2_id ? bracketMatch.equipo_2_id : 'Por Definir');

  const isWinner1 = bracketMatch.ganador_id && bracketMatch.ganador_id === bracketMatch.equipo_1_id;
  const isWinner2 = bracketMatch.ganador_id && bracketMatch.ganador_id === bracketMatch.equipo_2_id;

  const isLive = linkedMatch?.estado === 'EN_VIVO';
  const hasPenalties = (linkedMatch?.penales_local ?? 0) > 0 || (linkedMatch?.penales_visita ?? 0) > 0;

  const hasScore = linkedMatch && linkedMatch.estado !== 'PROGRAMADO';
  const score1 = (linkedMatch && bracketMatch.equipo_1_id)
    ? (linkedMatch.local_id === bracketMatch.equipo_1_id ? linkedMatch.goles_local : (linkedMatch.visita_id === bracketMatch.equipo_1_id ? linkedMatch.goles_visita : null))
    : null;
  const score2 = (linkedMatch && bracketMatch.equipo_2_id)
    ? (linkedMatch.visita_id === bracketMatch.equipo_2_id ? linkedMatch.goles_visita : (linkedMatch.local_id === bracketMatch.equipo_2_id ? linkedMatch.goles_local : null))
    : null;
  const pen1 = (hasPenalties && linkedMatch && bracketMatch.equipo_1_id)
    ? (linkedMatch.local_id === bracketMatch.equipo_1_id ? linkedMatch.penales_local : (linkedMatch.visita_id === bracketMatch.equipo_1_id ? linkedMatch.penales_visita : null))
    : null;
  const pen2 = (hasPenalties && linkedMatch && bracketMatch.equipo_2_id)
    ? (linkedMatch.visita_id === bracketMatch.equipo_2_id ? linkedMatch.penales_visita : (linkedMatch.local_id === bracketMatch.equipo_2_id ? linkedMatch.penales_local : null))
    : null;

  return (
    <div
      className={`w-full h-full flex flex-col rounded-2xl overflow-hidden border transition-all duration-300 hover:scale-[1.02] shadow-xl ${
        isFinal
          ? 'bg-gradient-to-b from-slate-900 via-amber-950/20 to-slate-950 border-amber-400/80 shadow-amber-500/15 ring-1 ring-amber-400/40'
          : isLive
          ? 'bg-gradient-to-b from-slate-900 via-emerald-950/20 to-slate-950 border-emerald-500/70 shadow-emerald-500/10 ring-1 ring-emerald-500/30'
          : 'bg-slate-900/90 border-white/10 hover:border-emerald-500/40 hover:bg-slate-900'
      }`}
    >
      {/* Cabecera de la Tarjeta */}
      <div className={`h-[32px] shrink-0 flex items-center justify-between px-3.5 text-[10px] sm:text-[10.5px] font-mono border-b ${
        isFinal
          ? 'text-amber-300 border-amber-500/30 bg-amber-500/10 font-bold'
          : 'text-slate-400 border-white/5 bg-slate-950/70'
      }`}>
        <span className="font-bold flex items-center gap-1.5 tracking-wider">
          <span className="text-slate-500 font-normal">#</span>{bracketMatch.cruce_id}
          {isFinal && (
            <span className="inline-flex items-center gap-1 text-[9px] text-amber-300 font-black px-1.5 py-0.5 rounded bg-amber-500/20 border border-amber-400/30">
              <Trophy className="w-2.5 h-2.5 text-amber-400" />
              GRAN FINAL
            </span>
          )}
        </span>

        {isLive ? (
          <span className="flex items-center gap-1 text-[9px] font-bold text-emerald-400 bg-emerald-500/20 px-2 py-0.5 rounded-full ring-1 ring-emerald-500/40 animate-pulse">
            <Radio className="w-2.5 h-2.5" />
            VIVO
          </span>
        ) : linkedMatch?.estado === 'FINALIZADO' ? (
          <span className="text-[9px] text-slate-400 font-semibold uppercase tracking-wider px-1.5 py-0.5 rounded bg-white/5">
            FINALIZADO
          </span>
        ) : (
          <span className="text-[9px] text-slate-500 font-medium px-1.5 py-0.5 rounded bg-white/[0.03]">
            POR JUGAR
          </span>
        )}
      </div>

      {/* Filas de Equipos y Marcadores con espacio óptimo vertical */}
      <div className="flex-1 p-2.5 flex flex-col justify-between gap-2 min-h-0">
        {/* Equipo 1 (primer orden) */}
        <div
          className={`h-[44px] shrink-0 flex items-center justify-between px-3 py-1 rounded-xl transition-all duration-200 ${
            isWinner1
              ? 'bg-gradient-to-r from-amber-500/20 via-amber-500/10 to-transparent border border-amber-500/50 text-amber-100 font-bold shadow-sm ring-1 ring-amber-400/20'
              : 'bg-slate-950/50 border border-white/[0.06] text-slate-300 hover:bg-slate-900/60'
          }`}
        >
          <div className="flex items-center gap-2.5 min-w-0 flex-1 mr-2">
            {bracketMatch.equipo_1_id ? (
              <TeamBadge
                name={team1Name}
                colorHex={team1?.color_hex ?? '#64748b'}
                logoUrl={team1?.logo_url}
                size="sm"
              />
            ) : (
              <div className="w-7 h-7 rounded-full bg-slate-800/80 border border-white/10 flex items-center justify-center shrink-0 text-slate-500">
                <Shield className="w-3.5 h-3.5 opacity-60" />
              </div>
            )}
            <span
              className={`truncate text-xs sm:text-[13px] leading-tight ${
                isWinner1 ? 'text-amber-200 font-bold' : 'text-slate-200 font-medium'
              }`}
              title={team1Name}
            >
              {team1Name}
            </span>
          </div>

          <div className="flex items-center gap-1.5 shrink-0">
            {pen1 !== null && (
              <span
                className="text-[10px] text-amber-400 font-mono font-bold px-1.5 py-0.5 rounded bg-amber-500/10 border border-amber-500/20"
                title="Goles en tanda de penales"
              >
                PEN {pen1}
              </span>
            )}
            {hasScore && score1 !== null ? (
              <span
                className={`font-mono font-black text-sm px-2 py-0.5 rounded-lg border min-w-[24px] text-center ${
                  isWinner1
                    ? 'text-amber-300 bg-amber-950/70 border-amber-500/50 shadow-inner'
                    : 'text-slate-100 bg-black/50 border-white/10'
                }`}
              >
                {score1}
              </span>
            ) : null}
            {isWinner1 && (
              <Crown className="w-4 h-4 text-amber-400 shrink-0 drop-shadow-[0_0_6px_rgba(251,191,36,0.6)] animate-pulse" />
            )}
          </div>
        </div>

        {/* Equipo 2 (segundo orden - con holgura y sin cortes) */}
        <div
          className={`h-[44px] shrink-0 flex items-center justify-between px-3 py-1 rounded-xl transition-all duration-200 ${
            isWinner2
              ? 'bg-gradient-to-r from-amber-500/20 via-amber-500/10 to-transparent border border-amber-500/50 text-amber-100 font-bold shadow-sm ring-1 ring-amber-400/20'
              : 'bg-slate-950/50 border border-white/[0.06] text-slate-300 hover:bg-slate-900/60'
          }`}
        >
          <div className="flex items-center gap-2.5 min-w-0 flex-1 mr-2">
            {bracketMatch.equipo_2_id ? (
              <TeamBadge
                name={team2Name}
                colorHex={team2?.color_hex ?? '#64748b'}
                logoUrl={team2?.logo_url}
                size="sm"
              />
            ) : (
              <div className="w-7 h-7 rounded-full bg-slate-800/80 border border-white/10 flex items-center justify-center shrink-0 text-slate-500">
                <Shield className="w-3.5 h-3.5 opacity-60" />
              </div>
            )}
            <span
              className={`truncate text-xs sm:text-[13px] leading-tight ${
                isWinner2 ? 'text-amber-200 font-bold' : 'text-slate-200 font-medium'
              }`}
              title={team2Name}
            >
              {team2Name}
            </span>
          </div>

          <div className="flex items-center gap-1.5 shrink-0">
            {pen2 !== null && (
              <span
                className="text-[10px] text-amber-400 font-mono font-bold px-1.5 py-0.5 rounded bg-amber-500/10 border border-amber-500/20"
                title="Goles en tanda de penales"
              >
                PEN {pen2}
              </span>
            )}
            {hasScore && score2 !== null ? (
              <span
                className={`font-mono font-black text-sm px-2 py-0.5 rounded-lg border min-w-[24px] text-center ${
                  isWinner2
                    ? 'text-amber-300 bg-amber-950/70 border-amber-500/50 shadow-inner'
                    : 'text-slate-100 bg-black/50 border-white/10'
                }`}
              >
                {score2}
              </span>
            ) : null}
            {isWinner2 && (
              <Crown className="w-4 h-4 text-amber-400 shrink-0 drop-shadow-[0_0_6px_rgba(251,191,36,0.6)] animate-pulse" />
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

// ─── Conector SVG entre Rondas ────────────────────────────────────────────────

interface ConnectorSVGProps {
  fromCenters: number[];
  toCenters: number[];
  totalH: number;
  width: number;
  color?: string;
}

const ConnectorSVG: React.FC<ConnectorSVGProps> = ({
  fromCenters,
  toCenters,
  totalH,
  width,
  color = '#10b981',
}) => {
  const mid = width / 2;

  return (
    <svg
      width={width}
      height={totalH + HEADER_H}
      className="shrink-0 pointer-events-none"
      style={{ overflow: 'visible' }}
    >
      <defs>
        <filter id={`glow-${color.replace('#', '')}`} x="-30%" y="-30%" width="160%" height="160%">
          <feDropShadow dx="0" dy="0" stdDeviation="2.5" floodColor={color} floodOpacity="0.5" />
        </filter>
        <linearGradient id={`grad-${color.replace('#', '')}`} x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" stopColor={color} stopOpacity="0.7" />
          <stop offset="100%" stopColor={color} stopOpacity="0.95" />
        </linearGradient>
      </defs>

      {toCenters.map((targetY, i) => {
        const topY    = fromCenters[i * 2]     ?? targetY;
        const bottomY = fromCenters[i * 2 + 1] ?? topY;
        const midY    = (topY + bottomY) / 2;

        const ty  = topY    + HEADER_H;
        const by  = bottomY + HEADER_H;
        const my  = midY    + HEADER_H;
        const tgy = targetY + HEADER_H;

        return (
          <g key={i} filter={`url(#glow-${color.replace('#', '')})`}>
            {/* Rama superior hacia el punto medio */}
            <line
              x1={0} y1={ty} x2={mid} y2={ty}
              stroke={color} strokeWidth={2.5} strokeOpacity={0.8}
              strokeLinecap="round"
            />

            {/* Rama inferior hacia el punto medio */}
            {fromCenters[i * 2 + 1] !== undefined && (
              <line
                x1={0} y1={by} x2={mid} y2={by}
                stroke={color} strokeWidth={2.5} strokeOpacity={0.8}
                strokeLinecap="round"
              />
            )}

            {/* Tronco vertical que conecta a los dos contendientes */}
            {fromCenters[i * 2 + 1] !== undefined && (
              <line
                x1={mid} y1={ty} x2={mid} y2={by}
                stroke={color} strokeWidth={2.5} strokeOpacity={0.8}
                strokeLinecap="round"
              />
            )}

            {/* Trazado hacia el partido destino con curva suave */}
            {Math.abs(my - tgy) > 2 ? (
              <path
                d={`M ${mid},${my} C ${mid + (width - mid) * 0.5},${my} ${mid + (width - mid) * 0.5},${tgy} ${width},${tgy}`}
                stroke={`url(#grad-${color.replace('#', '')})`} strokeWidth={2.5} strokeOpacity={0.9}
                fill="none"
                strokeLinecap="round"
              />
            ) : (
              <line
                x1={mid} y1={my} x2={width} y2={tgy}
                stroke={color} strokeWidth={2} strokeOpacity={0.85}
              />
            )}

            {/* Nodo luminoso en el cruce */}
            <circle cx={mid} cy={my} r={4} fill={color} fillOpacity={0.95} />
          </g>
        );
      })}
    </svg>
  );
};

// ─── Componente Principal PlayoffsBracket ─────────────────────────────────────

export const PlayoffsBracket: React.FC<PlayoffsBracketProps> = ({
  bracket,
  teams,
  matches,
  config,
}) => {
  const teamsMap = useMemo(() => {
    const m = new Map<string, Team>();
    teams.forEach(t => m.set(t.id_equipo, t));
    return m;
  }, [teams]);

  const matchesMap = useMemo(() => {
    const m = new Map<string, Match>();
    matches.forEach(match => {
      if (match.id_partido) m.set(match.id_partido, match);
      if (match.local_id && match.visita_id) {
        m.set(`${match.local_id}_${match.visita_id}`, match);
        m.set(`${match.visita_id}_${match.local_id}`, match);
      }
    });
    return m;
  }, [matches]);

  const effectiveBracket = useMemo(
    () => computeEffectiveBracket(bracket, matches),
    [bracket, matches]
  );

  const activeRounds = useMemo(() => detectActiveRounds(effectiveBracket), [effectiveBracket]);
  const orderedRoundMap = useMemo(() => buildOrderedRoundMap(effectiveBracket), [effectiveBracket]);

  const { centersByRound, totalH } = useMemo(
    () => computeCenters(activeRounds, orderedRoundMap),
    [activeRounds, orderedRoundMap]
  );

  const finalMatch = useMemo(() => {
    const finals = orderedRoundMap.get('FINAL') ?? [];
    return finals[0] ?? null;
  }, [orderedRoundMap]);

  const champion = useMemo(
    () => (finalMatch?.ganador_id ? teamsMap.get(finalMatch.ganador_id) ?? null : null),
    [finalMatch, teamsMap]
  );

  const qualifiersPerGroup = useMemo(() => {
    const raw = config?.clasificados_por_grupo;
    if (raw === undefined || raw === null || String(raw).trim() === '') return 2;
    const n = Number(raw);
    return isNaN(n) ? 2 : Math.max(0, n);
  }, [config?.clasificados_por_grupo]);

  // Partidos correspondientes a la fase de grupos (no eliminatorias)
  const groupMatches = useMemo(() => {
    return matches.filter(m => !isPlayoffMatch(m));
  }, [matches]);

  const totalGroupMatches = groupMatches.length;
  const finishedGroupMatches = useMemo(() => {
    return groupMatches.filter(m => m.estado === 'FINALIZADO').length;
  }, [groupMatches]);

  const isGroupStageFullyFinished = totalGroupMatches > 0 && finishedGroupMatches === totalGroupMatches;

  const groupClassified = useMemo(() => {
    // Si la configuración indica 0 clasificados por grupo, no hay avance desde grupos a eliminatorias
    if (qualifiersPerGroup <= 0) return [];

    const groups = [...new Set(teams.map(t => t.grupo).filter(Boolean))].sort();

    return groups.map(g => {
      const gUpper = g.toUpperCase();
      const gTeams = teams
        .filter(t => (t.grupo || '').toUpperCase() === gUpper)
        .sort((a, b) => b.puntos - a.puntos || b.dg - a.dg || b.gf - a.gf);

      // Partidos de este grupo específico
      const gMatches = groupMatches.filter(m => {
        const tLoc = teamsMap.get(m.local_id);
        const tVis = teamsMap.get(m.visita_id);
        return (tLoc?.grupo || '').toUpperCase() === gUpper ||
               (tVis?.grupo || '').toUpperCase() === gUpper;
      });

      const gTotal = gMatches.length;
      const gFinished = gMatches.filter(m => m.estado === 'FINALIZADO').length;
      const isGroupComplete = gTotal > 0 && gFinished === gTotal;

      return {
        grupo: g,
        isComplete: isGroupComplete,
        totalMatches: gTotal,
        finishedMatches: gFinished,
        // Solo se confirman los clasificados SI el grupo ya finalizó todos sus encuentros
        qualified: isGroupComplete ? gTeams.slice(0, qualifiersPerGroup) : [],
      };
    });
  }, [teams, teamsMap, groupMatches, qualifiersPerGroup]);

  const hasBracket = activeRounds.length > 0;
  const treeWidth = activeRounds.length * (MATCH_W + CONN_W) - CONN_W;

  // Si no hay clasificados por grupo configurados (0) y tampoco existen cruces de playoffs en curso,
  // ocultamos esta sección para evitar confusiones de llaves vacías.
  if (qualifiersPerGroup <= 0 && !hasBracket) {
    return null;
  }

  return (
    <section id="playoffs" className="mb-14 scroll-mt-24">
      {/* ── Encabezado de la Sección ── */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4 mb-6">
        <div>
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-amber-500/10 border border-amber-500/20 text-amber-400 text-xs font-bold uppercase tracking-wider mb-2">
            <Trophy className="w-3.5 h-3.5" />
            <span>Fase Eliminatoria</span>
          </div>
          <h2 className="text-2xl sm:text-3xl font-black text-white tracking-tight">
            Árbol de Llaves y Eliminación Directa
          </h2>
          <p className="text-xs sm:text-sm text-slate-400 mt-1">
            Seguimiento de cruces desde las fases preliminares hasta la consagración del campeón.
          </p>
        </div>

        {champion && (
          <button
            onClick={() => confetti({ particleCount: 150, spread: 90, origin: { y: 0.5 } })}
            className="flex items-center space-x-2 px-5 py-2.5 rounded-2xl bg-gradient-to-r from-amber-500 via-amber-400 to-yellow-300 text-slate-950 font-black text-xs sm:text-sm shadow-xl shadow-amber-500/25 hover:scale-105 active:scale-95 transition-all"
          >
            <Sparkles className="w-4 h-4" />
            <span>Celebrar Campeón</span>
          </button>
        )}
      </div>

      {/* ── Banner de Clasificados desde Fase de Grupos ── */}
      {qualifiersPerGroup > 0 && groupClassified.length > 0 && (
        <div className="mb-8 p-4 sm:p-5 rounded-3xl glass-panel border border-white/10 bg-slate-950/40 shadow-xl">
          <div className="flex items-center justify-between mb-3 flex-wrap gap-2">
            <div className="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-emerald-400">
              <Shield className="w-4 h-4" />
              <span>
                {isGroupStageFullyFinished
                  ? 'Equipos Clasificados a Eliminatorias'
                  : 'Clasificación a Eliminatorias'}
              </span>
              <span className={`text-[10px] px-2 py-0.5 rounded-full font-bold border ${
                isGroupStageFullyFinished
                  ? 'bg-emerald-500/20 text-emerald-300 border-emerald-500/40'
                  : 'bg-amber-500/20 text-amber-300 border-amber-500/40'
              }`}>
                {isGroupStageFullyFinished
                  ? 'Fase de Grupos Concluida'
                  : `Fase de Grupos en Disputa (${finishedGroupMatches}/${totalGroupMatches} PJ)`}
              </span>
            </div>
            <span className="text-[11px] text-slate-400">
              {isGroupStageFullyFinished
                ? `Top ${qualifiersPerGroup} de cada grupo acceden a ${ROUND_LABELS[activeRounds[0]] ?? 'Playoffs'}`
                : `Los cupos oficiales (${qualifiersPerGroup} por grupo) se confirmarán al finalizar los encuentros`}
            </span>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
            {groupClassified.map(({ grupo, isComplete, totalMatches, finishedMatches, qualified }) => (
              <div key={grupo} className="p-3 rounded-2xl bg-slate-900/80 border border-white/5 flex flex-col gap-1.5 shadow-inner">
                <div className="flex items-center justify-between">
                  <span className="text-[11px] font-black text-amber-400 uppercase tracking-wide">
                    Grupo {grupo}
                  </span>
                  {isComplete ? (
                    <span className="text-[9px] font-black text-emerald-400 bg-emerald-500/15 border border-emerald-500/30 px-1.5 py-0.5 rounded">
                      ✓ CONCLUIDO
                    </span>
                  ) : (
                    <span className="text-[9px] font-semibold text-slate-400 bg-white/5 px-1.5 py-0.5 rounded">
                      {finishedMatches}/{totalMatches} jugados
                    </span>
                  )}
                </div>

                <div className="flex flex-col gap-1.5 mt-1">
                  {isComplete && qualified.length > 0 ? (
                    qualified.map((team, idx) => (
                      <div key={team.id_equipo} className="flex items-center gap-2 text-xs text-slate-200">
                        <span className="w-4 h-4 rounded-full bg-emerald-500/20 text-emerald-400 text-[10px] font-black flex items-center justify-center shrink-0">
                          {idx + 1}°
                        </span>
                        <div className="w-2.5 h-2.5 rounded-full shrink-0 shadow-sm" style={{ backgroundColor: team.color_hex || '#64748B' }} />
                        <span className="truncate font-medium">{team.nombre}</span>
                      </div>
                    ))
                  ) : (
                    <div className="py-2.5 text-center text-xs text-slate-500 italic flex items-center justify-center gap-1.5">
                      <span className="w-1.5 h-1.5 rounded-full bg-amber-400/70 animate-pulse"></span>
                      <span>Por definir (Fase en juego)</span>
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ── Tarjeta de Campeón Destacado ── */}
      {champion && (
        <div className="relative overflow-hidden rounded-3xl glass-panel border border-amber-500/40 p-6 sm:p-8 mb-8 text-center bg-gradient-to-b from-amber-500/10 via-slate-950 to-slate-950 shadow-2xl">
          <div className="relative z-10 flex flex-col items-center">
            <div className="w-16 h-16 rounded-full bg-amber-400/20 border-2 border-amber-400 flex items-center justify-center mb-3 shadow-lg shadow-amber-500/30">
              <Trophy className="w-8 h-8 text-amber-400 animate-bounce" />
            </div>
            <span className="text-xs font-black uppercase tracking-widest text-amber-400">¡Gran Campeón del Torneo!</span>
            <div className="flex items-center gap-3 mt-2">
              <TeamBadge name={champion.nombre} colorHex={champion.color_hex} logoUrl={champion.logo_url} size="lg" />
              <h3 className="text-2xl sm:text-4xl font-black text-white font-scoreboard tracking-wide">{champion.nombre}</h3>
            </div>
            <p className="text-xs text-slate-300 mt-2 max-w-md">
              Felicitaciones a la delegación campeona por consagrarse en lo más alto de la competición.
            </p>
          </div>
        </div>
      )}

      {/* ── Árbol Visual Centrado con Conexiones SVG ── */}
      {hasBracket ? (
        <>
          <div className="relative rounded-3xl glass-panel border border-white/10 p-4 sm:p-8 overflow-x-auto shadow-2xl">
            {/* Paso a paso de rondas centradas */}
            <div className="flex items-center justify-center gap-2 sm:gap-3 mb-6 flex-wrap">
              {activeRounds.map((r, i) => {
                const isCurrentLast = i === activeRounds.length - 1;
                const theme = ROUND_THEMES[r] ?? ROUND_THEMES['CUARTOS'];
                return (
                  <React.Fragment key={r}>
                    {i > 0 && <span className="text-slate-600 font-bold text-xs sm:text-sm">→</span>}
                    <div className={`flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold border ${theme.badgeBg} ${theme.text} ${theme.border} shadow-sm`}>
                      {isCurrentLast && <Trophy className="w-3.5 h-3.5 text-amber-400" />}
                      <span>{ROUND_LABELS[r] ?? r}</span>
                    </div>
                  </React.Fragment>
                );
              })}
            </div>

            {/* Pista de scroll horizontal en móviles */}
            <div className="md:hidden flex items-center justify-center gap-1.5 text-[11px] text-slate-400 mb-4 bg-white/5 px-3 py-1.5 rounded-xl mx-auto w-fit">
              <ArrowRight className="w-3.5 h-3.5 text-emerald-400" />
              <span>Desliza horizontalmente para explorar el cuadro</span>
            </div>

            {/* Contenedor del Árbol: Centrado horizontalmente en desktop */}
            <div className="w-full flex justify-start md:justify-center overflow-visible">
              <div
                className="flex items-start shrink-0 mx-auto"
                style={{
                  minWidth: treeWidth,
                  paddingBottom: 12,
                }}
              >
                {activeRounds.map((round, ri) => {
                  const matchesOfRound = orderedRoundMap.get(round) ?? [];
                  const centers        = centersByRound.get(round) ?? [];
                  const isFinal        = round === 'FINAL';
                  const theme          = ROUND_THEMES[round] ?? ROUND_THEMES['CUARTOS'];
                  const nextRound      = activeRounds[ri + 1];
                  const nextCenters    = nextRound ? (centersByRound.get(nextRound) ?? []) : [];
                  const connColor      = theme.connColor;

                  return (
                    <React.Fragment key={round}>
                      {/* Columna de la Ronda */}
                      <div className="shrink-0" style={{ width: MATCH_W }}>
                        {/* Cabecera de la Columna */}
                        <div
                          className={`flex items-center justify-center gap-2 text-xs font-black uppercase tracking-wider border-b pb-2 ${theme.text} ${theme.border} ${theme.badgeBg} rounded-xl px-2 mb-2 shadow-sm`}
                          style={{ height: HEADER_H - 8 }}
                        >
                          {isFinal && <Trophy className="w-4 h-4 text-amber-400" />}
                          <span>{ROUND_LABELS[round] ?? round}</span>
                        </div>

                        {/* Partidos: posicionados con precisión milimétrica en Y */}
                        <div className="relative" style={{ height: totalH }}>
                          {matchesOfRound.map((bMatch, mi) => {
                            const cy = centers[mi] ?? (mi * (MATCH_H + BASE_GAP) + MATCH_H / 2);
                            const top = cy - MATCH_H / 2;

                            const linked =
                              matchesMap.get(bMatch.cruce_id) ||
                              matchesMap.get(`${bMatch.equipo_1_id}_${bMatch.equipo_2_id}`) ||
                              matchesMap.get(`${bMatch.equipo_2_id}_${bMatch.equipo_1_id}`);

                            return (
                              <div
                                key={bMatch.cruce_id}
                                className="absolute w-full"
                                style={{ top, height: MATCH_H }}
                              >
                                <TreeCard
                                  bracketMatch={bMatch}
                                  teamsMap={teamsMap}
                                  linkedMatch={linked}
                                  isFinal={isFinal}
                                />
                              </div>
                            );
                          })}

                          {matchesOfRound.length === 0 && (
                            <div className="flex items-center justify-center h-full text-slate-600 text-xs italic">
                              Por definir
                            </div>
                          )}
                        </div>
                      </div>

                      {/* Conector SVG hacia la siguiente ronda */}
                      {nextRound && (
                        <ConnectorSVG
                          fromCenters={centers}
                          toCenters={nextCenters}
                          totalH={totalH}
                          width={CONN_W}
                          color={connColor}
                        />
                      )}
                    </React.Fragment>
                  );
                })}
              </div>
            </div>
          </div>

          {/* Leyenda y Consejos */}
          <div className="flex items-center justify-between gap-4 mt-4 flex-wrap text-xs text-slate-400 px-2">
            <div className="flex items-center gap-4 flex-wrap">
              <div className="flex items-center gap-1.5">
                <div className="w-5 h-0.5 bg-emerald-500 rounded" />
                <span>Llave clasificatoria</span>
              </div>
              <div className="flex items-center gap-1.5">
                <Crown className="w-3.5 h-3.5 text-amber-400" />
                <span>Equipo clasificado a siguiente ronda</span>
              </div>
              <div className="flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
                <span>Marcadores sincronizados en tiempo real</span>
              </div>
            </div>

            {!effectiveBracket.some(b => b.siguiente_cruce_id) && (
              <span className="text-amber-400/80 text-[11px]">
                💡 Tip: Configura el campo 'siguiente_cruce_id' en la hoja para conexiones automáticas personalizadas.
              </span>
            )}
          </div>
        </>
      ) : (
        /* Estado vacío si aún no hay cruces */
        <div className="rounded-3xl glass-panel border border-white/10 p-12 text-center text-slate-400">
          <Trophy className="w-12 h-12 text-amber-400/40 mx-auto mb-3" />
          <h4 className="text-base font-bold text-white mb-1">Cuadro de Llaves en Espera</h4>
          <p className="text-xs max-w-md mx-auto text-slate-400">
            Los partidos de eliminación directa se activarán tan pronto finalice la fase de grupos o se registren los cruces de playoffs en la aplicación.
          </p>
        </div>
      )}
    </section>
  );
};
