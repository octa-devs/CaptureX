import { Skia } from '@shopify/react-native-skia';

/**
 * CaptureX High-Performance GLSL Fragment Shader
 * Operates in 32-bit floating point color space for real-time 60fps color grading,
 * film grain generation, vignette feathering, and bloom/glow synthesis.
 */
export const MasterColorGradingGLSL = `
uniform shader image;
uniform float u_exposure;      // -1.0 to 1.0
uniform float u_contrast;      // 0.5 to 2.0
uniform float u_saturation;    // 0.0 to 2.5
uniform float u_temperature;   // -1.0 (Cool) to 1.0 (Warm)
uniform float u_tint;          // -1.0 (Green) to 1.0 (Magenta)
uniform float u_highlights;    // -1.0 to 1.0
uniform float u_shadows;       // -1.0 to 1.0
uniform float u_vignette;      // 0.0 to 1.0
uniform float u_grain;         // 0.0 to 1.0
uniform float u_bloom;         // 0.0 to 1.0
uniform float u_neonBoost;     // 0.0 to 1.0
uniform float u_time;          // Time for dynamic film grain
uniform vec2 u_resolution;     // Viewport dimensions

// Pseudo-random number generator for procedural film grain
float rand(vec2 co) {
  return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

// Convert RGB to Rec.709 Luminance
float getLuminance(vec3 color) {
  return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

// Adjust Color Temperature (Kelvin shift) and Tint
vec3 adjustWhiteBalance(vec3 color, float temp, float tint) {
  // Warm shifts towards amber (+R, -B), Cool shifts towards ice (+B, -R)
  vec3 tempAdjust = vec3(temp * 0.12, 0.0, -temp * 0.12);
  // Tint shifts towards magenta (+R, +B, -G) or green (+G, -R, -B)
  vec3 tintAdjust = vec3(tint * 0.08, -tint * 0.12, tint * 0.08);
  return clamp(color + tempAdjust + tintAdjust, 0.0, 1.0);
}

// Highlight and Shadow recovery/crushing
vec3 adjustHighlightsShadows(vec3 color, float highlights, float shadows) {
  float lum = getLuminance(color);
  // Shadow mask: highest at lum=0, fades to 0 at lum=0.5
  float shadowMask = 1.0 - smoothstep(0.0, 0.5, lum);
  // Highlight mask: fades in from lum=0.5 to lum=1.0
  float highlightMask = smoothstep(0.5, 1.0, lum);
  
  vec3 adjusted = color;
  adjusted += color * (shadows * shadowMask * 0.4);
  adjusted += (1.0 - color) * (highlights * highlightMask * 0.4);
  return clamp(adjusted, 0.0, 1.0);
}

// Neon / Cyberpunk color amplification for Nightcore
vec3 applyNeonBoost(vec3 color, float boost) {
  if (boost <= 0.001) return color;
  float maxC = max(color.r, max(color.g, color.b));
  float minC = min(color.r, min(color.g, color.b));
  float delta = maxC - minC;
  
  // Isolate vibrant chromas and boost saturation non-linearly
  vec3 vibrant = color + (color - vec3(getLuminance(color))) * (boost * 1.5);
  // Enhance blues/purples and cyans for night aesthetics
  vibrant.b *= (1.0 + boost * 0.25);
  vibrant.r *= (1.0 + boost * 0.15);
  return clamp(mix(color, vibrant, boost), 0.0, 1.0);
}

// Dreamy Bloom / Glow synthesis
vec3 applyBloomGlow(vec3 color, float bloom) {
  if (bloom <= 0.001) return color;
  float lum = getLuminance(color);
  float glowFactor = smoothstep(0.4, 0.9, lum) * bloom * 0.6;
  vec3 warmGlow = vec3(1.0, 0.96, 0.90) * glowFactor;
  return clamp(color + warmGlow * (1.0 - color), 0.0, 1.0);
}

// Organic Vignette
vec3 applyVignette(vec3 color, vec2 uv, float intensity) {
  if (intensity <= 0.001) return color;
  vec2 center = uv - vec2(0.5);
  float dist = length(center);
  float vignetteMask = smoothstep(0.75, 0.35 * (1.0 - intensity * 0.4), dist);
  return color * mix(1.0, vignetteMask, intensity);
}

// Procedural 35mm Analog Film Grain
vec3 applyFilmGrain(vec3 color, vec2 uv, float grainAmount, float time) {
  if (grainAmount <= 0.001) return color;
  float noise = rand(uv * 2.5 + vec2(time * 0.05, time * 0.03)) - 0.5;
  float lum = getLuminance(color);
  // Film grain is naturally most visible in midtones, less in pure highlights/blacks
  float midtoneMask = 1.0 - abs(lum - 0.5) * 2.0;
  return clamp(color + noise * grainAmount * 0.18 * midtoneMask, 0.0, 1.0);
}

vec4 main(vec2 coord) {
  vec2 uv = coord / u_resolution;
  vec4 original = image.eval(coord);
  vec3 color = original.rgb;
  
  // 1. Exposure adjustment (linear gain)
  color = color * pow(2.0, u_exposure);
  
  // 2. White Balance & Tint
  color = adjustWhiteBalance(color, u_temperature, u_tint);
  
  // 3. Highlight and Shadow tone curves
  color = adjustHighlightsShadows(color, u_highlights, u_shadows);
  
  // 4. Contrast S-Curve
  color = clamp((color - 0.5) * u_contrast + 0.5, 0.0, 1.0);
  
  // 5. Saturation & Vibrance
  float lum = getLuminance(color);
  color = clamp(mix(vec3(lum), color, u_saturation), 0.0, 1.0);
  
  // 6. Nightcore Neon Booster
  color = applyNeonBoost(color, u_neonBoost);
  
  // 7. Dreamy Bloom & Diffusion
  color = applyBloomGlow(color, u_bloom);
  
  // 8. Vignette
  color = applyVignette(color, uv, u_vignette);
  
  // 9. Analog Film Grain
  color = applyFilmGrain(color, uv, u_grain, u_time);
  
  return vec4(color, original.a);
}
`;

export const ColorGradingRuntimeEffect = Skia.RuntimeEffect.Make(MasterColorGradingGLSL);
