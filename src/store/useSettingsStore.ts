import { create } from 'zustand';
import { WatermarkConfig, CapturedPhoto } from '../types';

interface SettingsStoreState {
  watermark: WatermarkConfig;
  hapticsEnabled: boolean;
  shutterSoundEnabled: boolean;
  saveLocationEnabled: boolean;
  photoQuality: 'high' | 'pro_raw' | 'heif';
  recentPhotos: CapturedPhoto[];
  
  setWatermarkEnabled: (enabled: boolean) => void;
  setWatermarkText: (text: string) => void;
  setWatermarkLogo: (showLogo: boolean) => void;
  setWatermarkExif: (showExif: boolean) => void;
  setWatermarkPosition: (position: WatermarkConfig['position']) => void;
  setWatermarkOpacity: (opacity: number) => void;
  setHapticsEnabled: (enabled: boolean) => void;
  setShutterSoundEnabled: (enabled: boolean) => void;
  addCapturedPhoto: (photo: CapturedPhoto) => void;
  deletePhoto: (id: string) => void;
}

export const useSettingsStore = create<SettingsStoreState>((set) => ({
  watermark: {
    enabled: true,
    text: 'Shot with CaptureX',
    showLogo: true,
    showExif: true,
    position: 'bottom-right',
    opacity: 0.9,
    scale: 1.0,
    customDeviceName: 'CaptureX Optical Engine',
  },
  hapticsEnabled: true,
  shutterSoundEnabled: true,
  saveLocationEnabled: true,
  photoQuality: 'high',
  recentPhotos: [],

  setWatermarkEnabled: (enabled) =>
    set((state) => ({ watermark: { ...state.watermark, enabled } })),
  setWatermarkText: (text) =>
    set((state) => ({ watermark: { ...state.watermark, text } })),
  setWatermarkLogo: (showLogo) =>
    set((state) => ({ watermark: { ...state.watermark, showLogo } })),
  setWatermarkExif: (showExif) =>
    set((state) => ({ watermark: { ...state.watermark, showExif } })),
  setWatermarkPosition: (position) =>
    set((state) => ({ watermark: { ...state.watermark, position } })),
  setWatermarkOpacity: (opacity) =>
    set((state) => ({ watermark: { ...state.watermark, opacity } })),
  setHapticsEnabled: (hapticsEnabled) => set({ hapticsEnabled }),
  setShutterSoundEnabled: (shutterSoundEnabled) => set({ shutterSoundEnabled }),
  addCapturedPhoto: (photo) =>
    set((state) => ({ recentPhotos: [photo, ...state.recentPhotos] })),
  deletePhoto: (id) =>
    set((state) => ({
      recentPhotos: state.recentPhotos.filter((p) => p.id !== id),
    })),
}));
