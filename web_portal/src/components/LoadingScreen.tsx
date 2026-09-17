import React, { useEffect, useState } from 'react';

interface LoadingScreenProps {
  isLoading: boolean;
}

const TYPING_PHRASES = [
  'TheDesignInYourEyes',
  'Plataforma Deportiva',
  'Resultados en Tiempo Real',
];

export const LoadingScreen: React.FC<LoadingScreenProps> = ({ isLoading }) => {
  const [visible, setVisible] = useState(true);
  const [phraseIndex, setPhraseIndex] = useState(0);
  const [currentText, setCurrentText] = useState('');
  const [isDeleting, setIsDeleting] = useState(false);
  const [activeDot, setActiveDot] = useState(0);

  // Manejo del desmontaje tras el fade-out
  useEffect(() => {
    if (!isLoading) {
      const timeout = setTimeout(() => setVisible(false), 700);
      return () => clearTimeout(timeout);
    } else {
      setVisible(true);
    }
  }, [isLoading]);

  // Animación de los puntos de progreso (onda consecutiva)
  useEffect(() => {
    const dotInterval = setInterval(() => {
      setActiveDot((prev) => (prev + 1) % 5);
    }, 280);
    return () => clearInterval(dotInterval);
  }, []);

  // Efecto máquina de escribir (Typing effect) amigable
  useEffect(() => {
    const targetPhrase = TYPING_PHRASES[phraseIndex];
    const typingSpeed = isDeleting ? 38 : 75;

    const timer = setTimeout(() => {
      if (!isDeleting) {
        if (currentText.length < targetPhrase.length) {
          setCurrentText(targetPhrase.slice(0, currentText.length + 1));
        } else {
          // Pausa con la palabra completa antes de borrar
          setTimeout(() => setIsDeleting(true), 2200);
        }
      } else {
        if (currentText.length > 0) {
          setCurrentText(targetPhrase.slice(0, currentText.length - 1));
        } else {
          setIsDeleting(false);
          setPhraseIndex((prev) => (prev + 1) % TYPING_PHRASES.length);
        }
      }
    }, typingSpeed);

    return () => clearTimeout(timer);
  }, [currentText, isDeleting, phraseIndex]);

  if (!visible) return null;

  return (
    <div
      className="loading-screen-overlay"
      style={{
        opacity: isLoading ? 1 : 0,
        transform: isLoading ? 'scale(1)' : 'scale(0.98)',
        transition: 'opacity 0.65s cubic-bezier(0.4, 0, 0.2, 1), transform 0.65s ease-out',
        position: 'fixed',
        inset: 0,
        zIndex: 9999,
        backgroundColor: '#020617', // slate-950
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        gap: '2.2rem',
        padding: '1.5rem',
        userSelect: 'none',
      }}
    >
      {/* Luces atmosféricas de estadio con pulsación lenta */}
      <div
        style={{
          position: 'absolute',
          top: '12%',
          left: '22%',
          width: '460px',
          height: '460px',
          background: 'radial-gradient(circle, rgba(16,185,129,0.15) 0%, transparent 68%)',
          borderRadius: '50%',
          pointerEvents: 'none',
          animation: 'ambientGlow 4s ease-in-out infinite alternate',
        }}
      />
      <div
        style={{
          position: 'absolute',
          bottom: '12%',
          right: '20%',
          width: '420px',
          height: '420px',
          background: 'radial-gradient(circle, rgba(99,102,241,0.12) 0%, transparent 68%)',
          borderRadius: '50%',
          pointerEvents: 'none',
          animation: 'ambientGlow 5s ease-in-out infinite alternate-reverse',
        }}
      />

      {/* Contenedor flotante de la pelota y sombra */}
      <div
        className="ball-container"
        style={{
          position: 'relative',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          perspective: '1000px',
        }}
      >
        {/* Aura / resplandor vivo detrás de la pelota */}
        <div
          style={{
            position: 'absolute',
            top: '50%',
            left: '50%',
            transform: 'translate(-50%, -50%)',
            width: '210px',
            height: '210px',
            background: 'radial-gradient(circle, rgba(16,185,129,0.22) 0%, rgba(16,185,129,0.05) 45%, transparent 70%)',
            borderRadius: '50%',
            animation: 'auraPulse 2.8s ease-in-out infinite',
            pointerEvents: 'none',
          }}
        />

        {/* Envoltorio con flotación suave (Bobbing) */}
        <div
          style={{
            animation: 'floatingBall 2.8s ease-in-out infinite',
            position: 'relative',
            width: '160px',
            height: '160px',
          }}
        >
          {/* Pelota de fútbol girando suave en 3D */}
          <div
            className="ball-spin"
            style={{
              width: '160px',
              height: '160px',
              animation: 'smoothSpin3D 3.2s linear infinite',
              transformStyle: 'preserve-3d',
            }}
          >
            <svg
              viewBox="0 0 160 160"
              width="160"
              height="160"
              xmlns="http://www.w3.org/2000/svg"
              style={{ filter: 'drop-shadow(0 10px 20px rgba(0,0,0,0.5))' }}
            >
              <defs>
                <radialGradient id="ballGradient" cx="36%" cy="30%" r="68%">
                  <stop offset="0%" stopColor="#ffffff" />
                  <stop offset="55%" stopColor="#e2e8f0" />
                  <stop offset="85%" stopColor="#cbd5e1" />
                  <stop offset="100%" stopColor="#94a3b8" />
                </radialGradient>
                <radialGradient id="shineGradient" cx="34%" cy="26%" r="38%">
                  <stop offset="0%" stopColor="rgba(255,255,255,0.9)" />
                  <stop offset="60%" stopColor="rgba(255,255,255,0.25)" />
                  <stop offset="100%" stopColor="rgba(255,255,255,0)" />
                </radialGradient>
                <clipPath id="ballClip">
                  <circle cx="80" cy="80" r="76" />
                </clipPath>
              </defs>

              {/* Esfera base */}
              <circle cx="80" cy="80" r="76" fill="url(#ballGradient)" />

              {/* Paneles del balón (patrón geométrico de fútbol) */}
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

              {/* Brillo especular esférico */}
              <circle cx="80" cy="80" r="76" fill="url(#shineGradient)" />

              {/* Borde exterior fino con resplandor */}
              <circle
                cx="80"
                cy="80"
                r="76"
                fill="none"
                stroke="rgba(16,185,129,0.35)"
                strokeWidth="1.5"
              />
            </svg>
          </div>

          {/* Logo circular de TheDesignInYourEyes superpuesto en el centro */}
          <div
            style={{
              position: 'absolute',
              top: '50%',
              left: '50%',
              transform: 'translate(-50%, -50%)',
              width: '68px',
              height: '68px',
              borderRadius: '50%',
              overflow: 'hidden',
              border: '2px solid rgba(16,185,129,0.85)',
              boxShadow: '0 0 22px rgba(16,185,129,0.5), 0 6px 16px rgba(0,0,0,0.6)',
              backgroundColor: 'rgba(255,255,255,0.96)',
              backdropFilter: 'blur(8px)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              zIndex: 10,
              animation: 'logoSmoothCounterSpin 3.2s linear infinite',
              padding: '4px',
            }}
          >
            <img
              src={`${import.meta.env.BASE_URL}thedesigninyoureyes-logo.png`}
              alt="TheDesignInYourEyes"
              style={{
                width: '56px',
                height: '56px',
                objectFit: 'contain',
                borderRadius: '50%',
              }}
            />
          </div>
        </div>

        {/* Sombra proyectada con pulsación reactiva al salto */}
        <div
          style={{
            marginTop: '18px',
            width: '110px',
            height: '14px',
            background: 'radial-gradient(ellipse, rgba(16,185,129,0.3) 0%, rgba(16,185,129,0.1) 40%, transparent 75%)',
            borderRadius: '50%',
            animation: 'shadowSync 2.8s ease-in-out infinite',
          }}
        />
      </div>

      {/* Sección de textos y marca con efecto typing */}
      <div style={{ textAlign: 'center', maxWidth: '380px' }}>
        {/* Badge superior sutil */}
        <div
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '6px',
            padding: '4px 12px',
            borderRadius: '9999px',
            backgroundColor: 'rgba(16,185,129,0.1)',
            border: '1px solid rgba(16,185,129,0.25)',
            marginBottom: '12px',
          }}
        >
          <span
            style={{
              width: '7px',
              height: '7px',
              borderRadius: '50%',
              backgroundColor: '#10b981',
              boxShadow: '0 0 8px #10b981',
              animation: 'dotBlink 1.4s infinite',
            }}
          />
          <span
            style={{
              color: '#34d399',
              fontSize: '0.68rem',
              fontWeight: 700,
              letterSpacing: '0.12em',
              textTransform: 'uppercase',
            }}
          >
            Cargando Torneo
          </span>
        </div>

        {/* Texto con efecto máquina de escribir (Typing effect) */}
        <div
          style={{
            minHeight: '36px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <h2
            style={{
              fontSize: '1.25rem',
              fontWeight: 800,
              letterSpacing: '0.04em',
              color: '#f8fafc',
              margin: 0,
              display: 'inline-flex',
              alignItems: 'center',
              textShadow: '0 2px 10px rgba(0,0,0,0.5)',
            }}
          >
            <span>{currentText}</span>
            {/* Cursor parpadeante estilo terminal moderno */}
            <span
              className="typing-cursor"
              style={{
                display: 'inline-block',
                width: '2.5px',
                height: '1.2em',
                backgroundColor: '#10b981',
                marginLeft: '3px',
                borderRadius: '1px',
                boxShadow: '0 0 8px rgba(16,185,129,0.8)',
                animation: 'cursorBlink 0.8s steps(2, start) infinite',
              }}
            />
          </h2>
        </div>

        {/* Subtítulo complementario */}
        <p
          style={{
            color: '#64748b',
            fontSize: '0.75rem',
            letterSpacing: '0.06em',
            marginTop: '6px',
            marginBottom: '16px',
          }}
        >
          Experiencia Deportiva en Vivo
        </p>

        {/* Barra de progreso con puntos dinámicos consecutivos */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '8px',
            marginTop: '8px',
          }}
        >
          {[0, 1, 2, 3, 4].map((index) => {
            const isActive = activeDot === index;
            return (
              <div
                key={index}
                style={{
                  width: isActive ? '24px' : '8px',
                  height: '8px',
                  borderRadius: '9999px',
                  backgroundColor: isActive ? '#10b981' : 'rgba(71,85,105,0.4)',
                  boxShadow: isActive ? '0 0 12px rgba(16,185,129,0.7)' : 'none',
                  transition: 'all 0.28s cubic-bezier(0.4, 0, 0.2, 1)',
                }}
              />
            );
          })}
        </div>
      </div>

      {/* Keyframes de animación CSS dedicados */}
      <style>{`
        @keyframes smoothSpin3D {
          0%   { transform: rotateY(0deg) rotateX(10deg); }
          100% { transform: rotateY(360deg) rotateX(10deg); }
        }

        @keyframes logoSmoothCounterSpin {
          0%   { transform: translate(-50%, -50%) rotateY(0deg); }
          100% { transform: translate(-50%, -50%) rotateY(-360deg); }
        }

        @keyframes floatingBall {
          0%, 100% { transform: translateY(0px); }
          50%      { transform: translateY(-10px); }
        }

        @keyframes shadowSync {
          0%, 100% {
            opacity: 0.55;
            transform: scaleX(1) scaleY(1);
          }
          50% {
            opacity: 0.25;
            transform: scaleX(0.8) scaleY(0.7);
          }
        }

        @keyframes auraPulse {
          0%, 100% {
            transform: translate(-50%, -50%) scale(1);
            opacity: 0.7;
          }
          50% {
            transform: translate(-50%, -50%) scale(1.15);
            opacity: 1;
          }
        }

        @keyframes ambientGlow {
          0%   { transform: scale(1) translate(0, 0); opacity: 0.12; }
          100% { transform: scale(1.18) translate(15px, -15px); opacity: 0.22; }
        }

        @keyframes cursorBlink {
          0%, 100% { opacity: 1; }
          50%      { opacity: 0; }
        }

        @keyframes dotBlink {
          0%, 100% { opacity: 1; transform: scale(1); }
          50%      { opacity: 0.4; transform: scale(0.85); }
        }
      `}</style>
    </div>
  );
};
