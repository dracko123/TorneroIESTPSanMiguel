import React from 'react';
import { MessageCircle, ShieldCheck, Sparkles, ExternalLink, Award } from 'lucide-react';
import type { TournamentConfig } from '../types/tournament';

interface CommercialFooterProps {
  config: TournamentConfig;
}

export const CommercialFooter: React.FC<CommercialFooterProps> = ({ config }) => {
  const whatsappNumber = '51931990036';
  const whatsappMessage = encodeURIComponent(
    'Hola Thedesigninyoureyes, vi la plataforma deportiva en vivo y deseo consultar información y precios para contratar este sistema para un torneo.'
  );
  const whatsappUrl = `https://wa.me/${whatsappNumber}?text=${whatsappMessage}`;

  return (
    <footer className="border-t border-white/10 bg-slate-950/95 relative z-10 pt-14 pb-10 overflow-hidden">
      {/* Resplandor ambiental de marca */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-3/4 h-32 bg-emerald-500/10 rounded-full blur-3xl pointer-events-none"></div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Bloque Superior de Conversión Comercial (B2B SaaS) */}
        <div className="relative overflow-hidden rounded-3xl p-8 sm:p-10 lg:p-12 mb-12 border border-white/15 bg-gradient-to-r from-slate-900/90 via-slate-900/60 to-emerald-950/40 shadow-2xl backdrop-blur-xl">
          <div className="relative z-10 flex flex-col lg:flex-row items-center justify-between gap-8">
            {/* Logo de Thedesigninyoureyes e información comercial */}
            <div className="flex flex-col sm:flex-row items-center sm:items-start text-center sm:text-left gap-6 max-w-2xl">
              <div className="w-28 h-28 sm:w-32 sm:h-32 rounded-2xl bg-white/90 backdrop-blur-md border border-white/40 p-2.5 shadow-2xl flex-shrink-0 flex items-center justify-center group hover:bg-white transition-all duration-300">
                <img
                  src={`${import.meta.env.BASE_URL}thedesigninyoureyes-logo.png`}
                  alt="Thedesigninyoureyes - Marketing, Audiovisual, Platforms & Apps"
                  className="w-full h-full object-contain filter drop-shadow-sm group-hover:scale-105 transition-transform duration-300"
                />
              </div>

              <div>
                <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-bold uppercase tracking-wider mb-2">
                  <Sparkles className="w-3.5 h-3.5 text-amber-400" />
                  <span>Plataforma Oficial Creada por</span>
                </div>

                <h3 className="text-2xl sm:text-3xl font-black text-white tracking-tight">
                  TheDesignInYourEyes
                </h3>
                <p className="text-xs sm:text-sm font-bold text-amber-400/90 tracking-widest uppercase mt-0.5">
                  MARKETING • AUDIOVISUAL • PLATFORMS & APPS
                </p>

                <p className="text-sm text-slate-300 mt-3 leading-relaxed">
                  ¿Organizas un torneo, liga o campeonato deportivo? Implementa esta moderna plataforma digital con marcadores en tiempo real, aplicación móvil y gestión automática de clasificaciones.
                </p>
              </div>
            </div>

            {/* Llamado a la Acción (CTA) WhatsApp Directo */}
            <div className="flex flex-col items-center sm:items-end w-full lg:w-auto">
              <a
                href={whatsappUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="w-full sm:w-auto inline-flex items-center justify-center gap-3 px-7 py-4 rounded-2xl bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-400 hover:to-teal-400 text-slate-950 font-black text-base shadow-xl shadow-emerald-500/25 transition-all duration-300 transform hover:scale-105 active:scale-95 group"
              >
                <div className="w-7 h-7 rounded-full bg-slate-950/20 flex items-center justify-center">
                  <MessageCircle className="w-5 h-5 text-slate-950 fill-current" />
                </div>
                <span className="text-sm sm:text-base font-black tracking-wide">
                  Contratar Servicio Vía WhatsApp
                </span>
                <ExternalLink className="w-4 h-4 text-slate-950/70 group-hover:translate-x-0.5 transition-transform" />
              </a>

              <span className="text-[11px] text-slate-400 mt-2 flex items-center gap-1.5">
                <ShieldCheck className="w-3.5 h-3.5 text-emerald-400" />
                <span>Atención inmediata y cotizaciones personalizadas</span>
              </span>
            </div>
          </div>
        </div>

        {/* Fila Inferior: Créditos del Torneo y Navegación Rápida */}
        <div className="flex flex-col md:flex-row items-center justify-between gap-6 pt-6 border-t border-white/10 text-xs text-slate-400">
          <div className="flex items-center space-x-3">
            <div className="w-8 h-8 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center border border-emerald-500/20">
              <Award className="w-4 h-4 text-amber-400" />
            </div>
            <div>
              <p className="font-bold text-white text-sm">
                {config.nombre_evento || 'Torneo Deportivo'}
              </p>
              <p className="text-[11px] text-slate-500">
                Organizado por {config.organizador_nombre || 'Comité Organizador'} • Sistema Deportivo B2B
              </p>
            </div>
          </div>

          <div className="flex items-center space-x-6 text-slate-400">
            <a href="#partidos" className="hover:text-emerald-400 transition-colors font-medium">Partidos</a>
            <a href="#posiciones" className="hover:text-emerald-400 transition-colors font-medium">Posiciones</a>
            <a href="#playoffs" className="hover:text-emerald-400 transition-colors font-medium">Playoffs</a>
          </div>

          <p className="text-[11px] text-slate-500 text-center md:text-right">
            © {new Date().getFullYear()} <span className="text-white font-semibold">Thedesigninyoureyes</span>. Todos los derechos reservados.
          </p>
        </div>
      </div>
    </footer>
  );
};
