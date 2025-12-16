import * as admin from "firebase-admin";
import * as path from "path";

// 1. Load credentials
// Ensure 'service-account-key.json' is in your server root (next to package.json)
const serviceAccount = require(path.join(
	__dirname,
	"../service-account-key.json"
));

admin.initializeApp({
	credential: admin.credential.cert(serviceAccount),
});

// 2. PASTE YOUR TOKEN HERE
const YOUR_DEVICE_TOKEN =
	"e_Lh6eL-QcOTNb2Wg7w5Ke:APA91bEWw3xii3ICd30UmzSuRpQkfvOjilR0cYe1XvcrJniD-M3L08YAZrV0TJBqqOOAkCvLjhmZGPRkDUb49qCpdhenXtgUwWWz6GzSNyuf6emuaR6mgIU";

async function sendTestNotification() {
	const message = {
		token: YOUR_DEVICE_TOKEN,
		notification: {
			title: "Mission Report",
			body: "The backend is speaking to the frontend. Over.",
		},
		data: {
			type: "urgent", // Tests your "High Importance" channel logic
		},
	};

	try {
		console.log("🚀 Sending payload...");
		const response = await admin.messaging().send(message);
		console.log("✅ Success! Message ID:", response);
	} catch (error) {
		console.error("❌ Failed:", error);
	}
}

sendTestNotification();
