//
//  GlassLens.metal
//  trAInSwift
//
//  Glass lens refraction shader with chromatic aberration
//  Based on research: proper parabolic (1-r²) distortion formula
//
//  KEY INSIGHT: Maximum displacement at CENTER, zero at EDGE
//  This creates magnification effect, not edge-only warping
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// MARK: - Capsule Signed Distance Function
// Returns negative inside, positive outside

float capsuleSDF(float2 p, float2 center, float2 size) {
    float halfWidth = size.x * 0.5;
    float halfHeight = size.y * 0.5;
    float radius = halfHeight;

    float2 offset = p - center;
    float clampedX = clamp(offset.x, -halfWidth + radius, halfWidth - radius);
    float2 nearest = float2(clampedX, 0.0);

    return length(offset - nearest) - radius;
}

// MARK: - Main Glass Lens with Chromatic Aberration
//
// This shader implements the research-based approach:
// 1. Parabolic distortion: falloff = 1 - r² (max at center, zero at edge)
// 2. Chromatic aberration: RGB sampled at different offsets
// 3. Soft edge transition to blend with surroundings

[[stitchable]] half4 glassLensRefraction(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float2 pillCenter,
    float2 pillSize,
    float magnification,       // e.g., 1.15 = 15% magnification at center
    float chromaticStrength,   // e.g., 0.02 = subtle rainbow fringing
    float edgeSoftness,        // Pixels of soft edge transition
    float isActive             // 1.0 when dragging, 0.0 at rest
) {
    // Calculate signed distance to capsule
    float dist = capsuleSDF(position, pillCenter, pillSize);

    // OUTSIDE THE PILL - return original pixel unchanged
    if (dist > edgeSoftness) {
        return layer.sample(position);
    }

    // SOFT EDGE TRANSITION (within edgeSoftness pixels of boundary)
    float edgeBlend = 1.0;
    if (dist > 0.0) {
        edgeBlend = 1.0 - smoothstep(0.0, edgeSoftness, dist);
    }

    // INSIDE THE PILL - calculate refraction displacement

    // Convert SDF distance to normalized radius within pill
    // dist is negative inside, so -dist is positive distance from edge
    float maxRadius = min(pillSize.x, pillSize.y) * 0.5;
    float r = clamp((-dist) / maxRadius, 0.0, 1.0);

    // Invert r so 0 = at edge, 1 = at center
    // Then apply parabolic falloff: (1 - r²) where r is now distance from CENTER
    float rFromCenter = 1.0 - r;  // 0 at center, 1 at edge
    float falloff = 1.0 - rFromCenter * rFromCenter;  // 1 at center, 0 at edge

    // Direction from pixel toward lens center (for radial displacement)
    float2 toCenter = pillCenter - position;
    float distToCenter = length(toCenter);
    float2 direction = distToCenter > 0.001 ? normalize(toCenter) : float2(0.0, 1.0);

    // Active state increases the effect
    float activeMag = mix(magnification, magnification * 1.3, isActive);
    float activeChromatic = mix(chromaticStrength, chromaticStrength * 1.5, isActive);

    // Base displacement: pulls pixels INWARD (toward center) for magnification
    // Negative magnification would push outward (minification)
    float baseDisplacement = falloff * (activeMag - 1.0) * distToCenter * edgeBlend;

    // CHROMATIC ABERRATION: Red bends less, Blue bends more
    float redDisplacement = baseDisplacement * (1.0 - activeChromatic);
    float greenDisplacement = baseDisplacement;
    float blueDisplacement = baseDisplacement * (1.0 + activeChromatic);

    // Calculate sample positions for each channel
    // We sample from position MINUS displacement because we're pulling pixels toward center
    float2 redPos = position + direction * redDisplacement;
    float2 greenPos = position + direction * greenDisplacement;
    float2 bluePos = position + direction * blueDisplacement;

    // Sample each channel from its displaced position
    half4 result;
    result.r = layer.sample(redPos).r;
    result.g = layer.sample(greenPos).g;
    result.b = layer.sample(bluePos).b;
    result.a = layer.sample(position).a;  // Alpha from original position

    // MARK: - Rim Highlight (Specular reflection on glass edge)

    float rimStart = maxRadius * 0.7;  // Start rim at 70% from center
    float rimDist = -dist;  // Distance from edge (0 at edge, increases inward)
    float rimZone = smoothstep(rimStart, 0.0, rimDist);  // 1 at edge, 0 at 70% in

    // Directional lighting from upper-left
    float2 lightDir = normalize(float2(-0.5, -0.7));
    float rimBias = dot(-direction, lightDir);  // How aligned is edge normal with light
    rimBias = clamp(rimBias * 0.5 + 0.5, 0.0, 1.0);  // Remap to 0-1

    // Specular highlight
    half3 rimColor = half3(1.0, 1.0, 1.05);  // Slightly blue tint
    float rimIntensity = rimZone * rimBias * 0.4 * mix(0.5, 1.0, isActive);

    result.rgb += rimColor * rimIntensity * edgeBlend;

    // Subtle shadow on opposite side
    float shadowIntensity = rimZone * (1.0 - rimBias) * 0.15 * mix(0.5, 1.0, isActive);
    result.rgb *= (1.0 - shadowIntensity * edgeBlend);

    // Blend with original at soft edge
    if (dist > 0.0) {
        half4 original = layer.sample(position);
        result = mix(original, result, edgeBlend);
    }

    return result;
}

// MARK: - Punchthrough Shader for Two-Layer System
//
// Applied to the GREY foreground layer.
// Makes the lens area transparent while applying refraction to what shows through.
// The refraction happens on the grey layer content - pulling it aside to reveal accent beneath.

[[stitchable]] half4 glassLensPunchthrough(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float2 pillCenter,
    float2 pillSize,
    float magnification,
    float chromaticStrength,
    float edgeSoftness,
    float isActive
) {
    float dist = capsuleSDF(position, pillCenter, pillSize);

    // Well outside pill - return original grey icons unchanged
    if (dist > edgeSoftness) {
        return layer.sample(position);
    }

    // Near or inside pill - calculate how much to show/hide
    float maxRadius = min(pillSize.x, pillSize.y) * 0.5;

    if (dist > 0.0) {
        // Soft edge: fade out grey layer as we approach pill
        half4 original = layer.sample(position);
        float fade = smoothstep(0.0, edgeSoftness, dist);
        original.a *= fade;
        return original;
    }

    // Inside the pill - apply refraction to push grey pixels aside
    // This creates the effect of seeing "through" the lens to the accent beneath

    float r = clamp((-dist) / maxRadius, 0.0, 1.0);
    float rFromCenter = 1.0 - r;
    float falloff = 1.0 - rFromCenter * rFromCenter;

    float2 toCenter = pillCenter - position;
    float distToCenter = length(toCenter);
    float2 direction = distToCenter > 0.001 ? normalize(toCenter) : float2(0.0, 1.0);

    float activeMag = mix(magnification, magnification * 1.3, isActive);
    float activeChromatic = mix(chromaticStrength, chromaticStrength * 1.5, isActive);

    // For punchthrough, we want to push grey pixels OUTWARD (away from center)
    // so that the accent icons beneath appear magnified
    // Displacement is NEGATIVE (opposite of normal refraction)
    float baseDisplacement = -falloff * (activeMag - 1.0) * distToCenter;

    // Chromatic aberration
    float redDisplacement = baseDisplacement * (1.0 - activeChromatic);
    float greenDisplacement = baseDisplacement;
    float blueDisplacement = baseDisplacement * (1.0 + activeChromatic);

    float2 redPos = position + direction * redDisplacement;
    float2 greenPos = position + direction * greenDisplacement;
    float2 bluePos = position + direction * blueDisplacement;

    // Sample displaced grey content
    half4 greyContent;
    greyContent.r = layer.sample(redPos).r;
    greyContent.g = layer.sample(greenPos).g;
    greyContent.b = layer.sample(bluePos).b;
    greyContent.a = layer.sample(greenPos).a;  // Use green's alpha (middle displacement)

    // The key insight: grey content gets pushed aside, revealing accent beneath
    // We reduce alpha proportionally to how much displacement occurred
    // More displacement = more transparency = more accent visible
    float transparency = falloff * 0.95;  // 95% transparent at center
    greyContent.a *= (1.0 - transparency);

    // Add rim highlights at lens edge for glass appearance
    float rimDist = -dist;
    float rimWidth = maxRadius * 0.25;
    float rimFade = smoothstep(rimWidth, 0.0, rimDist);

    float2 lightDir = normalize(float2(-0.5, -0.7));
    float rimBias = dot(-direction, lightDir);
    rimBias = clamp(rimBias * 0.5 + 0.5, 0.0, 1.0);

    half3 rimColor = half3(1.1, 1.1, 1.15);
    float rimIntensity = rimFade * rimBias * 0.35 * mix(0.5, 1.0, isActive);

    // Overlay rim highlight
    greyContent.rgb = greyContent.rgb + rimColor * rimIntensity * (1.0h - greyContent.a);
    greyContent.a = max(greyContent.a, half(rimIntensity * 0.5));

    return greyContent;
}

// MARK: - Single Layer Full Refraction
//
// For cases where we want to apply refraction to ALL content (not two-layer system).
// This is the "pure" implementation matching the research exactly.

[[stitchable]] half4 glassLensFull(
    float2 position,
    SwiftUI::Layer layer,
    float2 center,
    float radius,
    float magnification,
    float chromaticStrength
) {
    float2 fromCenter = position - center;
    float dist = length(fromCenter);
    float r = dist / radius;

    // Outside lens - no effect
    if (r >= 1.0) return layer.sample(position);

    // Parabolic lens distortion: (1 - r²) falloff
    float falloff = 1.0 - r * r;

    float2 direction = (dist > 0.001) ? fromCenter / dist : float2(0.0);
    float baseDisplacement = falloff * (magnification - 1.0) * dist;

    // Chromatic aberration: sample RGB at different offsets
    float redDisplacement = baseDisplacement * (1.0 + chromaticStrength);
    float greenDisplacement = baseDisplacement;
    float blueDisplacement = baseDisplacement * (1.0 - chromaticStrength);

    float2 redPos = center + direction * (dist - redDisplacement);
    float2 greenPos = center + direction * (dist - greenDisplacement);
    float2 bluePos = center + direction * (dist - blueDisplacement);

    half4 result;
    result.r = layer.sample(redPos).r;
    result.g = layer.sample(greenPos).g;
    result.b = layer.sample(bluePos).b;
    result.a = layer.sample(position).a;

    return result;
}
