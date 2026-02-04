import app from "./app";
import env from "./config/env";
import prisma from "./config/prisma";
import logger from "./utils/logger";

const validateDatabaseConnection = async () => {
   try {
      await prisma.$connect();
      logger.info("Database connected successfully");
   } catch (error) {
      logger.error("Database connection failed", error);
      process.exit(1);
   }
};

const startServer = async () => {
   await validateDatabaseConnection();

   app.listen(env.PORT, () => {
      logger.info(`=================================`);
      logger.info(`======= ENV: ${env.NODE_ENV} =======`);
      logger.info(`🚀 App listening on the port ${env.PORT}`);
      logger.info(`=================================`);
   });
};

startServer();
