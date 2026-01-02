import admin from "@config/firebase";

export const sendPushNotification = async (
  token: string,
  title: string,
  body: string
) => {
  try {
    const message = {
      token,
      notification: {
        title,
        body,
      },
    };

    const response = await admin.messaging().send(message);

    console.log('FCM RESPONSE:', response);

    return response;
  } catch (error: any) {
    console.error('FCM ERROR FULL:', error);
    throw error; // QUAN TRỌNG
  }
};
