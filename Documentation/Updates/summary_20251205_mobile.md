<div align="center">

<img src="app-logo-primary.png" alt="trAIn Logo" width="40"/>

# trAIn Development Report

**5th December 2025**

*Brody Bastiman & Luke Vassor*

</div>

---

## Database & Backend

**Redesigned exercise database schema**
New SQL structure with equipment hierarchy, canonical grouping, complexity levels, and contraindication mappings.

**Equipment hierarchy system**
Two-tier structure — categories expand to reveal specific equipment items.

**Contraindications table**
Injury-to-exercise mapping for flagging potentially aggravating movements.

---

## Questionnaire & Onboarding

**Expandable equipment selection**
Categories expand to show specific machines with parent-child checkbox behavior.

**Injury question updated**
Changed to joint-based selection (Shoulder, Lower Back, Knee) mapping to contraindications.

**Experience level redesign**
Confidence-based self-assessment replacing time-based training history.

**Muscle group selection fix**
Users can proceed with 0 selections; program generation handles gracefully.

---

## Workout Logger

**Inline rest timer**
Non-blocking timer at top of exercise card, auto-resets on new set.

**Keyboard dismissal**
"Done" button toolbar on number pads and keyboards.

**Contraindication warnings**
Yellow warning icon on exercises affecting recorded injuries.

**Progressive overload counter**
Green badge showing rep increase vs previous session.

**Progression prompts**
Updated modal feedback for load progression coaching.

**Exercise instructions**
Demo tab shows numbered steps from database.

**Library logger fix**
Removed logger tab from exercise library — Demo only.

---

## UI/UX & Design

**Charcoal gradient background**
Diagonal gradient on full-screen views only.

**Material distinction**
Gradient for screens; ultraThinMaterial for cards/modals.

**Glass lens tab bar**
Apple Phone app-style sliding lens with accent reveal and drag gesture.

**Metal shader refraction**
True optical refraction using parabolic (1-r²) distortion with chromatic aberration for rainbow fringing.

---

## Cleanup

**Deleted legacy files**
Removed outdated prompts, scripts, and docs.
