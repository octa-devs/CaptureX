import React, { useState, useRef } from 'react';
import {
  StyleSheet,
  View,
  StatusBar,
  SafeAreaView,
  Text,
  Modal,
  Dimensions,
  Image,
} from 'react-native';
import { CameraTopBar } from './components/camera/CameraTopBar';
import { CameraBottomControls } from './components/camera/CameraBottomControls';
import { LensSelector } from './components/camera/LensSelector';
import { FilterCarousel } from './components/filters/FilterCarousel';
import { ManualAdjustmentBar } from './components/editor/ManualAdjustmentBar';
import { SettingsModal } from './components/settings/SettingsModal';
import { LiquidGlass } from './components/ui/LiquidGlass';
import { useCameraStore } from './store/useCameraStore';
import { useFilterStore } from './store/useFilterStore';
import { useSettingsStore } from './store/useSettingsStore';
import { AudioHaptics } from './services/AudioHapticsService';
import { WatermarkService } from './services/WatermarkService';
import { CapturedPhoto } from './types';

const { width, height } = Dimensions.get('window');

/**
 * CaptureX Master Application Root
 * High-performance mobile camera studio for iOS and Android.
 */
export default function App() {
  const [isProDeckOpen, setIsProDeckOpen] = useState(false);
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const [isCapturing, setIsCapturing] = useState(false);
  const [galleryOpen, setGalleryOpen] = useState(false);

  const { gridEnabled, levelerEnabled } = useCameraStore();
  const { selectedPreset, manualAdjustments } = useFilterStore();
  const { watermark, addCapturedPhoto, recentPhotos } = useSettingsStore();

  const handleCapturePhoto = () => {
    setIsCapturing(true);
    AudioHaptics.playShutterSound();

    // In native runtime, VisionCamera takes full-res frame and Skia exports processed image with watermark
    const newPhoto: CapturedPhoto = {
      id: `photo_${Date.now()}`,
      uri: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=1080&q=80',
      width: 1080,
      height: 1440,
      timestamp: Date.now(),
      appliedFilterId: selectedPreset.id,
      adjustments: manualAdjustments,
      watermarkApplied: watermark.enabled,
      exif: {
        lens: '24mm f/1.78',
        aperture: 'f/1.78',
        shutterSpeed: '1/250s',
        iso: '64',
      },
    };

    addCapturedPhoto(newPhoto);

    setTimeout(() => {
      setIsCapturing(false);
    }, 150);
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#000000" />

      {/* Main Viewfinder Subsystem */}
      <View style={styles.viewfinder}>
        {/* Placeholder / Live Native Camera Feed */}
        <View style={styles.cameraStream}>
          <Image
            source={{
              uri: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=1080&q=80',
            }}
            style={styles.previewImage}
          />

          {/* Liquid Glass Overlay when Filter is Active */}
          <View
            style={[
              styles.filterTintOverlay,
              selectedPreset.category === 'moody' && styles.moodyTint,
              selectedPreset.category === 'dreamy' && styles.dreamyTint,
              selectedPreset.category === 'nightcore' && styles.nightcoreTint,
              selectedPreset.category === 'vivid' && styles.vividTint,
            ]}
          />
        </View>

        {/* Rule-of-Thirds Grid */}
        {gridEnabled && (
          <View style={styles.gridOverlay} pointerEvents="none">
            <View style={[styles.gridLine, styles.gridH1]} />
            <View style={[styles.gridLine, styles.gridH2]} />
            <View style={[styles.gridLine, styles.gridV1]} />
            <View style={[styles.gridLine, styles.gridV2]} />
          </View>
        )}

        {/* Top Controls Bar */}
        <CameraTopBar
          onOpenSettings={() => setIsSettingsOpen(true)}
          onToggleProDeck={() => setIsProDeckOpen(!isProDeckOpen)}
          isProDeckOpen={isProDeckOpen}
        />

        {/* Center Pro Adjustment Slide-up Deck */}
        {isProDeckOpen && (
          <View style={styles.proDeckContainer}>
            <ManualAdjustmentBar onClose={() => setIsProDeckOpen(false)} />
          </View>
        )}

        {/* Lower HUD Section */}
        <View style={styles.lowerHud}>
          {/* Lens Selector */}
          <LensSelector />

          {/* Filter Preset Carousel */}
          <FilterCarousel />

          {/* Master Bottom Bar (Shutter, Gallery, Flip) */}
          <CameraBottomControls
            onCapture={handleCapturePhoto}
            onOpenGallery={() => setGalleryOpen(true)}
            onFlipCamera={() => AudioHaptics.playLensSwitch()}
            isCapturing={isCapturing}
          />
        </View>
      </View>

      {/* Settings Modal */}
      {isSettingsOpen && <SettingsModal onClose={() => setIsSettingsOpen(false)} />}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000000',
  },
  viewfinder: {
    flex: 1,
    position: 'relative',
    justifyContent: 'space-between',
  },
  cameraStream: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: '#05070a',
  },
  previewImage: {
    width: '100%',
    height: '100%',
    resizeMode: 'cover',
  },
  filterTintOverlay: {
    ...StyleSheet.absoluteFillObject,
    opacity: 0.35,
  },
  moodyTint: {
    backgroundColor: '#042f2e',
  },
  dreamyTint: {
    backgroundColor: '#f472b6',
  },
  nightcoreTint: {
    backgroundColor: '#701a75',
  },
  vividTint: {
    backgroundColor: '#0284c7',
  },
  gridOverlay: {
    ...StyleSheet.absoluteFillObject,
    zIndex: 5,
  },
  gridLine: {
    position: 'absolute',
    backgroundColor: 'rgba(255, 255, 255, 0.25)',
  },
  gridH1: { top: '33.33%', left: 0, right: 0, height: 1 },
  gridH2: { top: '66.66%', left: 0, right: 0, height: 1 },
  gridV1: { left: '33.33%', top: 0, bottom: 0, width: 1 },
  gridV2: { left: '66.66%', top: 0, bottom: 0, width: 1 },
  proDeckContainer: {
    position: 'absolute',
    bottom: 220,
    left: 0,
    right: 0,
    zIndex: 35,
  },
  lowerHud: {
    zIndex: 20,
  },
});
