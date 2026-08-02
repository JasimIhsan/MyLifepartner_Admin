export interface IEmailService {
   sendOtpEmail(to: string, otp: string): Promise<unknown>;
   sendWelcomeEmail(to: string, userName?: string): Promise<unknown>;
   sendSubscriptionSuccessEmail(to: string, planName: string, userName?: string): Promise<unknown>;
   sendPaymentReceiptEmail(to: string, planName: string, price: number, userName?: string): Promise<unknown>;
   sendSubscriptionRenewalEmail(to: string, planName: string, endDate: string, userName?: string): Promise<unknown>;
   sendSubscriptionFailureEmail(to: string, planName: string, userName?: string): Promise<unknown>;
}
