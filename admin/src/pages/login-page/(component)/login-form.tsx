import { adminLogin } from "@/api/auth.service";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Field, FieldGroup, FieldLabel } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { handleApiError } from "@/lib/error-handler";
import { cn } from "@/lib/utils";
import { setAuthenticated } from "@/store/authSlice";
import { Eye, EyeOff } from "lucide-react";
import { useState } from "react";
import { useDispatch } from "react-redux";
import { useNavigate } from "react-router-dom";

export function LoginForm({ className, ...props }: React.ComponentProps<"div">) {
   const [showPassword, setShowPassword] = useState(false);
   const [loading, setLoading] = useState(false);
   const [error, setError] = useState<string | null>(null);
   const [username, setUsername] = useState("");
   const [password, setPassword] = useState("");
   const navigate = useNavigate();
   const dispatch = useDispatch();

   const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
      e.preventDefault();
      setLoading(true);
      setError(null);

      try {
         const response = await adminLogin(username, password);
         console.log("Login successful:", response.data);
         dispatch(setAuthenticated(true)); // Update Redux state
         navigate("/");
      } catch (err) {
         console.error("Login failed:", err);
         setError(handleApiError(err, "Login failed. Please try again."));
      } finally {
         setLoading(false);
      }
   };

   return (
      <div className={cn("flex flex-col gap-6", className)} {...props}>
         <Card>
            <CardHeader>
               <CardTitle className="text-center">MyLifePartner Admin</CardTitle>
               <CardDescription className="text-center">Login to admin panel</CardDescription>
            </CardHeader>
            <CardContent>
               <form onSubmit={handleSubmit}>
                  <FieldGroup>
                     <Field>
                        <FieldLabel htmlFor="username">Username</FieldLabel>
                        <Input id="username" type="text" onChange={(e) => setUsername(e.target.value)} placeholder="username" required disabled={loading} />
                     </Field>
                     <Field>
                        <FieldLabel htmlFor="password">Password</FieldLabel>
                        <div className="relative">
                           <Input id="password" className="pr-10" type={showPassword ? "text" : "password"} onChange={(e) => setPassword(e.target.value)} placeholder="password" required disabled={loading} />
                           <button type="button" onClick={() => setShowPassword(!showPassword)} className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors cursor-pointer" disabled={loading}>
                              {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                           </button>
                        </div>
                     </Field>
                     {error && <p className="text-sm text-destructive text-center font-medium">{error}</p>}
                     <Field>
                        <Button type="submit" className="w-full" disabled={loading}>
                           {loading ? "Logging in..." : "Login"}
                        </Button>
                     </Field>
                  </FieldGroup>
               </form>
            </CardContent>
         </Card>
      </div>
   );
}
