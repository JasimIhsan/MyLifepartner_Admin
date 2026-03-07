export interface IS3Service {
   uploadToS3(file: Express.Multer.File, folder?: string): Promise<string>;
   deleteFromS3(fileIdentifier: string): Promise<void>;
   getPresignedUrl(fileIdentifier: string, expiresIn?: number): Promise<string>;
}
