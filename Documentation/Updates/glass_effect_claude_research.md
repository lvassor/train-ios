# Implementing glass lens refraction and chromatic aberration in iOS 26 SwiftUI

Apple's iOS 26 Clock app showcases a stunning lens distortion effect where the tab bar's sliding pill creates **real pixel displacement** — icons appear warped, magnified, and exhibit rainbow color fringing at the lens edges. However, this specific refraction effect **uses private APIs that third-party developers cannot directly access**. The public `.glassEffect()` modifier provides blur and tinting but not the lens distortion. Recreating this effect requires custom Metal shaders using `.layerEffect()`.

## Apple's implementation relies on private Core Animation layers

The ShatteredGlass reverse-engineering project reveals Apple's internal architecture for Liquid Glass effects. The system constructs a multi-tiered `CALayer` hierarchy with specialized private classes:

```
CustomGlassView (NSView)
└── SwiftUI.SDFLayer
    ├── CABackdropLayer (glassBackground filter)
    │   └── CASDFLayer ("@0") - SDF texture via CASDFOutputEffect
    │       └── CASDFElementLayer - shape definition
    ├── CASDFLayer ("@1") - glass highlight
    └── CASDFLayer ("@2") - glass highlight
```

**CABackdropLayer** renders the primary distorted background using a private `glassBackground` filter that applies refraction, blur, vibrancy, and tone mappings. **CASDFLayer** provides Signed Distance Function textures for shape-aware rendering, while **CASDFGlassHighlightEffect** creates the edge lighting simulation. These private APIs — including `CASDFOutputEffect`, `vibrantColorMatrix`, and the entire SDF pipeline — are **not available to third-party developers**.

Linear's engineering team confirmed this limitation explicitly: "The one effect we chose not to reproduce was Liquid Glass's refraction. Technically, it requires access to pixel-level data that isn't available to third-party developers."

## The public SwiftUI glass API provides appearance, not distortion

The `.glassEffect()` modifier introduced in iOS 26 offers blur/frosting, adaptive tinting, specular highlights, and interactive response animations — but **excludes the refraction/lensing effect**. Standard TabView automatically adopts Liquid Glass styling when compiled with Xcode 26, gaining the glass material appearance without requiring code changes:

```swift
Text("Hello, Liquid Glass!")
    .padding()
    .glassEffect(.regular.interactive(), in: .capsule)
```

Glass effect variants include `.regular` (standard), `.clear` (more transparent), and `.identity` (disabled). The `GlassEffectContainer` wrapper enables multiple glass elements to interact correctly since glass material cannot sample other glass. For morphing transitions between glass elements, use `glassEffectID(_:in:)` with a namespace.

## Custom Metal shaders enable refraction through pixel displacement

SwiftUI's `.layerEffect()` modifier (iOS 17+) provides the foundation for recreating lens distortion using custom Metal shaders. The key technique samples pixels at offset positions using `layer.sample(position + offset)`:

```metal
#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]] half4 glassLensWithChromatic(
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
```

The SwiftUI integration requires specifying `maxSampleOffset` to account for maximum pixel displacement:

```swift
Image("content")
    .drawingGroup()
    .layerEffect(
        ShaderLibrary.glassLensWithChromatic(
            .float2(lensPosition),
            .float(50),    // radius
            .float(1.5),   // magnification
            .float(0.02)   // chromatic strength
        ),
        maxSampleOffset: CGSize(width: 100, height: 100)
    )
```

## The mathematics of parabolic lens distortion

The **`1 - r²`** formula creates smooth, physically-plausible lens falloff where `r` is the normalized distance from center (0 at center, 1 at edge). This produces maximum distortion at the lens center that diminishes smoothly toward the boundary:

| r (normalized distance) | Distortion factor (1 - r²) |
|------------------------|---------------------------|
| 0.0 (center) | 1.0 (full effect) |
| 0.5 (midpoint) | 0.75 |
| 0.7 | 0.51 |
| 1.0 (edge) | 0.0 (no effect) |

Alternative distortion models include **barrel distortion** using `pow(radius, BarrelPower)` for fisheye effects, and the **polynomial radial model** `1 + k1*r² + k2*r⁴ + k3*r⁶` used in camera calibration (OpenCV model).

For glass marble/water droplet effects with physically-based refraction, implement simplified Snell's Law:

```metal
float z = sqrt(1.0 - r * r);  // sphere surface normal z-component
float eta = 1.0 / ior;        // ior ~1.5 for glass
float2 refractedOffset = offset * (1.0 - eta * z);
```

## Chromatic aberration separates RGB channels spatially

The rainbow fringing effect at lens edges comes from sampling red, green, and blue channels at **slightly different positions**. Red wavelengths refract less than blue, so red samples closer to the original position while blue samples further:

```metal
// Radial chromatic aberration
float2 direction = normalize(position - center);
float dist = length(position - center);
float2 multiplier = direction * dist;

half4 result;
result.r = layer.sample(position + multiplier * 0.009).r;   // red: small offset
result.g = layer.sample(position + multiplier * 0.006).g;   // green: medium
result.b = layer.sample(position - multiplier * 0.006).b;   // blue: opposite
```

The twostraws/Inferno library (2.7k stars) includes a "Color Planes" shader demonstrating this RGB separation technique, while the Czajnikowski/GlassEffect repository provides a complete SwiftUI glass effect with both refraction and Fresnel reflections.

## Core Image provides alternative distortion approaches

For developers preferring higher-level APIs, Core Image offers several distortion filters compatible with SwiftUI through manual image conversion:

- **CIBumpDistortion**: Creates concave/convex lens bumps with center, radius, and scale parameters
- **CIGlassDistortion**: Texture-based glass distortion requiring a displacement texture
- **CITorusLensDistortion**: Torus-shaped lens with explicit refraction parameter
- **CIDisplacementDistortion**: General displacement map-based warping

However, Core Image has **no built-in chromatic aberration filter** — this requires custom `CIKernel` implementation. Integration with SwiftUI requires the conversion chain: `CIImage → CGImage → UIImage → Image`, making it less suitable for real-time interactive effects than direct Metal shaders.

**Important limitation**: `CALayer.backgroundFilters` only works on macOS — iOS ignores these properties entirely, eliminating this as a viable approach for iOS glass effects.

## Third-party resources for implementation reference

Victor Baro's Metal shader course at **metal.graphics** covers refraction implementation including Snell's Law simulation, radial falloff mathematics, and SDF-based "gooey" organic animations. His Medium posts on "Implementing a Refractive Glass Shader in Metal" and "SDF in Metal: Adding the Liquid to the Glass" provide detailed code walkthroughs.

The **twostraws/Inferno** GitHub repository offers production-ready SwiftUI Metal shaders including "Warping Loupe" (glass orb zoom effect) and "Bubble" (soap bubble refraction). The **AlexStrNik/ShatteredGlass** project reverse-engineers Apple's private Liquid Glass APIs, documenting the exact layer hierarchy and filter parameters used internally.

## Conclusion

Replicating the iOS 26 Clock app's tab bar lens distortion requires custom Metal shader implementation since Apple's public `.glassEffect()` excludes refraction capabilities. The core technique combines **parabolic displacement** using `layer.sample(position + offset * (1 - r²) * strength)` with **RGB channel separation** for chromatic aberration. While Apple's system-level implementation uses sophisticated private APIs including CABackdropLayer and CASDFLayer hierarchies, developers can achieve visually similar results through SwiftUI's `.layerEffect()` modifier with carefully tuned shader parameters. The mathematical foundation — parabolic falloff for natural lens behavior plus wavelength-dependent sampling offsets for color fringing — translates directly into approximately 30-50 lines of Metal shader code.