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

   public async sendVerificationEmail(to: string, verificationUrl: string) {
      try {
         const info = await this.transporter.sendMail({
            from: `"MyLifePartner" <${env.SMTP_FROM || env.SMTP_USER}>`,
            to,
            subject: "Verify Your Email - MyLifePartner",
            html: this.getVerificationEmailHtml(verificationUrl),
         });

         console.log("Message sent: %s", info.messageId);

         return info;
      } catch (error) {
         console.error("Error sending email: ", error);
         throw new Error("Failed to send verification email");
      }
   }

   private getVerificationEmailHtml(verificationUrl: string): string {
      const templatePath = path.join(__dirname, "../../src/templates/emails/verification.html");
      let html = fs.readFileSync(templatePath, "utf-8");
      
      const year = new Date().getFullYear().toString();
      html = html.replace(/{{VERIFICATION_URL}}/g, verificationUrl);
      html = html.replace(/{{YEAR}}/g, year);
      
      return html;
   }

   public async sendPasswordResetEmail(to: string, resetUrl: string) {
      try {
         const info = await this.transporter.sendMail({
            from: `"MyLifePartner" <${env.SMTP_FROM || env.SMTP_USER}>`,
            to,
            subject: "Reset Your Password - MyLifePartner",
            html: this.getPasswordResetEmailHtml(resetUrl),
         });

         console.log("Message sent: %s", info.messageId);

         return info;
      } catch (error) {
         console.error("Error sending email: ", error);
         throw new Error("Failed to send password reset email");
      }
   }

   private getPasswordResetEmailHtml(resetUrl: string): string {
      const templatePath = path.join(__dirname, "../../src/templates/emails/password-reset.html");
      let html = fs.readFileSync(templatePath, "utf-8");
      
      const year = new Date().getFullYear().toString();
      html = html.replace(/{{RESET_URL}}/g, resetUrl);
      html = html.replace(/{{YEAR}}/g, year);
      
      return html;
   }

}
