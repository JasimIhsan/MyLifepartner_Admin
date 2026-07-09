export interface IImageProcessorService {
   createBlurredImageBuffer(file: Express.Multer.File): Promise<Buffer>;
}
