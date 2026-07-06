class ApiError extends Error {
   public readonly statusCode: number;
   public readonly data: null;
   public readonly success: false;
   public readonly errors: unknown[];

   constructor(statusCode: number, message: string = "Something went wrong", errors: unknown[] = [], stack?: string) {
      super(message);

      this.name = "ApiError";
      this.statusCode = statusCode;
      this.data = null;
      this.success = false;
      this.errors = errors;

      if (stack) {
         this.stack = stack;
      } else {
         Error.captureStackTrace(this, this.constructor);
      }
   }
}

export { ApiError };
