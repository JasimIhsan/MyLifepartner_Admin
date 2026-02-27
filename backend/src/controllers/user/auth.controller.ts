import authService from "@/services/user/user.auth.service";
import { AuthRequest } from "@/types/AuthRequest";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";

class AuthController {
   login = asyncHandler(async (req: Request, res: Response) => {
      const { mobileNumber, otp } = req.body;
      const result = await authService.login(mobileNumber, otp);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "User login success"));
   });

   sendOtp = asyncHandler(async (req: Request, res: Response) => {
      const { mobileNumber, sendOption } = req.body;
      console.log(`👉 Mobile Number : `, mobileNumber);
      console.log(`👉 Send Option : `, sendOption);
      const result = await authService.sendOtp(mobileNumber, sendOption);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Otp sent successfully"));
   });

   resendOtp = asyncHandler(async (req: Request, res: Response) => {
      const { mobileNumber, sendOption } = req.body;
      console.log(`👉 Resending OTP to : ${mobileNumber} via ${sendOption}`);
      const result = await authService.resendOtp(mobileNumber, sendOption);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Otp resent successfully"));
   });

   detectCountry = asyncHandler(async (req: Request, res: Response) => {
      const countryCodeHeader = (req.headers["cf-ipcountry"] || req.headers["x-vercel-ip-country"]) as string;
      const ip = req.ip;

      const result = await authService.detectCountryAsync(ip, countryCodeHeader);

      return res.status(HTTP_STATUS.OK).json(
         new ApiResponse(
            HTTP_STATUS.OK,
            {
               country: result.country,
               countryCode: result.countryCode,
               callingCode: result.callingCode,
            },
            result.message
         )
      );
   });

   refreshToken = asyncHandler(async (req: Request, res: Response) => {
      const { refreshToken } = req.body;
      const result = await authService.refreshToken(refreshToken);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Token refreshed successfully"));
   });

   sendMagicLink = asyncHandler(async (req: AuthRequest, res: Response) => {
      const { email } = req.body;
      console.log("email: ", email);
      const userId = req.user?.id;
      console.log("userId: ", userId);

      await authService.sendMagicLink(userId, email);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, null, "Verification link sent to your email"));
   });

   verifyEmailPage = asyncHandler(async (req: Request, res: Response) => {
      const token = req.query.token as string;
      if (!token) {
         return res.status(HTTP_STATUS.BAD_REQUEST).send("Invalid token.");
      }

      const appSchemeUrl = `mylifepartner://verify-email?token=${token}`;

      // Intent scheme for Android
      const androidIntentUrl = `intent://verify-email?token=${token}#Intent;scheme=mylifepartner;package=com.ciltriq.mylifepartner;end;`;

      const html = `
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Verify Email - MyLifePartner</title>
          
          <!-- iOS Smart App Banners (Requires Apple Developer Team ID setup usually, but good practice) -->
          <meta name="apple-itunes-app" content="app-id=YOUR_APP_ID, app-argument=${appSchemeUrl}">

          <style>
              body {
                  font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
                  background-color: #FDF5F2;
                  margin: 0;
                  display: flex;
                  justify-content: center;
                  align-items: center;
                  height: 100vh;
                  color: #4E342E;
                  text-align: center;
                  padding: 20px;
              }
              .container {
                  background-color: #ffffff;
                  padding: 40px;
                  border-radius: 12px;
                  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.05);
                  max-width: 400px;
                  width: 100%;
              }
              h2 {
                  margin-top: 0;
                  color: #B88973;
              }
              p {
                  color: #757575;
                  line-height: 1.6;
                  margin-bottom: 25px;
              }
              .btn {
                  display: inline-block;
                  background-color: #B88973;
                  color: #ffffff !important;
                  text-decoration: none;
                  padding: 14px 30px;
                  border-radius: 8px;
                  font-size: 16px;
                  font-weight: bold;
                  transition: background-color 0.3s;
                  margin: 5px;
              }
              .btn:hover {
                  background-color: #a07764;
              }
              .loader {
                  border: 4px solid #f3f3f3;
                  border-top: 4px solid #B88973;
                  border-radius: 50%;
                  width: 30px;
                  height: 30px;
                  animation: spin 1s linear infinite;
                  margin: 0 auto 20px auto;
              }
              @keyframes spin {
                  0% { transform: rotate(0deg); }
                  100% { transform: rotate(360deg); }
              }
          </style>
          <script>
              window.onload = function() {
                  const isAndroid = /android/i.test(navigator.userAgent);
                  const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
                  
                  const appSchemeUrl = "${appSchemeUrl}";
                  const androidIntentUrl = "${androidIntentUrl}";
                  
                  // Attempt to open the app automatically
                  if (isAndroid) {
                      window.location.href = androidIntentUrl;
                  } else {
                      window.location.href = appSchemeUrl;
                      
                      // iOS specific iframe hack attempt
                      if (isIOS) {
                          setTimeout(function() {
                              window.location.replace(appSchemeUrl);
                          }, 500);
                      }
                  }

                  // Fallback: If the user is still here after 3 seconds, show the button
                  setTimeout(() => {
                      document.getElementById('loader').style.display = 'none';
                      document.getElementById('fallback').style.display = 'block';
                  }, 3000);
              };
          </script>
      </head>
      <body>
          <div class="container">
              <div id="loader" class="loader"></div>
              <h2>Verifying your email...</h2>
              <p>You are being redirected to the MyLifePartner app.</p>
              
              <div id="fallback" style="display: none;">
                  <p>If you are not redirected automatically, please click a button below to open the app manually:</p>
                  <a href="${androidIntentUrl}" class="btn" id="android-btn" style="display:none;">Open App (Android)</a>
                  <a href="${appSchemeUrl}" class="btn" id="ios-btn" style="display:none;">Open App (iOS/Web)</a>
                  <script>
                      if (/android/i.test(navigator.userAgent)) {
                          document.getElementById('android-btn').style.display = 'inline-block';
                      } else {
                          document.getElementById('ios-btn').style.display = 'inline-block';
                      }
                  </script>
              </div>
          </div>
      </body>
      </html>
      `;

      return res.status(HTTP_STATUS.OK).send(html);
   });

   verifyEmail = asyncHandler(async (req: Request, res: Response) => {
      const token = req.body.token || req.query.token;
      const result = await authService.verifyEmail(token);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, result.message));
   });
}

export default new AuthController();
