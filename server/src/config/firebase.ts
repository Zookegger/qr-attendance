import * as admin from "firebase-admin";

const initializeFirebase = () => {
  if (admin.apps.length > 0) return admin.app();

  try {
    // Ép kiểu 'as string' để báo với TS rằng các biến này chắc chắn có giá trị
    const projectId = process.env.FIREBASE_PROJECT_ID as string;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL as string;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, "\n") as string;

    // Kiểm tra thủ công một lần nữa để an toàn
    if (!projectId || !clientEmail || !privateKey) {
        console.error("❌ Firebase config is missing in .env");
        return null;
    }

    return admin.initializeApp({
      credential: admin.credential.cert({
        projectId,
        clientEmail,
        privateKey,
      }),
    });
  } catch (error) {
    console.error("❌ Firebase Initialization Error:", error);
    return null;
  }
};

const firebaseAdmin = initializeFirebase();

export default firebaseAdmin;