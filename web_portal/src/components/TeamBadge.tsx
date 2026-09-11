import React, { useState } from 'react';
import { Shield } from 'lucide-react';
import { normalizeImageUrl } from '../utils/imageUrl';

interface TeamBadgeProps {
  name: string;
  colorHex?: string;
  logoUrl?: string;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
}

const sizeClasses = {
  sm: 'w-6 h-6 text-[10px]',
  md: 'w-10 h-10 text-xs',
  lg: 'w-14 h-14 text-sm',
  xl: 'w-20 h-20 text-base'
};

const iconSizes = {
  sm: 12,
  md: 18,
  lg: 26,
  xl: 36
};

export const TeamBadge: React.FC<TeamBadgeProps> = ({
  name,
  colorHex = '#10b981',
  logoUrl,
  size = 'md',
  className = ''
}) => {
  const [imageError, setImageError] = useState(false);
  const normalizedLogo = normalizeImageUrl(logoUrl);

  const getBadgeInitials = (n: string): string => {
    if (!n) return '?';
    const clean = n.replace(/^(equipo|eq\.)\s+/i, '').trim();
    if (clean.length > 0 && clean.length <= 3) return clean.toUpperCase();
    const words = n.split(' ').filter(Boolean);
    if (words.length >= 2) {
      return (words[0][0] + words[1][0]).toUpperCase();
    }
    return n.charAt(0).toUpperCase();
  };

  const initial = getBadgeInitials(name);

  if (normalizedLogo && !imageError) {
    return (
      <div
        className={`relative inline-flex items-center justify-center shrink-0 rounded-full p-0.5 shadow-md overflow-hidden bg-slate-900 border border-white/20 ${sizeClasses[size]} ${className}`}
        style={{ borderColor: colorHex }}
        title={name}
      >
        <img
          src={normalizedLogo}
          alt={name}
          referrerPolicy="no-referrer"
          className="w-full h-full object-cover rounded-full"
          onError={() => setImageError(true)}
          loading="lazy"
        />
      </div>
    );
  }

  return (
    <div
      className={`relative inline-flex items-center justify-center shrink-0 rounded-full font-black shadow-lg border-2 border-white/25 text-white transition-transform hover:scale-105 ${sizeClasses[size]} ${className}`}
      style={{
        backgroundColor: colorHex,
        boxShadow: `0 4px 14px -2px ${colorHex}55`
      }}
      title={name}
    >
      {size === 'sm' ? (
        <span className={initial.length > 1 ? 'text-[8.5px] tracking-tighter leading-none' : 'text-[10px] leading-none'}>
          {initial}
        </span>
      ) : (
        <div className="flex flex-col items-center justify-center">
          <Shield size={iconSizes[size]} className="opacity-40 absolute" />
          <span className="relative z-10 drop-shadow-md font-scoreboard">{initial}</span>
        </div>
      )}
    </div>
  );
};
