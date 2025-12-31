// Augment Express Request with `user` property using the application's User model
import type User from "@models/user";

declare module "express-serve-static-core" {
  interface Request {
    user?: User | null;
  }
}

export { };
