import axios, { type AxiosInstance, type InternalAxiosRequestConfig } from "axios";

const server_url = import.meta.env.VITE_SERVER_URL as string;
const baseURL = `${server_url}/api`;

// // ===== TOKEN STORAGE =====
// let currentAccessToken: string | null = null;
// let isRefreshing = false;
// let failedQueue: any[] = []; // Queue for pending requests

// export const setAccessToken = (token: string) => {
//    currentAccessToken = token;
// };

// ===== REFRESH CLIENT (NO INTERCEPTORS) =====
export const tokenClient: AxiosInstance = axios.create({
   baseURL,
   withCredentials: true,
   headers: {
      "ngrok-skip-browser-warning": "true",
   },
});

// ===== MAIN AXIOS INSTANCE =====
const axiosInstance: AxiosInstance = axios.create({
   baseURL,
   withCredentials: true,
   headers: {
      "ngrok-skip-browser-warning": "true",
   },
});

// ===== TOKEN REFRESH LOGIC =====
interface FailedRequest {
   resolve: (value?: unknown) => void;
   reject: (reason?: unknown) => void;
}

let isRefreshing = false;
let failedQueue: FailedRequest[] = []; // Queue for pending requests

const processQueue = (error: unknown) => {
   failedQueue.forEach((prom) => {
      if (error) {
         prom.reject(error);
      } else {
         prom.resolve();
      }
   });
   failedQueue = [];
};

axiosInstance.interceptors.response.use(
   (response) => response,
   async (error) => {
      const originalRequest = error.config as InternalAxiosRequestConfig & { _retry?: boolean };

      // Handle 401 Unauthorized
      if (error.response?.status === 401 && !originalRequest._retry) {
         originalRequest._retry = true;

         // Skip token refresh logic entirely if the login request fails
         if (originalRequest.url === "/admin/auth/login") {
            return Promise.reject(error);
         }

         if (isRefreshing) {
            return new Promise((resolve, reject) => {
               failedQueue.push({ resolve, reject });
            })
               .then(() => {
                  return axiosInstance(originalRequest);
               })
               .catch((err) => {
                  return Promise.reject(err);
               });
         }

         isRefreshing = true;

         try {
            await axios.post(`${baseURL}/admin/auth/refresh`, {}, { withCredentials: true });
            isRefreshing = false;
            processQueue(null);
            return axiosInstance(originalRequest); // Retry the failed request
         } catch (refreshError) {
            isRefreshing = false;
            processQueue(refreshError);

            const isLoginPage = window.location.pathname === "/login" || window.location.pathname === "/admin/login";

            // Ignore for the login route itself and avoid reloading if already on login page
            if (originalRequest.url !== "/admin/auth/login" && !isLoginPage) {
               // Redirect to login if token refresh fails
               window.location.href = "/login";
            }
            return Promise.reject(refreshError);
         }
      }

      return Promise.reject(error);
   }
);

export default axiosInstance;
