// import { format } from "date-fns";

export class HealthService {
	formatMemoryUsage = (usage: NodeJS.MemoryUsage) => {
		const toMB = (bytes: number) => (bytes / 1024 / 1024).toFixed(2) + "MB";
		return Object.fromEntries(
			Object.entries(usage).map(([key, value]) => [key, toMB(value)])
		);
	};

	formatUptime = (seconds: number) => {
		const days = Math.floor(seconds / 86400);
		const hours = Math.floor((seconds % 86400) / 3600);
		const minutes = Math.floor((seconds % 3600) / 60);
		const secs = Math.floor(seconds % 60);

		const parts = [];
		if (days > 0) parts.push(`${days}d`);
		if (hours > 0) parts.push(`${hours}h`);
		if (minutes > 0) parts.push(`${minutes}m`);
		parts.push(`${secs}s`);

		return parts.join(" ");
	};

	public getHealthStatus() {
		return {
			status: "UP",
			timestamp: new Date(),
			usage: this.formatMemoryUsage(process.memoryUsage()),
			uptime: this.formatUptime(process.uptime()),
		};
	}
}
