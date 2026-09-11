import React, { useState } from 'react';
import { Trophy, Shield, Sparkles } from 'lucide-react';
import type { TournamentConfig } from '../types/tournament';
import { CountdownBanner } from './CountdownBanner';
import { normalizeImageUrl } from '../utils/imageUrl';

interface SportsHeroBannerProps {
  config: TournamentConfig;
}

export const SportsHeroBanner: React.FC<SportsHeroBannerProps> = ({ config }) => {
  const [bannerError, setBannerError] = useState(false);
  const [logoError, setLogoError] = useState(false);

  const bannerUrl = normalizeImageUrl(config.banner_bg_url);
  const organizerLogo = normalizeImageUrl(config.organizador_logo_url);
  const organizerName = config.organizador_nombre || 'Comité Organizador Oficial';
  const hasCustomBg = !!bannerUrl && !bannerError;

  return (
    <div className="mb-10">
      {hasCustomBg ? (
        /* CASO A: EL USUARIO TIENE UN BANNER PERSONALIZADO (Flyer / Gráfica oficial / Cabecera) */
        <div className="space-y-4">
          {/* Tarjeta de visualización cinematográfica del Banner */}
          <div className="relative overflow-hidden rounded-3xl border border-white/15 shadow-2xl shadow-emerald-950/40 bg-slate-950 group">
            {/* Ambilight ambiental: reflejo atmosférico sutil con los colores del banner hacia el exterior */}
            <div className="absolute -inset-2 opacity-35 blur-3xl pointer-events-none overflow-hidden">
              <img
                src={bannerUrl}
                alt=""
                aria-hidden="true"
                referrerPolicy="no-referrer"
                className="w-full h-full object-cover scale-110 filter saturate-150"
              />
            </div>

            {/* Imagen del Banner en Alta Fidelidad (nítida, visible al 100%, sin opacidades ni textos invasivos encima) */}
            <div className="relative z-10 w-full overflow-hidden flex items-center justify-center bg-gradient-to-b from-slate-900/40 via-slate-950/20 to-slate-950/80">
              <img
                src={bannerUrl}
                alt={config.nombre_evento || 'Banner Oficial'}
                referrerPolicy="no-referrer"
                onError={() => setBannerError(true)}
                className="w-full h-auto max-h-[380px] lg:max-h-[440px] object-cover sm:object-contain object-center transition-transform duration-700 group-hover:scale-[1.01]"
              />
              {/* Marco de resplandor vítreo sutil en el borde interior */}
              <div className="absolute inset-0 pointer-events-none rounded-3xl ring-1 ring-inset ring-white/15"></div>
            </div>
          </div>

          {/* Barra de Información Oficial del Torneo y Organizador (Sleek Sports HUD) */}
          <div className="glass-panel border border-white/10 rounded-2xl p-4 sm:p-5 shadow-xl flex flex-col md:flex-row items-center justify-between gap-4 backdrop-blur-xl bg-slate-900/85">
            {/* Identidad del Organizador */}
            <div className="flex items-center space-x-3.5 w-full md:w-auto">
              <div className="relative group shrink-0">
                <div className="w-12 h-12 sm:w-14 sm:h-14 rounded-2xl bg-gradient-to-br from-amber-400/30 via-emerald-500/20 to-teal-500/30 p-0.5 shadow-lg backdrop-blur-md flex items-center justify-center border border-white/20 transition-transform duration-300 group-hover:scale-105">
                  {organizerLogo && !logoError ? (
                    <img
                      src={organizerLogo}
                      alt={organizerName}
                      referrerPolicy="no-referrer"
                      className="w-full h-full object-contain rounded-[14px]"
                      onError={() => setLogoError(true)}
                    />
                  ) : (
                    <div className="w-full h-full bg-slate-900/90 rounded-[14px] flex items-center justify-center">
                      <Shield className="w-6 h-6 text-amber-400" />
                    </div>
                  )}
                </div>
                <div className="absolute -bottom-1 -right-1 bg-amber-500 text-slate-950 p-0.5 rounded-full shadow-md" title="Organizador Oficial">
                  <Sparkles className="w-2.5 h-2.5" />
                </div>
              </div>

              <div>
                <span className="text-[10px] font-extrabold uppercase tracking-widest text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded-full border border-emerald-500/20">
                  Organizador Oficial
                </span>
                <h3 className="text-sm sm:text-base font-black text-white tracking-wide mt-0.5">
                  {organizerName}
                </h3>
              </div>
            </div>

            {/* Título del Torneo y Badges de Disciplina / Fase */}
            <div className="flex flex-wrap items-center justify-center md:justify-end gap-2.5 w-full md:w-auto">
              <h1 className="text-base sm:text-lg lg:text-xl font-black text-white font-scoreboard tracking-tight mr-1 text-center md:text-right">
                {config.nombre_evento || 'Torneo Deportivo'}
              </h1>
              <span className="px-3 py-1 rounded-xl bg-slate-800/80 border border-white/10 text-xs font-bold text-slate-200">
                ⚽ {config.disciplina || 'FÚTBOL'}
              </span>
              <span className="px-3 py-1 rounded-xl bg-emerald-500/20 border border-emerald-500/30 text-xs font-black text-emerald-400 uppercase tracking-wider">
                {config.fase_actual || 'FASE DE GRUPOS'}
              </span>
            </div>
          </div>
        </div>
      ) : (
        /* CASO B: SIN BANNER PERSONALIZADO -> ESTADIO NOCTURNO MAJESTUOSO GENERADO CON CSS */
        <div className="relative overflow-hidden rounded-3xl border border-white/15 shadow-2xl bg-slate-950 p-6 sm:p-8 lg:p-10">
          {/* Fondo de Estadio Nocturno */}
          <div className="absolute inset-0 z-0 overflow-hidden bg-gradient-to-b from-slate-900 via-emerald-950/40 to-slate-950">
            <div className="absolute top-0 left-1/4 w-96 h-96 bg-emerald-500/20 rounded-full blur-3xl transform -translate-y-1/2"></div>
            <div className="absolute top-0 right-1/4 w-96 h-96 bg-blue-500/15 rounded-full blur-3xl transform -translate-y-1/2"></div>
            <div className="absolute bottom-0 left-1/2 w-full h-48 bg-gradient-to-t from-emerald-600/10 via-transparent to-transparent -translate-x-1/2"></div>
            <div className="absolute inset-0 opacity-10 bg-[radial-gradient(#10b981_1px,transparent_1px)] [background-size:24px_24px]"></div>
          </div>

          {/* Contenido en vivo del Torneo */}
          <div className="relative z-10">
            <div className="flex flex-wrap items-center justify-between gap-4 mb-6 pb-6 border-b border-white/10">
              <div className="flex items-center space-x-4">
                <div className="relative group">
                  <div className="w-16 h-16 sm:w-20 sm:h-20 rounded-2xl bg-gradient-to-br from-amber-400/30 via-emerald-500/20 to-teal-500/30 p-1 shadow-2xl backdrop-blur-md flex items-center justify-center border border-white/20">
                    {organizerLogo && !logoError ? (
                      <img
                        src={organizerLogo}
                        alt={organizerName}
                        referrerPolicy="no-referrer"
                        className="w-full h-full object-contain rounded-xl"
                        onError={() => setLogoError(true)}
                      />
                    ) : (
                      <div className="w-full h-full bg-slate-900/90 rounded-xl flex items-center justify-center">
                        <Shield className="w-8 h-8 text-amber-400" />
                      </div>
                    )}
                  </div>
                  <div className="absolute -bottom-1 -right-1 bg-amber-500 text-slate-950 p-1 rounded-full shadow-md">
                    <Sparkles className="w-3 h-3" />
                  </div>
                </div>

                <div>
                  <span className="text-[10px] sm:text-xs font-extrabold uppercase tracking-widest text-emerald-400 bg-emerald-500/10 px-2.5 py-0.5 rounded-full border border-emerald-500/20">
                    Organizador Oficial
                  </span>
                  <h3 className="text-base sm:text-xl font-black text-white tracking-wide mt-1">
                    {organizerName}
                  </h3>
                  <p className="text-xs text-slate-400 flex items-center gap-1.5 mt-0.5">
                    <Trophy className="w-3.5 h-3.5 text-amber-400" />
                    <span>Torneo Oficial Certificado</span>
                  </p>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <span className="px-3.5 py-1.5 rounded-xl bg-slate-900/80 border border-white/10 text-xs sm:text-sm font-bold text-slate-200 backdrop-blur-md">
                  ⚽ {config.disciplina || 'FÚTBOL'}
                </span>
                <span className="px-3.5 py-1.5 rounded-xl bg-emerald-500/20 border border-emerald-500/30 text-xs sm:text-sm font-black text-emerald-400 backdrop-blur-md uppercase tracking-wider">
                  {config.fase_actual || 'FASE DE GRUPOS'}
                </span>
              </div>
            </div>

            <div className="max-w-4xl mb-4">
              <h1 className="text-3xl sm:text-5xl lg:text-6xl font-black tracking-tight text-white leading-tight font-scoreboard drop-shadow-md">
                {config.nombre_evento || 'Gran Torneo Deportivo 2026'}
              </h1>
              <p className="text-sm sm:text-base text-slate-300 mt-2 font-medium">
                Sigue en directo los resultados, fixture y tabla de clasificación actualizada en tiempo real.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Cuenta Regresiva Oficial (Con su propio espacio limpio si existe fecha objetivo) */}
      {config.countdown_target && (
        <div className="mt-6">
          <CountdownBanner
            targetDateStr={config.countdown_target}
            title={config.countdown_title || 'Próximo Encuentro Oficial'}
          />
        </div>
      )}
    </div>
  );
};
