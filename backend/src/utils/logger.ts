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

const getLogLevel = (): string => {
   return env.NODE_ENV === "development" ? "debug" : "warn";
};

winston.addColors(LOG_COLORS);

const loggerFormat = winston.format.combine(
   winston.format.timestamp({
      format: "YYYY-MM-DD HH:mm:ss",
   }),
   winston.format.colorize({
      all: true,
   }),
   winston.format.printf(({ timestamp, level, message }) => {
      return `${timestamp} ${level}: ${message}`;
   })
);

const logger = winston.createLogger({
   level: getLogLevel(),
   levels: LOG_LEVELS,
   format: loggerFormat,
   transports: [new winston.transports.Console()],
});

export default logger;
