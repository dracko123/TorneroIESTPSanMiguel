import React, { useEffect, useState } from 'react';

interface LoadingScreenProps {
  isLoading: boolean;
}

export const LoadingScreen: React.FC<LoadingScreenProps> = ({ isLoading }) => {
  const [visible, setVisible] = useState(true);

  useEffect(() => {
    if (!isLoading) {
      // Esperar la duración del fade-out antes de desmontar
      const timeout = setTimeout(() => setVisible(false), 700);
      return () => clearTimeout(timeout);
    } else {
      setVisible(true);
    }
  }, [isLoading]);

  if (!visible) return null;

  return (
    <div
      className="loading-screen-overlay"
      style={{
        opacity: isLoading ? 1 : 0,
        transition: 'opacity 0.7s ease-out',
        position: 'fixed',
        inset: 0,
        zIndex: 9999,
        backgroundColor: '#020617', // slate-950
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        gap: '2rem',
      }}
    >
      {/* Luces ambientales de estadio */}
      <div style={{
        position: 'absolute',
        top: '15%',
        left: '25%',
        width: '400px',
        height: '400px',
        background: 'radial-gradient(circle, rgba(16,185,129,0.12) 0%, transparent 70%)',
        borderRadius: '50%',
        pointerEvents: 'none',
      }} />
      <div style={{
        position: 'absolute',
        bottom: '15%',
        right: '20%',
        width: '350px',
        height: '350px',
        background: 'radial-gradient(circle, rgba(99,102,241,0.10) 0%, transparent 70%)',
        borderRadius: '50%',
        pointerEvents: 'none',
      }} />

      {/* Contenedor de la pelota con el logo */}
      <div className="ball-wrapper" style={{ position: 'relative', width: '160px', height: '160px' }}>
        {/* Sombra proyectada hacia abajo */}
        <div style={{
          position: 'absolute',
          bottom: '-20px',
          left: '50%',
          transform: 'translateX(-50%)',
          width: '100px',
          height: '18px',
          background: 'radial-gradient(ellipse, rgba(16,185,129,0.25) 0%, transparent 70%)',
          borderRadius: '50%',
          animation: 'shadowPulse 1.5s linear infinite',
        }} />

        {/* Pelota de fútbol animada (SVG 3D) */}
        <div className="ball-spin" style={{
          width: '160px',
          height: '160px',
          animation: 'spin3D 1.8s linear infinite',
          transformStyle: 'preserve-3d',
        }}>
          <svg
            viewBox="0 0 160 160"
            width="160"
            height="160"
            xmlns="http://www.w3.org/2000/svg"
          >
            <defs>
              <radialGradient id="ballGradient" cx="38%" cy="32%" r="65%">
                <stop offset="0%" stopColor="#ffffff" />
                <stop offset="55%" stopColor="#e2e8f0" />
                <stop offset="100%" stopColor="#94a3b8" />
              </radialGradient>
              <radialGradient id="shineGradient" cx="35%" cy="28%" r="40%">
                <stop offset="0%" stopColor="rgba(255,255,255,0.85)" />
                <stop offset="100%" stopColor="rgba(255,255,255,0)" />
              </radialGradient>
              <clipPath id="ballClip">
                <circle cx="80" cy="80" r="76" />
              </clipPath>
            </defs>

            {/* Esfera base */}
            <circle cx="80" cy="80" r="76" fill="url(#ballGradient)" />

            {/* Paneles negros del balón (patrón clásico hexagonal) */}
            <g clipPath="url(#ballClip)" fill="#1e293b" opacity="0.88">
              {/* Pentágono central */}
              <polygon points="80,42 101,57 93,81 67,81 59,57" />
              {/* Pentágono superior izquierdo */}
              <polygon points="46,24 67,24 75,42 59,57 38,48" />
              {/* Pentágono superior derecho */}
              <polygon points="114,24 122,48 101,57 85,42 93,24" />
              {/* Pentágono izquierdo */}
              <polygon points="18,66 38,48 59,57 67,81 46,93 22,84" />
              {/* Pentágono derecho */}
              <polygon points="142,66 138,84 114,93 101,81 101,57 122,48" />
              {/* Pentágono inferior izquierdo */}
              <polygon points="46,93 67,81 93,81 101,93 88,114 58,114" />
              {/* Pentágono inferior */}
              <polygon points="58,114 88,114 96,132 80,140 64,132" />
            </g>

            {/* Brillo especular */}
            <circle cx="80" cy="80" r="76" fill="url(#shineGradient)" />

            {/* Borde sutil */}
            <circle cx="80" cy="80" r="76" fill="none" stroke="rgba(148,163,184,0.3)" strokeWidth="1.5" />
          </svg>
        </div>

        {/* Logo de Thedesigninyoureyes centrado sobre la pelota */}
        <div style={{
          position: 'absolute',
          top: '50%',
          left: '50%',
          transform: 'translate(-50%, -50%)',
          width: '64px',
          height: '64px',
          borderRadius: '50%',
          overflow: 'hidden',
          border: '2.5px solid rgba(16,185,129,0.6)',
          boxShadow: '0 0 16px rgba(16,185,129,0.35), 0 4px 12px rgba(0,0,0,0.5)',
          backgroundColor: 'rgba(255,255,255,0.95)',
          backdropFilter: 'blur(4px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 10,
          animation: 'logoCounterSpin 1.8s linear infinite',
        }}>
          <img
            src={`${import.meta.env.BASE_URL}thedesigninyoureyes-logo.png`}
            alt="Thedesigninyoureyes"
            style={{
              width: '54px',
              height: '54px',
              objectFit: 'contain',
              borderRadius: '50%',
            }}
          />
        </div>
      </div>

      {/* Texto de carga */}
      <div style={{ textAlign: 'center' }}>
        <p style={{
          color: '#f1f5f9',
          fontSize: '1rem',
          fontWeight: 700,
          letterSpacing: '0.1em',
          textTransform: 'uppercase',
          marginBottom: '6px',
        }}>
          Cargando torneo
          <span className="loading-dots" style={{ color: '#10b981' }}>...</span>
        </p>
        <p style={{
          color: '#64748b',
          fontSize: '0.72rem',
          letterSpacing: '0.05em',
        }}>
          TheDesignInYourEyes • Plataforma Deportiva
        </p>
      </div>

      {/* Estilos de animación en línea */}
      <style>{`
        @keyframes spin3D {
          0%   { transform: rotateY(0deg) rotateX(15deg); }
          100% { transform: rotateY(360deg) rotateX(15deg); }
        }
        @keyframes logoCounterSpin {
          0%   { transform: translate(-50%, -50%) rotateY(0deg); }
          100% { transform: translate(-50%, -50%) rotateY(-360deg); }
        }
        @keyframes shadowPulse {
          0%, 100% { opacity: 0.6; transform: translateX(-50%) scaleX(1); }
          50%       { opacity: 0.3; transform: translateX(-50%) scaleX(0.75); }
        }
        @keyframes dotBlink {
          0%, 20%  { opacity: 0; }
          50%      { opacity: 1; }
          100%     { opacity: 0; }
        }
        .loading-dots {
          display: inline-block;
          animation: dotBlink 1.4s ease-in-out infinite;
        }
      `}</style>
    </div>
  );
};
