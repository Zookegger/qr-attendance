import { GeofenceConfig } from "@models/officeConfig";

export interface CreateOfficeDTO {
   name: string;
   latitude: number;
   longitude: number;
   radius: number | null;
   wifiSsid?: string | null;
   geofence: GeofenceConfig | null;
}

export interface UpdateOfficeDTO {
   name?: string;
   latitude?: number;
   longitude?: number;
   radius?: number;
   wifiSsid?: string | null;
   geofence?: GeofenceConfig | null;
}