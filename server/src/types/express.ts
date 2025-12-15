// Augment Express Request with `user` property using the application's User model
import type { User as AppUser } from "@models/user";

declare module "express-serve-static-core" {
  interface Request {
    user?: AppUser | null;
  }
}

export {};
