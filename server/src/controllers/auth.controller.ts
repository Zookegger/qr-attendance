import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { User } from '../models';
import { v4 as uuidv4 } from 'uuid';

const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_key';

export class AuthController {
  // Register (For Admin/Testing)
  static async register(req: Request, res: Response) {
    try {
      const { name, email, password, role, position, department } = req.body;

      const existingUser = await User.findOne({ where: { email } });
      if (existingUser) {
        return res.status(400).json({ message: 'User already exists' });
      }

      const salt = await bcrypt.genSalt(10);
      const password_hash = await bcrypt.hash(password, salt);

      const user = await User.create({
        name,
        email,
        password_hash,
        role: role || 'user',
        position,
        department,
      });

      res.status(201).json({ message: 'User created successfully', user: { id: user.id, email: user.email } });
    } catch (error) {
      res.status(500).json({ message: 'Server error', error });
    }
  }

  // Login
  static async login(req: Request, res: Response) {
    try {
      const { email, password, device_uuid } = req.body;

      const user = await User.findOne({ where: { email } });
      if (!user) {
        return res.status(400).json({ message: 'Invalid credentials' });
      }

      const isMatch = await bcrypt.compare(password, user.password_hash);
      if (!isMatch) {
        return res.status(400).json({ message: 'Invalid credentials' });
      }

      // Device Binding Check (Only for non-admin users)
      if (user.role === 'user') {
        if (!device_uuid) {
            return res.status(400).json({ message: 'Device UUID is required for login' });
        }

        if (user.device_uuid && user.device_uuid !== device_uuid) {
          return res.status(403).json({ message: 'This account is bound to another device.' });
        }

        // Bind device if not bound
        if (!user.device_uuid) {
          user.device_uuid = device_uuid;
          await user.save();
        }
      }

      const token = jwt.sign({ id: user.id, role: user.role }, JWT_SECRET, { expiresIn: '1d' });

      res.json({
        token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          device_uuid: user.device_uuid,
        },
      });
    } catch (error) {
      res.status(500).json({ message: 'Server error', error });
    }
  }

  // Get Current User
  static async me(req: Request, res: Response) {
    try {
      const user = req.user;
      if (!user) {
          return res.status(404).json({ message: 'User not found' });
      }
      res.json(user);
    } catch (error) {
      res.status(500).json({ message: 'Server error', error });
    }
  }
}
