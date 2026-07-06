import { ImageAssetsSection } from "@/interfaces/services/image-asset.service.interface";
import { Request, Response } from "express";
import { IImageAssetService } from "../../interfaces/services/image-asset.service.interface";

export class ImageAssetController {
   constructor(private readonly imageAssetService: IImageAssetService) {}

   public createAsset = async (req: Request, res: Response): Promise<void> => {
      try {
         const data = req.body;
         const file = req.file;
         const asset = await this.imageAssetService.createAsset(data, file);
         res.status(201).json({ success: true, data: asset });
      } catch (error: any) {
         res.status(500).json({ success: false, message: error.message });
      }
   };

   public getAllAssets = async (req: Request, res: Response): Promise<void> => {
      try {
         const { section, skip, take } = req.query;
         const filters: any = {};
         if (section) filters.section = section as ImageAssetsSection;

         const result = await this.imageAssetService.getAllAssets(filters, skip ? parseInt(skip as string) : undefined, take ? parseInt(take as string) : undefined);
         res.status(200).json({ success: true, ...result });
      } catch (error: any) {
         res.status(500).json({ success: false, message: error.message });
      }
   };

   public getAssetsBySection = async (req: Request, res: Response): Promise<void> => {
      try {
         const section = req.params.section as string;
         const assets = await this.imageAssetService.getAssetsBySection(section as ImageAssetsSection);
         res.status(200).json({ success: true, data: assets });
      } catch (error: any) {
         res.status(500).json({ success: false, message: error.message });
      }
   };

   public updateAsset = async (req: Request, res: Response): Promise<void> => {
      try {
         const id = req.params.id as string;
         const data = req.body;
         const file = req.file;
         const asset = await this.imageAssetService.updateAsset(parseInt(id), data, file);
         res.status(200).json({ success: true, data: asset });
      } catch (error: any) {
         res.status(500).json({ success: false, message: error.message });
      }
   };

   public deleteAsset = async (req: Request, res: Response): Promise<void> => {
      try {
         const id = req.params.id as string;
         await this.imageAssetService.deleteAsset(parseInt(id));
         res.status(200).json({ success: true, message: "Asset deleted successfully" });
      } catch (error: any) {
         res.status(500).json({ success: false, message: error.message });
      }
   };
}
