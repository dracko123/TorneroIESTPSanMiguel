import React, { useState, useMemo } from 'react';
import type { Team } from '../types/tournament';
import { TeamBadge } from './TeamBadge';
import { Trophy, CheckCircle2, Info } from 'lucide-react';

interface GroupStandingsProps {
  teams: Team[];
  qualifiersPerGroup?: number;
}

export const GroupStandings: React.FC<GroupStandingsProps> = ({
  teams,
  qualifiersPerGroup = 2
}) => {
  // Obtener lista única de grupos ordenados (A, B, C...)
  const groups = useMemo(() => {
    const set = new Set<string>();
    teams.forEach(t => {
      if (t.grupo) set.add(t.grupo.toUpperCase().trim());
    });
    const arr = Array.from(set).sort();
    return arr.length > 0 ? arr : ['A'];
  }, [teams]);

  const [selectedGroup, setSelectedGroup] = useState<string>(() => groups[0] || 'A');

  // Filtrar y ordenar equipos del grupo seleccionado
  // Criterios de desempate estándar: 1. Puntos, 2. Diferencia de Gol, 3. Goles a Favor
  const sortedTeams = useMemo(() => {
    const groupTeams = teams.filter(t => (t.grupo || '').toUpperCase().trim() === selectedGroup);

    return [...groupTeams].sort((a, b) => {
      // 1. Puntos
      if (b.puntos !== a.puntos) return b.puntos - a.puntos;
      // 2. Diferencia de Gol
      if (b.dg !== a.dg) return b.dg - a.dg;
      // 3. Goles a Favor
      if (b.gf !== a.gf) return b.gf - a.gf;
      // 4. Alfabético
      return a.nombre.localeCompare(b.nombre);
    });
  }, [teams, selectedGroup]);

  return (
    <section id="posiciones" className="mb-14 scroll-mt-24">
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4 mb-6">
        <div>
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-amber-500/10 border border-amber-500/20 text-amber-400 text-xs font-bold uppercase tracking-wider mb-2">
            <Trophy className="w-3.5 h-3.5" />
            <span>Fase de Clasificación</span>
          </div>
          <h2 className="text-2xl sm:text-3xl font-black text-white tracking-tight">
            Tabla de Posiciones
          </h2>
          <p className="text-xs sm:text-sm text-slate-400 mt-1">
            Los primeros <strong className="text-emerald-400">{qualifiersPerGroup} equipos</strong> de cada grupo avanzan a la ronda de Playoffs
          </p>
        </div>

        {/* Pestañas de Grupos */}
        <div className="flex items-center space-x-1.5 p-1 rounded-2xl bg-slate-900/90 border border-white/10 self-start md:self-auto overflow-x-auto max-w-full">
          {groups.map(grp => (
            <button
              key={grp}
              onClick={() => setSelectedGroup(grp)}
              className={`px-4 py-2 rounded-xl text-xs font-bold uppercase tracking-wider transition-all whitespace-nowrap ${
                selectedGroup === grp
                  ? 'bg-emerald-500 text-slate-950 shadow-md shadow-emerald-500/25 glow-emerald font-black'
                  : 'text-slate-400 hover:text-white hover:bg-white/5'
              }`}
            >
              Grupo {grp}
            </button>
          ))}
        </div>
      </div>

      {/* Contenedor de la Tabla Glassmorphism */}
      <div className="rounded-3xl glass-panel border border-white/10 overflow-hidden shadow-2xl">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[650px]">
            <thead>
              <tr className="border-b border-white/10 bg-slate-950/60 text-[11px] font-bold uppercase tracking-wider text-slate-400">
                <th className="py-4 px-4 text-center w-14">Pos</th>
                <th className="py-4 px-4">Equipo</th>
                <th className="py-4 px-3 text-center" title="Partidos Jugados">PJ</th>
                <th className="py-4 px-3 text-center" title="Partidos Ganados">PG</th>
                <th className="py-4 px-3 text-center" title="Partidos Empatados">PE</th>
                <th className="py-4 px-3 text-center" title="Partidos Perdidos">PP</th>
                <th className="py-4 px-3 text-center" title="Goles a Favor">GF</th>
                <th className="py-4 px-3 text-center" title="Goles en Contra">GC</th>
                <th className="py-4 px-3 text-center" title="Diferencia de Goles">DG</th>
                <th className="py-4 px-5 text-center text-white" title="Puntos Totales">PTS</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5 text-sm font-medium">
              {sortedTeams.length === 0 ? (
                <tr>
                  <td colSpan={10} className="py-10 text-center text-slate-500">
                    No hay equipos registrados en el Grupo {selectedGroup}.
                  </td>
                </tr>
              ) : (
                sortedTeams.map((team, idx) => {
                  const pos = idx + 1;
                  const isClassified = qualifiersPerGroup > 0 && pos <= qualifiersPerGroup;

                  return (
                    <tr
                      key={team.id_equipo}
                      className={`transition-colors hover:bg-white/[0.03] ${
                        isClassified ? 'bg-emerald-950/15' : ''
                      }`}
                    >
                      {/* Posición con indicación de clasificación */}
                      <td className="py-4 px-4 text-center">
                        <div className="flex items-center justify-center">
                          {pos === 1 && (
                            <span className="w-7 h-7 rounded-full bg-amber-500/20 text-amber-400 font-bold flex items-center justify-center text-xs border border-amber-500/40">
                              1º
                            </span>
                          )}
                          {pos === 2 && (
                            <span className="w-7 h-7 rounded-full bg-slate-300/20 text-slate-200 font-bold flex items-center justify-center text-xs border border-slate-300/40">
                              2º
                            </span>
                          )}
                          {pos === 3 && (
                            <span className="w-7 h-7 rounded-full bg-amber-700/20 text-amber-600 font-bold flex items-center justify-center text-xs border border-amber-700/40">
                              3º
                            </span>
                          )}
                          {pos > 3 && (
                            <span className="text-slate-500 font-bold text-xs">{pos}º</span>
                          )}
                        </div>
                      </td>

                      {/* Escudo y Nombre del Equipo */}
                      <td className="py-4 px-4">
                        <div className="flex items-center space-x-3">
                          <TeamBadge
                            name={team.nombre}
                            colorHex={team.color_hex}
                            logoUrl={team.logo_url}
                            size="md"
                          />
                          <div>
                            <div className="flex items-center gap-2">
                              <span className="font-bold text-white text-sm sm:text-base">
                                {team.nombre}
                              </span>
                              {isClassified && (
                                <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
                                  <CheckCircle2 className="w-3 h-3" />
                                  <span className="hidden sm:inline">Zona de Avance</span>
                                </span>
                              )}
                            </div>
                            <span className="text-[11px] text-slate-400">
                              ID: {team.id_equipo}
                            </span>
                          </div>
                        </div>
                      </td>

                      {/* Estadísticas */}
                      <td className="py-4 px-3 text-center text-slate-300 font-scoreboard">{team.pj || 0}</td>
                      <td className="py-4 px-3 text-center text-emerald-400 font-scoreboard font-bold">{team.pg || 0}</td>
                      <td className="py-4 px-3 text-center text-slate-400 font-scoreboard">{team.pe || 0}</td>
                      <td className="py-4 px-3 text-center text-rose-400 font-scoreboard">{team.pp || 0}</td>
                      <td className="py-4 px-3 text-center text-slate-300 font-scoreboard">{team.gf || 0}</td>
                      <td className="py-4 px-3 text-center text-slate-400 font-scoreboard">{team.gc || 0}</td>

                      {/* Diferencia de Gol */}
                      <td className="py-4 px-3 text-center font-scoreboard font-bold">
                        <span className={team.dg > 0 ? 'text-emerald-400' : team.dg < 0 ? 'text-rose-400' : 'text-slate-400'}>
                          {team.dg > 0 ? `+${team.dg}` : team.dg}
                        </span>
                      </td>

                      {/* Puntos Destacados */}
                      <td className="py-4 px-5 text-center">
                        <span className="inline-block px-3 py-1 rounded-xl bg-slate-900 border border-white/10 text-white font-scoreboard font-black text-base sm:text-lg shadow-inner">
                          {team.puntos || 0}
                        </span>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        {/* Pie de tabla con leyenda explicativa */}
        <div className="p-4 bg-slate-950/80 border-t border-white/5 flex flex-wrap items-center justify-between gap-3 text-xs text-slate-400">
          {qualifiersPerGroup > 0 ? (
            <div className="flex items-center gap-2">
              <span className="w-3 h-3 rounded-full bg-emerald-500/30 border border-emerald-500"></span>
              <span>
                {qualifiersPerGroup === 1
                  ? 'Puesto de avance a playoffs (1º lugar)'
                  : `Puestos de avance a playoffs (1º al ${qualifiersPerGroup}º lugar)`}
              </span>
            </div>
          ) : (
            <div className="flex items-center gap-2 text-slate-400">
              <span className="w-2.5 h-2.5 rounded-full bg-slate-600"></span>
              <span>Fase Regular — Tabla General</span>
            </div>
          )}

          <div className="flex items-center gap-1.5 text-slate-500">
            <Info className="w-3.5 h-3.5" />
            <span>Sistema: 3 pts por Victoria, 1 pt por Empate, 0 pts por Derrota</span>
          </div>
        </div>
      </div>
    </section>
  );
};
