import { ThemeProvider } from "@/components/theme-provider.tsx";
import { Toaster } from "@/components/ui/sonner";
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { Provider } from "react-redux";
import { BrowserRouter } from "react-router-dom";
import App from "./App.tsx";
import "./index.css";
import { store } from "./store/index.ts";

createRoot(document.getElementById("root")!).render(
   <StrictMode>
      <BrowserRouter>
         <ThemeProvider defaultTheme="system" storageKey="vite-ui-theme" attribute="class">
            <Provider store={store}>
               <Toaster position="top-right" />
               <App />
            </Provider>
         </ThemeProvider>
      </BrowserRouter>
   </StrictMode>
);
