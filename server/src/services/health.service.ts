import { format } from "date-fns";

export class HealthService {
  public getHealthStatus() {
    return {
      status: 'UP',
      timestamp: new Date(),
      uptime: format(process.uptime(), "dd/MM/yyyy - hh:mm:ss aa"),
    };
  }
}
