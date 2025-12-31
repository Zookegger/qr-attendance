import { Queue } from "bullmq";
import redis from "@config/redis";

export interface QRJobData {
   officeId?: number;
}

export const qrCodeQueue = new Queue<QRJobData>("qrCode", {
   connection: redis,

   defaultJobOptions: {
      attempts: 3,
      backoff: { type: "exponential", delay: 2000 },
      removeOnComplete: { count: 100, age: 24 * 3600 },
      removeOnFail: { count: 1000 },
   },
});

export default qrCodeQueue;

export const closeQrCodeQueue = async () => {
   try {
      await qrCodeQueue.close();
   } catch (err) {
      // ignore
   }
};
