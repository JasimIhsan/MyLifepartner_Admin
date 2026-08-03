export interface IEmailService {
   sendOtpEmail(to: string, otp: string): Promise<unknown>;
   sendWelcomeEmail(to: string, userName?: string): Promise<unknown>;
   sendSubscriptionSuccessEmail(to: string, planName: string, userName?: string): Promise<unknown>;
   sendPaymentReceiptEmail(to: string, planName: string, price: number, currency: string, userName?: string): Promise<unknown>;
   sendSubscriptionRenewalEmail(to: string, planName: string, endDate: string, userName?: string): Promise<unknown>;
   sendSubscriptionFailureEmail(to: string, planName: string, userName?: string): Promise<unknown>;
   sendSubscriptionCancelledEmail(to: string, planName: string, expiresAt: string, userName?: string): Promise<unknown>;
   sendSubscriptionExpiredEmail(to: string, planName: string, userName?: string): Promise<unknown>;
   sendSubscriptionRestoredEmail(to: string, planName: string, userName?: string): Promise<unknown>;
   sendReportStatusUpdateEmail(to: string, userName: string, reportedUserName: string, reportId: number, status: string, notes?: string): Promise<unknown>;
}
