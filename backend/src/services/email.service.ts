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
const SUBSCRIPTION_EMAIL_TEMPLATE_PATH = path.join(process.cwd(), "src/templates/subscription/subscription.html");
const RECEIPT_EMAIL_TEMPLATE_PATH = path.join(process.cwd(), "src/templates/subscription/receipt.html");

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
         logger.error("Error in sendOtpEmail", { error });
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
         logger.error("Error in sendWelcomeEmail", { error });
         throw new ApiError(HTTP_STATUS.INTERNAL_SERVER_ERROR, "Failed to send Welcome email");
      }
   }

   /**
    * Sends Subscription Success email.
    */
   async sendSubscriptionSuccessEmail(to: string, planName: string, userName: string = "there"): Promise<SentMessageInfo> {
      try {
         logger.info(`[EmailService] Preparing to send Subscription Success email to: ${to} for plan: ${planName}`);
         const headerImageUrl = await this.s3Service.getPresignedUrl("assets/email-headers/welcome-header.png", URL_EXPIRY_TIME);
         const title = "Subscription Activated";
         const message = `<p>Great news! Your subscription to the <strong>${planName}</strong> plan is now active.</p><p>You now have full access to all the premium features. Start exploring and make the most out of your experience!</p>`;
         const textMessage = `Great news! Your subscription to the ${planName} plan is now active.\n\nYou now have full access to all the premium features. Start exploring and make the most out of your experience!`;
         const info = await this.transporter.sendMail({
            from: `"${APP_NAME}" <${env.SMTP_FROM ?? env.SMTP_USER}>`,
            to,
            subject: "Your Subscription is Active!",
            html: this.getSubscriptionEmailHtml(title, message, userName, headerImageUrl),
            text: textMessage,
         });
         logger.info(`[EmailService] Successfully sent Subscription Success email to: ${to}, Message ID: ${info.messageId}`);
         return info;
      } catch (error) {
         logger.error("Error in sendSubscriptionSuccessEmail", { error, to, planName });
         throw new ApiError(HTTP_STATUS.INTERNAL_SERVER_ERROR, "Failed to send Subscription Success email");
      }
   }

   /**
    * Sends Payment Receipt email.
    */
   async sendPaymentReceiptEmail(to: string, planName: string, price: number, currency: string, userName: string = "there"): Promise<SentMessageInfo> {
      try {
         logger.info(`[EmailService] Preparing to send Payment Receipt email to: ${to} for plan: ${planName}, price: ${price} ${currency}`);
         const headerImageUrl = await this.s3Service.getPresignedUrl("assets/email-headers/welcome-header.png", URL_EXPIRY_TIME);
         const title = "Payment Receipt";

         const formattedPrice = new Intl.NumberFormat("en-IN", { style: "currency", currency: currency || "INR", minimumFractionDigits: 0 }).format(price);
         const date = new Date().toLocaleDateString("en-IN", { year: "numeric", month: "long", day: "numeric" });

         const textMessage = `Thank you for your purchase! Your payment has been successfully processed.\n\nOrder Summary:\n- Plan: ${planName}\n- Date: ${date}\n- Total Amount: ${formattedPrice}\n\nYou now have full access to all the premium features associated with your plan.`;

         const htmlMessage = this.getPaymentReceiptEmailHtml(title, planName, date, formattedPrice, userName, headerImageUrl);

         const info = await this.transporter.sendMail({
            from: `"${APP_NAME}" <${env.SMTP_FROM ?? env.SMTP_USER}>`,
            to,
            subject: "Your Payment Receipt",
            html: htmlMessage,
            text: textMessage,
         });
         logger.info(`[EmailService] Successfully sent Payment Receipt email to: ${to}, Message ID: ${info.messageId}`);
         return info;
      } catch (error) {
         logger.error("Error in sendPaymentReceiptEmail", { error, to, planName });
         throw new ApiError(HTTP_STATUS.INTERNAL_SERVER_ERROR, "Failed to send Payment Receipt email");
      }
   }

   /**
    * Sends Subscription Renewal email.
    */
   async sendSubscriptionRenewalEmail(to: string, planName: string, endDate: string, userName: string = "there"): Promise<SentMessageInfo> {
      try {
         logger.info(`[EmailService] Preparing to send Subscription Renewal email to: ${to} for plan: ${planName}, endDate: ${endDate}`);
         const headerImageUrl = await this.s3Service.getPresignedUrl("assets/email-headers/welcome-header.png", URL_EXPIRY_TIME);
         const title = "Subscription Renewed";
         const message = `<p>Your subscription to the <strong>${planName}</strong> plan has been successfully renewed.</p><p>Your new billing cycle has started, and your plan is active until ${endDate}. Enjoy your continued access to premium features!</p>`;
         const textMessage = `Your subscription to the ${planName} plan has been successfully renewed.\n\nYour new billing cycle has started, and your plan is active until ${endDate}. Enjoy your continued access to premium features!`;
         const info = await this.transporter.sendMail({
            from: `"${APP_NAME}" <${env.SMTP_FROM ?? env.SMTP_USER}>`,
            to,
            subject: "Your Subscription has been Renewed",
            html: this.getSubscriptionEmailHtml(title, message, userName, headerImageUrl),
            text: textMessage,
         });
         logger.info(`[EmailService] Successfully sent Subscription Renewal email to: ${to}, Message ID: ${info.messageId}`);
         return info;
      } catch (error) {
         logger.error("Error in sendSubscriptionRenewalEmail", { error, to, planName });
         throw new ApiError(HTTP_STATUS.INTERNAL_SERVER_ERROR, "Failed to send Subscription Renewal email");
      }
   }

   /**
    * Sends Subscription Failure email.
    */
   async sendSubscriptionFailureEmail(to: string, planName: string, userName: string = "there"): Promise<SentMessageInfo> {
      try {
         logger.info(`[EmailService] Preparing to send Subscription Failure email to: ${to} for plan: ${planName}`);
         const headerImageUrl = await this.s3Service.getPresignedUrl("assets/email-headers/welcome-header.png", URL_EXPIRY_TIME);
         const title = "Action Required: Payment Failed";
         const message = `<p>We were unable to process the payment for your <strong>${planName}</strong> plan.</p><p>To avoid any interruption in your premium access, please update your payment method through the app store as soon as possible.</p>`;
         const textMessage = `We were unable to process the payment for your ${planName} plan.\n\nTo avoid any interruption in your premium access, please update your payment method through the app store as soon as possible.`;
         const info = await this.transporter.sendMail({
            from: `"${APP_NAME}" <${env.SMTP_FROM ?? env.SMTP_USER}>`,
            to,
            subject: "Payment Failed - Update your payment method",
            html: this.getSubscriptionEmailHtml(title, message, userName, headerImageUrl),
            text: textMessage,
         });
         logger.info(`[EmailService] Successfully sent Subscription Failure email to: ${to}, Message ID: ${info.messageId}`);
         return info;
      } catch (error) {
         logger.error("Error in sendSubscriptionFailureEmail", { error, to, planName });
         throw new ApiError(HTTP_STATUS.INTERNAL_SERVER_ERROR, "Failed to send Subscription Failure email");
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

   /**
    * Builds Subscription email HTML.
    */
   private getSubscriptionEmailHtml(title: string, message: string, userName: string, headerImageUrl: string): string {
      const template = fs.readFileSync(SUBSCRIPTION_EMAIL_TEMPLATE_PATH, "utf-8");
      const currentYear = new Date().getFullYear().toString();

      return template
         .replace(/{{TITLE}}/g, title)
         .replace(/{{MESSAGE}}/g, message)
         .replace(/{{USER_NAME}}/g, userName)
         .replace(/{{YEAR}}/g, currentYear)
         .replace(/{{HEADER_IMAGE_URL}}/g, headerImageUrl);
   }

   /**
    * Builds Payment Receipt email HTML.
    */
   private getPaymentReceiptEmailHtml(title: string, planName: string, date: string, formattedPrice: string, userName: string, headerImageUrl: string): string {
      const template = fs.readFileSync(RECEIPT_EMAIL_TEMPLATE_PATH, "utf-8");
      const currentYear = new Date().getFullYear().toString();

      return template
         .replace(/{{TITLE}}/g, title)
         .replace(/{{PLAN_NAME}}/g, planName)
         .replace(/{{DATE}}/g, date)
         .replace(/{{FORMATTED_PRICE}}/g, formattedPrice)
         .replace(/{{USER_NAME}}/g, userName)
         .replace(/{{YEAR}}/g, currentYear)
         .replace(/{{HEADER_IMAGE_URL}}/g, headerImageUrl);
   }
}
