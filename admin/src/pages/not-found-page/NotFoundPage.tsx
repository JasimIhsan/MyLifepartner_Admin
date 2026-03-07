import { Button } from "@/components/ui/button";
import { MoveLeft } from "lucide-react";
import { Link } from "react-router-dom";

const NotFoundPage = () => {
   return (
      <div className="flex h-[80vh] w-full flex-col items-center justify-center space-y-4 text-center">
         <h1 className="text-7xl font-extrabold tracking-tight">404</h1>
         <h2 className="text-2xl font-semibold tracking-tight">Page Not Found</h2>
         <p className="text-muted-foreground max-w-125">The page you are looking for doesn't exist or has been moved.</p>
         <Button asChild className="mt-4">
            <Link to="/">
               <MoveLeft className="mr-2 h-4 w-4" /> Back to Dashboard
            </Link>
         </Button>
      </div>
   );
};

export default NotFoundPage;
