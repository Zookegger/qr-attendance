import { Worker, Job } from "bullmq";
import crypto from "crypto";
import redis from "@config/redis";
import { QRJobData } from "@utils/queues/qrCodeQueue";
import logger from "@utils/logger";
import { OfficeConfig } from "@models";
import { getIo } from "@utils/socket";

const refreshSeconds = 30;
const ttlSeconds = 45; // 30s rotation + 15s grace

const qrWorker = new Worker<QRJobData>(
   "qrCode",
   async (job: Job<QRJobData>) => {
      try {
         logger.debug(`[QR Worker] Job ${job.id} started`);

         // If officeId provided, limit to that; otherwise generate for all configured offices
         const offices = job.data.officeId
            ? await OfficeConfig.findAll({ where: { id: job.data.officeId } })
            : await OfficeConfig.findAll();

         for (const office of offices) {
            const officeId = (office as any).id;
            const num = crypto.randomInt(0, 10000);
            const code = num.toString().padStart(4, "0");

            const key = `checkin:office:${officeId}:code:${code}`;
            await redis.set(key, "1", "EX", ttlSeconds);

            try {
               const io = getIo();
               io.to(`office_${officeId}`).emit("qr:update", {
                  code,
                  refreshAt: refreshSeconds,
               });
            } catch (err) {
               logger.warn(`[QR Worker] Failed to emit socket for office ${officeId}: ${err}`);
            }
         }

         logger.debug(`[QR Worker] Job ${job.id} finished`);
      } catch (err) {
         logger.error(`[QR Worker] Error processing job ${job.id}: ${err}`);
         throw err;
      }
   },
   {
      connection: redis,
      concurrency: 1,
   }
);

qrWorker.on("completed", (job) => {
   logger.debug(`[QR Worker] job ${job.id} completed`);
});

qrWorker.on("failed", (job, err) => {
   logger.error(`[QR Worker] job ${job?.id} failed: ${err}`);
});

export const shutdownQrWorker = async () => {
   try {
      await qrWorker.close();
      logger.info("QR Worker closed");
   } catch (err) {
      logger.warn(`QR Worker close error: ${err}`);
   }
};

export default qrWorker;
