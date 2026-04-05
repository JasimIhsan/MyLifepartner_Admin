import { useEffect } from "react";
import { useDispatch } from "react-redux";
import { Route, Routes, useLocation, useNavigate } from "react-router-dom";
import axiosInstance from "./api/api.config";
import { AdminLayout } from "./components/layout/admin-layout";
import { ProtectedRoute } from "./components/layout/ProtectedRoute";
import AdminsPage from "./pages/admins-page/AdminsPage";
import DashboardPage from "./pages/dashboard-page/DashboardPage";
import LoginPage from "./pages/login-page/LoginPage";
import NotFoundPage from "./pages/not-found-page/NotFoundPage";
import ProfileVerificationPage from "./pages/profile-verification-page/ProfileVerificationPage";
import QuestionnairePage from "./pages/questionnaire-page/QuestionnairePage";
import SubscriptionPage from "./pages/subscription-page/SubscriptionPage";
import UsersPage from "./pages/users-page/UsersPage";
import { setAuthenticated, setLoading, setUser } from "./store/authSlice";

import { FeaturesPage } from "./pages/features-page/FeaturesPage"; // New
import ImageAssetsPage from "./pages/image-assets-page/ImageAssetsPage";

function App() {
   const dispatch = useDispatch();
   const location = useLocation();
   const navigate = useNavigate();

   useEffect(() => {
      const verifySession = async () => {
         try {
            const response = await axiosInstance.get("/admin/auth/me");
            dispatch(setUser(response.data.data.user));
            dispatch(setAuthenticated(true));

            if (location.pathname === "/login") {
               navigate("/", { replace: true });
            }
         } catch (error) {
            dispatch(setAuthenticated(false));
         } finally {
            dispatch(setLoading(false));
         }
      };

      verifySession();
   }, [dispatch, location.pathname, navigate]);

   return (
      <>
         <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route element={<ProtectedRoute />}>
               <Route element={<AdminLayout />}>
                  <Route path="/" element={<DashboardPage />} />
                  <Route path="/admins" element={<AdminsPage />} />
                  <Route path="/users" element={<UsersPage />} />
                  <Route path="/questionnaire" element={<QuestionnairePage />} />
                  <Route path="/profile-verification" element={<ProfileVerificationPage />} />
                  <Route path="/image-assets" element={<ImageAssetsPage />} />
                  <Route path="/subscriptions/plans" element={<SubscriptionPage />} />
                  <Route path="/subscriptions/features" element={<FeaturesPage />} />
                  <Route path="*" element={<NotFoundPage />} />
               </Route>
            </Route>
         </Routes>
      </>
   );
}

export default App;
