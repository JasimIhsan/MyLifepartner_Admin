import nodemailer from "nodemailer";
import fs from "fs";
import path from "path";
import env from "../config/env";
import { IEmailService } from "../interfaces/services/email.service.interface";

export class EmailService implements IEmailService {
   private transporter: nodemailer.Transporter;

   constructor() {
      this.transporter = nodemailer.createTransport({
         service: "gmail",
         auth: {
            user: env.SMTP_USER,
            pass: env.SMTP_PASS,
         },
      });
   }

   public async sendOtpEmail(to: string, otp: string) {
      try {
         const info = await this.transporter.sendMail({
            from: `"Life Partner Again" <${env.SMTP_FROM || env.SMTP_USER}>`,
            to,
            subject: "Your OTP - Life Partner Again",
            html: this.getOtpEmailHtml(otp),
         });

         console.log("Message sent: %s", info.messageId);

         return info;
      } catch (error) {
         console.error("Error sending email: ", error);
         throw new Error("Failed to send OTP email");
      }
   }

   private getOtpEmailHtml(otp: string): string {
      const templatePath = path.join(process.cwd(), "src/templates/emails/otp.html");
      let html = fs.readFileSync(templatePath, "utf-8");
      
      const year = new Date().getFullYear().toString();
      html = html.replace(/{{OTP}}/g, otp);
      html = html.replace(/{{YEAR}}/g, year);
      
      return html;
   }

}
