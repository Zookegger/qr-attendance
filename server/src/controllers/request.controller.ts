import { Request, Response } from 'express';
import { RequestModel } from '@models/request';
import { v4 as uuidv4 } from 'uuid';


export async function createRequest(req: Request, res: Response) {
  try {
    const user = (req as any).user;
    if (!user) return res.status(403).json({ message: 'Unauthorized' });

    const { type, from_date, to_date, reason, image_url } = req.body;

    // Validate request type against a predefined list of allowed values
    const ALLOWED_REQUEST_TYPES = ['vacation', 'sick', 'personal', 'other'];
    if (typeof type !== 'string' || !ALLOWED_REQUEST_TYPES.includes(type)) {
      return res.status(400).json({
        message: 'Invalid request type',
        allowedTypes: ALLOWED_REQUEST_TYPES,
      });
    }

    // (Optional) validate other fields here, map client type strings -> allowed values if needed
    const created = await RequestModel.create({
      id: uuidv4(),
      user_id: user.id,
      type,
      from_date: from_date || null,
      to_date: to_date || null,
      reason,
      image_url,
    });

    return res.status(201).json({ message: 'Request created', request: created });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Server error', error: err });
  }
}