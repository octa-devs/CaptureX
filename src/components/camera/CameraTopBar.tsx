import React from 'react';
import { View, StyleSheet, TouchableOpacity, Text } from 'react-native';
import { LiquidGlass } from '../ui/LiquidGlass';
import { useCameraStore } from '../../store/useCameraStore';
import { AudioHaptics } from '../../services/AudioHapticsService';

interface CameraTopBarProps {
  onOpenSettings: () => void;
  onToggleProDeck: () => void;
  isProDeckOpen: boolean;
}

export const CameraTopBar: React.FC<CameraTopBarProps> = ({
  onOpenSettings,
  onToggleProDeck,
  isProDeckOpen,
}) => {
  const {
    flashMode,
    setFlashMode,
    timer,
    setTimer,
    aspectRatio,
    setAspectRatio,
    gridEnabled,
    toggleGrid,
    rawModeEnabled,
    toggleRawMode,
    hdrEnabled,
    toggleHdr,
  } = useCameraStore();

  const cycleFlash = () => {
    AudioHaptics.playDialTick();
    const modes: ('off' | 'auto' | 'on' | 'torch')[] = ['off', 'auto', 'on', 'torch'];
    const nextIndex = (modes.indexOf(flashMode) + 1) % modes.length;
    setFlashMode(modes[nextIndex]);
  };

  const cycleTimer = () => {
    AudioHaptics.playDialTick();
    const timers: (0 | 3 | 10)[] = [0, 3, 10];
    const nextIndex = (timers.indexOf(timer) + 1) % timers.length;
    setTimer(timers[nextIndex]);
  };

  const cycleAspect = () => {
    AudioHaptics.playDialTick();
    const ratios: ('4:3' | '16:9' | '1:1' | 'full')[] = ['4:3', '16:9', '1:1', 'full'];
    const nextIndex = (ratios.indexOf(aspectRatio) + 1) % ratios.length;
    setAspectRatio(ratios[nextIndex]);
  };

  return (
    <View style={styles.container}>
      <LiquidGlass intensity="medium" borderRadius={20} style={styles.bar}>
        {/* Flash Mode Toggle */}
        <TouchableOpacity
          style={[styles.btn, flashMode !== 'off' && styles.activeBtn]}
          onPress={cycleFlash}
          activeOpacity={0.7}
        >
          <Text style={[styles.btnText, flashMode !== 'off' && styles.activeText]}>
            ⚡ {flashMode.toUpperCase()}
          </Text>
        </TouchableOpacity>

        {/* Timer Toggle */}
        <TouchableOpacity
          style={[styles.btn, timer > 0 && styles.activeBtn]}
          onPress={cycleTimer}
          activeOpacity={0.7}
        >
          <Text style={[styles.btnText, timer > 0 && styles.activeText]}>
            ⏱ {timer === 0 ? 'OFF' : `${timer}s`}
          </Text>
        </TouchableOpacity>

        {/* Aspect Ratio */}
        <TouchableOpacity style={styles.btn} onPress={cycleAspect} activeOpacity={0.7}>
          <Text style={styles.btnText}>{aspectRatio}</Text>
        </TouchableOpacity>

        {/* HDR / RAW Button */}
        <TouchableOpacity
          style={[styles.btn, (rawModeEnabled || hdrEnabled) && styles.badgeBtn]}
          onPress={() => {
            AudioHaptics.playDialTick();
            toggleRawMode();
          }}
          activeOpacity={0.7}
        >
          <Text style={styles.badgeText}>{rawModeEnabled ? 'RAW' : 'HDR'}</Text>
        </TouchableOpacity>

        {/* Grid & Leveler */}
        <TouchableOpacity
          style={[styles.btn, gridEnabled && styles.activeBtn]}
          onPress={() => {
            AudioHaptics.playDialTick();
            toggleGrid();
          }}
          activeOpacity={0.7}
        >
          <Text style={[styles.btnText, gridEnabled && styles.activeText]}>#</Text>
        </TouchableOpacity>

        {/* Pro Color Tweaker Deck Toggle */}
        <TouchableOpacity
          style={[styles.btn, isProDeckOpen && styles.proActiveBtn]}
          onPress={() => {
            AudioHaptics.playDialTick();
            onToggleProDeck();
          }}
          activeOpacity={0.7}
        >
          <Text style={[styles.btnText, isProDeckOpen && styles.proActiveText]}>PRO</Text>
        </TouchableOpacity>

        {/* Settings */}
        <TouchableOpacity
          style={styles.btn}
          onPress={() => {
            AudioHaptics.playDialTick();
            onOpenSettings();
          }}
          activeOpacity={0.7}
        >
          <Text style={styles.btnText}>⚙️</Text>
        </TouchableOpacity>
      </LiquidGlass>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 16,
    paddingTop: 12,
    zIndex: 20,
  },
  bar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 10,
    paddingVertical: 8,
  },
  btn: {
    paddingHorizontal: 8,
    paddingVertical: 6,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  activeBtn: {
    backgroundColor: 'rgba(255, 255, 255, 0.18)',
  },
  proActiveBtn: {
    backgroundColor: 'rgba(56, 189, 248, 0.25)',
    borderWidth: 1,
    borderColor: '#38bdf8',
  },
  badgeBtn: {
    backgroundColor: 'rgba(244, 63, 94, 0.2)',
    borderWidth: 1,
    borderColor: '#f43f5e',
  },
  btnText: {
    color: '#e2e8f0',
    fontSize: 12,
    fontWeight: '600',
    letterSpacing: 0.4,
  },
  activeText: {
    color: '#ffffff',
    fontWeight: '700',
  },
  proActiveText: {
    color: '#38bdf8',
    fontWeight: '700',
  },
  badgeText: {
    color: '#f43f5e',
    fontSize: 11,
    fontWeight: '800',
    letterSpacing: 0.5,
  },
});
