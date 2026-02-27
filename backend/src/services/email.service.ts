import nodemailer from "nodemailer";
import env from "../config/env";

class EmailService {
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
      return `
      <!DOCTYPE html>
      <html>
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
              body {
                  font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
                  background-color: #FDF5F2; /* App background */
                  margin: 0;
                  padding: 0;
                  color: #4E342E; /* Text primary */
              }
              .container {
                  max-width: 600px;
                  margin: 40px auto;
                  background-color: #ffffff;
                  border-radius: 12px;
                  overflow: hidden;
                  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.05);
              }
              .header {
                  background-color: #B88973; /* Primary */
                  padding: 30px 20px;
                  text-align: center;
              }
              .header h1 {
                  color: #ffffff;
                  margin: 0;
                  font-size: 24px;
                  font-weight: 600;
              }
              .content {
                  padding: 40px 30px;
                  text-align: center;
              }
              .content p {
                  font-size: 16px;
                  line-height: 1.6;
                  color: #757575; /* Text secondary */
                  margin-bottom: 25px;
              }
              .btn {
                  display: inline-block;
                  background-color: #B88973; /* Primary */
                  color: #ffffff !important;
                  text-decoration: none;
                  padding: 14px 30px;
                  border-radius: 8px;
                  font-size: 16px;
                  font-weight: bold;
                  margin-top: 10px;
                  margin-bottom: 10px;
              }
              .footer {
                  background-color: #FBEFEA; /* Primary light */
                  padding: 20px;
                  text-align: center;
                  font-size: 13px;
                  color: #8D6E63; /* Primary dark */
              }
              .sub-text {
                  font-size: 13px;
                  color: #a0a0a0;
                  margin-top: 30px;
              }
          </style>
      </head>
      <body>
          <div class="container">
              <div class="header">
                  <h1>Verify Your Email</h1>
              </div>
              <div class="content">
                  <p>Welcome to <strong>MyLifePartner</strong>!</p>
                  <p>Please verify your email address to ensure the security of your account and complete your profile setup.</p>
                  <a href="${verificationUrl}" class="btn">Verify Email</a>
                  <p class="sub-text">This link will expire in 15 minutes.</p>
                  <p class="sub-text">If you did not request this email, you can safely ignore it.</p>
              </div>
              <div class="footer">
                  &copy; ${new Date().getFullYear()} MyLifePartner. All rights reserved.
              </div>
          </div>
      </body>
      </html>
      `;
   }
}

export default new EmailService();
