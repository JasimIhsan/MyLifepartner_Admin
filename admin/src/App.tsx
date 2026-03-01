import { Route, Routes } from "react-router-dom";
import { AdminLayout } from "./components/layout/admin-layout";
import DashboardPage from "./pages/dashboard-page/DashboardPage";
import LoginPage from "./pages/login-page/LoginPage";
import NotFoundPage from "./pages/not-found-page/NotFoundPage";
import QuestionnairePage from "./pages/questionnaire-page/QuestionnairePage";
import UsersPage from "./pages/users-page/UsersPage";
import ProfileVerificationPage from "./pages/profile-verification-page/ProfileVerificationPage";

function App() {
   return (
      <>
         <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route element={<AdminLayout />}>
               <Route path="/" element={<DashboardPage />} />
               <Route path="/users" element={<UsersPage />} />
               <Route path="/questionnaire" element={<QuestionnairePage />} />
               <Route path="/profile-verification" element={<ProfileVerificationPage />} />
               <Route path="*" element={<NotFoundPage />} />
            </Route>
         </Routes>
      </>
   );
}

export default App;
