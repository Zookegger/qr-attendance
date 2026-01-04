import { NextFunction, Request, Response } from "express";
import OfficeService from "@services/office.service";
import { validationResult } from "express-validator";

export class OfficeController {
   static async getAllOffices(_req: Request, res: Response, next: NextFunction) {
      try {
         const offices = await OfficeService.getAllOffices();
         return res.json(offices);
      } catch (error) {
         return next(error);
      }
   }

   static async getOfficeById(req: Request, res: Response, next: NextFunction) {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
         return res.status(400).json({ errors: errors.array() });
      }

      try {
         const { id } = req.params as { id: string };
         const office = await OfficeService.getOfficeById(id);
         if (!office) {
            return res.status(404).json({ message: "Office not found" });
         }
         return res.json(office);
      } catch (error) {
         return next(error);
      }
   }

   static async createOffice(req: Request, res: Response, next: NextFunction) {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
         return res.status(400).json({ errors: errors.array() });
      }

      try {
         const office = await OfficeService.createOffice(req.body);
         return res.status(201).json(office);
      } catch (error) {
         return next(error);
      }
   }

   static async updateOffice(req: Request, res: Response, next: NextFunction) {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
         return res.status(400).json({ errors: errors.array() });
      }

      try {
         const { id } = req.params as { id: string };
         const office = await OfficeService.updateOffice(id, req.body);
         return res.json(office);
      } catch (error) {
         return next(error);
      }
   }

   static async deleteOffice(req: Request, res: Response, next: NextFunction) {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
         return res.status(400).json({ errors: errors.array() });
      }

      try {
         const { id } = req.params as { id: string };
         await OfficeService.deleteOffice(id);
         return res.json({ message: "Office deleted" });
      } catch (error) {
         return next(error);
      }
   }
}
