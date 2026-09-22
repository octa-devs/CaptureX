export type FilterCategory = 'all' | 'moody' | 'dreamy' | 'nightcore' | 'vivid' | 'film' | 'cinematic' | 'bw';

export interface FilterPreset {
  id: string;
  name: string;
  category: FilterCategory;
  description: string;
  badge?: string;
  colorMatrix?: number[];
  shaderUniforms: {
    exposure: number;      // -1.0 to 1.0
    contrast: number;      // 0.5 to 2.0
    saturation: number;    // 0.0 to 2.5
    temperature: number;   // -1.0 (Cool) to 1.0 (Warm)
    tint: number;          // -1.0 (Green) to 1.0 (Magenta)
    highlights: number;    // -1.0 to 1.0
    shadows: number;       // -1.0 to 1.0
    vignette: number;      // 0.0 to 1.0
    grain: number;         // 0.0 to 1.0
    bloom: number;         // 0.0 to 1.0 (Dreamy glow)
    neonBoost: number;     // 0.0 to 1.0 (Nightcore saturation)
    clarity: number;       // 0.0 to 1.0
  };
}

export interface ManualAdjustments {
  exposure: number;       // -100 to 100
  contrast: number;       // -100 to 100
  saturation: number;     // -100 to 100
  temperature: number;    // -100 to 100 (Cool - Warm)
  tint: number;           // -100 to 100 (Green - Magenta)
  highlights: number;     // -100 to 100
  shadows: number;        // -100 to 100
  vignette: number;       // 0 to 100
  grain: number;          // 0 to 100
  sharpness: number;      // 0 to 100
  bloom: number;          // 0 to 100
}

export type AspectRatio = '1:1' | '4:3' | '16:9' | 'full';

export type FlashMode = 'off' | 'on' | 'auto' | 'torch';

export type CameraLens = 'ultrawide' | 'wide' | 'telephoto' | 'front';

export interface WatermarkConfig {
  enabled: boolean;
  text: string;
  showLogo: boolean;
  showExif: boolean;
  position: 'bottom-right' | 'bottom-left' | 'bottom-center' | 'top-right';
  opacity: number;       // 0.0 to 1.0
  scale: number;         // 0.5 to 1.5
  customDeviceName?: string;
}

export interface CapturedPhoto {
  id: string;
  uri: string;
  width: number;
  height: number;
  timestamp: number;
  appliedFilterId?: string;
  adjustments: ManualAdjustments;
  watermarkApplied: boolean;
  exif?: {
    aperture?: string;
    shutterSpeed?: string;
    iso?: string;
    focalLength?: string;
    lens?: string;
  };
}

export interface CameraState {
  isActive: boolean;
  lens: CameraLens;
  aspectRatio: AspectRatio;
  flashMode: FlashMode;
  timer: 0 | 3 | 10;
  gridEnabled: boolean;
  levelerEnabled: boolean;
  rawModeEnabled: boolean;
  hdrEnabled: boolean;
  zoom: number;
  focusPoint?: { x: number; y: number };
  exposureCompensation: number;
}
