import { Trophy, Shield, Sparkles } from 'lucide-react';
import type { TournamentConfig } from '../types/tournament';
import { CountdownBanner } from './CountdownBanner';

interface SportsHeroBannerProps {
  config: TournamentConfig;
}

export const SportsHeroBanner: React.FC<SportsHeroBannerProps> = ({ config }) => {
  const hasCustomBg = !!config.banner_bg_url;
  const organizerLogo = config.organizador_logo_url;
  const organizerName = config.organizador_nombre || 'Comité Organizador Oficial';

  return (
    <div className="relative overflow-hidden rounded-3xl mb-10 border border-white/15 shadow-2xl bg-slate-950">
      {/* 1. Fondo Deportivo Panorámico con Iluminación de Estadio */}
      <div className="absolute inset-0 z-0">
        {hasCustomBg ? (
          <img
            src={config.banner_bg_url}
            alt="Fondo Deportivo"
            className="w-full h-full object-cover object-center opacity-35 filter saturate-150"
          />
        ) : (
          /* Fondo nativo de Estadio Nocturno generado con CSS y gradientes */
          <div className="w-full h-full relative overflow-hidden bg-gradient-to-b from-slate-900 via-emerald-950/40 to-slate-950">
            {/* Reflectores de luz de estadio */}
            <div className="absolute top-0 left-1/4 w-96 h-96 bg-emerald-500/20 rounded-full blur-3xl transform -translate-y-1/2"></div>
            <div className="absolute top-0 right-1/4 w-96 h-96 bg-blue-500/15 rounded-full blur-3xl transform -translate-y-1/2"></div>
            <div className="absolute bottom-0 left-1/2 w-full h-48 bg-gradient-to-t from-emerald-600/10 via-transparent to-transparent -translate-x-1/2"></div>
            
            {/* Patrón sutil de cancha de fútbol (líneas de campo) */}
            <div className="absolute inset-0 opacity-10 bg-[radial-gradient(#10b981_1px,transparent_1px)] [background-size:24px_24px]"></div>
          </div>
        )}
        {/* Degradado para garantizar legibilidad óptima de los textos */}
        <div className="absolute inset-0 bg-gradient-to-t from-slate-950 via-slate-950/80 to-transparent"></div>
        <div className="absolute inset-0 bg-gradient-to-r from-slate-950/90 via-slate-950/60 to-slate-950/90"></div>
      </div>

      {/* 2. Contenido Principal del Hero Banner */}
      <div className="relative z-10 p-6 sm:p-8 lg:p-10">
        {/* Fila Superior: Badge del Organizador y Estado */}
        <div className="flex flex-wrap items-center justify-between gap-4 mb-6 pb-6 border-b border-white/10">
          {/* Identidad del Organizador */}
          <div className="flex items-center space-x-4">
            <div className="relative group">
              <div className="w-16 h-16 sm:w-20 sm:h-20 rounded-2xl bg-gradient-to-br from-amber-400/30 via-emerald-500/20 to-teal-500/30 p-1 shadow-2xl backdrop-blur-md flex items-center justify-center border border-white/20 transition-transform duration-300 group-hover:scale-105">
                {organizerLogo ? (
                  <img
                    src={organizerLogo}
                    alt={organizerName}
                    className="w-full h-full object-contain rounded-xl"
                    onError={(e) => {
                      // Fallback si la imagen falla al cargar
                      (e.target as HTMLElement).style.display = 'none';
                    }}
                  />
                ) : (
                  <div className="w-full h-full bg-slate-900/90 rounded-xl flex items-center justify-center">
                    <Shield className="w-8 h-8 text-amber-400" />
                  </div>
                )}
              </div>
              <div className="absolute -bottom-1 -right-1 bg-amber-500 text-slate-950 p-1 rounded-full shadow-md" title="Organizador Oficial">
                <Sparkles className="w-3 h-3" />
              </div>
            </div>

            <div>
              <div className="flex items-center gap-2">
                <span className="text-[10px] sm:text-xs font-extrabold uppercase tracking-widest text-emerald-400 bg-emerald-500/10 px-2.5 py-0.5 rounded-full border border-emerald-500/20">
                  Organizador Oficial
                </span>
              </div>
              <h3 className="text-base sm:text-xl font-black text-white tracking-wide mt-1">
                {organizerName}
              </h3>
              <p className="text-xs text-slate-400 flex items-center gap-1.5 mt-0.5">
                <Trophy className="w-3.5 h-3.5 text-amber-400" />
                <span>Torneo Oficial Certificado</span>
              </p>
            </div>
          </div>

          {/* Badges de Disciplina y Fase */}
          <div className="flex items-center gap-2">
            <span className="px-3.5 py-1.5 rounded-xl bg-slate-900/80 border border-white/10 text-xs sm:text-sm font-bold text-slate-200 backdrop-blur-md">
              ⚽ {config.disciplina || 'FÚTBOL'}
            </span>
            <span className="px-3.5 py-1.5 rounded-xl bg-emerald-500/20 border border-emerald-500/30 text-xs sm:text-sm font-black text-emerald-400 backdrop-blur-md uppercase tracking-wider">
              {config.fase_actual || 'FASE DE GRUPOS'}
            </span>
          </div>
        </div>

        {/* Fila Central: Nombre Grande del Evento */}
        <div className="max-w-4xl mb-8">
          <h1 className="text-3xl sm:text-5xl lg:text-6xl font-black tracking-tight text-white leading-tight font-scoreboard drop-shadow-md">
            {config.nombre_evento || 'Gran Torneo Deportivo 2026'}
          </h1>
          <p className="text-sm sm:text-base text-slate-300 mt-3 flex items-center gap-2 font-medium">
            <span>Sigue en directo los resultados, fixture y tabla de clasificación actualizada en tiempo real.</span>
          </p>
        </div>

        {/* 3. Cuenta Regresiva o Estado de la Jornada integrado */}
        <CountdownBanner
          targetDateStr={config.countdown_target}
          title={config.countdown_title || 'Próximo Encuentro Oficial'}
        />
      </div>
    </div>
  );
};
