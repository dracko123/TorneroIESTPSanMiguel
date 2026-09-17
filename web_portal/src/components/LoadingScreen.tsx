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

  // Manejo del desmontaje tras el fade-out suave
  useEffect(() => {
    if (!isLoading) {
      const timeout = setTimeout(() => setVisible(false), 700);
      return () => clearTimeout(timeout);
    } else {
      setVisible(true);
    }
  }, [isLoading]);

  // Barra de puntos dinámicos en onda continua
  useEffect(() => {
    const dotInterval = setInterval(() => {
      setActiveDot((prev) => (prev + 1) % 5);
    }, 280);
    return () => clearInterval(dotInterval);
  }, []);

  // Efecto máquina de escribir (Typing effect)
  useEffect(() => {
    const targetPhrase = TYPING_PHRASES[phraseIndex];
    const typingSpeed = isDeleting ? 38 : 70;

    const timer = setTimeout(() => {
      if (!isDeleting) {
        if (currentText.length < targetPhrase.length) {
          setCurrentText(targetPhrase.slice(0, currentText.length + 1));
        } else {
          // Pausa con la frase completa visible
          setTimeout(() => setIsDeleting(true), 2400);
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
        gap: '1.4rem',
        padding: '1.5rem',
        userSelect: 'none',
      }}
    >
      {/* Luces atmosféricas de estadio */}
      <div
        style={{
          position: 'absolute',
          top: '15%',
          left: '25%',
          width: '380px',
          height: '380px',
          background: 'radial-gradient(circle, rgba(16,185,129,0.14) 0%, transparent 70%)',
          borderRadius: '50%',
          pointerEvents: 'none',
          animation: 'ambientGlow 4s ease-in-out infinite alternate',
        }}
      />
      <div
        style={{
          position: 'absolute',
          bottom: '15%',
          right: '25%',
          width: '360px',
          height: '360px',
          background: 'radial-gradient(circle, rgba(99,102,241,0.12) 0%, transparent 70%)',
          borderRadius: '50%',
          pointerEvents: 'none',
          animation: 'ambientGlow 5s ease-in-out infinite alternate-reverse',
        }}
      />

      {/* Badge superior "Cargando Torneo" */}
      <div
        style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: '6px',
          padding: '4px 12px',
          borderRadius: '9999px',
          backgroundColor: 'rgba(16,185,129,0.1)',
          border: '1px solid rgba(16,185,129,0.3)',
          boxShadow: '0 0 12px rgba(16,185,129,0.15)',
        }}
      >
        <span
          style={{
            width: '6px',
            height: '6px',
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

      {/* Contenedor compacto de la Pelota Al Rihla (84px) */}
      <div
        style={{
          position: 'relative',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          margin: '0.5rem 0',
        }}
      >
        {/* Aura viva circular detrás del balón */}
        <div
          style={{
            position: 'absolute',
            top: '50%',
            left: '50%',
            transform: 'translate(-50%, -50%)',
            width: '120px',
            height: '120px',
            background: 'radial-gradient(circle, rgba(16,185,129,0.25) 0%, rgba(56,189,248,0.12) 45%, transparent 70%)',
            borderRadius: '50%',
            animation: 'auraPulse 2.6s ease-in-out infinite',
            pointerEvents: 'none',
          }}
        />

        {/* Flotación suave (Levitación vertical) */}
        <div
          style={{
            animation: 'ballFloat 2.6s ease-in-out infinite',
            position: 'relative',
            width: '84px',
            height: '84px',
          }}
        >
          {/* Giro 2D continuo en el eje Z: rotación 100% circular, regular y perfecta */}
          <div
            style={{
              width: '84px',
              height: '84px',
              borderRadius: '50%',
              overflow: 'hidden',
              animation: 'ballRollZ 3.4s linear infinite',
              filter: 'drop-shadow(0 6px 14px rgba(0,0,0,0.55))',
            }}
          >
            <img
              src={`${import.meta.env.BASE_URL}al-rihla-ball.png`}
              alt="Pelota Oficial Al Rihla"
              style={{
                width: '100%',
                height: '100%',
                objectFit: 'cover',
                display: 'block',
              }}
            />
          </div>
        </div>

        {/* Sombra de contacto sincronizada con la flotación */}
        <div
          style={{
            marginTop: '10px',
            width: '64px',
            height: '10px',
            background: 'radial-gradient(ellipse, rgba(16,185,129,0.35) 0%, rgba(0,0,0,0.4) 40%, transparent 75%)',
            borderRadius: '50%',
            animation: 'shadowSync 2.6s ease-in-out infinite',
          }}
        />
      </div>

      {/* Bloque de Marca: Logo TheDesignInYourEyes + Typing + Progreso */}
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          textAlign: 'center',
          maxWidth: '360px',
          gap: '8px',
        }}
      >
        {/* Logo de TheDesignInYourEyes nítido y enmarcado con cristal */}
        <div
          style={{
            width: '46px',
            height: '46px',
            borderRadius: '50%',
            overflow: 'hidden',
            border: '1.5px solid rgba(16,185,129,0.7)',
            boxShadow: '0 0 16px rgba(16,185,129,0.35), 0 4px 10px rgba(0,0,0,0.5)',
            backgroundColor: 'rgba(255,255,255,0.96)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '3px',
            animation: 'logoPulse 2.6s ease-in-out infinite',
          }}
        >
          <img
            src={`${import.meta.env.BASE_URL}thedesigninyoureyes-logo.png`}
            alt="TheDesignInYourEyes"
            style={{
              width: '100%',
              height: '100%',
              objectFit: 'contain',
              borderRadius: '50%',
            }}
          />
        </div>

        {/* Texto animado con máquina de escribir */}
        <div
          style={{
            minHeight: '32px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <h2
            style={{
              fontSize: '1.15rem',
              fontWeight: 800,
              letterSpacing: '0.03em',
              color: '#f8fafc',
              margin: 0,
              display: 'inline-flex',
              alignItems: 'center',
              textShadow: '0 2px 8px rgba(0,0,0,0.6)',
            }}
          >
            <span>{currentText}</span>
            <span
              className="typing-cursor"
              style={{
                display: 'inline-block',
                width: '2px',
                height: '1.15em',
                backgroundColor: '#10b981',
                marginLeft: '3px',
                borderRadius: '1px',
                boxShadow: '0 0 8px rgba(16,185,129,0.85)',
                animation: 'cursorBlink 0.8s steps(2, start) infinite',
              }}
            />
          </h2>
        </div>

        {/* Lema secundario deportivo */}
        <p
          style={{
            color: '#94a3b8',
            fontSize: '0.72rem',
            letterSpacing: '0.05em',
            margin: 0,
          }}
        >
          Experiencia Deportiva en Vivo
        </p>

        {/* Barra de puntos dinámicos en onda de progreso */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '6px',
            marginTop: '4px',
          }}
        >
          {[0, 1, 2, 3, 4].map((index) => {
            const isActive = activeDot === index;
            return (
              <div
                key={index}
                style={{
                  width: isActive ? '20px' : '6px',
                  height: '6px',
                  borderRadius: '9999px',
                  backgroundColor: isActive ? '#10b981' : 'rgba(71,85,105,0.45)',
                  boxShadow: isActive ? '0 0 10px rgba(16,185,129,0.8)' : 'none',
                  transition: 'all 0.28s cubic-bezier(0.4, 0, 0.2, 1)',
                }}
              />
            );
          })}
        </div>
      </div>

      {/* Keyframes de animación optimizados */}
      <style>{`
        /* Giro continuo circular en eje Z: 100% simétrico, fluido y natural */
        @keyframes ballRollZ {
          0%   { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }

        /* Levitación suave arriba/abajo */
        @keyframes ballFloat {
          0%, 100% { transform: translateY(0px); }
          50%      { transform: translateY(-7px); }
        }

        /* Sombra reactiva a la levitación */
        @keyframes shadowSync {
          0%, 100% {
            opacity: 0.6;
            transform: scaleX(1) scaleY(1);
          }
          50% {
            opacity: 0.3;
            transform: scaleX(0.82) scaleY(0.75);
          }
        }

        /* Aura viva con respiración sutil */
        @keyframes auraPulse {
          0%, 100% { transform: translate(-50%, -50%) scale(1); opacity: 0.7; }
          50%      { transform: translate(-50%, -50%) scale(1.15); opacity: 1; }
        }

        /* Logo con leve micro-respiración */
        @keyframes logoPulse {
          0%, 100% { transform: scale(1); }
          50%      { transform: scale(1.04); }
        }

        @keyframes ambientGlow {
          0%   { transform: scale(1); opacity: 0.12; }
          100% { transform: scale(1.18); opacity: 0.22; }
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
