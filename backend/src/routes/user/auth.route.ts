import { Router } from "express";

const router = Router();

router.post("/login", (req, res) => {
   res.status(200).json({ message: "User login" });
});

export default router;
