import errorMiddleware from "@/middlewares/error.middleware";
import { globalLimiter } from "@/middlewares/rateLimiter.middleware";
import indexRoute from "@/routes/index.route";
import logger from "@/utils/logger";
import cookieParser from "cookie-parser";
import cors from "cors";
import express from "express";
import helmet from "helmet";
import morgan from "morgan";

const app = express();

// Trust proxy for IP detection behind Vercel/Cloudflare
app.set("trust proxy", true);

// Middlewares
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());
app.use(cors({ origin: true, credentials: true }));
app.use(helmet());

// Logger middleware
const stream = {
   write: (message: string) => {
      logger.info(message.substring(0, message.lastIndexOf("\n")));
   },
};
app.use(morgan("dev", { stream }));

// Routes
app.get("/api/health", (req, res) => {
   res.status(200).json({ status: "UP", message: "Server is running" });
});

app.use("/api", globalLimiter, indexRoute);

// Error Middleware
app.use(errorMiddleware);

export default app;
