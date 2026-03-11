export interface IEmailService {
   sendVerificationEmail(to: string, verificationUrl: string): Promise<any>;
   sendPasswordResetEmail(to: string, resetUrl: string): Promise<any>;
}
