import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";
import { debugLog } from "./debugLog";

/**
 * Validates the caller's build number against Firestore's version_control configuration.
 * Throws a failed-precondition HttpsError if the build is older than min_supported_build
 * and force_update is enabled.
 */
export async function assertAppVersionSupported(buildNumber: unknown): Promise<void> {
  let minBuild = 0;
  let force = true;
  try {
    const configSnap = await admin.firestore()
      .collection("app_config")
      .doc("version_control")
      .get();
    if (configSnap.exists) {
      const config = configSnap.data();
      minBuild = Number(config?.min_supported_build || 0);
      force = Boolean(config?.force_update ?? true);
    }
  } catch (err: unknown) {
    debugLog.warn("[assertAppVersionSupported] Firestore version read failed:", err);
  }

  const clientBuild = Number(buildNumber || 0);
  if (force && minBuild > 0 && clientBuild < minBuild) {
    throw new HttpsError(
      "failed-precondition",
      "APP_UPDATE_REQUIRED: A critical update is required to continue using Slipe AI. Please update from the Google Play Store.",
    );
  }
}
