import { Request, Response } from 'express';
import { RequestModel } from '@models/request';
import { v4 as uuidv4 } from 'uuid';


export async function createRequest(req: Request, res: Response) {
  try {
    const user = (req as any).user;
    if (!user) return res.status(403).json({ message: 'Unauthorized' });

    const { type, from_date, to_date, reason, image_url } = req.body;

    // (Optional) validate fields here, map client type strings -> allowed values if needed

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