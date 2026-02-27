import axiosInstance from "./api.config";

export const adminLogin = async (username: string, password: string) => {
   try {
      const response = await axiosInstance.post("/admin/auth/login", { username, password });
      return response.data;
   } catch (error) {
      throw error;
   }
};
