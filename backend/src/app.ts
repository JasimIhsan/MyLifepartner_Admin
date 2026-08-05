import errorMiddleware from "@/middlewares/error.middleware";
import { globalLimiter } from "@/middlewares/rateLimiter.middleware";
import indexRoute from "@/routes/index.route";
import env from "@/config/env";
import logger from "@/utils/logger";
import cookieParser from "cookie-parser";
import cors from "cors";
import express from "express";
import helmet from "helmet";
import morgan from "morgan";

// Global BigInt JSON serialization helper without using 'any'
declare global {
   interface BigInt {
      toJSON(): string | number;
   }
}

BigInt.prototype.toJSON = function (this: bigint): string | number {
   const num = Number(this);
   return Number.isSafeInteger(num) ? num : this.toString();
};

const app = express();

// Trust proxy for IP detection behind Vercel/Cloudflare
app.set("trust proxy", 1);

// Middlewares
import { auditContextMiddleware } from "./middlewares/auditContext.middleware";
app.use(auditContextMiddleware);
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());


// CORS: restrict to allowlist in production, open in development
const allowedOrigins = env.ALLOWED_ORIGINS
   ? env.ALLOWED_ORIGINS.split(",")
        .map((o) => o.trim())
        .filter(Boolean)
   : [];

app.use(
   cors({
      origin: env.NODE_ENV === "production" && allowedOrigins.length > 0 ? allowedOrigins : true,
      credentials: true,
   })
);
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
