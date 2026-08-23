import { useEffect } from "react";
import { useDispatch } from "react-redux";
import { Route, Routes, useNavigate } from "react-router-dom";
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
import UserSubscriptionsPage from "./pages/user-subscriptions-page/UserSubscriptionsPage";
import UsersPage from "./pages/users-page/UsersPage";
import UserDetailPage from "./pages/users-page/UserDetailPage";
import { setAuthenticated, setLoading, setUser } from "./store/authSlice";

import { FeaturesPage } from "./pages/features-page/FeaturesPage"; // New
import ImageAssetsPage from "./pages/image-assets-page/ImageAssetsPage";
import LpaGuidePage from "./pages/lpa-guide-page/LpaGuidePage";
import ReportsPage from "./pages/reports-page/ReportsPage";
import ReportDetailPage from "./pages/reports-page/ReportDetailPage";
import SuspendedUsersPage from "./pages/suspended-users-page/SuspendedUsersPage";
import DeletionRequestsPage from "./pages/deletion-requests-page/DeletionRequestsPage";

import AuditLogsPage from "./pages/audit-logs-page/AuditLogsPage";
import TransactionsPage from "./pages/transactions-page/TransactionsPage";
import LegalDocumentsPage from "./pages/legal-documents-page/LegalDocumentsPage";

function App() {
   const dispatch = useDispatch();
   const navigate = useNavigate();

   useEffect(() => {
      const verifySession = async () => {
         try {
            const response = await axiosInstance.get("/admin/auth/me");
            dispatch(setUser(response.data.data.user));
            dispatch(setAuthenticated(true));

            if (window.location.pathname === "/login") {
               navigate("/", { replace: true });
            }
         } catch {
            dispatch(setAuthenticated(false));
         } finally {
            dispatch(setLoading(false));
         }
      };

      verifySession();
   }, [dispatch, navigate]);

   return (
      <>
         <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route element={<ProtectedRoute />}>
               <Route element={<AdminLayout />}>
                  <Route path="/" element={<DashboardPage />} />
                  <Route path="/admins" element={<AdminsPage />} />
                  <Route path="/users" element={<UsersPage />} />
                  <Route path="/users/:id" element={<UserDetailPage />} />
                  <Route path="/suspended-users" element={<SuspendedUsersPage />} />
                  <Route path="/deletion-requests" element={<DeletionRequestsPage />} />

                  <Route path="/questionnaire" element={<QuestionnairePage />} />
                  <Route path="/profile-verification" element={<ProfileVerificationPage />} />
                  <Route path="/image-assets" element={<ImageAssetsPage />} />
                  <Route path="/lpa-guide" element={<LpaGuidePage />} />
                  <Route path="/legal-documents" element={<LegalDocumentsPage />} />
                  <Route path="/subscriptions/users" element={<UserSubscriptionsPage />} />
                  <Route path="/subscriptions/plans" element={<SubscriptionPage />} />
                  <Route path="/subscriptions/features" element={<FeaturesPage />} />
                  <Route path="/transactions" element={<TransactionsPage />} />
                  <Route path="/reports" element={<ReportsPage />} />
                  <Route path="/reports/:id" element={<ReportDetailPage />} />
                  <Route path="/audit-logs" element={<AuditLogsPage />} />
                  <Route path="*" element={<NotFoundPage />} />
               </Route>
            </Route>
         </Routes>
      </>
   );
}

export default App;
