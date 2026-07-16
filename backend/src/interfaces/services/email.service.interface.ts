export interface IEmailService {
   sendOtpEmail(to: string, otp: string): Promise<unknown>;
   sendWelcomeEmail(to: string, userName?: string): Promise<unknown>;
}
