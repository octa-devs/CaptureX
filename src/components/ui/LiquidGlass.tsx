import React from 'react';
import { View, StyleSheet, ViewStyle, StyleProp } from 'react-native';

interface LiquidGlassProps {
  children?: React.ReactNode;
  style?: StyleProp<ViewStyle>;
  intensity?: 'ultra-light' | 'light' | 'medium' | 'heavy' | 'accent';
  borderRadius?: number;
  glowColor?: string;
  hasBorder?: boolean;
}

/**
 * CaptureX Liquid Glass UI Component
 * Implements high-end iOS/Android glassmorphism with ambient light refraction,
 * soft specular sheen gradients, and sub-pixel edge borders.
 */
export const LiquidGlass: React.FC<LiquidGlassProps> = ({
  children,
  style,
  intensity = 'medium',
  borderRadius = 24,
  glowColor,
  hasBorder = true,
}) => {
  const getGlassStyle = () => {
    switch (intensity) {
      case 'ultra-light':
        return {
          backgroundColor: 'rgba(255, 255, 255, 0.04)',
          borderColor: 'rgba(255, 255, 255, 0.1)',
        };
      case 'light':
        return {
          backgroundColor: 'rgba(22, 26, 38, 0.45)',
          borderColor: 'rgba(255, 255, 255, 0.14)',
        };
      case 'heavy':
        return {
          backgroundColor: 'rgba(10, 12, 18, 0.85)',
          borderColor: 'rgba(255, 255, 255, 0.22)',
        };
      case 'accent':
        return {
          backgroundColor: 'rgba(56, 189, 248, 0.12)',
          borderColor: 'rgba(56, 189, 248, 0.35)',
        };
      case 'medium':
      default:
        return {
          backgroundColor: 'rgba(16, 20, 30, 0.65)',
          borderColor: 'rgba(255, 255, 255, 0.16)',
        };
    }
  };

  const glassStyle = getGlassStyle();

  return (
    <View
      style={[
        styles.container,
        {
          borderRadius,
          backgroundColor: glassStyle.backgroundColor,
          borderWidth: hasBorder ? 1 : 0,
          borderColor: glassStyle.borderColor,
          shadowColor: glowColor || '#000000',
        },
        style,
      ]}
    >
      {/* Specular Top Reflection Sheen */}
      <View
        style={[
          styles.topSheen,
          {
            borderTopLeftRadius: borderRadius - 1,
            borderTopRightRadius: borderRadius - 1,
          },
        ]}
      />
      {children}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    overflow: 'hidden',
    position: 'relative',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.35,
    shadowRadius: 20,
    elevation: 8,
  },
  topSheen: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    height: 1,
    backgroundColor: 'rgba(255, 255, 255, 0.35)',
    zIndex: 1,
  },
});
