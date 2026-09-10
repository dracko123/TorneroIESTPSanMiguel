import React, { useState, useEffect, useRef } from 'react';
import { Clock, Radio, Calendar, ArrowDownCircle } from 'lucide-react';
import confetti from 'canvas-confetti';

interface CountdownBannerProps {
  targetDateStr?: string;
  title?: string;
}

interface TimeRemaining {
  total: number;
  days: number;
  hours: number;
  minutes: number;
  seconds: number;
}

function calculateTimeRemaining(targetStr?: string): TimeRemaining {
  if (!targetStr) {
    return { total: 0, days: 0, hours: 0, minutes: 0, seconds: 0 };
  }

  const target = new Date(targetStr).getTime();
  if (isNaN(target)) {
    return { total: 0, days: 0, hours: 0, minutes: 0, seconds: 0 };
  }

  const now = Date.now();
  const diff = target - now;

  if (diff <= 0) {
    return { total: 0, days: 0, hours: 0, minutes: 0, seconds: 0 };
  }

  return {
    total: diff,
    days: Math.floor(diff / (1000 * 60 * 60 * 24)),
    hours: Math.floor((diff / (1000 * 60 * 60)) % 24),
    minutes: Math.floor((diff / 1000 / 60) % 60),
    seconds: Math.floor((diff / 1000) % 60)
  };
}

export const CountdownBanner: React.FC<CountdownBannerProps> = ({
  targetDateStr,
  title = 'Próximo Encuentro Oficial'
}) => {
  const [time, setTime] = useState<TimeRemaining>(() => calculateTimeRemaining(targetDateStr));
  const confettiTriggeredRef = useRef<boolean>(false);

  useEffect(() => {
    const initial = calculateTimeRemaining(targetDateStr);
    setTime(initial);

    // Si la fecha ya pasó o no está configurada, no iniciar intervalo ni disparar confeti
    if (initial.total <= 0) {
      confettiTriggeredRef.current = true;
      return;
    }

    // Fecha en el futuro: iniciar cuenta regresiva
    confettiTriggeredRef.current = false;

    const timer = setInterval(() => {
      const remaining = calculateTimeRemaining(targetDateStr);
      setTime(remaining);

      // Si llegó al momento cero exactamente durante esta sesión
      if (remaining.total <= 0) {
        clearInterval(timer);

        if (!confettiTriggeredRef.current) {
          confettiTriggeredRef.current = true;

          // Disparo único y elegante de celebración deportiva
          confetti({
            particleCount: 100,
            spread: 80,
            origin: { y: 0.6 },
            colors: ['#10b981', '#f59e0b', '#3b82f6', '#ffffff']
          });

          setTimeout(() => {
            confetti({
              particleCount: 50,
              angle: 60,
              spread: 55,
              origin: { x: 0 }
            });
            confetti({
              particleCount: 50,
              angle: 120,
              spread: 55,
              origin: { x: 1 }
            });
          }, 350);
        }
      }
    }, 1000);

    return () => clearInterval(timer);
  }, [targetDateStr]);

  const isLive = time.total <= 0;
  const padZero = (n: number) => n.toString().padStart(2, '0');

  const scrollToMatches = () => {
    const el = document.getElementById('partidos');
    if (el) {
      el.scrollIntoView({ behavior: 'smooth' });
    }
  };

  return (
    <div className="relative overflow-hidden rounded-3xl glass-panel border border-white/10 p-6 sm:p-8 lg:p-10 mb-10 shadow-2xl">
      {/* Resplandores de estadio */}
      <div className="stadium-light bg-emerald-500 -top-32 -left-32 opacity-20"></div>
      <div className="stadium-light bg-amber-500 -bottom-32 -right-32 opacity-15"></div>

      <div className="relative z-10 flex flex-col lg:flex-row items-center justify-between gap-8">
        {/* Lado izquierdo: Título y estado */}
        <div className="text-center lg:text-left max-w-xl">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs sm:text-sm font-semibold mb-3">
            {isLive ? (
              <>
                <Radio className="w-4 h-4 text-emerald-400 animate-pulse" />
                <span className="text-emerald-300 font-bold uppercase tracking-wider">Torneo en Disputa</span>
              </>
            ) : (
              <>
                <Clock className="w-4 h-4 text-emerald-400" />
                <span className="uppercase tracking-wider">Cuenta Regresiva Oficial</span>
              </>
            )}
          </div>

          <h2 className="text-2xl sm:text-3xl lg:text-4xl font-black tracking-tight text-white leading-tight">
            {title}
          </h2>

          <p className="text-sm sm:text-base text-slate-400 mt-2 flex items-center justify-center lg:justify-start gap-2">
            <Calendar className="w-4 h-4 text-slate-500" />
            {targetDateStr ? (
              <span>
                {new Date(targetDateStr).toLocaleDateString('es-ES', {
                  weekday: 'long',
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric',
                  hour: '2-digit',
                  minute: '2-digit'
                })}
              </span>
            ) : (
              <span>Fecha por confirmar</span>
            )}
          </p>
        </div>

        {/* Lado derecho: Reloj activo o Tarjeta compacta En Vivo */}
        {isLive ? (
          <div className="flex flex-col items-center sm:items-end justify-center p-6 rounded-2xl bg-gradient-to-r from-emerald-500/15 via-slate-900/60 to-emerald-950/40 border border-emerald-500/30 text-center sm:text-right shadow-xl backdrop-blur-md w-full lg:w-auto">
            <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full bg-emerald-500 text-slate-950 font-black text-xs uppercase tracking-widest shadow-md">
              <span className="w-2 h-2 rounded-full bg-slate-950 animate-ping"></span>
              Jornada en Vivo
            </div>
            <p className="text-lg sm:text-xl font-black text-white mt-3 font-scoreboard">
              PARTIDOS Y MARCADORES EN DIRECTO
            </p>
            <p className="text-xs text-slate-300 mt-1 mb-4">
              Los encuentros se actualizan automáticamente en tiempo real
            </p>
            <button
              onClick={scrollToMatches}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-bold text-xs uppercase tracking-wider transition-all duration-200 transform hover:scale-105 active:scale-95 shadow-lg shadow-emerald-500/20"
            >
              <ArrowDownCircle className="w-4 h-4" />
              <span>Ver Marcadores</span>
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-4 gap-2 sm:gap-4 w-full sm:w-auto">
            {/* Días */}
            <div className="flex flex-col items-center">
              <div className="w-16 sm:w-20 lg:w-24 h-20 sm:h-24 lg:h-28 rounded-2xl bg-slate-900/90 border border-white/10 flex items-center justify-center shadow-xl relative overflow-hidden group hover:border-emerald-500/50 transition-colors">
                <div className="absolute inset-0 bg-gradient-to-t from-emerald-500/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
                <span className="text-3xl sm:text-4xl lg:text-5xl font-black text-white font-scoreboard">
                  {padZero(time.days)}
                </span>
              </div>
              <span className="text-[10px] sm:text-xs font-bold text-slate-400 uppercase tracking-widest mt-2">
                Días
              </span>
            </div>

            {/* Horas */}
            <div className="flex flex-col items-center">
              <div className="w-16 sm:w-20 lg:w-24 h-20 sm:h-24 lg:h-28 rounded-2xl bg-slate-900/90 border border-white/10 flex items-center justify-center shadow-xl relative overflow-hidden group hover:border-emerald-500/50 transition-colors">
                <div className="absolute inset-0 bg-gradient-to-t from-emerald-500/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
                <span className="text-3xl sm:text-4xl lg:text-5xl font-black text-white font-scoreboard">
                  {padZero(time.hours)}
                </span>
              </div>
              <span className="text-[10px] sm:text-xs font-bold text-slate-400 uppercase tracking-widest mt-2">
                Horas
              </span>
            </div>

            {/* Minutos */}
            <div className="flex flex-col items-center">
              <div className="w-16 sm:w-20 lg:w-24 h-20 sm:h-24 lg:h-28 rounded-2xl bg-slate-900/90 border border-white/10 flex items-center justify-center shadow-xl relative overflow-hidden group hover:border-emerald-500/50 transition-colors">
                <div className="absolute inset-0 bg-gradient-to-t from-emerald-500/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
                <span className="text-3xl sm:text-4xl lg:text-5xl font-black text-emerald-400 font-scoreboard">
                  {padZero(time.minutes)}
                </span>
              </div>
              <span className="text-[10px] sm:text-xs font-bold text-slate-400 uppercase tracking-widest mt-2">
                Minutos
              </span>
            </div>

            {/* Segundos */}
            <div className="flex flex-col items-center">
              <div className="w-16 sm:w-20 lg:w-24 h-20 sm:h-24 lg:h-28 rounded-2xl bg-slate-900/90 border border-emerald-500/30 flex items-center justify-center shadow-xl relative overflow-hidden group glow-emerald">
                <div className="absolute inset-0 bg-gradient-to-t from-emerald-500/20 to-transparent"></div>
                <span className="text-3xl sm:text-4xl lg:text-5xl font-black text-amber-400 font-scoreboard">
                  {padZero(time.seconds)}
                </span>
              </div>
              <span className="text-[10px] sm:text-xs font-bold text-slate-400 uppercase tracking-widest mt-2">
                Segundos
              </span>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
