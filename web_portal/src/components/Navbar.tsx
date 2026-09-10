import { Trophy, Radio } from 'lucide-react';
import type { TournamentConfig } from '../types/tournament';

interface NavbarProps {
  config: TournamentConfig;
  isLiveSync: boolean;
  loading: boolean;
  lastUpdated: Date;
}

export const Navbar: React.FC<NavbarProps> = ({
  config,
  isLiveSync,
  loading,
  lastUpdated
}) => {
  const formattedTime = lastUpdated.toLocaleTimeString('es-ES', {
    hour: '2-digit',
    minute: '2-digit'
  });

  const whatsappUrl = 'https://wa.me/51931990036?text=' + encodeURIComponent(
    'Hola Thedesigninyoureyes, vi la plataforma en el torneo y deseo consultar precios para contratar el sistema.'
  );

  return (
    <header className="sticky top-0 z-40 w-full glass-panel border-b border-white/10 shadow-2xl backdrop-blur-xl">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-20">
          {/* Logo y Nombre del Torneo / Organizador */}
          <div className="flex items-center space-x-3">
            <div className="relative group">
              <div className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-emerald-600 via-emerald-500 to-teal-400 p-0.5 shadow-lg shadow-emerald-500/25 flex items-center justify-center">
                <div className="w-full h-full bg-slate-950 rounded-[14px] flex items-center justify-center overflow-hidden p-1">
                  {config.organizador_logo_url ? (
                    <img
                      src={config.organizador_logo_url}
                      alt={config.organizador_nombre || 'Organizador'}
                      className="w-full h-full object-contain"
                      onError={(e) => {
                        (e.target as HTMLElement).style.display = 'none';
                      }}
                    />
                  ) : (
                    <Trophy className="w-6 h-6 text-amber-400" />
                  )}
                </div>
              </div>
              <span className="absolute -bottom-1 -right-1 flex h-3.5 w-3.5">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-3.5 w-3.5 bg-emerald-500"></span>
              </span>
            </div>

            <div>
              <div className="flex items-center space-x-2">
                <h1 className="text-xl sm:text-2xl font-black tracking-tight text-white flex items-center gap-2">
                  {config.nombre_evento || 'Torneo Deportivo'}
                </h1>
                <span className="hidden sm:inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                  {config.disciplina || 'FÚTBOL'}
                </span>
              </div>
              <p className="text-xs text-slate-400 flex items-center gap-1.5 mt-0.5">
                <span className="font-semibold text-slate-300">
                  {config.organizador_nombre ? `Org: ${config.organizador_nombre}` : `Fase: ${config.fase_actual || 'GRUPOS'}`}
                </span>
                <span className="text-slate-600">•</span>
                <span>Actualizado {formattedTime}</span>
                {loading && (
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-ping ml-1" title="Sincronizando..."></span>
                )}
              </p>
            </div>
          </div>

          {/* Navegación y Botón Comercial de Thedesigninyoureyes */}
          <div className="flex items-center space-x-3 sm:space-x-5">
            {/* Indicador de Transmisión en Tiempo Real */}
            <div className="hidden md:flex items-center space-x-2 px-3.5 py-1.5 rounded-full bg-slate-900/80 border border-white/10 text-xs shadow-inner">
              <Radio className={`w-3.5 h-3.5 ${isLiveSync ? 'text-emerald-400 animate-pulse' : 'text-emerald-500'}`} />
              <span className="text-emerald-300 font-bold tracking-wide">
                TIEMPO REAL
              </span>
            </div>

            {/* Enlaces de ancla */}
            <nav className="hidden lg:flex items-center space-x-1">
              <a
                href="#partidos"
                className="px-3 py-1.5 rounded-xl text-xs font-semibold text-slate-300 hover:text-white hover:bg-white/5 transition-colors"
              >
                Partidos
              </a>
              <a
                href="#posiciones"
                className="px-3 py-1.5 rounded-xl text-xs font-semibold text-slate-300 hover:text-white hover:bg-white/5 transition-colors"
              >
                Posiciones
              </a>
              {((config?.clasificados_por_grupo === undefined || Number(config.clasificados_por_grupo) > 0) || (config?.fase_actual && config.fase_actual.toUpperCase() !== 'GRUPOS')) && (
                <a
                  href="#playoffs"
                  className="px-3 py-1.5 rounded-xl text-xs font-semibold text-slate-300 hover:text-white hover:bg-white/5 transition-colors"
                >
                  Playoffs
                </a>
              )}
            </nav>

            {/* Logo Thedesigninyoureyes con sombra y resplandor blanco luminoso */}
            <a
              href={whatsappUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="relative p-1.5 flex items-center justify-center transition-all duration-300 transform hover:scale-110 active:scale-95 group"
              title="Consultar por este servicio en WhatsApp: +51 931 990 036"
            >
              <img
                src="/thedesigninyoureyes-logo.png"
                alt="Thedesigninyoureyes"
                className="h-8 sm:h-9 w-auto object-contain transition-all duration-300 filter drop-shadow-[0_0_8px_rgba(255,255,255,0.9)] drop-shadow-[0_0_18px_rgba(255,255,255,0.45)] group-hover:drop-shadow-[0_0_12px_rgba(255,255,255,1)] group-hover:drop-shadow-[0_0_24px_rgba(255,255,255,0.7)]"
              />
            </a>
          </div>
        </div>
      </div>
    </header>
  );
};
