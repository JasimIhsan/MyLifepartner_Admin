import { Route, Routes } from "react-router-dom";
import { AdminLayout } from "./components/layout/admin-layout";
import DashboardPage from "./pages/dashboard-page/DashboardPage";
import LoginPage from "./pages/login-page/LoginPage";
import UsersPage from "./pages/users-page/UsersPage";

function App() {
   return (
      <>
         <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route element={<AdminLayout />}>
               <Route path="/" element={<DashboardPage />} />
               <Route path="/users" element={<UsersPage />} />
            </Route>
         </Routes>
      </>
   );
}

export default App;
