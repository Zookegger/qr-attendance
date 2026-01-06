import { Workshift } from '@models';
import { CreateWorkshiftDTO, UpdateWorkshiftDTO } from '@my-types/workshift';

export default class WorkshiftService {
  static async createWorkshift(data: CreateWorkshiftDTO) {
   const created = await Workshift.create(data);
    return created;
  }

   static async listWorkshifts() {
      return Workshift.findAll({ order: [['createdAt', 'DESC']] });
   }

   static async getWorkshiftById(id: number) {
      return Workshift.findByPk(id);
   }

   static async updateWorkshift(id: number, payload: UpdateWorkshiftDTO) {
      const item = await Workshift.findByPk(id);
      if (!item) return null;
      await item.update(payload);
      return item;
   }

   static async deleteWorkshift(id: number) {
      const item = await Workshift.findByPk(id);
      if (!item) return false;
      await item.destroy();
      return true;
   }
}