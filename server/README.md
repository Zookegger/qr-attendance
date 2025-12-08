# Server Application

This is the backend server for the QR Attendance App, built with Node.js, Express, and TypeScript.

## Project Structure

- `src/app.ts`: Entry point of the application.
- `src/controllers`: Request handlers.
- `src/services`: Business logic.
- `src/routes`: Route definitions.
- `src/middlewares`: Express middlewares (e.g., error handling).
- `src/utils`: Utility functions (e.g., logger).
- `src/config`: Configuration files.
- `src/models`: Database models (currently using Sequelize with JS in root `models/` folder, can be migrated to TS).

## Scripts

- `npm run dev`: Run the server in development mode with hot-reloading.
- `npm run build`: Compile TypeScript to JavaScript in `dist/`.
- `npm start`: Run the compiled server from `dist/`.
- `npm test`: Run tests.

## API Endpoints

- `GET /api/health`: Check server health status.
