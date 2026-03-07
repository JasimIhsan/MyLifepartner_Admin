import type { RootState } from "@/store";
import { useSelector } from "react-redux";
import { Navigate, Outlet } from "react-router-dom";

export const ProtectedRoute = () => {
   const { isAuthenticated, isLoading } = useSelector((state: RootState) => state.auth);

   if (isLoading) {
      return (
         <div className="flex items-center justify-center min-h-screen">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
         </div>
      );
   }

   if (!isAuthenticated) {
      return <Navigate to="/login" replace />;
   }

   return <Outlet />;
};
