import { sendPushNotification } from "@controllers/notification.service";
import { Router } from "express";

const testRouter = Router();

/**
 * TEST: gửi notification thủ công
 */
testRouter.post("/test-push", async (req, res) => {
  try {
    const { token } = req.body;

    await sendPushNotification(
      token,
      "Test Firebase",
      "Push notification OK"
    );

    res.json({ message: "Send success" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Send failed" });
  }
});

export default testRouter;
