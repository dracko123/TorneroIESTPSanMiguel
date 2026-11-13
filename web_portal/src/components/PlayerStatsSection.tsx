import React, { useMemo, useState } from 'react';
import type { Player, Team } from '../types/tournament';
import { TeamBadge } from './TeamBadge';
import { Award, ShieldAlert, Flame, Users } from 'lucide-react';

interface PlayerStatsSectionProps {
  players: Player[];
  teams: Team[];
}

export const PlayerStatsSection: React.FC<PlayerStatsSectionProps> = ({ players, teams }) => {
  const [activeTab, setActiveTab] = useState<'goleadores' | 'disciplina'>('goleadores');

  const teamsMap = useMemo(() => {
    const map = new Map<string, Team>();
    teams.forEach(t => map.set(t.id_equipo, t));
    return map;
  }, [teams]);

  const getPlayerGoals = (p: Player) => Number(p.goles_totales ?? p.goles ?? 0);
  const getPlayerYellows = (p: Player) => Number(p.amarillas_totales ?? p.amarillas_total ?? 0);
  const getPlayerReds = (p: Player) => Number(p.rojas_totales ?? p.rojas_total ?? 0);
  const isPlayerSuspended = (p: Player) =>
    String(p.estado_disciplinario || '').toUpperCase().startsWith('SUSPENDIDO');
  const getSuspensionReason = (p: Player) => {
    if (p.motivo_suspension) return p.motivo_suspension;
    const raw = String(p.estado_disciplinario || '');
    if (raw.includes(':')) return raw.split(':').slice(1).join(':').trim();
    return '';
  };

  const topScorers = useMemo(() => {
    return [...players]
      .filter(p => getPlayerGoals(p) > 0)
      .sort((a, b) => getPlayerGoals(b) - getPlayerGoals(a));
  }, [players]);

  const disciplinaryPlayers = useMemo(() => {
    return [...players]
      .filter(
        p =>
          isPlayerSuspended(p) ||
          getPlayerReds(p) > 0 ||
          getPlayerYellows(p) > 0
      )
      .sort((a, b) => {
        const aSusp = isPlayerSuspended(a) ? 1 : 0;
        const bSusp = isPlayerSuspended(b) ? 1 : 0;
        if (bSusp !== aSusp) return bSusp - aSusp;
        if (getPlayerReds(b) !== getPlayerReds(a)) {
          return getPlayerReds(b) - getPlayerReds(a);
        }
        return getPlayerYellows(b) - getPlayerYellows(a);
      });
  }, [players]);

  // Si no hay jugadores registrados en el torneo, ocultar completamente la sección
  if (!players || players.length === 0) {
    return null;
  }

  // Si aún no hay goles ni tarjetas registradas, mostrar vista compacta o cambiar pestaña activa
  const hasScorers = topScorers.length > 0;
  const hasDisciplinary = disciplinaryPlayers.length > 0;

  return (
    <section id="estadisticas-jugadores" className="mb-14 scroll-mt-24">
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4 mb-6">
        <div>
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-bold uppercase tracking-wider mb-2">
            <Award className="w-3.5 h-3.5" />
            <span>Estadísticas Individuales</span>
          </div>
          <h2 className="text-2xl sm:text-3xl font-black text-white tracking-tight">
            Goleadores y Registro Disciplinario
          </h2>
          <p className="text-xs sm:text-sm text-slate-400 mt-1">
            Seguimiento oficial de artilleros, acumulación de tarjetas por fase y jugadores suspendidos.
          </p>
        </div>

        {/* Selector de Pestañas */}
        <div className="inline-flex p-1 rounded-2xl bg-slate-900/90 border border-white/10 self-start md:self-auto">
          <button
            type="button"
            onClick={() => setActiveTab('goleadores')}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-black uppercase tracking-wider transition-all ${
              activeTab === 'goleadores'
                ? 'bg-emerald-500 text-slate-950 shadow-lg shadow-emerald-500/25'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            <Flame className="w-3.5 h-3.5" />
            <span>Goleadores ({topScorers.length})</span>
          </button>
          <button
            type="button"
            onClick={() => setActiveTab('disciplina')}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-black uppercase tracking-wider transition-all ${
              activeTab === 'disciplina'
                ? 'bg-amber-500 text-slate-950 shadow-lg shadow-amber-500/25'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            <ShieldAlert className="w-3.5 h-3.5" />
            <span>Tarjetas y Suspensiones ({disciplinaryPlayers.length})</span>
          </button>
        </div>
      </div>

      {activeTab === 'goleadores' ? (
        <div className="rounded-3xl glass-panel border border-white/10 overflow-hidden bg-slate-950/60 shadow-2xl">
          {hasScorers ? (
            <div className="divide-y divide-white/5">
              {topScorers.slice(0, 15).map((player, idx) => {
                const team = teamsMap.get(player.id_equipo);
                const isTop3 = idx < 3;
                return (
                  <div
                    key={player.id_jugador}
                    className={`flex items-center justify-between px-4 sm:px-6 py-3.5 transition-colors hover:bg-white/[0.02] ${
                      idx === 0 ? 'bg-gradient-to-r from-amber-500/10 via-transparent to-transparent' : ''
                    }`}
                  >
                    <div className="flex items-center gap-3 sm:gap-4 min-w-0">
                      <span
                        className={`w-7 h-7 rounded-xl font-mono text-xs font-black flex items-center justify-center shrink-0 ${
                          idx === 0
                            ? 'bg-amber-400 text-slate-950 shadow-md shadow-amber-500/30'
                            : idx === 1
                            ? 'bg-slate-300 text-slate-950'
                            : idx === 2
                            ? 'bg-amber-700 text-amber-100'
                            : 'bg-slate-800 text-slate-400 border border-white/10'
                        }`}
                      >
                        {idx + 1}
                      </span>

                      <TeamBadge
                        name={team?.nombre || 'Equipo'}
                        colorHex={team?.color_hex || '#64748b'}
                        logoUrl={team?.logo_url}
                        size="sm"
                      />

                      <div className="min-w-0">
                        <div className="flex items-center gap-2 flex-wrap">
                          {player.dorsal ? (
                            <span className="text-[10px] font-mono font-bold px-1.5 py-0.5 rounded bg-emerald-500/15 text-emerald-300 border border-emerald-500/30">
                              #{player.dorsal}
                            </span>
                          ) : null}
                          <span className={`text-sm font-bold truncate ${isTop3 ? 'text-white' : 'text-slate-200'}`}>
                            {player.apelativo ? `${player.apelativo} (${player.nombres_apellidos})` : player.nombres_apellidos}
                          </span>
                        </div>
                        <p className="text-[11px] text-slate-400 truncate mt-0.5">
                          {team?.nombre || player.id_equipo}
                        </p>
                      </div>
                    </div>

                    <div className="flex items-center gap-2 shrink-0">
                      <div className="px-3 py-1 rounded-xl bg-emerald-500/15 border border-emerald-500/30 flex items-center gap-1.5">
                        <span className="text-sm sm:text-base font-black font-mono text-emerald-400">
                          {getPlayerGoals(player)}
                        </span>
                        <span className="text-[10px] font-bold uppercase text-emerald-300/80">
                          {getPlayerGoals(player) === 1 ? 'Gol' : 'Goles'}
                        </span>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          ) : (
            <div className="p-10 text-center text-slate-400">
              <Users className="w-10 h-10 text-emerald-400/40 mx-auto mb-2" />
              <p className="text-sm font-bold text-white">Aún no se han registrado goles individuales</p>
              <p className="text-xs text-slate-400 mt-1">
                Hay {players.length} jugadores inscritos. Los goleadores aparecerán en tiempo real conforme se anoten en mesa.
              </p>
            </div>
          )}
        </div>
      ) : (
        <div className="rounded-3xl glass-panel border border-white/10 overflow-hidden bg-slate-950/60 shadow-2xl">
          {hasDisciplinary ? (
            <div className="divide-y divide-white/5">
              {disciplinaryPlayers.map(player => {
                const team = teamsMap.get(player.id_equipo);
                const isSuspended = isPlayerSuspended(player);
                const suspensionReason = getSuspensionReason(player);
                let phaseHistory: Record<string, any> = {};
                try {
                  if (player.historial_fases_json) {
                    phaseHistory = JSON.parse(player.historial_fases_json);
                  }
                } catch {
                  phaseHistory = {};
                }
                const phaseKeys = Object.keys(phaseHistory);

                return (
                  <div
                    key={player.id_jugador}
                    className={`flex flex-col sm:flex-row sm:items-center justify-between gap-3 px-4 sm:px-6 py-3.5 transition-colors ${
                      isSuspended ? 'bg-rose-950/20' : 'hover:bg-white/[0.02]'
                    }`}
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <TeamBadge
                        name={team?.nombre || 'Equipo'}
                        colorHex={team?.color_hex || '#64748b'}
                        logoUrl={team?.logo_url}
                        size="sm"
                      />
                      <div className="min-w-0">
                        <div className="flex items-center gap-2 flex-wrap">
                          {player.dorsal ? (
                            <span className="text-[10px] font-mono font-bold px-1.5 py-0.5 rounded bg-slate-800 text-slate-300 border border-white/10">
                              #{player.dorsal}
                            </span>
                          ) : null}
                          <span className="text-sm font-bold text-white truncate">
                            {player.apelativo ? `${player.apelativo} (${player.nombres_apellidos})` : player.nombres_apellidos}
                          </span>
                          {isSuspended ? (
                            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-black uppercase tracking-wider bg-rose-500/20 text-rose-300 border border-rose-500/40 animate-pulse">
                              ⛔ SUSPENDIDO ({player.partidos_suspendido_restantes || 1} PJ)
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[9.5px] font-bold uppercase tracking-wider bg-emerald-500/15 text-emerald-300 border border-emerald-500/30">
                              ✓ HABILITADO
                            </span>
                          )}
                        </div>
                        <p className="text-[11px] text-slate-400 truncate mt-0.5">
                          {team?.nombre || player.id_equipo}
                          {suspensionReason ? ` • Motivo: ${suspensionReason}` : ''}
                        </p>
                        {phaseKeys.length > 0 && (
                          <div className="flex items-center gap-1.5 flex-wrap mt-1.5">
                            {phaseKeys.map(pk => {
                              const ph = phaseHistory[pk] || {};
                              const cumplidos = Array.isArray(ph.partidos_cumplidos) ? ph.partidos_cumplidos.length : 0;
                              return (
                                <span
                                  key={pk}
                                  className="text-[9.5px] font-mono px-2 py-0.5 rounded bg-slate-900/90 border border-white/10 text-slate-300"
                                >
                                  {pk}: {ph.amarillas || 0}🟨 {ph.rojas || 0}🟥
                                  {cumplidos > 0 ? ` (✓ ${cumplidos} cumpl.)` : ''}
                                </span>
                              );
                            })}
                          </div>
                        )}
                      </div>
                    </div>

                    <div className="flex items-center gap-2 shrink-0 self-end sm:self-center">
                      <span
                        className="inline-flex items-center gap-1 px-2.5 py-1 rounded-xl bg-amber-400/15 border border-amber-400/30 text-amber-300 font-mono text-xs font-black"
                        title="Tarjetas Amarillas en Fase Actual / Totales"
                      >
                        <span className="w-2.5 h-3.5 rounded-[2px] bg-amber-400 inline-block" />
                        <span>{player.amarillas_fase_actual ?? getPlayerYellows(player)}</span>
                        <span className="text-[10px] text-amber-300/60 font-normal">
                          (Tot: {getPlayerYellows(player)})
                        </span>
                      </span>

                      <span
                        className="inline-flex items-center gap-1 px-2.5 py-1 rounded-xl bg-rose-500/15 border border-rose-500/30 text-rose-300 font-mono text-xs font-black"
                        title="Tarjetas Rojas Totales"
                      >
                        <span className="w-2.5 h-3.5 rounded-[2px] bg-rose-500 inline-block" />
                        <span>{getPlayerReds(player)}</span>
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>
          ) : (
            <div className="p-10 text-center text-slate-400">
              <ShieldAlert className="w-10 h-10 text-amber-400/40 mx-auto mb-2" />
              <p className="text-sm font-bold text-white">Sin tarjetas ni jugadores suspendidos</p>
              <p className="text-xs text-slate-400 mt-1">
                Todos los jugadores inscritos se encuentran habilitados para disputar la jornada.
              </p>
            </div>
          )}
        </div>
      )}
    </section>
  );
};

