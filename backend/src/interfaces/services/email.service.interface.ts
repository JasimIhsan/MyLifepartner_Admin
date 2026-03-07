export interface IEmailService {
   sendVerificationEmail(to: string, verificationUrl: string): Promise<any>;
}
