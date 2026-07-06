import env from "@/config/env";
import { IEmailService } from "@/interfaces/services/email.service.interface";
import { ApiError } from "@/utils/ApiError";
import { HTTP_STATUS } from "@/utils/constants";
import fs from "fs";
import nodemailer, { SentMessageInfo, Transporter } from "nodemailer";
import path from "path";

const EMAIL_TEMPLATE_PATH = path.join(process.cwd(), "src/templates/emails/otp.html");

const APP_NAME = "Life Partner Again";
const OTP_EMAIL_SUBJECT = "Your OTP - Life Partner Again";

export class EmailService implements IEmailService {
   private readonly transporter: Transporter;

   constructor() {
      this.transporter = nodemailer.createTransport({
         service: "gmail",
         auth: {
            user: env.SMTP_USER,
            pass: env.SMTP_PASS,
         },
      });
   }

   /**
    * Sends OTP email.
    *
    * @param to - Receiver email address.
    * @param otp - OTP code.
    * @returns Sent email info.
    */
   async sendOtpEmail(to: string, otp: string): Promise<SentMessageInfo> {
      try {
         return await this.transporter.sendMail({
            from: `"${APP_NAME}" <${env.SMTP_FROM ?? env.SMTP_USER}>`,
            to,
            subject: OTP_EMAIL_SUBJECT,
            html: this.getOtpEmailHtml(otp),
         });
      } catch {
         throw new ApiError(HTTP_STATUS.INTERNAL_SERVER_ERROR, "Failed to send OTP email");
      }
   }

   /**
    * Builds OTP email HTML.
    *
    * @param otp - OTP code.
    * @returns OTP email HTML.
    */
   private getOtpEmailHtml(otp: string): string {
      const template = fs.readFileSync(EMAIL_TEMPLATE_PATH, "utf-8");
      const currentYear = new Date().getFullYear().toString();

      return template.replace(/{{OTP}}/g, otp).replace(/{{YEAR}}/g, currentYear);
   }
}
