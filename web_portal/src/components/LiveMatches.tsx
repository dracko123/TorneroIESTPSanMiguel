import React, { useState, useMemo } from 'react';
import type { Match, Team } from '../types/tournament';
import { MatchCard } from './MatchCard';
import { Calendar, CheckCircle, Radio } from 'lucide-react';

interface LiveMatchesProps {
  matches: Match[];
  teams: Team[];
}

export const LiveMatches: React.FC<LiveMatchesProps> = ({ matches, teams }) => {
  const [activeFilter, setActiveFilter] = useState<'ALL' | 'LIVE' | 'SCHEDULED' | 'FINISHED'>('ALL');
  const [phaseFilter, setPhaseFilter] = useState<string>('ALL');

  // Mapeo rápido de id_equipo -> Team para no hacer finds repetidos
  const teamsMap = useMemo(() => {
    const map = new Map<string, Team>();
    teams.forEach(t => map.set(t.id_equipo, t));
    return map;
  }, [teams]);

  // Lista única de fases presentes
  const phases = useMemo(() => {
    const set = new Set<string>();
    matches.forEach(m => {
      if (m.fase) set.add(m.fase);
    });
    return Array.from(set);
  }, [matches]);

  // Contadores
  const counts = useMemo(() => {
    return {
      all: matches.length,
      live: matches.filter(m => m.estado === 'EN_VIVO' || m.estado === 'ENTRETIEMPO').length,
      scheduled: matches.filter(m => m.estado === 'PROGRAMADO').length,
      finished: matches.filter(m => m.estado === 'FINALIZADO').length
    };
  }, [matches]);

  // Filtrado de partidos
  const filteredMatches = useMemo(() => {
    return matches.filter(m => {
      // Filtro de fase
      if (phaseFilter !== 'ALL' && m.fase !== phaseFilter) {
        return false;
      }

      // Filtro de estado
      if (activeFilter === 'LIVE') {
        return m.estado === 'EN_VIVO' || m.estado === 'ENTRETIEMPO';
      }
      if (activeFilter === 'SCHEDULED') {
        return m.estado === 'PROGRAMADO';
      }
      if (activeFilter === 'FINISHED') {
        return m.estado === 'FINALIZADO';
      }
      return true;
    });
  }, [matches, activeFilter, phaseFilter]);

  return (
    <section id="partidos" className="mb-14 scroll-mt-24">
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4 mb-6">
        <div>
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-bold uppercase tracking-wider mb-2">
            <Radio className="w-3.5 h-3.5 animate-pulse" />
            <span>Fixture & Marcadores en Vivo</span>
          </div>
          <h2 className="text-2xl sm:text-3xl font-black text-white tracking-tight">
            Partidos del Torneo
          </h2>
          <p className="text-xs sm:text-sm text-slate-400 mt-1">
            Seguimiento de goles minuto a minuto y programación completa
          </p>
        </div>

        {/* Selector de Fases */}
        {phases.length > 1 && (
          <div className="flex items-center space-x-2">
            <label className="text-xs text-slate-400 font-medium">Fase:</label>
            <select
              value={phaseFilter}
              onChange={(e) => setPhaseFilter(e.target.value)}
              className="px-3 py-1.5 rounded-xl bg-slate-900 border border-white/10 text-xs text-slate-200 focus:outline-none focus:border-emerald-500"
            >
              <option value="ALL">Todas las Fases</option>
              {phases.map(p => (
                <option key={p} value={p}>{p}</option>
              ))}
            </select>
          </div>
        )}
      </div>

      {/* Barra de Filtros */}
      <div className="flex flex-wrap items-center gap-2 mb-6 pb-2 border-b border-white/5">
        <button
          onClick={() => setActiveFilter('ALL')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 ${
            activeFilter === 'ALL'
              ? 'bg-white text-slate-950 shadow-md shadow-white/10'
              : 'bg-slate-900/80 text-slate-400 hover:text-white hover:bg-slate-800'
          }`}
        >
          <span>Todos</span>
          <span className={`px-1.5 py-0.5 rounded-md text-[10px] ${
            activeFilter === 'ALL' ? 'bg-slate-900 text-white' : 'bg-slate-800 text-slate-400'
          }`}>
            {counts.all}
          </span>
        </button>

        <button
          onClick={() => setActiveFilter('LIVE')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 ${
            activeFilter === 'LIVE'
              ? 'bg-emerald-500 text-slate-950 shadow-md shadow-emerald-500/25 glow-emerald'
              : 'bg-slate-900/80 text-slate-400 hover:text-emerald-400 hover:bg-slate-800'
          }`}
        >
          <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping"></span>
          <span>En Vivo</span>
          <span className={`px-1.5 py-0.5 rounded-md text-[10px] ${
            activeFilter === 'LIVE' ? 'bg-slate-950 text-emerald-400' : 'bg-emerald-500/20 text-emerald-300'
          }`}>
            {counts.live}
          </span>
        </button>

        <button
          onClick={() => setActiveFilter('SCHEDULED')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 ${
            activeFilter === 'SCHEDULED'
              ? 'bg-sky-500 text-slate-950 shadow-md shadow-sky-500/25'
              : 'bg-slate-900/80 text-slate-400 hover:text-sky-400 hover:bg-slate-800'
          }`}
        >
          <Calendar className="w-3.5 h-3.5" />
          <span>Por Jugar</span>
          <span className={`px-1.5 py-0.5 rounded-md text-[10px] ${
            activeFilter === 'SCHEDULED' ? 'bg-slate-950 text-sky-400' : 'bg-slate-800 text-slate-400'
          }`}>
            {counts.scheduled}
          </span>
        </button>

        <button
          onClick={() => setActiveFilter('FINISHED')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 ${
            activeFilter === 'FINISHED'
              ? 'bg-slate-700 text-white shadow-md'
              : 'bg-slate-900/80 text-slate-400 hover:text-white hover:bg-slate-800'
          }`}
        >
          <CheckCircle className="w-3.5 h-3.5" />
          <span>Finalizados</span>
          <span className={`px-1.5 py-0.5 rounded-md text-[10px] ${
            activeFilter === 'FINISHED' ? 'bg-slate-950 text-white' : 'bg-slate-800 text-slate-400'
          }`}>
            {counts.finished}
          </span>
        </button>
      </div>

      {/* Cuadrícula de Tarjetas de Partido */}
      {filteredMatches.length === 0 ? (
        <div className="rounded-2xl glass-panel p-12 text-center">
          <Calendar className="w-12 h-12 text-slate-600 mx-auto mb-3" />
          <h3 className="text-lg font-bold text-white">No hay partidos en este filtro</h3>
          <p className="text-xs text-slate-400 mt-1 max-w-sm mx-auto">
            Selecciona otra pestaña o cambia el filtro de fase para ver los demás encuentros del torneo.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {filteredMatches.map(match => (
            <MatchCard key={match.id_partido} match={match} teamsMap={teamsMap} />
          ))}
        </div>
      )}
    </section>
  );
};
