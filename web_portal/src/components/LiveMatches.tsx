import React, { useState, useMemo, useEffect, useRef } from 'react';
import type { Match, Team } from '../types/tournament';
import { MatchCard } from './MatchCard';
import { Calendar, CheckCircle, Radio, ChevronLeft, ChevronRight } from 'lucide-react';

const ITEMS_PER_PAGE = 6;

interface LiveMatchesProps {
  matches: Match[];
  teams: Team[];
}

export const LiveMatches: React.FC<LiveMatchesProps> = ({ matches, teams }) => {
  const [activeFilter, setActiveFilter] = useState<'ALL' | 'LIVE' | 'SCHEDULED' | 'FINISHED'>('LIVE');
  const [phaseFilter, setPhaseFilter] = useState<string>('ALL');
  const [currentPage, setCurrentPage] = useState<number>(1);
  const userInteractedRef = useRef<boolean>(false);

  // Selección inteligente al cargar los partidos si el usuario no ha interactuado manualmente
  useEffect(() => {
    if (userInteractedRef.current || matches.length === 0) return;
    const hasLive = matches.some(m => m.estado === 'EN_VIVO' || m.estado === 'ENTRETIEMPO');
    if (hasLive) {
      setActiveFilter('LIVE');
    } else {
      const hasScheduled = matches.some(m => m.estado === 'PROGRAMADO');
      setActiveFilter(hasScheduled ? 'SCHEDULED' : 'FINISHED');
    }
    setCurrentPage(1);
  }, [matches]);

  const handleFilterClick = (filter: 'ALL' | 'LIVE' | 'SCHEDULED' | 'FINISHED') => {
    userInteractedRef.current = true;
    setActiveFilter(filter);
    setCurrentPage(1);
  };

  const handlePhaseChange = (phase: string) => {
    setPhaseFilter(phase);
    setCurrentPage(1);
  };

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

  // Filtrado y ordenamiento de partidos
  const filteredMatches = useMemo(() => {
    const filtered = matches.filter(m => {
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

    const getTime = (dateStr?: string) => {
      if (!dateStr) return 0;
      const t = new Date(dateStr).getTime();
      return isNaN(t) ? 0 : t;
    };

    return filtered.sort((a, b) => {
      const timeA = getTime(a.fecha_hora);
      const timeB = getTime(b.fecha_hora);

      // 1. Partidos Finalizados (Jugados): del más reciente al más antiguo (Descendente)
      if (activeFilter === 'FINISHED') {
        if (timeB !== timeA) return timeB - timeA;
        return (b.id_partido || '').localeCompare(a.id_partido || '');
      }

      // 2. Partidos Programados (Por Jugar): del más próximo al más lejano (Ascendente)
      if (activeFilter === 'SCHEDULED') {
        if (timeA !== timeB) return timeA - timeB;
        return (a.id_partido || '').localeCompare(b.id_partido || '');
      }

      // 3. Partidos En Vivo: cronológico
      if (activeFilter === 'LIVE') {
        if (timeA !== timeB) return timeA - timeB;
        return (a.id_partido || '').localeCompare(b.id_partido || '');
      }

      // 4. Pestaña "Todos": Prioridad por estado (En Vivo > Por Jugar > Finalizados)
      const statusPriority: Record<string, number> = {
        'EN_VIVO': 1,
        'ENTRETIEMPO': 1,
        'PROGRAMADO': 2,
        'FINALIZADO': 3
      };
      const prioA = statusPriority[a.estado] || 4;
      const prioB = statusPriority[b.estado] || 4;
      if (prioA !== prioB) return prioA - prioB;

      // Si ambos están finalizados en "Todos", el más reciente primero
      if (a.estado === 'FINALIZADO') {
        if (timeB !== timeA) return timeB - timeA;
        return (b.id_partido || '').localeCompare(a.id_partido || '');
      }

      // Para los programados o en vivo en "Todos", cronológico normal
      if (timeA !== timeB) return timeA - timeB;
      return (a.id_partido || '').localeCompare(b.id_partido || '');
    });
  }, [matches, activeFilter, phaseFilter]);

  const totalPages = Math.max(1, Math.ceil(filteredMatches.length / ITEMS_PER_PAGE));
  const safeCurrentPage = Math.min(currentPage, totalPages);

  // Ajustar página si tras una actualización el total de páginas disminuyó
  useEffect(() => {
    if (currentPage > totalPages) {
      setCurrentPage(totalPages);
    }
  }, [currentPage, totalPages]);

  const startIndex = (safeCurrentPage - 1) * ITEMS_PER_PAGE;
  const endIndex = Math.min(startIndex + ITEMS_PER_PAGE, filteredMatches.length);
  const paginatedMatches = useMemo(() => {
    return filteredMatches.slice(startIndex, endIndex);
  }, [filteredMatches, startIndex, endIndex]);

  // Generador de pestañas de páginas (con puntos suspensivos si hay muchas páginas)
  const pageItems = useMemo(() => {
    if (totalPages <= 7) {
      return Array.from({ length: totalPages }, (_, i) => i + 1);
    }
    const items: (number | '...')[] = [1];
    if (safeCurrentPage > 3) items.push('...');
    const start = Math.max(2, safeCurrentPage - 1);
    const end = Math.min(totalPages - 1, safeCurrentPage + 1);
    for (let p = start; p <= end; p++) {
      items.push(p);
    }
    if (safeCurrentPage < totalPages - 2) items.push('...');
    items.push(totalPages);
    return items;
  }, [totalPages, safeCurrentPage]);

  const handlePageChange = (page: number) => {
    if (page < 1 || page > totalPages || page === safeCurrentPage) return;
    setCurrentPage(page);
    const sectionEl = document.getElementById('partidos');
    if (sectionEl) {
      sectionEl.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  };

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
              onChange={(e) => handlePhaseChange(e.target.value)}
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

      {/* Barra de Filtros en orden: 1. En Vivo, 2. Por Jugar, 3. Finalizados, 4. Todos */}
      <div className="flex flex-wrap items-center justify-between gap-3 mb-6 pb-2 border-b border-white/5">
        <div className="flex flex-wrap items-center gap-2">
          {/* 1° En Vivo */}
          <button
            onClick={() => handleFilterClick('LIVE')}
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

          {/* 2° Por Jugar */}
          <button
            onClick={() => handleFilterClick('SCHEDULED')}
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

          {/* 3° Finalizados */}
          <button
            onClick={() => handleFilterClick('FINISHED')}
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

          {/* 4° Todos */}
          <button
            onClick={() => handleFilterClick('ALL')}
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
        </div>

        {/* Resumen rápido de paginación arriba */}
        {filteredMatches.length > 0 && (
          <div className="text-[11px] text-slate-400 font-medium flex items-center gap-1.5">
            <span>
              Mostrando <strong className="text-slate-200">{startIndex + 1}–{endIndex}</strong> de{' '}
              <strong className="text-slate-200">{filteredMatches.length}</strong> partidos
            </span>
            {totalPages > 1 && (
              <span className="px-2 py-0.5 rounded-full bg-white/5 border border-white/10 text-emerald-400 font-bold">
                Pág. {safeCurrentPage}/{totalPages}
              </span>
            )}
          </div>
        )}
      </div>

      {/* Cuadrícula de Tarjetas de Partido (Máximo 6 por página) */}
      {filteredMatches.length === 0 ? (
        <div className="rounded-2xl glass-panel p-12 text-center">
          <Calendar className="w-12 h-12 text-slate-600 mx-auto mb-3" />
          <h3 className="text-lg font-bold text-white">No hay partidos en este filtro</h3>
          <p className="text-xs text-slate-400 mt-1 max-w-sm mx-auto">
            Selecciona otra pestaña o cambia el filtro de fase para ver los demás encuentros del torneo.
          </p>
        </div>
      ) : (
        <>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            {paginatedMatches.map(match => (
              <MatchCard key={match.id_partido} match={match} teamsMap={teamsMap} />
            ))}
          </div>

          {/* Barra de Paginación Tipo Pestañas */}
          {totalPages > 1 && (
            <div className="mt-8 pt-5 border-t border-white/10 flex flex-col sm:flex-row items-center justify-between gap-4">
              <div className="text-xs text-slate-400 text-center sm:text-left">
                {activeFilter === 'FINISHED' && safeCurrentPage === 1 ? (
                  <span>
                    Viendo los <strong className="text-emerald-400">últimos {paginatedMatches.length} partidos</strong> jugados • Usa las páginas para ver encuentros anteriores
                  </span>
                ) : activeFilter === 'SCHEDULED' && safeCurrentPage === 1 ? (
                  <span>
                    Viendo los <strong className="text-sky-400">próximos {paginatedMatches.length} partidos</strong> programados
                  </span>
                ) : (
                  <span>
                    Página <strong className="text-white">{safeCurrentPage}</strong> de <strong className="text-white">{totalPages}</strong> ({filteredMatches.length} partidos en total)
                  </span>
                )}
              </div>

              <div className="flex flex-wrap items-center justify-center gap-1.5">
                {/* Botón Anterior */}
                <button
                  onClick={() => handlePageChange(safeCurrentPage - 1)}
                  disabled={safeCurrentPage === 1}
                  className={`px-3 py-2 rounded-xl text-xs font-bold flex items-center gap-1 transition-all border ${
                    safeCurrentPage === 1
                      ? 'bg-slate-900/40 text-slate-600 border-white/5 cursor-not-allowed'
                      : 'bg-slate-900/90 text-slate-300 border-white/10 hover:bg-slate-800 hover:text-white hover:border-emerald-500/40'
                  }`}
                >
                  <ChevronLeft className="w-3.5 h-3.5" />
                  <span>Anterior</span>
                </button>

                {/* Pestañas numeradas */}
                {pageItems.map((item, idx) =>
                  item === '...' ? (
                    <span
                      key={`ellipsis-${idx}`}
                      className="px-2 py-1.5 text-xs text-slate-500 font-bold select-none"
                    >
                      •••
                    </span>
                  ) : (
                    <button
                      key={`page-${item}`}
                      onClick={() => handlePageChange(item)}
                      className={`min-w-[36px] h-9 px-2.5 rounded-xl text-xs font-black transition-all border ${
                        safeCurrentPage === item
                          ? 'bg-emerald-500 text-slate-950 border-emerald-400 shadow-lg shadow-emerald-500/25 scale-105'
                          : 'bg-slate-900/80 text-slate-400 border-white/10 hover:bg-slate-800 hover:text-white hover:border-white/20'
                      }`}
                    >
                      {item}
                    </button>
                  )
                )}

                {/* Botón Siguiente */}
                <button
                  onClick={() => handlePageChange(safeCurrentPage + 1)}
                  disabled={safeCurrentPage === totalPages}
                  className={`px-3 py-2 rounded-xl text-xs font-bold flex items-center gap-1 transition-all border ${
                    safeCurrentPage === totalPages
                      ? 'bg-slate-900/40 text-slate-600 border-white/5 cursor-not-allowed'
                      : 'bg-slate-900/90 text-slate-300 border-white/10 hover:bg-slate-800 hover:text-white hover:border-emerald-500/40'
                  }`}
                >
                  <span>Siguiente</span>
                  <ChevronRight className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
          )}
        </>
      )}
    </section>
  );
};
