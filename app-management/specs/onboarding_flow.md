# Onboarding Flow
- The Train app commences with an onboarding questionnaire, for gathering information about the user.
- This includes personal information and anthropomorphic metrics like height and weight, before gathering information surrounding gym equipment and availability for training.
- The flow also contains two interstitial videos to break up the monotony of the flow for the user.

### Correct Flow (14 screens, streamlined)


1. Welcome (with app preview mockups, using the `screenshot*.PNG` files in the `onboarding` folder.
2. Goal (single or multi select)
3. Name "What should we call you?"
4. Body Stats (Apple Health OR manual - gender, age)
5. Body Stats (height, weight combined) - conditional, show if the apple health data does not contain height or weight
6. Experience (4 levels with descriptions)
7. [INTERSTITIAL] - Personal training value prop with trainer video
8. Training Frequency (with smart recommendation)
9. Training Split Choice
10. Session Duration
11. Equipment Availability (pre-selected based on gym type, with images)
12. [INTERSTITIAL] - Train creates your perfect workout for your individual needs.
13. Muscle Priority (body diagram, optional, select up to 3)
14. Injuries (optional, skip if none). CTA now says "Generate Your Program"
15. [LOADING] - "Build Your Program: with progress bar"
16. Program Ready with confetti animation. CTA: "Start Training Now!"
17. Signup (Apple/Google/Email)
18. Notifications - turn on notifications screen. If yes then Apple modal overlay displays to access push notification settings.
19. Referral page (optional) - how did you hear about us?