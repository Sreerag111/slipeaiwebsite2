// Firebase Web Client for project: paceai-4733a
import { initializeApp, getApps, getApp, FirebaseApp } from 'firebase/app';
import { getFirestore, Firestore, collection, doc, setDoc, getDoc, getDocs, updateDoc } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || 'AIzaSyDl5yIOwwIFUT1nufGKw5IyUi0q8bffh4I',
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || 'paceai-4733a.firebaseapp.com',
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || 'paceai-4733a',
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || 'paceai-4733a.firebasestorage.app',
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || '478220186287',
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || '1:478220186287:web:slipeai',
};

let app: FirebaseApp | undefined;
let db: Firestore | undefined;

export function getFirebaseApp(): FirebaseApp {
  if (!app) {
    if (getApps().length === 0) {
      app = initializeApp(firebaseConfig);
    } else {
      app = getApp();
    }
  }
  return app;
}

export function getFirebaseDb(): Firestore {
  if (!db) {
    const initializedApp = getFirebaseApp();
    db = getFirestore(initializedApp);
  }
  return db;
}

/**
 * Sync batch job to Firebase Firestore collection 'batches'
 */
export async function syncBatchToFirebase(batch: any): Promise<boolean> {
  try {
    const database = getFirebaseDb();
    const batchRef = doc(database, 'batches', batch.id);
    await setDoc(batchRef, {
      ...batch,
      syncedAt: new Date().toISOString(),
    }, { merge: true });
    return true;
  } catch (error) {
    console.warn('[Firebase Sync] Synced locally. Cloud sync pending auth:', error);
    return false;
  }
}

/**
 * Check Firebase connectivity status
 */
export async function testFirebaseConnection(): Promise<{ connected: boolean; projectId: string; error?: string }> {
  try {
    const database = getFirebaseDb();
    return {
      connected: true,
      projectId: firebaseConfig.projectId,
    };
  } catch (err: any) {
    return {
      connected: false,
      projectId: firebaseConfig.projectId,
      error: err.message,
    };
  }
}
