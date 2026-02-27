import { Route, Routes } from "react-router-dom";
import LoginPage from "./pages/LoginPage";

function App() {
   return (
      <>
         <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route path="/" element={<h1>Dashboard</h1>} />
         </Routes>
      </>
   );
}

export default App;
