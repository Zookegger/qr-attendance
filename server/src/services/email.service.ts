import nodemailer from "nodemailer";
import { EmailJobData } from "@utils/queues/emailQueue";
import logger from "@utils/logger";
import dotenv from "dotenv";

dotenv.config();

const SMTP_CONFIG_HOST = process.env.SMTP_CONFIG_HOST ?? "localhost";
const SMTP_CONFIG_PORT = process.env.SMTP_CONFIG_PORT
	? Number.parseInt(process.env.SMTP_CONFIG_PORT)
	: 587;
const SMTP_CONFIG_USER = process.env.SMTP_CONFIG_USER;
const SMTP_CONFIG_PASS = process.env.SMTP_CONFIG_PASS;

/*
 * Nodemailer transporter instance.
 *
 * Configured with SMTP settings for sending emails through the configured provider.
 * Supports both secure (465) and non-secure (587) SMTP connections.
 */
const transporter = nodemailer.createTransport({
	host: SMTP_CONFIG_HOST,
	port: SMTP_CONFIG_PORT,
	secure: SMTP_CONFIG_PORT === 465,
	auth: {
		user: SMTP_CONFIG_USER,
		pass: SMTP_CONFIG_PASS,
	},
});

export class EmailService {
	static async sendEmail(data: EmailJobData): Promise<void> {
		const FROM_EMAIL: string =
			process.env.FROM_EMAIL ||
			SMTP_CONFIG_USER ||
			"qr_attendance@example.com";

		const result = await transporter.sendMail({
			from: FROM_EMAIL,
			to: data.to,
			subject: data.subject,
			html: data.html,
			text: data.text,
		});
		if (!result)
			throw new Error("Something went wrong while sending email");

		logger.info(`Email sent successfully. MessageId: ${result}`);
	}

	/**
	 * Generates HTML content for password reset emails.
	 *
	 * Creates a styled HTML email template with reset link and user greeting.
	 * Includes responsive design and fallback text link for email clients that
	 * don't support HTML or buttons.
	 *
	 * @param username - Username of the account requesting password reset
	 * @param resetPasswordLink - Complete reset password URL with token
	 * @returns HTML string containing the formatted password reset email
	 */
	static generateResetPasswordHTML = (
		username: string,
		resetPasswordLink: string
	): string => {
		return `
      <!DOCTYPE html>
      <html lang="en">
         <head>
               <meta charset="UTF-8">
               <meta name="viewport" content="width=device-width, initial-scale=1.0">
               <meta http-equiv="X-UA-Compatible" content="ie=edge">
               <title>Password Reset Request</title>
               <style>
                  /* Basic Reset */
                  body, table, td, a { -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }
                  table, td { mso-table-lspace: 0pt; mso-table-rspace: 0pt; }
                  img { -ms-interpolation-mode: bicubic; border: 0; height: auto; line-height: 100%; outline: none; text-decoration: none; }
                  table { border-collapse: collapse !important; }
                  body { height: 100% !important; margin: 0 !important; padding: 0 !important; width: 100% !important; }

                  /* Main Styles */
                  body {
                     font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
                     background-color: #f4f4f4;
                     color: #333333;
                  }
                  .container {
                     max-width: 600px;
                     margin: 20px auto;
                     background-color: #ffffff;
                     border-radius: 8px;
                     overflow: hidden;
                     box-shadow: 0 4px 15px rgba(0,0,0,0.1);
                  }
                  .header {
                     background-color: #007bff;
                     color: #ffffff;
                     padding: 40px;
                     text-align: center;
                  }
                  .header h1 {
                     margin: 0;
                     font-size: 24px;
                  }
                  .content {
                     padding: 40px;
                     line-height: 1.6;
                     color: #555555;
                  }
                  .button-container {
                     text-align: center;
                     margin: 30px 0;
                  }
                  .button {
                     display: inline-block;
                     padding: 15px 30px;
                     background-color: #007bff;
                     color: #ffffff;
                     text-decoration: none;
                     font-weight: bold;
                     border-radius: 5px;
                     transition: background-color 0.3s;
                  }
                  .button:hover {
                     background-color: #0056b3;
                  }
                  .link {
                     word-break: break-all;
                     font-size: 12px;
                     color: #888888;
                  }
                  .footer {
                     text-align: center;
                     font-size: 12px;
                     color: #888888;
                     padding: 20px 40px;
                     border-top: 1px solid #eeeeee;
                  }
               </style>
         </head>
         <body>
               <div class="container">
                  <div class="header">
                     <h1>Password Reset Request</h1>
                  </div>
                  <div class="content">
                     <p>Hi ${username},</p>
                     <p>We received a request to reset the password for your EasyRide account. To proceed, please click the button below. This link will expire in 1 hour.</p>
                     <div class="button-container">
                           <a href="${resetPasswordLink}" class="button" style="color: #ffffff;">Reset Your Password</a>
                     </div>
                     <p>If the button doesn't work, you can copy and paste this link into your browser:</p>
                     <p class="link">${resetPasswordLink}</p>
                  </div>
                  <div class="footer">
                     <p>If you did not request a password reset, please ignore this email. Your password will not be changed.</p>
                  </div>
               </div>
         </body>
      </html>
    `;
	};
}
