export interface S3UploadOptions {
   buffer: Buffer;
   folder: string;
   extension: string;
   contentType: string;
}

export interface IS3Service {
   uploadToS3(file: Express.Multer.File, folder?: string): Promise<string>;
   uploadBufferToS3(options: S3UploadOptions): Promise<string>;
   deleteFromS3(fileIdentifier: string): Promise<void>;
   getPresignedUrl(fileIdentifier: string, expiresIn?: number): Promise<string>;
}
