# Video Interstitials Test Plan

## PR #4: Video Interstitials Implementation

### Components Created:
1. **VideoBackgroundView** - Reusable video background component
2. **VideoInterstitialView** - Swipeable interstitial screens

### Features:
- **Seamless Video Looping**: Using AVPlayerLooper for infinite playback
- **No Audio**: Videos are muted for background use
- **Aspect Fill**: Videos fill screen maintaining aspect ratio
- **Gradient Overlay**: Clear to black (0.85 opacity) from center to bottom
- **Swipe Navigation**: Left swipe or NEXT button to advance
- **Premium Feel**: Bold typography with Train accent colors

### Video Integration:
- **Videos**: `onboarding_first.mov` and `onboarding_second.mov`
- **Location**: `trAInSwift/Resources/Onboarding/Videos/`
- **Playback**: Auto-play, muted, looping, aspect fill

### Screen Content:

#### Screen 1:
- Video: `onboarding_first.mov`
- Subtitle: "You're in the right place" (gray)
- Headline: "Real trainers and science-backed programs to hit your goals." (white bold)

#### Screen 2:
- Video: `onboarding_second.mov`
- Subtitle: "We're built for you!" (gray)
- Headline: "Train creates your perfect workout for your individual needs." (white bold)

### Technical Implementation:
- UIViewRepresentable wrapping AVPlayerLayer
- AVQueuePlayer with AVPlayerLooper for seamless loops
- Proper memory management with objc_setAssociatedObject
- TabView with PageTabViewStyle (hidden indicators)
- Gesture handling for swipe navigation
- Gradient overlay for text readability

### Usage Integration:
These interstitials can be integrated into the questionnaire flow at key transition points:
- After goals/health profile collection
- Before equipment/training setup
- During loading transitions
- Between major flow sections

### Test Cases:
1. **Video Playback**: Both videos should auto-play and loop seamlessly
2. **No Audio**: Videos should be muted
3. **Swipe Navigation**: Left swipe should advance to next screen
4. **Button Navigation**: NEXT button should advance screens
5. **Final Screen**: Last screen should call onComplete()
6. **Memory Management**: Videos should stop when view is deallocated
7. **Layout**: Content should be properly positioned with gradient overlay
8. **Typography**: Text should be readable with proper contrast

### Assets Added:
- `onboarding_first.mov` - First interstitial video
- `onboarding_second.mov` - Second interstitial video

### Performance Considerations:
- Videos are loaded from local bundle for optimal performance
- AVPlayerLooper handles efficient looping without gaps
- Proper cleanup prevents memory leaks
- Gradient overlay ensures text readability across all video content