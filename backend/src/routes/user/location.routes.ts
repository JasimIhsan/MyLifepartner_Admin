import { Router } from "express";
import {
   getPlaceDetails,
   reverseGeocode,
   searchLocations,
} from "../../controllers/user/location.controller";

const router = Router();

router.get("/search", searchLocations);
router.get("/place/:placeId", getPlaceDetails);
router.get("/reverse-geocode", reverseGeocode);

export default router;
