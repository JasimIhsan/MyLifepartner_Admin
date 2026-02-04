import { useState } from "react";
import "./App.css";
import axiosInstance from "./api/config/api.config";

function App() {
   const [data, setData] = useState("");

   const handleApiTest = async () => {
      const response = await axiosInstance.get("/health");
      setData(response.data.message);
   };

   return (
      <>
         <h1>Admin Panel</h1>
         {data && <p>{data} ✅✅✅</p>}
         <button onClick={handleApiTest}>Api Test</button>
      </>
   );
}

export default App;
