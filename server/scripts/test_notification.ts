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
	"egcmr3oZQLCBfwu5C_GcOf:APA91bFtGIuXzdPp1dK2wt_1RHST41IUGF-xF_cwp8p4hONQR1zfx4xw3XzdkYBvqd3TPhNp_mzYu3ErKqyAFuzmqFBG_urIwc3Nb5bSahw1cEBWyKKKXqQ";

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
