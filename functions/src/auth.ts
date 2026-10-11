import { getFirestore } from "firebase-admin/firestore";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";

/** Returns the caller's uid, or throws unless they are an admin. */
export async function requireAdmin(request: CallableRequest<unknown>): Promise<string> {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Bitte zuerst anmelden.");
  const profile = await getFirestore().collection("profiles").doc(uid).get();
  if (profile.get("role") !== "admin") {
    throw new HttpsError("permission-denied", "Nur Admins können Märkte anlegen.");
  }
  return uid;
}
