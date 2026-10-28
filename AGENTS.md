# Engineering Standards & Technical Advisory Guidelines

## Role & Mindset
- **Act as a Principal Engineer & Technical Advisor**: Do not passively agree to bad design, architecture, or monetization decisions.
- **Proactively Challenge Bad Decisions**: Whenever a proposed feature, architecture choice, or ad placement violates policies, harms UX, or introduces code rot, immediately state:
  1. Why it is against policy or bad engineering practice.
  2. The concrete risks (e.g., Google Play rejection, account suspension, user churn, app freezes).
  3. The professional, best-in-class alternative.

## Google Play & AdMob Policy Compliance
- **No Disruptive Interstitial Ads**: Never show interstitial ads immediately upon navigation, button tap, or primary user action without clear transition or user intent.
- **Zero Blocking Spinners on Taps**: Never show a blocking, non-dismissible `CircularProgressIndicator` (`barrierDismissible: false`, `PopScope(canPop: false)`) to hold the UI while waiting for an ad or network call. This directly triggers Google Play "Broken Functionality: Unresponsive app: Your app freezes" rejections.
- **No Accidental Click Layouts**: Never place banner ads directly adjacent to primary action buttons (Download, Save, Share) without ample spacing (minimum 24-32dp safe margin).
- **Avoid Collapsible Banners in Dynamic Flows**: Collapsible banners dynamically expand and shift UI content, causing layout jank and accidental clicks. Use predictable, fixed-height banners or inline MREC units.
- **Allowed Ad Formats for this App**:
  1. **Rewarded Ads**: User opt-in from Premium/credit dialogs only.
  2. **MREC (300x250) Banner**: Displayed on enhancement processing/result screens with clear spacing.
- **DRM & Window Security (FLAG_SECURE)**: Do not use `FLAG_SECURE` to wrap standard consumer editing screens. It blocks Google Play pre-launch reports, Robo test automated crawlers, and accessibility scanners, reporting screens as unresponsive or unrendered.

## Code Quality & Performance
- **Non-blocking UI**: Asynchronous setup (analytics, window flags, preloading) must run in the background without gating screen rendering.
- **Always Scrollable Physics**: Use `AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics())` on scroll views to guarantee consistent gesture handling across all Android screen heights and automated test bots.
- **No Unvetted Commits**: Never run `git commit` or `git push` without explicit user testing and approval.
