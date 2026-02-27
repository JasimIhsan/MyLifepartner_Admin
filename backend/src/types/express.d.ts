declare global {
   namespace Express {
      interface Request {
         user?: any; // The payload attached by verifyJWT ({ id, mobileNumber, etc })
      }
   }
}
