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
const REPORT_STATUS_EMAIL_TEMPLATE_PATH = path.join(process.cwd(), "src/templates/report/report-status.html");

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
    * Sends Subscription Cancelled email.
    * Informs the user that their subscription is cancelled but premium access
    * remains active until the end of the current billing period.
    */
   async sendSubscriptionCancelledEmail(to: string, planName: string, expiresAt: string, userName: string = "there"): Promise<SentMessageInfo> {
      try {
         logger.info(`[EmailService] Preparing to send Subscription Cancelled email to: ${to} for plan: ${planName}, expiresAt: ${expiresAt}`);
         const headerImageUrl = await this.s3Service.getPresignedUrl("assets/email-headers/welcome-header.png", URL_EXPIRY_TIME);
         const title = "Subscription Cancelled";
         const message = `<p>Your <strong>${planName}</strong> subscription has been cancelled.</p><p>Don't worry — you'll continue to have full premium access until <strong>${expiresAt}</strong>. After that date, your account will be downgraded to the free plan.</p><p>You can resubscribe at any time from the app to continue enjoying premium features.</p>`;
         const textMessage = `Your ${planName} subscription has been cancelled.\n\nYou'll continue to have full premium access until ${expiresAt}. After that, your account will be downgraded to the free plan.\n\nYou can resubscribe at any time from the app.`;
         const info = await this.transporter.sendMail({
            from: `"${APP_NAME}" <${env.SMTP_FROM ?? env.SMTP_USER}>`,
            to,
            subject: "Your Subscription Has Been Cancelled",
            html: this.getSubscriptionEmailHtml(title, message, userName, headerImageUrl),
            text: textMessage,
         });
         logger.info(`[EmailService] Successfully sent Subscription Cancelled email to: ${to}, Message ID: ${info.messageId}`);
         return info;
      } catch (error) {
         logger.error("Error in sendSubscriptionCancelledEmail", { error, to, planName });
         throw new ApiError(HTTP_STATUS.INTERNAL_SERVER_ERROR, "Failed to send Subscription Cancelled email");
      }
   }

   /**
    * Sends Subscription Expired email.
    * Sent when the subscription has fully expired and the user has been
    * downgraded to the free plan.
    */
   async sendSubscriptionExpiredEmail(to: string, planName: string, userName: string = "there"): Promise<SentMessageInfo> {
      try {
         logger.info(`[EmailService] Preparing to send Subscription Expired email to: ${to} for plan: ${planName}`);
         const headerImageUrl = await this.s3Service.getPresignedUrl("assets/email-headers/welcome-header.png", URL_EXPIRY_TIME);
         const title = "Your Subscription Has Expired";
         const message = `<p>Your <strong>${planName}</strong> subscription has expired and your account has been moved to the free plan.</p><p>You can resubscribe at any time from the app to regain access to all premium features.</p>`;
         const textMessage = `Your ${planName} subscription has expired. Your account has been moved to the free plan.\n\nYou can resubscribe at any time from the app to regain premium access.`;
         const info = await this.transporter.sendMail({
            from: `"${APP_NAME}" <${env.SMTP_FROM ?? env.SMTP_USER}>`,
            to,
            subject: "Your Subscription Has Expired",
            html: this.getSubscriptionEmailHtml(title, message, userName, headerImageUrl),
            text: textMessage,
         });
         logger.info(`[EmailService] Successfully sent Subscription Expired email to: ${to}, Message ID: ${info.messageId}`);
         return info;
      } catch (error) {
         logger.error("Error in sendSubscriptionExpiredEmail", { error, to, planName });
         throw new ApiError(HTTP_STATUS.INTERNAL_SERVER_ERROR, "Failed to send Subscription Expired email");
      }
   }

   /**
    * Sends Subscription Restored email.
    * Sent when a previously cancelled subscription is un-cancelled (user
    * reactivated auto-renewal before expiry).
    */
   async sendSubscriptionRestoredEmail(to: string, planName: string, userName: string = "there"): Promise<SentMessageInfo> {
      try {
         logger.info(`[EmailService] Preparing to send Subscription Restored email to: ${to} for plan: ${planName}`);
         const headerImageUrl = await this.s3Service.getPresignedUrl("assets/email-headers/welcome-header.png", URL_EXPIRY_TIME);
         const title = "Subscription Reactivated";
         const message = `<p>Welcome back! Your <strong>${planName}</strong> subscription has been successfully reactivated.</p><p>Your auto-renewal is now turned back on and your premium access continues uninterrupted. Thank you for staying with us!</p>`;
         const textMessage = `Welcome back! Your ${planName} subscription has been successfully reactivated.\n\nAuto-renewal is on and your premium access continues. Thank you for staying with us!`;
         const info = await this.transporter.sendMail({
            from: `"${APP_NAME}" <${env.SMTP_FROM ?? env.SMTP_USER}>`,
            to,
            subject: "Your Subscription Has Been Reactivated",
            html: this.getSubscriptionEmailHtml(title, message, userName, headerImageUrl),
            text: textMessage,
         });
         logger.info(`[EmailService] Successfully sent Subscription Restored email to: ${to}, Message ID: ${info.messageId}`);
         return info;
      } catch (error) {
         logger.error("Error in sendSubscriptionRestoredEmail", { error, to, planName });
         throw new ApiError(HTTP_STATUS.INTERNAL_SERVER_ERROR, "Failed to send Subscription Restored email");
      }
   }

   /**
    * Sends Report Status Update email.
    */
   async sendReportStatusUpdateEmail(to: string, userName: string, reportedUserName: string, reportId: number, status: string, notes?: string): Promise<SentMessageInfo> {
      try {
         logger.info(`[EmailService] Preparing to send Report Status Update email to: ${to} for report: ${reportId}`);
         const headerImageUrl = await this.s3Service.getPresignedUrl("assets/email-headers/welcome-header.png", URL_EXPIRY_TIME);
         const title = "Update on Your Report";
         let message = `<p>We wanted to let you know that the status of your report against <strong>${reportedUserName}</strong> has been updated to: <strong>${status.replace(/_/g, " ")}</strong>.</p>`;
         if (notes) {
            message += `<p><strong>Admin Note:</strong> ${notes}</p>`;
         }
         message += `<p>Thank you for helping us keep our community safe.</p>`;
         
         let textMessage = `We wanted to let you know that the status of your report against ${reportedUserName} has been updated to: ${status.replace(/_/g, " ")}.\n\n`;
         if (notes) {
            textMessage += `Admin Note: ${notes}\n\n`;
         }
         textMessage += `Thank you for helping us keep our community safe.`;

         const info = await this.transporter.sendMail({
            from: `"${APP_NAME}" <${env.SMTP_FROM ?? env.SMTP_USER}>`,
            to,
            subject: "Update on Your Report",
            html: this.getReportStatusEmailHtml(title, message, userName, headerImageUrl),
            text: textMessage,
         });
         logger.info(`[EmailService] Successfully sent Report Status Update email to: ${to}, Message ID: ${info.messageId}`);
         return info;
      } catch (error) {
         logger.error("Error in sendReportStatusUpdateEmail", { error, to, reportId });
         throw new ApiError(HTTP_STATUS.INTERNAL_SERVER_ERROR, "Failed to send Report Status Update email");
      }
   }

   /**
    * Sends Moderation Action email.
    */
   async sendModerationEmail(to: string, userName: string, title: string, message: string): Promise<SentMessageInfo> {
      try {
         logger.info(`[EmailService] Preparing to send Moderation email to: ${to}`);
         const headerImageUrl = await this.s3Service.getPresignedUrl("assets/email-headers/welcome-header.png", URL_EXPIRY_TIME);
         
         const textMessage = `${title}\n\nHi ${userName},\n\n${message}\n\nIf you need any help, our support team is always here for you.`;

         const info = await this.transporter.sendMail({
            from: `"${APP_NAME}" <${env.SMTP_FROM ?? env.SMTP_USER}>`,
            to,
            subject: title,
            html: this.getReportStatusEmailHtml(title, message, userName, headerImageUrl),
            text: textMessage,
         });
         logger.info(`[EmailService] Successfully sent Moderation email to: ${to}, Message ID: ${info.messageId}`);
         return info;
      } catch (error) {
         logger.error("Error in sendModerationEmail", { error, to });
         throw new ApiError(HTTP_STATUS.INTERNAL_SERVER_ERROR, "Failed to send moderation email");
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
    * Builds Report Status Update email HTML.
    */
   private getReportStatusEmailHtml(title: string, message: string, userName: string, headerImageUrl: string): string {
      const template = fs.readFileSync(REPORT_STATUS_EMAIL_TEMPLATE_PATH, "utf-8");
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

   /**
    * Sends Account Deletion Verification email.
    */
   async sendAccountDeletionEmail(to: string, token: string): Promise<SentMessageInfo> {
      try {
         logger.info(`[EmailService] Preparing to send Account Deletion email to: ${to}`);
         const headerImageUrl = await this.s3Service.getPresignedUrl("assets/email-headers/welcome-header.png", URL_EXPIRY_TIME);
         
         const verificationLink = `${env.BASE_URL}/api/user/account-deletion/verify?token=${token}`;
         const textMessage = `You have requested to delete your account.\n\nPlease click the link below to verify your request:\n${verificationLink}\n\nIf you did not request this, please ignore this email.`;
         const message = `<p>You have requested to delete your account.</p><p>Please click the button below to verify your request.</p><p><a href="${verificationLink}" style="padding: 10px 20px; background-color: #ff4b4b; color: white; text-decoration: none; border-radius: 5px;">Verify Deletion</a></p><p>If you did not request this, please ignore this email.</p>`;

         const info = await this.transporter.sendMail({
            from: `"${APP_NAME}" <${env.SMTP_FROM ?? env.SMTP_USER}>`,
            to,
            subject: "Verify Account Deletion Request",
            html: this.getSubscriptionEmailHtml("Verify Account Deletion", message, "User", headerImageUrl),
            text: textMessage,
         });
         logger.info(`[EmailService] Successfully sent Account Deletion email to: ${to}, Message ID: ${info.messageId}`);
         return info;
      } catch (error) {
         logger.error("Error in sendAccountDeletionEmail", { error, to });
         throw new ApiError(HTTP_STATUS.INTERNAL_SERVER_ERROR, "Failed to send account deletion email");
      }
   }
}
