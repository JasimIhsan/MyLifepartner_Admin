import env from "@/config/env";
import { IS3Service } from "@/interfaces/services/s3.service.interface";
import { EmailService } from "@/services/email.service";

/**
 * Integration test to verify that real emails are sent successfully.
 * Ensure your .env has valid SMTP_USER, SMTP_PASS, and SMTP_FROM values.
 *
 * To run this test specifically:
 * npm test src/__tests__/email.integration.test.ts
 */
describe("EmailService Integration", () => {
   let emailService: EmailService;

   beforeAll(() => {
      // Mock S3 service to return a placeholder image URL for the header
      const mockS3Service: IS3Service = {
         getPresignedUrl: jest.fn().mockResolvedValue("https://via.placeholder.com/600x200.png?text=Life+Partner+Again"),
         uploadFile: jest.fn(),
         deleteFile: jest.fn(),
      } as unknown as IS3Service;

      emailService = new EmailService(mockS3Service);
   });

   // Increase timeout to 15 seconds to allow SMTP connection time
   jest.setTimeout(15000);

   it("should send a subscription success email", async () => {
      const recipient = env.SMTP_USER; // Sending to the configured SMTP email to verify
      const result = await emailService.sendSubscriptionSuccessEmail(recipient, "Premium Plan", "Jasim");
      expect(result).toBeDefined();
      console.log("Subscription success email sent successfully:", result.messageId);
   });

   it("should send a subscription renewal email", async () => {
      const recipient = env.SMTP_USER;
      const endDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toLocaleDateString();
      const result = await emailService.sendSubscriptionRenewalEmail(recipient, "Premium Plan", endDate, "Jasim");
      expect(result).toBeDefined();
      console.log("Subscription renewal email sent successfully:", result.messageId);
   });

   it("should send a subscription failure email", async () => {
      const recipient = env.SMTP_USER;
      const result = await emailService.sendSubscriptionFailureEmail(recipient, "Premium Plan", "Jasim");
      expect(result).toBeDefined();
      console.log("Subscription failure email sent successfully:", result.messageId);
   });
});
