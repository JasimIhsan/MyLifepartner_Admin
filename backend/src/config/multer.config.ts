import { ApiError } from "@/utils/ApiError";
import multer from "multer";

const storage = multer.memoryStorage();

export const multerConfig = multer({
   storage,
   limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB limit
   fileFilter: (req, file, cb) => {
      const allowedMimes = ["image/jpeg", "image/jpg", "image/png", "image/webp"];
      if (allowedMimes.includes(file.mimetype)) {
         cb(null, true);
      } else {
         cb(new ApiError(400, "Invalid file type. Only JPG, JPEG, PNG, and WEBP are allowed."));
      }
   },
});
