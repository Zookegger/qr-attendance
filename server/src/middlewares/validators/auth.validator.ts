import { body } from "express-validator";

export const changePasswordValidator = [
	body("currentPassword")
		.isString()
		.notEmpty()
		.withMessage("Current password is required"),
	body("newPassword")
		.isString()
		.isLength({ min: 6 })
		.withMessage("New password must be at least 6 characters long"),
	body("confirmNewPassword")
		.isString()
		.notEmpty()
		.withMessage("Password confirmation is required")
		.custom((value, { req }) => {
			if (value !== req.body.newPassword) {
				throw new Error("Password confirmation does not match new password");
			}
			return true;
		}),
];