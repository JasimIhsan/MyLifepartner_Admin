import errorMiddleware from "@/middlewares/error.middleware";
import logger from "@/utils/logger";
import cors from "cors";
import express from "express";
import helmet from "helmet";
import morgan from "morgan";

// Import routes (will be added later)
import indexRoute from "@/routes/index.route";

const app = express();

// Middlewares
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
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

app.use("/api", indexRoute);

// Error Middleware
app.use(errorMiddleware);

export default app;
