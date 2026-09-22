import React, { useState } from 'react';
import { View, StyleSheet, ScrollView, TouchableOpacity, Text, Slider } from 'react-native';
import { LiquidGlass } from '../ui/LiquidGlass';
import { useFilterStore } from '../../store/useFilterStore';
import { AudioHaptics } from '../../services/AudioHapticsService';
import { ManualAdjustments } from '../../types';

interface ToolItem {
  id: keyof ManualAdjustments;
  label: string;
  icon: string;
  min: number;
  max: number;
  unit: string;
}

const TOOLS: ToolItem[] = [
  { id: 'exposure', label: 'Exposure', icon: '☀️', min: -100, max: 100, unit: 'EV' },
  { id: 'contrast', label: 'Contrast', icon: '◐', min: -100, max: 100, unit: '%' },
  { id: 'saturation', label: 'Saturation', icon: '🎨', min: -100, max: 100, unit: '%' },
  { id: 'temperature', label: 'Temp', icon: '🌡️', min: -100, max: 100, unit: 'K' },
  { id: 'tint', label: 'Tint', icon: '🧪', min: -100, max: 100, unit: '' },
  { id: 'vignette', label: 'Vignette', icon: '🔘', min: 0, max: 100, unit: '%' },
  { id: 'grain', label: 'Grain', icon: '✨', min: 0, max: 100, unit: '%' },
  { id: 'bloom', label: 'Dream Glow', icon: '💫', min: 0, max: 100, unit: '%' },
  { id: 'sharpness', label: 'Clarity', icon: '💎', min: 0, max: 100, unit: '%' },
];

export const ManualAdjustmentBar: React.FC<{ onClose: () => void }> = ({ onClose }) => {
  const { manualAdjustments, setManualAdjustment, resetAdjustments } = useFilterStore();
  const [activeTool, setActiveTool] = useState<keyof ManualAdjustments>('exposure');

  const currentTool = TOOLS.find((t) => t.id === activeTool) || TOOLS[0];
  const currentValue = manualAdjustments[activeTool];

  const handleValueChange = (val: number) => {
    AudioHaptics.playDialTick();
    setManualAdjustment(activeTool, Math.round(val));
  };

  return (
    <LiquidGlass intensity="heavy" borderRadius={28} style={styles.container}>
      {/* Header & Reset */}
      <View style={styles.header}>
        <TouchableOpacity
          onPress={() => {
            AudioHaptics.triggerHaptic('medium');
            resetAdjustments();
          }}
          style={styles.headerBtn}
        >
          <Text style={styles.resetText}>RESET</Text>
        </TouchableOpacity>

        <Text style={styles.title}>PRO COLOR STUDIO</Text>

        <TouchableOpacity onPress={onClose} style={styles.headerBtn}>
          <Text style={styles.closeText}>✕</Text>
        </TouchableOpacity>
      </View>

      {/* Active Slider Readout */}
      <View style={styles.sliderSection}>
        <View style={styles.valueRow}>
          <Text style={styles.toolName}>{currentTool.label.toUpperCase()}</Text>
          <Text style={styles.valBadge}>
            {currentValue > 0 ? `+${currentValue}` : currentValue} {currentTool.unit}
          </Text>
        </View>

        {/* Dynamic Dial Slider */}
        <View style={styles.sliderTrack}>
          <input
            type="range"
            min={currentTool.min}
            max={currentTool.max}
            value={currentValue}
            onChange={(e) => handleValueChange(Number(e.target.value))}
            style={{
              width: '100%',
              accentColor: '#38bdf8',
              cursor: 'pointer',
              height: 6,
            }}
          />
        </View>
      </View>

      {/* Tool Selector Horizontal Scroll */}
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.toolList}
      >
        {TOOLS.map((tool) => {
          const isSelected = activeTool === tool.id;
          const isModified = manualAdjustments[tool.id] !== 0;

          return (
            <TouchableOpacity
              key={tool.id}
              onPress={() => {
                AudioHaptics.triggerHaptic('selection');
                setActiveTool(tool.id);
              }}
              activeOpacity={0.7}
              style={[styles.toolBtn, isSelected && styles.toolBtnActive]}
            >
              <Text style={styles.toolIcon}>{tool.icon}</Text>
              <Text style={[styles.toolLabel, isSelected && styles.toolLabelActive]}>
                {tool.label}
              </Text>
              {isModified && <View style={styles.modifiedDot} />}
            </TouchableOpacity>
          );
        })}
      </ScrollView>
    </LiquidGlass>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 16,
    marginHorizontal: 12,
    marginBottom: 8,
    zIndex: 30,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  headerBtn: {
    padding: 6,
  },
  title: {
    color: '#94a3b8',
    fontSize: 11,
    fontWeight: '800',
    letterSpacing: 1.2,
  },
  resetText: {
    color: '#f43f5e',
    fontSize: 11,
    fontWeight: '700',
  },
  closeText: {
    color: '#ffffff',
    fontSize: 14,
    fontWeight: '700',
  },
  sliderSection: {
    backgroundColor: 'rgba(255, 255, 255, 0.04)',
    borderRadius: 16,
    padding: 12,
    marginBottom: 12,
  },
  valueRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  toolName: {
    color: '#ffffff',
    fontSize: 13,
    fontWeight: '700',
  },
  valBadge: {
    color: '#38bdf8',
    fontSize: 13,
    fontWeight: '800',
    fontFamily: 'monospace',
  },
  sliderTrack: {
    paddingVertical: 6,
  },
  toolList: {
    gap: 8,
  },
  toolBtn: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 14,
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    minWidth: 70,
    position: 'relative',
  },
  toolBtnActive: {
    backgroundColor: 'rgba(56, 189, 248, 0.18)',
    borderWidth: 1,
    borderColor: '#38bdf8',
  },
  toolIcon: {
    fontSize: 18,
    marginBottom: 4,
  },
  toolLabel: {
    color: 'rgba(255, 255, 255, 0.65)',
    fontSize: 10,
    fontWeight: '600',
  },
  toolLabelActive: {
    color: '#ffffff',
    fontWeight: '700',
  },
  modifiedDot: {
    position: 'absolute',
    top: 6,
    right: 6,
    width: 5,
    height: 5,
    borderRadius: 2.5,
    backgroundColor: '#38bdf8',
  },
});
