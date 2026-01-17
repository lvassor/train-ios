# Onboarding Flow
- The Train app commences with an onboarding questionnaire, for gathering information about the user.
- This includes personal information and anthropomorphic metrics like height and weight, before gathering information surrounding gym equipment and availability for training.
- The flow also contains two interstitial videos to break up the monotony of the flow for the user.

### Correct Flow (14 screens, streamlined)

| Step # | Step Name | Step Description | Update Required? | Update Description |
|--------|-----------|------------------|------------------|--------------------|
| 1 | Welcome | With app preview mockups, using the `screenshot*.PNG` files in the `Assets.xcassets` folder in the xcode project root. | Y | Bug, the WelcomeView exists but is not surfaced to the user as step 1 of the onboarding flow. See reference image for how you should create and style this. Search for dormant code which may have been produced at some point. Strangely we have the screenshots in their own subfolders in `Assets.xcassets` as well as all 4 screenshots in one folder `Onboarding/Screenshots`. Reconcile this redundancy and create an aesthetic looking view.|
| 2 | Goal | Single or multi select | N | |
| 3 | Name | "What should we call you?" | N | |
| 4 | Body Stats | Apple Health OR manual - gender, age | Y | Double check that the xcode project accept apple health kit integration for this step. |
| 5 | Body Stats | Height, weight combined - conditional, show if the apple health data does not contain height or weight | N | |
| 6 | Experience | 4 levels with descriptions | N | |
| 7 | [INTERSTITIAL] | Personal training value prop with trainer video | Y | For the carousel in step 1, the `screenshot.png` files are stored in the `Asseets.xcassets` Xcode assets folder. However, I don't see the interstitial videos in there. We also have a `Onboarding/Videos` subfolder in the `Resources` folder meaning we're storing image and video assets differently. This needs reconciling according to best practice. Either in `xcassets/Onboarding` or in the `Resources/Onboarding` for both images and videos but not both locations.|
| 8 | Training Frequency | With smart recommendation | N | |
| 9 | Training Split Choice | Displays available split based on answers to previous step. | N | |
| 10 | Session Duration | User selects session duration they desire.| N | |
| 11 | Equipment Availability | User selects the equipment available to them. | N | |
| 12 | [INTERSTITIAL] | Train creates your perfect workout for your individual needs | N | |
| 13 | Muscle Priority | Body diagram, optional, select up to 3 | N | |
| 14 | Injuries | Optional, skip if none. CTA now says "Generate Your Program" | N | |
| 15 | [LOADING] | "Build Your Program: with progress bar" | Y | We currently have a progress bar and a buffer wheel, which is redundant. Replace the buffer wheel with the train logo (`/Users/lukevassor/Documents/trAIn-ios/trAInSwift/Assets.xcassets/TrainLogoWithText.imageset/train-logo-with-text_isolate.svg`)|
| 16 | Program Ready | With confetti animation. CTA: "Start Training Now!" | | |
| 17 | Signup | Apple/Google/Email | Y | Several bugs present. HIGH PRIORITY: signing up via any of the three routes does not progress the user to step 18, it simply returns the user to the "Create Your Account" page. This needs fixing first. Other bugs: if using "Sign up with Apple" and the user cancels, they are returned to step 16. Whereas Yoif using "Continue with Email" and the user cancels, they are returned to the "Create Your Account" page. Signing up via any of the three routes and cancelling should return the user to the "Create Your Account" page. There needs to be consistency across all three routes. Furthermore "Continue with Email" should read "Sign up with Email" and have an envelope icon preceding, for consistency with the other two buttons. Lastly "Sign up with Google" currently does nothing - this needs implementing so that the user can actually sign in with Google. Again, if they cancel, they should be returned to Create Your Account. Successfully signing up with any of the three routes should then progress the user to step 18.|
| 18 | Notifications | Turn on notifications screen. If yes then Apple modal overlay displays to access push notification settings | Y | User can decide yes or no to notifications and must be progressed to step 19.|
| 19 | Referral page | Optional - how did you hear about us? | Y | CTA button should read "Start Training Now!" and clicking this should progress the user to the dashboard view showing their program. |