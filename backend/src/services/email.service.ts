import env from "@/config/env";
import { IEmailService } from "@/interfaces/services/email.service.interface";
import { IS3Service } from "@/interfaces/services/s3.service.interface";
import { ApiError } from "@/utils/ApiError";
import { HTTP_STATUS } from "@/utils/constants";
import logger from "@/utils/logger";
import fs from "fs";
import nodemailer, { SentMessageInfo, Transporter } from "nodemailer";
import path from "path";

const EMAIL_TEMPLATE_PATH = path.join(process.cwd(), "src/templates/otp/otp.html");
const WELCOME_EMAIL_TEMPLATE_PATH = path.join(process.cwd(), "src/templates/welcome/welcome.html");

const APP_NAME = "Life Partner Again";
const OTP_EMAIL_SUBJECT = "Your OTP - Life Partner Again";
const WELCOME_EMAIL_SUBJECT = "Welcome to Life Partner Again!";

const URL_EXPIRY_TIME = 604800; // 7 days

export class EmailService implements IEmailService {
   private readonly transporter: Transporter;
   private readonly s3Service: IS3Service;

   constructor(s3Service: IS3Service) {
      this.transporter = nodemailer.createTransport({
         service: "gmail",
         auth: {
            user: env.SMTP_USER,
            pass: env.SMTP_PASS,
         },
      });
      this.s3Service = s3Service;
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
         const headerImageUrl = await this.s3Service.getPresignedUrl("assets/email-headers/otp-header.png", URL_EXPIRY_TIME); // 7 days
         return await this.transporter.sendMail({
            from: `"${APP_NAME}" <${env.SMTP_FROM ?? env.SMTP_USER}>`,
            to,
            subject: OTP_EMAIL_SUBJECT,
            html: this.getOtpEmailHtml(otp, headerImageUrl),
         });
      } catch (error) {
         logger.error("Error in sendOtpEmail:", error);
         throw new ApiError(HTTP_STATUS.INTERNAL_SERVER_ERROR, "Failed to send OTP email");
      }
   }

   /**
    * Sends Welcome email.
    *
    * @param to - Receiver email address.
    * @param userName - User name.
    * @returns Sent email info.
    */
   async sendWelcomeEmail(to: string, userName: string = "there"): Promise<SentMessageInfo> {
      try {
         const headerImageUrl = await this.s3Service.getPresignedUrl("assets/email-headers/welcome-header.png", URL_EXPIRY_TIME); // 7 days
         return await this.transporter.sendMail({
            from: `"${APP_NAME}" <${env.SMTP_FROM ?? env.SMTP_USER}>`,
            to,
            subject: WELCOME_EMAIL_SUBJECT,
            html: this.getWelcomeEmailHtml(userName, headerImageUrl),
         });
      } catch (error) {
         logger.error("Error in sendWelcomeEmail:", error);
         throw new ApiError(HTTP_STATUS.INTERNAL_SERVER_ERROR, "Failed to send Welcome email");
      }
   }

   /**
    * Builds OTP email HTML.
    *
    * @param otp - OTP code.
    * @param headerImageUrl - S3 presigned URL for header image.
    * @returns OTP email HTML.
    */
   private getOtpEmailHtml(otp: string, headerImageUrl: string): string {
      const template = fs.readFileSync(EMAIL_TEMPLATE_PATH, "utf-8");
      const currentYear = new Date().getFullYear().toString();

      return template
         .replace(/{{OTP}}/g, otp)
         .replace(/{{YEAR}}/g, currentYear)
         .replace(/{{HEADER_IMAGE_URL}}/g, headerImageUrl);
   }

   /**
    * Builds Welcome email HTML.
    *
    * @param userName - User name.
    * @param headerImageUrl - S3 presigned URL for header image.
    * @returns Welcome email HTML.
    */
   private getWelcomeEmailHtml(userName: string, headerImageUrl: string): string {
      const template = fs.readFileSync(WELCOME_EMAIL_TEMPLATE_PATH, "utf-8");
      const currentYear = new Date().getFullYear().toString();

      return template
         .replace(/{{USER_NAME}}/g, userName)
         .replace(/{{YEAR}}/g, currentYear)
         .replace(/{{HEADER_IMAGE_URL}}/g, headerImageUrl);
   }
}
