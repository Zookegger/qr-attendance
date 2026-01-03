import { Schedule } from "@models";
import { CreateScheduleDTO, UpdateScheduleDTO, ScheduleQuery } from '@my-types/schedule';

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
         order: [["created_at", "DESC"]],
         limit: pageSize,
         offset,
      });

      return { data: items, page: pageNum, limit: pageSize };
   }

   static async getScheduleById(id: number) {
      return Schedule.findByPk(id);
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
      if (query.user_id) where.user_id = query.user_id;
      if (query.shift_id) where.shift_id = Number(query.shift_id);
      if (query.start_date) where.start_date = query.start_date;
      if (query.end_date) where.end_date = query.end_date;

      return Schedule.findAll({ where, order: [["start_date", "DESC"]] });
   }
}