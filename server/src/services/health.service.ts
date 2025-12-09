export class HealthService {
  public getHealthStatus() {
    return {
      status: 'UP',
      timestamp: new Date(),
      uptime: process.uptime(),
    };
  }
}
