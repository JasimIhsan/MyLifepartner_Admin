import { ApiError } from "@/utils/ApiError";
import multer from "multer";

const MAX_FILE_SIZE_IN_BYTES = 15 * 1024 * 1024;

const ALLOWED_IMAGE_MIME_TYPES = ["image/jpeg", "image/jpg", "image/png", "image/webp"];

const storage = multer.memoryStorage();

export const multerConfig = multer({
   storage,
   limits: {
      fileSize: MAX_FILE_SIZE_IN_BYTES,
   },
   fileFilter: (_req, file, callback) => {
      if (!ALLOWED_IMAGE_MIME_TYPES.includes(file.mimetype)) {
         callback(new ApiError(400, "Invalid file type. Only JPG, JPEG, PNG, and WEBP are allowed."));
         return;
      }

      callback(null, true);
   },
});
