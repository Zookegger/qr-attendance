import { Router } from "express";
import { OfficeController } from "@controllers/office.controller";
import { authenticate, authorize } from "@middlewares/auth.middleware";
import { UserRole } from "@models/user";
import { createOfficeValidator, updateOfficeValidator, officeIdValidator } from "@middlewares/validators/office.validator";

const officeRouter = Router();

officeRouter.get(
    "/offices",
    authenticate,
    OfficeController.getAllOffices
);

officeRouter.get(
    "/offices/:id",
    authenticate,
    officeIdValidator,
    OfficeController.getOfficeById
);

officeRouter.post(
    "/offices",
    authenticate,
    authorize([UserRole.ADMIN, UserRole.MANAGER]),
    createOfficeValidator,
    OfficeController.createOffice
);

officeRouter.put(
    "/offices/:id",
    authenticate,
    authorize([UserRole.ADMIN, UserRole.MANAGER]),
    officeIdValidator,
    updateOfficeValidator,
    OfficeController.updateOffice
);

officeRouter.delete(
    "/offices/:id",
    authenticate,
    authorize([UserRole.ADMIN, UserRole.MANAGER]),
    officeIdValidator,
    OfficeController.deleteOffice
);

export default officeRouter;
