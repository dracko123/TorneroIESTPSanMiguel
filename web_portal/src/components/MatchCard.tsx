import React from 'react';
import { MapPin, User, Calendar } from 'lucide-react';
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
  const isWalkover = match.walkover && match.walkover !== 'NO';

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
              EN VIVO
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

      {/* Duelo de equipos y Marcador central */}
      <div className="py-4 grid grid-cols-7 items-center gap-2">
        {/* Local (Col 1-3) */}
        <div className="col-span-3 flex flex-col items-center text-center">
          <TeamBadge
            name={localTeam.nombre}
            colorHex={localTeam.color_hex}
            logoUrl={localTeam.logo_url}
            size="lg"
            className="mb-2"
          />
          <span className="text-sm sm:text-base font-bold text-white line-clamp-2 leading-tight">
            {localTeam.nombre}
          </span>
          {localTeam.grupo && (
            <span className="text-[10px] text-slate-400 mt-0.5 font-medium">
              Grupo {localTeam.grupo}
            </span>
          )}
        </div>

        {/* Marcador Central (Col 4) */}
        <div className="col-span-1 flex flex-col items-center justify-center">
          {match.estado === 'PROGRAMADO' ? (
            <div className="px-2 py-1 rounded bg-slate-900/80 border border-white/10 text-slate-400 font-scoreboard font-bold text-sm sm:text-base">
              VS
            </div>
          ) : (
            <div className="flex flex-col items-center">
              <div className="flex items-center gap-1.5 sm:gap-2 px-3 py-1.5 rounded-xl bg-slate-950/80 border border-white/10 shadow-inner">
                <span className={`text-2xl sm:text-3xl font-black font-scoreboard ${isLive ? 'text-emerald-400' : 'text-white'}`}>
                  {match.goles_local}
                </span>
                <span className="text-slate-600 font-bold">:</span>
                <span className={`text-2xl sm:text-3xl font-black font-scoreboard ${isLive ? 'text-emerald-400' : 'text-white'}`}>
                  {match.goles_visita}
                </span>
              </div>

              {hasPenalties && (
                <div className="mt-1 text-[10px] sm:text-xs text-amber-400 font-bold font-scoreboard tracking-wide">
                  Pen: ({match.penales_local}) - ({match.penales_visita})
                </div>
              )}

              {isWalkover && (
                <div className="mt-1 text-[10px] text-rose-400 font-bold uppercase tracking-wider text-center">
                  {match.walkover === 'DOBLE'
                    ? 'Doble W.O.'
                    : (match.walkover === 'LOCAL' ? 'Gana Local W.O.' : 'Gana Visita W.O.')}
                </div>
              )}
            </div>
          )}
        </div>

        {/* Visita (Col 5-7) */}
        <div className="col-span-3 flex flex-col items-center text-center">
          <TeamBadge
            name={visitorTeam.nombre}
            colorHex={visitorTeam.color_hex}
            logoUrl={visitorTeam.logo_url}
            size="lg"
            className="mb-2"
          />
          <span className="text-sm sm:text-base font-bold text-white line-clamp-2 leading-tight">
            {visitorTeam.nombre}
          </span>
          {visitorTeam.grupo && (
            <span className="text-[10px] text-slate-400 mt-0.5 font-medium">
              Grupo {visitorTeam.grupo}
            </span>
          )}
        </div>
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
