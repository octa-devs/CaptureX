import { create } from 'zustand';
import { CameraState, CameraLens, AspectRatio, FlashMode } from '../types';

interface CameraStoreState extends CameraState {
  setLens: (lens: CameraLens) => void;
  setAspectRatio: (ratio: AspectRatio) => void;
  setFlashMode: (flash: FlashMode) => void;
  setTimer: (timer: 0 | 3 | 10) => void;
  toggleGrid: () => void;
  toggleLeveler: () => void;
  toggleRawMode: () => void;
  toggleHdr: () => void;
  setZoom: (zoom: number) => void;
  setFocusPoint: (point: { x: number; y: number } | undefined) => void;
  setExposureCompensation: (ev: number) => void;
}

export const useCameraStore = create<CameraStoreState>((set) => ({
  isActive: true,
  lens: 'wide',
  aspectRatio: '4:3',
  flashMode: 'off',
  timer: 0,
  gridEnabled: true,
  levelerEnabled: false,
  rawModeEnabled: false,
  hdrEnabled: true,
  zoom: 1.0,
  focusPoint: undefined,
  exposureCompensation: 0.0,

  setLens: (lens) => set({ lens }),
  setAspectRatio: (aspectRatio) => set({ aspectRatio }),
  setFlashMode: (flashMode) => set({ flashMode }),
  setTimer: (timer) => set({ timer }),
  toggleGrid: () => set((state) => ({ gridEnabled: !state.gridEnabled })),
  toggleLeveler: () => set((state) => ({ levelerEnabled: !state.levelerEnabled })),
  toggleRawMode: () => set((state) => ({ rawModeEnabled: !state.rawModeEnabled })),
  toggleHdr: () => set((state) => ({ hdrEnabled: !state.hdrEnabled })),
  setZoom: (zoom) => set({ zoom }),
  setFocusPoint: (focusPoint) => set({ focusPoint }),
  setExposureCompensation: (exposureCompensation) => set({ exposureCompensation }),
}));
