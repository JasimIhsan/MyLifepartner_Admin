import axios, { type AxiosInstance } from "axios";

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
});

// ===== MAIN AXIOS INSTANCE =====
const axiosInstance: AxiosInstance = axios.create({
   baseURL,
   withCredentials: true,
});

// // ===== QUEUE HANDLER =====
// const processQueue = (error: any, token: string | null = null) => {
//    failedQueue.forEach((prom) => {
//       if (error) {
//          prom.reject(error);
//       } else {
//          prom.resolve(token);
//       }
//    });
//    failedQueue = [];
// };

// // ===== REFRESH TOKEN FUNCTION =====
// const refreshAccessToken = async (): Promise<string> => {
//    if (isRefreshing) {
//       // ✅ If already refreshing → return promise to wait for it
//       return new Promise((resolve, reject) => {
//          failedQueue.push({ resolve, reject });
//       });
//    }

//    isRefreshing = true;
//    try {
//       const response = await tokenClient.post("/user/refresh-token", null);
//       const { accessToken } = response.data;
//       if (!accessToken) throw new Error("No access token received");

//       currentAccessToken = accessToken;
//       axiosInstance.defaults.headers.common["Authorization"] = `Bearer ${accessToken}`;
//       processQueue(null, accessToken); // ✅ Retry all queued requests
//       return accessToken;
//    } catch (error) {
//       processQueue(error, null);
//       localStorage.removeItem("persist:root");
//       window.location.href = "/authenticate";
//       throw error;
//    } finally {
//       isRefreshing = false;
//    }
// };

// // ===== REQUEST INTERCEPTOR =====
// axiosInstance.interceptors.request.use(
//    (config) => {
//       if (currentAccessToken) {
//          config.headers.Authorization = `Bearer ${currentAccessToken}`;
//       }
//       return config;
//    },
//    (error) => Promise.reject(error)
// );

// // ===== RESPONSE INTERCEPTOR =====
// axiosInstance.interceptors.response.use(
//    (response) => response,
//    async (error: AxiosError) => {
//       const originalRequest: any = error.config;

//       if (error.response?.status === 401 && !originalRequest._retry) {
//          originalRequest._retry = true;
//          try {
//             const newToken = await refreshAccessToken();
//             originalRequest.headers.Authorization = `Bearer ${newToken}`;
//             return axiosInstance(originalRequest);
//          } catch (refreshError) {
//             return Promise.reject(refreshError);
//          }
//       }

//       if (error.response?.status === 403) {
//          toast.error("Caught 403 error, please log out and log back in.");
//          localStorage.removeItem("persist:root");
//          window.location.href = "/authenticate";
//       }

//       return Promise.reject(error);
//    }
// );

export default axiosInstance;
