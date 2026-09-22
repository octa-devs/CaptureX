import React from 'react';
import { View, StyleSheet, ScrollView, TouchableOpacity, Text } from 'react-native';
import { LiquidGlass } from '../ui/LiquidGlass';
import { FILTER_PRESETS, FILTER_CATEGORIES } from '../../shaders/presets';
import { useFilterStore } from '../../store/useFilterStore';
import { AudioHaptics } from '../../services/AudioHapticsService';
import { FilterPreset, FilterCategory } from '../../types';

export const FilterCarousel: React.FC = () => {
  const { selectedPreset, setSelectedPreset, activeCategory, setActiveCategory } = useFilterStore();

  const filteredPresets = FILTER_PRESETS.filter(
    (preset) => activeCategory === 'all' || preset.category === activeCategory
  );

  const handleSelectCategory = (cat: FilterCategory) => {
    AudioHaptics.playDialTick();
    setActiveCategory(cat);
  };

  const handleSelectPreset = (preset: FilterPreset) => {
    AudioHaptics.triggerHaptic('selection');
    setSelectedPreset(preset);
  };

  return (
    <View style={styles.container}>
      {/* Category Tabs */}
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.categoryScroll}
      >
        {FILTER_CATEGORIES.map((cat) => {
          const isActive = activeCategory === cat.id;
          return (
            <TouchableOpacity
              key={cat.id}
              onPress={() => handleSelectCategory(cat.id as FilterCategory)}
              activeOpacity={0.7}
              style={styles.catTab}
            >
              <LiquidGlass
                intensity={isActive ? 'accent' : 'light'}
                borderRadius={16}
                style={[styles.catGlass, isActive && styles.catActiveGlass]}
              >
                <Text style={[styles.catText, isActive && styles.catActiveText]}>
                  {cat.label}
                </Text>
              </LiquidGlass>
            </TouchableOpacity>
          );
        })}
      </ScrollView>

      {/* Filter Presets Carousel */}
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.presetScroll}
      >
        {filteredPresets.map((preset) => {
          const isSelected = selectedPreset.id === preset.id;
          return (
            <TouchableOpacity
              key={preset.id}
              onPress={() => handleSelectPreset(preset)}
              activeOpacity={0.8}
              style={styles.cardWrapper}
            >
              <LiquidGlass
                intensity={isSelected ? 'accent' : 'medium'}
                borderRadius={18}
                style={[styles.presetCard, isSelected && styles.selectedPresetCard]}
              >
                {/* Visual Category Accent Dot */}
                <View
                  style={[
                    styles.accentDot,
                    preset.category === 'moody' && { backgroundColor: '#14b8a6' },
                    preset.category === 'dreamy' && { backgroundColor: '#f472b6' },
                    preset.category === 'nightcore' && { backgroundColor: '#a855f7' },
                    preset.category === 'vivid' && { backgroundColor: '#f59e0b' },
                    preset.category === 'film' && { backgroundColor: '#ef4444' },
                    preset.category === 'cinematic' && { backgroundColor: '#38bdf8' },
                  ]}
                />
                
                {preset.badge && (
                  <View style={styles.badgePill}>
                    <Text style={styles.badgeText}>{preset.badge}</Text>
                  </View>
                )}

                <Text
                  style={[styles.presetName, isSelected && styles.selectedPresetName]}
                  numberOfLines={1}
                >
                  {preset.name}
                </Text>
                
                <Text style={styles.presetSub} numberOfLines={1}>
                  {preset.category.toUpperCase()}
                </Text>
              </LiquidGlass>
            </TouchableOpacity>
          );
        })}
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingVertical: 6,
    zIndex: 15,
  },
  categoryScroll: {
    paddingHorizontal: 16,
    gap: 8,
    marginBottom: 8,
  },
  catTab: {
    marginRight: 4,
  },
  catGlass: {
    paddingHorizontal: 14,
    paddingVertical: 6,
  },
  catActiveGlass: {
    borderColor: '#38bdf8',
  },
  catText: {
    color: 'rgba(255, 255, 255, 0.65)',
    fontSize: 12,
    fontWeight: '600',
  },
  catActiveText: {
    color: '#38bdf8',
    fontWeight: '700',
  },
  presetScroll: {
    paddingHorizontal: 16,
    gap: 10,
  },
  cardWrapper: {
    marginRight: 2,
  },
  presetCard: {
    width: 96,
    height: 78,
    padding: 8,
    justifyContent: 'space-between',
    position: 'relative',
  },
  selectedPresetCard: {
    borderColor: '#38bdf8',
    borderWidth: 1.5,
    backgroundColor: 'rgba(56, 189, 248, 0.16)',
  },
  accentDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: '#ffffff',
  },
  badgePill: {
    position: 'absolute',
    top: 6,
    right: 6,
    backgroundColor: 'rgba(255, 255, 255, 0.18)',
    paddingHorizontal: 5,
    paddingVertical: 2,
    borderRadius: 6,
  },
  badgeText: {
    color: '#ffffff',
    fontSize: 8,
    fontWeight: '800',
  },
  presetName: {
    color: '#ffffff',
    fontSize: 12,
    fontWeight: '700',
    marginTop: 6,
  },
  selectedPresetName: {
    color: '#38bdf8',
  },
  presetSub: {
    color: 'rgba(255, 255, 255, 0.45)',
    fontSize: 9,
    fontWeight: '600',
    letterSpacing: 0.5,
  },
});
