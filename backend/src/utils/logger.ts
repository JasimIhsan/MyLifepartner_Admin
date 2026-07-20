import env from "@/config/env";
import winston from "winston";

const LOG_LEVELS = {
   error: 0,
   warn: 1,
   info: 2,
   http: 3,
   debug: 4,
};

const LOG_COLORS = {
   error: "red",
   warn: "yellow",
   info: "green",
   http: "magenta",
   debug: "white",
};

winston.addColors(LOG_COLORS);

const isDevelopment = env.NODE_ENV === "development";
const isProduction = env.NODE_ENV === "production";

const getLogLevel = (): keyof typeof LOG_LEVELS => {
   if (isDevelopment) return "debug";
   if (isProduction) return "info";

   return "info";
};

const developmentFormat = winston.format.combine(
   winston.format.timestamp({
      format: "YYYY-MM-DD HH:mm:ss",
   }),
   winston.format.errors({
      stack: true,
   }),
   winston.format.colorize({
      all: true,
   }),
   winston.format.printf(({ timestamp, level, message, stack, ...metadata }) => {
      const output = stack || message;

      const extraData = Object.keys(metadata).length > 0 ? `\n${JSON.stringify(metadata, null, 2)}` : "";

      return `${timestamp} [${level}]: ${output}${extraData}`;
   })
);

const productionFormat = winston.format.combine(
   winston.format.timestamp(),
   winston.format.errors({
      stack: true,
   }),
   winston.format.metadata({
      fillExcept: ["timestamp", "level", "message", "stack"],
   }),
   winston.format.json()
);

const logger = winston.createLogger({
   levels: LOG_LEVELS,
   level: getLogLevel(),
   format: isDevelopment ? developmentFormat : productionFormat,
   // defaultMeta: {
   //    service: env.APP_NAME,
   //    environment: env.NODE_ENV,
   // },
   transports: [
      new winston.transports.Console({
         handleExceptions: true,
         handleRejections: true,
      }),
   ],
   exitOnError: false,
});

export const serializeError = (error: unknown) => {
   if (error instanceof Error) {
      return {
         name: error.name,
         message: error.message,
         stack: error.stack,
      };
   }

   return {
      message: String(error),
   };
};

export default logger;
