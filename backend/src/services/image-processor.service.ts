import { IImageProcessorService } from "@/interfaces/services/image-processor.service.interface";
import sharp from "sharp";

export class ImageProcessorService implements IImageProcessorService {
   /**
    * Creates a blurred version of the uploaded image buffer.
    * Uses sharp to resize, apply strong blur, and output as JPEG.
    * 
    * @param file Express.Multer.File containing the original image buffer
    * @returns Promise<Buffer> containing the blurred image
    */
   public async createBlurredImageBuffer(file: Express.Multer.File): Promise<Buffer> {
      return sharp(file.buffer)
         .resize({ width: 200, withoutEnlargement: true })
         .jpeg({ quality: 30 })
         .blur(20)
         .toBuffer();
   }
}
