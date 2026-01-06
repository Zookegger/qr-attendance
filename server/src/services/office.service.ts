import OfficeConfig from "@models/officeConfig";

export interface CreateOfficeDTO {
    name: string;
    latitude: number;
    longitude: number;
    radius: number;
    wifiSsid?: string | null;
}

export interface UpdateOfficeDTO {
    name?: string;
    latitude?: number;
    longitude?: number;
    radius?: number;
    wifiSsid?: string | null;
}

export default class OfficeService {
    static async getAllOffices() {
        return await OfficeConfig.findAll();
    }

    static async getOfficeById(id: string) {
        return await OfficeConfig.findByPk(id);
    }

    static async createOffice(dto: CreateOfficeDTO) {
        return await OfficeConfig.create({
            name: dto.name,
            latitude: dto.latitude,
            longitude: dto.longitude,
            radius: dto.radius,
            wifiSsid: dto.wifiSsid || null,
        });
    }

    static async updateOffice(id: string, dto: UpdateOfficeDTO) {
        const office = await OfficeConfig.findByPk(id);
        if (!office) {
            throw new Error("Office not found");
        }
        
        if (dto.name !== undefined) office.name = dto.name;
        if (dto.latitude !== undefined) office.latitude = dto.latitude;
        if (dto.longitude !== undefined) office.longitude = dto.longitude;
        if (dto.radius !== undefined) office.radius = dto.radius;
        if (dto.wifiSsid !== undefined) office.wifiSsid = dto.wifiSsid;
        
        await office.save();
        return office;
    }

    static async deleteOffice(id: string) {
        const office = await OfficeConfig.findByPk(id);
        if (!office) {
            throw new Error("Office not found");
        }
        await office.destroy();
        return { message: "Office deleted successfully" };
    }
}
