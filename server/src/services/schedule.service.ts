import { Schedule } from "@models";
import { CreateScheduleDTO, UpdateScheduleDTO, ScheduleQuery } from '@my-types/schedule';
import { Op } from "sequelize";

export default class ScheduleService {
   static async createSchedule(data: CreateScheduleDTO) {
      const created = await Schedule.create(data as any);
      return created;
   }

   static async listSchedules(page = 1, limit = 50) {
      const pageNum = Math.max(1, Number(page) || 1);
      const pageSize = Math.max(1, Math.min(100, Number(limit) || 50));
      const offset = (pageNum - 1) * pageSize;

      const items = await Schedule.findAll({
         order: [["createdAt", "DESC"]],
         include: ["Shift", "User"],
         limit: pageSize,
         offset,
      });

      return { data: items, page: pageNum, limit: pageSize };
   }

   static async getScheduleById(id: number) {
      return Schedule.findByPk(id, {
         order: [["createdAt", "DESC"]],
         include: ["Shift", "User"],
      });
   }
   
   static async getSchedulebyUser(userId: string) {
      return Schedule.findAll({ 
         where: { userId },
         order: [["createdAt", "DESC"]],
         include: ["Shift", "User"],
      });
   }

   static async updateSchedule(id: number, payload: UpdateScheduleDTO) {
      const item = await Schedule.findByPk(id);
      if (!item) return null;
      await item.update(payload);
      return item;
   }

   static async deleteSchedule(id: number) {
      const item = await Schedule.findByPk(id);
      if (!item) return false;
      await item.destroy();
      return true;
   }

   static async searchSchedules(query: ScheduleQuery) {
      const where: any = {};
      if (query.userId) where.userId = query.userId;
      if (query.shiftId) where.shiftId = Number(query.shiftId);
      if (query.startDate) where.startDate = query.startDate;
      if (query.endDate) where.endDate = query.endDate;

      // Range Overlap Logic:
      // Schedule starts before the end of the range AND (ends after the start of the range OR is indefinite)
      if (query.from && query.to) {
         where[Op.and] = [
            { startDate: { [Op.lte]: query.to } },
            {
               [Op.or]: [
                  { endDate: { [Op.gte]: query.from } },
                  { endDate: null }
               ]
            }
         ];
      }

      return Schedule.findAll({
         where,
         order: [["startDate", "DESC"]],
         include: ["Shift", "User"] // Include relations for the roster
      });
   }
}