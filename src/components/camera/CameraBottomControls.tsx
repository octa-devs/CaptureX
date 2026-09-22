import React from 'react';
import { View, StyleSheet, TouchableOpacity, Text, Image } from 'react-native';
import { LiquidGlass } from '../ui/LiquidGlass';
import { AudioHaptics } from '../../services/AudioHapticsService';
import { useSettingsStore } from '../../store/useSettingsStore';

interface CameraBottomControlsProps {
  onCapture: () => void;
  onOpenGallery: () => void;
  onFlipCamera: () => void;
  isCapturing?: boolean;
}

export const CameraBottomControls: React.FC<CameraBottomControlsProps> = ({
  onCapture,
  onOpenGallery,
  onFlipCamera,
  isCapturing = false,
}) => {
  const { recentPhotos } = useSettingsStore();
  const latestPhoto = recentPhotos[0];

  const handleCapturePress = () => {
    AudioHaptics.playShutterSound();
    onCapture();
  };

  return (
    <View style={styles.container}>
      <LiquidGlass intensity="medium" borderRadius={36} style={styles.glassBar}>
        {/* Left: Gallery Quick-Access Thumbnail */}
        <TouchableOpacity
          onPress={() => {
            AudioHaptics.triggerHaptic('selection');
            onOpenGallery();
          }}
          activeOpacity={0.7}
          style={styles.thumbWrapper}
        >
          {latestPhoto ? (
            <Image source={{ uri: latestPhoto.uri }} style={styles.thumbImg} />
          ) : (
            <View style={styles.emptyThumb}>
              <Text style={styles.emptyThumbIcon}>🖼️</Text>
            </View>
          )}
        </TouchableOpacity>

        {/* Center: Master Shutter Button */}
        <TouchableOpacity
          onPress={handleCapturePress}
          activeOpacity={0.65}
          style={styles.shutterOuter}
        >
          <View style={[styles.shutterRing, isCapturing && styles.shutterRingCapturing]}>
            <View style={styles.shutterInner}>
              <View style={styles.shutterCore} />
            </View>
          </View>
        </TouchableOpacity>

        {/* Right: Camera Flip / Lens Switch */}
        <TouchableOpacity
          onPress={() => {
            AudioHaptics.playLensSwitch();
            onFlipCamera();
          }}
          activeOpacity={0.7}
          style={styles.flipBtn}
        >
          <LiquidGlass intensity="light" borderRadius={24} style={styles.flipGlass}>
            <Text style={styles.flipIcon}>🔄</Text>
          </LiquidGlass>
        </TouchableOpacity>
      </LiquidGlass>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 20,
    paddingBottom: 24,
    paddingTop: 8,
    zIndex: 25,
  },
  glassBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 24,
    paddingVertical: 14,
  },
  thumbWrapper: {
    width: 52,
    height: 52,
    borderRadius: 26,
    overflow: 'hidden',
    borderWidth: 2,
    borderColor: 'rgba(255, 255, 255, 0.35)',
    backgroundColor: '#0f131a',
  },
  thumbImg: {
    width: '100%',
    height: '100%',
  },
  emptyThumb: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.08)',
  },
  emptyThumbIcon: {
    fontSize: 20,
  },
  shutterOuter: {
    padding: 4,
  },
  shutterRing: {
    width: 78,
    height: 78,
    borderRadius: 39,
    borderWidth: 3.5,
    borderColor: '#ffffff',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.08)',
  },
  shutterRingCapturing: {
    transform: [{ scale: 0.92 }],
    borderColor: '#38bdf8',
  },
  shutterInner: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: '#ffffff',
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#38bdf8',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.45,
    shadowRadius: 10,
  },
  shutterCore: {
    width: 20,
    height: 20,
    borderRadius: 10,
    backgroundColor: '#090b10',
    opacity: 0.1,
  },
  flipBtn: {
    width: 52,
    height: 52,
    alignItems: 'center',
    justifyContent: 'center',
  },
  flipGlass: {
    width: 48,
    height: 48,
    alignItems: 'center',
    justifyContent: 'center',
  },
  flipIcon: {
    fontSize: 20,
  },
});
