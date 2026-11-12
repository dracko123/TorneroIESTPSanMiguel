import React from 'react';
import { MapPin, User, Calendar, Trophy, XCircle, AlertTriangle } from 'lucide-react';
import type { Match, Team } from '../types/tournament';
import { TeamBadge } from './TeamBadge';

interface MatchCardProps {
  match: Match;
  teamsMap: Map<string, Team>;
}

export const MatchCard: React.FC<MatchCardProps> = ({ match, teamsMap }) => {
  const localTeam = teamsMap.get(match.local_id) || {
    id_equipo: match.local_id,
    nombre: match.local_id || 'Equipo Local',
    grupo: '',
    color_hex: '#2563EB',
    pj: 0, pg: 0, pe: 0, pp: 0, gf: 0, gc: 0, dg: 0, puntos: 0
  };

  const visitorTeam = teamsMap.get(match.visita_id) || {
    id_equipo: match.visita_id,
    nombre: match.visita_id || 'Equipo Visita',
    grupo: '',
    color_hex: '#DC2626',
    pj: 0, pg: 0, pe: 0, pp: 0, gf: 0, gc: 0, dg: 0, puntos: 0
  };

  const isLive = match.estado === 'EN_VIVO';
  const isHalftime = match.estado === 'ENTRETIEMPO';
  const isFinished = match.estado === 'FINALIZADO';

  const walkoverVal = (match.walkover || 'NO').toUpperCase().trim();
  const isWalkover = walkoverVal === 'LOCAL' || walkoverVal === 'VISITA' || walkoverVal === 'DOBLE';
  const isLocalWoWinner = walkoverVal === 'LOCAL';
  const isVisitorWoWinner = walkoverVal === 'VISITA';
  const isDoubleWo = walkoverVal === 'DOBLE';
  const isLocalWoLoser = walkoverVal === 'VISITA' || walkoverVal === 'DOBLE';
  const isVisitorWoLoser = walkoverVal === 'LOCAL' || walkoverVal === 'DOBLE';

  const formattedDate = match.fecha_hora ? new Date(match.fecha_hora).toLocaleDateString('es-ES', {
    weekday: 'short',
    day: 'numeric',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit'
  }) : 'Horario por definir';

  // Ganador en penales si existe
  const hasPenalties = (match.penales_local !== undefined && match.penales_local !== null && match.penales_local > 0) ||
                       (match.penales_visita !== undefined && match.penales_visita !== null && match.penales_visita > 0);

  return (
    <div
      className={`relative overflow-hidden rounded-2xl glass-panel-interactive p-5 flex flex-col justify-between ${
        isLive ? 'border-emerald-500/50 shadow-lg shadow-emerald-500/10' : ''
      }`}
    >
      {/* Barra de estado superior */}
      <div className="flex items-center justify-between gap-2 pb-3 border-b border-white/5 text-xs">
        <span className="font-semibold text-slate-400 uppercase tracking-wider text-[11px]">
          {match.fase || 'Fase Regular'}
        </span>

        <div className="flex items-center gap-1.5">
          {isWalkover && (
            <span className="inline-flex items-center px-2 py-0.5 rounded-full bg-rose-500/20 text-rose-400 border border-rose-500/40 text-[10px] font-black uppercase tracking-wider">
              W.O.
            </span>
          )}

          {isLive && (
            <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/40 text-[11px] font-black uppercase tracking-wider">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping"></span>
              EN VIVO{match.tiempo_en_vivo ? ` • ${match.tiempo_en_vivo}` : ''}
            </span>
          )}

          {isHalftime && (
            <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-amber-500/20 text-amber-300 border border-amber-500/40 text-[11px] font-bold uppercase tracking-wider">
              ENTRETIEMPO
            </span>
          )}

          {isFinished && (
            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full bg-slate-800 text-slate-400 border border-white/5 text-[11px] font-medium">
              FINALIZADO
            </span>
          )}

          {match.estado === 'PROGRAMADO' && (
            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full bg-sky-500/10 text-sky-300 border border-sky-500/20 text-[11px] font-medium">
              PROGRAMADO
            </span>
          )}
        </div>
      </div>

      {/* Duelo de equipos y Marcador central (Grid sincronizado en paralelo por filas) */}
      <div className="py-4 grid grid-cols-[1fr_auto_1fr] gap-x-2 sm:gap-x-3 items-stretch">
        {/* ── FILA 1: Escudo Local | Marcador Central | Escudo Visita ── */}
        <div
          className={`flex items-center justify-center transition-all ${
            isLocalWoLoser ? 'opacity-50 grayscale-[40%]' : ''
          }`}
        >
          <div
            className={`shrink-0 rounded-full ${
              isLocalWoWinner ? 'ring-2 ring-emerald-400/80 shadow-lg shadow-emerald-500/20' : ''
            }`}
          >
            <TeamBadge
              name={localTeam.nombre}
              colorHex={localTeam.color_hex}
              logoUrl={localTeam.logo_url}
              size="lg"
            />
          </div>
        </div>

        <div className="shrink-0 w-24 sm:w-28 flex items-center justify-center">
          {match.estado === 'PROGRAMADO' ? (
            <div className="px-3.5 py-1.5 rounded-xl bg-slate-900/90 border border-white/10 text-slate-400 font-scoreboard font-bold text-sm sm:text-base tracking-wider shadow-inner">
              VS
            </div>
          ) : (
            <div className="w-full flex items-center justify-center gap-1.5 sm:gap-2 px-2 py-1.5 rounded-xl bg-slate-950/90 border border-white/10 shadow-inner">
              <span
                className={`text-2xl sm:text-3xl font-black font-scoreboard tabular-nums ${
                  isLive
                    ? 'text-emerald-400'
                    : isHalftime
                    ? 'text-amber-400'
                    : isLocalWoWinner
                    ? 'text-emerald-400'
                    : isLocalWoLoser
                    ? 'text-slate-500'
                    : 'text-white'
                }`}
              >
                {match.goles_local}
              </span>
              <span className="text-slate-600 font-bold">:</span>
              <span
                className={`text-2xl sm:text-3xl font-black font-scoreboard tabular-nums ${
                  isLive
                    ? 'text-emerald-400'
                    : isHalftime
                    ? 'text-amber-400'
                    : isVisitorWoWinner
                    ? 'text-emerald-400'
                    : isVisitorWoLoser
                    ? 'text-slate-500'
                    : 'text-white'
                }`}
              >
                {match.goles_visita}
              </span>
            </div>
          )}
        </div>

        <div
          className={`flex items-center justify-center transition-all ${
            isVisitorWoLoser ? 'opacity-50 grayscale-[40%]' : ''
          }`}
        >
          <div
            className={`shrink-0 rounded-full ${
              isVisitorWoWinner ? 'ring-2 ring-emerald-400/80 shadow-lg shadow-emerald-500/20' : ''
            }`}
          >
            <TeamBadge
              name={visitorTeam.nombre}
              colorHex={visitorTeam.color_hex}
              logoUrl={visitorTeam.logo_url}
              size="lg"
            />
          </div>
        </div>

        {/* ── FILA 2: Nombres de Equipos en paralelo y misma altura ── */}
        <div
          className={`mt-2 min-h-[40px] px-1 flex items-center justify-center text-center transition-all ${
            isLocalWoLoser ? 'opacity-50 grayscale-[40%]' : ''
          }`}
        >
          <span
            className={`text-xs sm:text-[13px] font-bold leading-snug break-words text-center w-full ${
              isLocalWoWinner
                ? 'text-emerald-300'
                : isLocalWoLoser
                ? 'text-slate-400'
                : 'text-white'
            }`}
            title={localTeam.nombre}
          >
            {localTeam.nombre}
          </span>
        </div>

        <div className="mt-2 flex flex-col items-center justify-center px-0.5">
          {hasPenalties && (
            <div className="text-[10px] text-amber-400 font-bold font-scoreboard tracking-wide whitespace-nowrap bg-amber-500/10 px-2 py-0.5 rounded-full border border-amber-500/20">
              Pen: ({match.penales_local}) - ({match.penales_visita})
            </div>
          )}

          {isWalkover && (
            <div
              className={`${
                hasPenalties ? 'mt-1' : ''
              } inline-flex items-center gap-1 text-[9px] font-black uppercase tracking-wider text-center px-2 py-0.5 rounded-full border whitespace-nowrap ${
                isDoubleWo
                  ? 'text-rose-400 bg-rose-500/15 border-rose-500/30'
                  : 'text-emerald-300 bg-emerald-500/15 border-emerald-500/35'
              }`}
            >
              {isDoubleWo ? (
                <>
                  <AlertTriangle className="w-2.5 h-2.5 shrink-0" />
                  <span>DOBLE W.O.</span>
                </>
              ) : isLocalWoWinner ? (
                <span>◀ GANADOR W.O.</span>
              ) : (
                <span>GANADOR W.O. ▶</span>
              )}
            </div>
          )}
        </div>

        <div
          className={`mt-2 min-h-[40px] px-1 flex items-center justify-center text-center transition-all ${
            isVisitorWoLoser ? 'opacity-50 grayscale-[40%]' : ''
          }`}
        >
          <span
            className={`text-xs sm:text-[13px] font-bold leading-snug break-words text-center w-full ${
              isVisitorWoWinner
                ? 'text-emerald-300'
                : isVisitorWoLoser
                ? 'text-slate-400'
                : 'text-white'
            }`}
            title={visitorTeam.nombre}
          >
            {visitorTeam.nombre}
          </span>
        </div>

        {/* ── FILA 3: Etiquetas de Grupo en paralelo y del mismo tamaño ── */}
        {(localTeam.grupo || visitorTeam.grupo) && (
          <>
            <div
              className={`mt-1.5 flex items-center justify-center transition-all ${
                isLocalWoLoser ? 'opacity-50 grayscale-[40%]' : ''
              }`}
            >
              {localTeam.grupo ? (
                <span className="min-w-[78px] h-[22px] px-2.5 rounded-full bg-white/5 border border-white/10 text-[10px] text-slate-300 font-semibold inline-flex items-center justify-center whitespace-nowrap">
                  Grupo {localTeam.grupo}
                </span>
              ) : (
                <span className="min-w-[78px] h-[22px]" />
              )}
            </div>

            <div className="mt-1.5" />

            <div
              className={`mt-1.5 flex items-center justify-center transition-all ${
                isVisitorWoLoser ? 'opacity-50 grayscale-[40%]' : ''
              }`}
            >
              {visitorTeam.grupo ? (
                <span className="min-w-[78px] h-[22px] px-2.5 rounded-full bg-white/5 border border-white/10 text-[10px] text-slate-300 font-semibold inline-flex items-center justify-center whitespace-nowrap">
                  Grupo {visitorTeam.grupo}
                </span>
              ) : (
                <span className="min-w-[78px] h-[22px]" />
              )}
            </div>
          </>
        )}

        {/* ── FILA 4: Badges de Walkover en paralelo y del mismo alto ── */}
        {isWalkover && (
          <>
            <div className="mt-1.5 flex items-center justify-center">
              {isLocalWoWinner && (
                <span className="h-[22px] inline-flex items-center justify-center gap-1 px-2.5 rounded-full bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 text-[9.5px] font-black uppercase tracking-wider shadow-sm whitespace-nowrap">
                  <Trophy className="w-2.5 h-2.5 text-amber-400 shrink-0" />
                  <span>GANADOR W.O.</span>
                </span>
              )}
              {isLocalWoLoser && (
                <span className="h-[22px] inline-flex items-center justify-center gap-1 px-2.5 rounded-full bg-rose-500/15 text-rose-400 border border-rose-500/30 text-[9.5px] font-bold uppercase tracking-wider opacity-85 whitespace-nowrap">
                  <XCircle className="w-2.5 h-2.5 shrink-0" />
                  <span>{isDoubleWo ? 'AUSENTE W.O.' : 'NO SE PRESENTÓ'}</span>
                </span>
              )}
            </div>

            <div className="mt-1.5" />

            <div className="mt-1.5 flex items-center justify-center">
              {isVisitorWoWinner && (
                <span className="h-[22px] inline-flex items-center justify-center gap-1 px-2.5 rounded-full bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 text-[9.5px] font-black uppercase tracking-wider shadow-sm whitespace-nowrap">
                  <Trophy className="w-2.5 h-2.5 text-amber-400 shrink-0" />
                  <span>GANADOR W.O.</span>
                </span>
              )}
              {isVisitorWoLoser && (
                <span className="h-[22px] inline-flex items-center justify-center gap-1 px-2.5 rounded-full bg-rose-500/15 text-rose-400 border border-rose-500/30 text-[9.5px] font-bold uppercase tracking-wider opacity-85 whitespace-nowrap">
                  <XCircle className="w-2.5 h-2.5 shrink-0" />
                  <span>{isDoubleWo ? 'AUSENTE W.O.' : 'NO SE PRESENTÓ'}</span>
                </span>
              )}
            </div>
          </>
        )}
      </div>

      {/* Pie de tarjeta: Cancha, Horario y Árbitro */}
      <div className="pt-3 border-t border-white/5 flex flex-wrap items-center justify-between gap-y-1.5 text-[11px] text-slate-400">
        <div className="flex items-center gap-1.5 text-slate-300">
          <MapPin className="w-3.5 h-3.5 text-emerald-400 shrink-0" />
          <span className="truncate max-w-[180px]">{match.cancha || 'Cancha por asignar'}</span>
        </div>

        <div className="flex items-center gap-1.5 text-slate-400">
          <Calendar className="w-3.5 h-3.5 text-slate-500 shrink-0" />
          <span>{formattedDate}</span>
        </div>

        {match.arbitro_asignado && (
          <div className="w-full flex items-center gap-1.5 text-[10px] text-slate-500 pt-1">
            <User className="w-3 h-3 text-slate-600" />
            <span className="truncate">Árbitro: {match.arbitro_asignado}</span>
          </div>
        )}
      </div>
    </div>
  );
};
