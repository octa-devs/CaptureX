import { create } from 'zustand';
import { FilterPreset, FilterCategory, ManualAdjustments } from '../types';
import { FILTER_PRESETS } from '../shaders/presets';

interface FilterStoreState {
  selectedPreset: FilterPreset;
  activeCategory: FilterCategory;
  manualAdjustments: ManualAdjustments;
  intensity: number; // 0 to 100 % filter blend
  
  setSelectedPreset: (preset: FilterPreset) => void;
  setActiveCategory: (category: FilterCategory) => void;
  setManualAdjustment: (key: keyof ManualAdjustments, value: number) => void;
  setIntensity: (intensity: number) => void;
  resetAdjustments: () => void;
}

const DEFAULT_ADJUSTMENTS: ManualAdjustments = {
  exposure: 0,
  contrast: 0,
  saturation: 0,
  temperature: 0,
  tint: 0,
  highlights: 0,
  shadows: 0,
  vignette: 0,
  grain: 0,
  sharpness: 0,
  bloom: 0,
};

export const useFilterStore = create<FilterStoreState>((set) => ({
  selectedPreset: FILTER_PRESETS[0], // Original
  activeCategory: 'all',
  manualAdjustments: { ...DEFAULT_ADJUSTMENTS },
  intensity: 100,

  setSelectedPreset: (selectedPreset) => set({ selectedPreset }),
  setActiveCategory: (activeCategory) => set({ activeCategory }),
  setManualAdjustment: (key, value) =>
    set((state) => ({
      manualAdjustments: {
        ...state.manualAdjustments,
        [key]: value,
      },
    })),
  setIntensity: (intensity) => set({ intensity }),
  resetAdjustments: () => set({ manualAdjustments: { ...DEFAULT_ADJUSTMENTS }, intensity: 100 }),
}));
