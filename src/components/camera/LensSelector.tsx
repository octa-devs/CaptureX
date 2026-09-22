import React from 'react';
import { View, StyleSheet, TouchableOpacity, Text } from 'react-native';
import { LiquidGlass } from '../ui/LiquidGlass';
import { useCameraStore } from '../../store/useCameraStore';
import { AudioHaptics } from '../../services/AudioHapticsService';
import { CameraLens } from '../../types';

interface LensOption {
  id: CameraLens;
  label: string;
  zoom: number;
}

const LENSES: LensOption[] = [
  { id: 'ultrawide', label: '.5', zoom: 0.5 },
  { id: 'wide', label: '1x', zoom: 1.0 },
  { id: 'telephoto', label: '2x', zoom: 2.0 },
  { id: 'telephoto', label: '3x', zoom: 3.0 },
];

export const LensSelector: React.FC = () => {
  const { lens, zoom, setLens, setZoom } = useCameraStore();

  const handleSelectLens = (option: LensOption) => {
    AudioHaptics.playLensSwitch();
    setLens(option.id);
    setZoom(option.zoom);
  };

  return (
    <View style={styles.container}>
      <LiquidGlass intensity="medium" borderRadius={24} style={styles.pill}>
        {LENSES.map((opt, index) => {
          const isSelected = zoom === opt.zoom;
          return (
            <TouchableOpacity
              key={`${opt.id}-${index}`}
              style={[styles.lensBtn, isSelected && styles.selectedBtn]}
              onPress={() => handleSelectLens(opt)}
              activeOpacity={0.7}
            >
              <Text style={[styles.lensText, isSelected && styles.selectedText]}>
                {opt.label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </LiquidGlass>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    marginVertical: 10,
    zIndex: 10,
  },
  pill: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 6,
    paddingVertical: 4,
  },
  lensBtn: {
    width: 38,
    height: 38,
    borderRadius: 19,
    alignItems: 'center',
    justifyContent: 'center',
    marginHorizontal: 2,
  },
  selectedBtn: {
    backgroundColor: '#ffffff',
    shadowColor: '#ffffff',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 6,
  },
  lensText: {
    color: 'rgba(255, 255, 255, 0.75)',
    fontSize: 13,
    fontWeight: '700',
  },
  selectedText: {
    color: '#090b10',
    fontWeight: '800',
  },
});
