import React from 'react';
import { View, StyleSheet, ScrollView, TouchableOpacity, Text, Switch, TextInput } from 'react-native';
import { LiquidGlass } from '../ui/LiquidGlass';
import { useSettingsStore } from '../../store/useSettingsStore';
import { AudioHaptics } from '../../services/AudioHapticsService';

interface SettingsModalProps {
  onClose: () => void;
}

export const SettingsModal: React.FC<SettingsModalProps> = ({ onClose }) => {
  const {
    watermark,
    setWatermarkEnabled,
    setWatermarkText,
    setWatermarkLogo,
    setWatermarkExif,
    setWatermarkPosition,
    setWatermarkOpacity,
    hapticsEnabled,
    setHapticsEnabled,
    shutterSoundEnabled,
    setShutterSoundEnabled,
  } = useSettingsStore();

  return (
    <View style={styles.backdrop}>
      <LiquidGlass intensity="heavy" borderRadius={32} style={styles.card}>
        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.title}>CAPTUREX SETTINGS</Text>
          <TouchableOpacity onPress={onClose} style={styles.closeBtn}>
            <Text style={styles.closeText}>✕</Text>
          </TouchableOpacity>
        </View>

        <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.content}>
          {/* SECTION 1: WATERMARK ENGINE */}
          <Text style={styles.sectionHeader}>WATERMARK ENGINE</Text>
          <LiquidGlass intensity="light" borderRadius={20} style={styles.sectionCard}>
            {/* Toggle Watermark */}
            <View style={styles.row}>
              <View>
                <Text style={styles.rowTitle}>Automatic Watermark</Text>
                <Text style={styles.rowSubtitle}>Overlay stylish branding on captured photos</Text>
              </View>
              <Switch
                value={watermark.enabled}
                onValueChange={(val) => {
                  AudioHaptics.triggerHaptic('selection');
                  setWatermarkEnabled(val);
                }}
                trackColor={{ false: '#334155', true: '#38bdf8' }}
              />
            </View>

            {watermark.enabled && (
              <>
                <View style={styles.divider} />

                {/* Watermark Text */}
                <View style={styles.settingBlock}>
                  <Text style={styles.blockLabel}>Watermark Text</Text>
                  <TextInput
                    style={styles.textInput}
                    value={watermark.text}
                    onChangeText={setWatermarkText}
                    placeholder="Shot with CaptureX"
                    placeholderTextColor="#64748b"
                  />
                </View>

                {/* Show Logo Switch */}
                <View style={styles.row}>
                  <Text style={styles.rowTitle}>Include CaptureX Logo</Text>
                  <Switch
                    value={watermark.showLogo}
                    onValueChange={setWatermarkLogo}
                    trackColor={{ false: '#334155', true: '#38bdf8' }}
                  />
                </View>

                {/* Show EXIF Specs */}
                <View style={styles.row}>
                  <Text style={styles.rowTitle}>Display EXIF Shooting Specs</Text>
                  <Switch
                    value={watermark.showExif}
                    onValueChange={setWatermarkExif}
                    trackColor={{ false: '#334155', true: '#38bdf8' }}
                  />
                </View>

                {/* Position Picker */}
                <View style={styles.settingBlock}>
                  <Text style={styles.blockLabel}>Position</Text>
                  <View style={styles.positionGrid}>
                    {(['bottom-right', 'bottom-left', 'bottom-center', 'top-right'] as const).map(
                      (pos) => {
                        const isSelected = watermark.position === pos;
                        return (
                          <TouchableOpacity
                            key={pos}
                            onPress={() => {
                              AudioHaptics.playDialTick();
                              setWatermarkPosition(pos);
                            }}
                            style={[styles.posBtn, isSelected && styles.posBtnSelected]}
                          >
                            <Text style={[styles.posBtnText, isSelected && styles.posBtnTextActive]}>
                              {pos.replace('-', ' ').toUpperCase()}
                            </Text>
                          </TouchableOpacity>
                        );
                      }
                    )}
                  </View>
                </View>

                {/* Opacity Slider */}
                <View style={styles.settingBlock}>
                  <View style={styles.labelRow}>
                    <Text style={styles.blockLabel}>Badge Opacity</Text>
                    <Text style={styles.valText}>{Math.round(watermark.opacity * 100)}%</Text>
                  </View>
                  <input
                    type="range"
                    min="20"
                    max="100"
                    value={Math.round(watermark.opacity * 100)}
                    onChange={(e) => setWatermarkOpacity(Number(e.target.value) / 100)}
                    style={{ width: '100%', accentColor: '#38bdf8', height: 6 }}
                  />
                </View>
              </>
            )}
          </LiquidGlass>

          {/* SECTION 2: AUDIO & HAPTICS */}
          <Text style={styles.sectionHeader}>AUDIO & HAPTIC EXPERIENCE</Text>
          <LiquidGlass intensity="light" borderRadius={20} style={styles.sectionCard}>
            <View style={styles.row}>
              <View>
                <Text style={styles.rowTitle}>Mechanical Shutter Sound</Text>
                <Text style={styles.rowSubtitle}>Simulates realistic focal-plane shutter</Text>
              </View>
              <Switch
                value={shutterSoundEnabled}
                onValueChange={(val) => {
                  setShutterSoundEnabled(val);
                  AudioHaptics.setSoundEnabled(val);
                }}
                trackColor={{ false: '#334155', true: '#38bdf8' }}
              />
            </View>

            <View style={styles.divider} />

            <View style={styles.row}>
              <View>
                <Text style={styles.rowTitle}>Tactile Haptic Feedback</Text>
                <Text style={styles.rowSubtitle}>Physical clicks on dials, lenses, and shutter</Text>
              </View>
              <Switch
                value={hapticsEnabled}
                onValueChange={(val) => {
                  setHapticsEnabled(val);
                  AudioHaptics.setHapticsEnabled(val);
                }}
                trackColor={{ false: '#334155', true: '#38bdf8' }}
              />
            </View>
          </LiquidGlass>

          {/* SECTION 3: PRO SYSTEM INFO */}
          <Text style={styles.sectionHeader}>SYSTEM & PIPELINE</Text>
          <LiquidGlass intensity="light" borderRadius={20} style={styles.sectionCard}>
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Shader Engine</Text>
              <Text style={styles.infoVal}>Skia 32-bit Float GLSL</Text>
            </View>
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Color Space</Text>
              <Text style={styles.infoVal}>Display P3 / sRGB Wide Gamut</Text>
            </View>
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Version</Text>
              <Text style={styles.infoVal}>CaptureX v1.0.0 Pro</Text>
            </View>
          </LiquidGlass>
        </ScrollView>
      </LiquidGlass>
    </View>
  );
};

const styles = StyleSheet.create({
  backdrop: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0, 0, 0, 0.75)',
    zIndex: 100,
    justifyContent: 'center',
    padding: 20,
  },
  card: {
    maxHeight: '90%',
    padding: 20,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  title: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '800',
    letterSpacing: 1.5,
  },
  closeBtn: {
    padding: 6,
  },
  closeText: {
    color: '#94a3b8',
    fontSize: 16,
    fontWeight: '700',
  },
  content: {
    paddingBottom: 16,
  },
  sectionHeader: {
    color: '#38bdf8',
    fontSize: 11,
    fontWeight: '800',
    letterSpacing: 1.2,
    marginTop: 16,
    marginBottom: 8,
  },
  sectionCard: {
    padding: 16,
    gap: 12,
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  rowTitle: {
    color: '#ffffff',
    fontSize: 14,
    fontWeight: '600',
  },
  rowSubtitle: {
    color: 'rgba(255, 255, 255, 0.45)',
    fontSize: 11,
    marginTop: 2,
  },
  divider: {
    height: 1,
    backgroundColor: 'rgba(255, 255, 255, 0.08)',
    marginVertical: 4,
  },
  settingBlock: {
    gap: 6,
  },
  labelRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  blockLabel: {
    color: '#cbd5e1',
    fontSize: 12,
    fontWeight: '600',
  },
  valText: {
    color: '#38bdf8',
    fontSize: 12,
    fontWeight: '700',
    fontFamily: 'monospace',
  },
  textInput: {
    backgroundColor: 'rgba(255, 255, 255, 0.08)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.15)',
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 8,
    color: '#ffffff',
    fontSize: 13,
  },
  positionGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  posBtn: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 10,
    backgroundColor: 'rgba(255, 255, 255, 0.06)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.12)',
  },
  posBtnSelected: {
    backgroundColor: 'rgba(56, 189, 248, 0.2)',
    borderColor: '#38bdf8',
  },
  posBtnText: {
    color: 'rgba(255, 255, 255, 0.6)',
    fontSize: 10,
    fontWeight: '700',
  },
  posBtnTextActive: {
    color: '#38bdf8',
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 4,
  },
  infoLabel: {
    color: 'rgba(255, 255, 255, 0.5)',
    fontSize: 12,
  },
  infoVal: {
    color: '#ffffff',
    fontSize: 12,
    fontWeight: '600',
  },
});
