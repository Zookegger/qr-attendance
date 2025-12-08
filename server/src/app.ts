import express, { Application } from 'express';
import cors from 'cors';
import routes from './routes';
import { errorHandler } from './middlewares/error.middleware';
import { logger } from './utils/logger';
import { initCronJobs } from './services/cron.service';
import { sequelize } from './config/database';

const app: Application = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api', routes);

// Error Handling
app.use(errorHandler);

// Start Server
if (require.main === module) {
  // Sync Database
  sequelize.sync({ alter: true }).then(() => {
    logger.info('Database synced');
    // Init Cron Jobs
    initCronJobs();
    
    app.listen(PORT, () => {
      logger.info(`Server running on port ${PORT}`);
    });
  }).catch((err) => {
    logger.error('Failed to sync database:', err);
  });
}

export default app;
