import axiosInstance from "@/api/api.config";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { ArrowLeft, CheckCircle2, CircleMinus, Crown, ShieldAlert, Trash2 } from "lucide-react";
import { type ReactNode, useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { toast } from "sonner";

type BadgeTone = "success" | "warning" | "danger" | "neutral" | "accent";

const badgeToneClass: Record<BadgeTone, string> = {
   success: "border-chart-2/30 bg-chart-2/10 text-chart-2",
   warning: "border-chart-5/30 bg-chart-5/10 text-chart-5",
   danger: "border-destructive/30 bg-destructive/10 text-destructive",
   neutral: "border-border bg-muted/40 text-muted-foreground",
   accent: "border-primary/20 bg-primary/10 text-primary",
};

function ToneBadge({ tone, children }: { tone: BadgeTone; children: ReactNode }) {
   return (
      <Badge variant="outline" className={`gap-1.5 px-2.5 py-1 text-xs font-medium ${badgeToneClass[tone]}`}>
         {children}
      </Badge>
   );
}

function StatusBadge({ active, activeLabel, inactiveLabel, tone = "success" }: { active: boolean; activeLabel: string; inactiveLabel: string; tone?: BadgeTone }) {
   return <ToneBadge tone={active ? tone : "neutral"}>{active ? activeLabel : inactiveLabel}</ToneBadge>;
}

function DetailRow({ label, children }: { label: string; children: ReactNode }) {
   return (
      <div className="grid gap-1.5 border-b border-border/60 py-3 last:border-b-0 sm:grid-cols-[8.5rem_minmax(0,1fr)] sm:items-center">
         <span className="text-sm font-medium text-muted-foreground">{label}</span>
         <div className="min-w-0 text-sm font-semibold text-foreground sm:text-right">{children}</div>
      </div>
   );
}

function OverviewCard({ title, children }: { title: string; children: ReactNode }) {
   return (
      <Card className="h-full gap-0 overflow-hidden rounded-lg border-border/80 bg-card/95 py-0 shadow-sm">
         <CardHeader className="border-b border-border/70 px-5 py-4">
            <CardTitle className="text-base font-semibold">{title}</CardTitle>
         </CardHeader>
         <CardContent className="px-5 py-1">{children}</CardContent>
      </Card>
   );
}

function Section({ title, children }: { title: string; children: ReactNode }) {
   return (
      <section className="space-y-3">
         <div className="flex items-center gap-3">
            <h2 className="text-sm font-semibold uppercase text-muted-foreground">{title}</h2>
            <div className="h-px flex-1 bg-border/70" />
         </div>
         {children}
      </section>
   );
}

function FieldItem({ label, children }: { label: string; children: ReactNode }) {
   return (
      <div className="min-w-0 rounded-md border border-border/70 bg-muted/20 px-4 py-3">
         <span className="text-xs font-medium text-muted-foreground">{label}</span>
         <div className="mt-1 min-w-0 break-words text-sm font-semibold text-foreground">{children}</div>
      </div>
   );
}

function ImageSlot({ label, src, alt, badge, objectFit = "object-cover" }: { label: string; src?: string | null; alt: string; badge?: ReactNode; objectFit?: "object-cover" | "object-contain" }) {
   return (
      <div className="min-w-0 space-y-2">
         <div className="flex items-center justify-between gap-2">
            <span className="text-xs font-medium text-muted-foreground">{label}</span>
            {badge}
         </div>
         <div className="relative flex aspect-square w-full items-center justify-center overflow-hidden rounded-md border bg-muted/40">
            {src ? (
               <img src={src} alt={alt} className={`h-full w-full ${objectFit}`} />
            ) : (
               <span className="px-3 text-center text-sm text-muted-foreground">N/A</span>
            )}
         </div>
      </div>
   );
}

function formatStatusText(value: string | null | undefined) {
   if (!value) return "Incomplete";
   return value
      .replace(/_/g, " ")
      .toLowerCase()
      .replace(/\b\w/g, (char) => char.toUpperCase());
}

export default function UserDetailPage() {
   const { id } = useParams<{ id: string }>();
   const navigate = useNavigate();
   const [user, setUser] = useState<any>(null);
   const [isLoading, setIsLoading] = useState(true);

   useEffect(() => {
      const fetchUser = async () => {
         try {
            const response = await axiosInstance.get(`/admin/users/${id}`);
            setUser(response.data.data);
         } catch (error) {
            console.error("Failed to fetch user details", error);
            toast.error("Failed to load user details");
         } finally {
            setIsLoading(false);
         }
      };

      if (id) {
         fetchUser();
      }
   }, [id]);

   if (isLoading) {
      return (
         <div className="space-y-6 flex flex-col w-full">
            <div className="flex items-center gap-4">
               <Skeleton className="h-10 w-10" />
               <div>
                  <Skeleton className="h-8 w-64 mb-2" />
                  <Skeleton className="h-4 w-40" />
               </div>
            </div>
            <Skeleton className="h-100 w-full" />
         </div>
      );
   }

   if (!user) {
      return (
         <div className="flex flex-col items-center justify-center h-[50vh] space-y-4">
            <h2 className="text-2xl font-bold">User Not Found</h2>
            <Button variant="outline" onClick={() => navigate("/users")}>
               Back to Users
            </Button>
         </div>
      );
   }

   const profile = user.profile || {};
   const partnerPref = user.partnerPreference || {};
   const selfieImages = [
      { label: "Front", src: profile.selfieUrl, alt: "User front selfie" },
      { label: "Left", src: profile.leftSelfieUrl, alt: "User left selfie" },
      { label: "Right", src: profile.rightSelfieUrl, alt: "User right selfie" },
   ];
   const profileImages = Array.isArray(profile.images) ? profile.images.slice(0, 4) : [];

   const formatDate = (date: string | null) => {
      if (!date) return "N/A";
      return new Date(date).toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" });
   };

   return (
      <div className="flex w-full flex-col gap-5 pb-8">
         <div className="flex flex-col gap-4 border-b border-border/70 pb-5 md:flex-row md:items-start md:justify-between">
            <div className="flex min-w-0 items-start gap-3">
               <Button variant="ghost" size="icon" className="mt-0.5 h-9 w-9 shrink-0 rounded-md text-muted-foreground hover:text-foreground" onClick={() => navigate("/users")}>
                  <ArrowLeft className="h-5 w-5" />
               </Button>
               <div className="min-w-0 space-y-2">
                  <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
                     <h1 className="min-w-0 truncate text-xl font-semibold sm:text-2xl">{profile.name || "Unknown"}</h1>
                     <span className="rounded-md border border-border/70 bg-muted/30 px-2 py-0.5 text-xs font-medium text-muted-foreground">ID {user.id}</span>
                  </div>
                  <div className="flex flex-wrap items-center gap-2">
                     {user.isVerified ? (
                        <ToneBadge tone="success">
                           <CheckCircle2 className="h-3 w-3" /> Verified
                        </ToneBadge>
                     ) : (
                        <ToneBadge tone="neutral">
                           <CircleMinus className="h-3 w-3" /> Unverified
                        </ToneBadge>
                     )}
                     {user.isBanned && <Badge variant="destructive">Banned</Badge>}
                     {user.isSuspended && (
                        <ToneBadge tone="warning">
                           <ShieldAlert className="h-3 w-3" /> Suspended
                        </ToneBadge>
                     )}
                     {user.isFoundingMember && (
                        <ToneBadge tone="warning">
                           <Crown className="h-3 w-3" /> Founding Member
                        </ToneBadge>
                     )}
                     {user.isDeleted && (
                        <ToneBadge tone="danger">
                           <Trash2 className="h-3 w-3" /> Deleted
                        </ToneBadge>
                     )}
                  </div>
               </div>
            </div>
         </div>

         <div className="space-y-6">
            <Section title="Overview">
               <div className="grid grid-cols-1 items-stretch gap-4 xl:grid-cols-2">
                  <OverviewCard title="Account Information">
                     <DetailRow label="Email">
                        <span className="block truncate" title={user.email || "N/A"}>
                           {user.email || "N/A"}
                        </span>
                     </DetailRow>
                     <DetailRow label="Mobile">{user.mobileNumber || "N/A"}</DetailRow>
                     <DetailRow label="Joined">{formatDate(user.createdAt)}</DetailRow>
                     <DetailRow label="Last Updated">{formatDate(user.updatedAt)}</DetailRow>
                     <DetailRow label="Profile Status">
                        <ToneBadge tone={profile.profileStatus === "COMPLETED" ? "success" : "neutral"}>{formatStatusText(profile.profileStatus)}</ToneBadge>
                     </DetailRow>
                  </OverviewCard>

                  <OverviewCard title="Account Statuses">
                     <DetailRow label="Banned">
                        <StatusBadge active={user.isBanned} activeLabel="Banned" inactiveLabel="Clear" tone="danger" />
                     </DetailRow>
                     <DetailRow label="Suspended">
                        <StatusBadge active={user.isSuspended} activeLabel="Suspended" inactiveLabel="Clear" tone="warning" />
                     </DetailRow>
                     <DetailRow label="Founding Member">
                        <StatusBadge active={user.isFoundingMember} activeLabel="Member" inactiveLabel="Not Member" tone="warning" />
                     </DetailRow>
                     <DetailRow label="Deleted">
                        <StatusBadge active={user.isDeleted} activeLabel="Deleted" inactiveLabel="Active" tone="danger" />
                     </DetailRow>
                     <DetailRow label="Deletion Requested">
                        <StatusBadge active={user.isDeleteRequested} activeLabel="Requested" inactiveLabel="None" tone="accent" />
                     </DetailRow>
                  </OverviewCard>
               </div>
            </Section>

            <Section title="Profile & Demographic">
               <Card className="gap-0 rounded-lg border-border/80 bg-card/95 py-0 shadow-sm">
                  <CardHeader className="border-b border-border/70 px-5 py-4">
                     <CardTitle className="text-base font-semibold">Demographic Details</CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-4 px-5 py-5">
                     <div className="grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-3">
                        <FieldItem label="Date of Birth">{formatDate(profile.dateOfBirth)}</FieldItem>
                        <FieldItem label="Gender">{profile.gender || "N/A"}</FieldItem>
                        <FieldItem label="Marital Status">{profile.maritalStatus || "N/A"}</FieldItem>
                        <FieldItem label="Mother Tongue">{profile.motherTongue || "N/A"}</FieldItem>
                        <FieldItem label="Location">{[profile.city, profile.state, profile.country].filter(Boolean).join(", ") || "N/A"}</FieldItem>
                        <FieldItem label="Education">{profile.highestEducation || "N/A"}</FieldItem>
                        <FieldItem label="Job">{profile.job?.name || "N/A"}</FieldItem>
                        <FieldItem label="Smoking Habit">{profile.smokingHabit || "N/A"}</FieldItem>
                        <FieldItem label="Drinking Habit">{profile.drinkingHabit || "N/A"}</FieldItem>
                     </div>
                     {profile.bio && (
                        <div className="rounded-md border border-border/70 bg-muted/20 p-4">
                           <h4 className="text-sm font-semibold">Bio</h4>
                           <p className="mt-2 whitespace-pre-wrap text-sm text-muted-foreground">{profile.bio}</p>
                        </div>
                     )}
                  </CardContent>
               </Card>
            </Section>

            <Section title="Partner Preferences">
               <Card className="gap-0 rounded-lg border-border/80 bg-card/95 py-0 shadow-sm">
                  <CardHeader className="border-b border-border/70 px-5 py-4">
                     <CardTitle className="text-base font-semibold">Partner Preferences</CardTitle>
                  </CardHeader>
                  <CardContent className="px-5 py-5">
                     <div className="grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-3">
                        <FieldItem label="Age Range">
                           {partnerPref.ageFrom || "Any"} - {partnerPref.ageTo || "Any"}
                        </FieldItem>
                        <FieldItem label="Marital Statuses">{partnerPref.maritalStatus?.join(", ") || "Any"}</FieldItem>
                        <FieldItem label="Mother Tongues">{partnerPref.motherTongue?.join(", ") || "Any"}</FieldItem>
                     </div>
                  </CardContent>
               </Card>
            </Section>

            <Section title="Images & Verification">
               <div className="grid grid-cols-1 gap-4">
                  <Card className="gap-0 rounded-lg border-border/80 bg-card/95 py-0 shadow-sm">
                     <CardHeader className="border-b border-border/70 px-5 py-4">
                        <CardTitle className="text-base font-semibold">Verification Selfies</CardTitle>
                        <CardDescription className="flex items-center gap-2 pt-1">
                           Status <Badge variant={profile.selfieStatus === "APPROVED" ? "default" : "secondary"}>{profile.selfieStatus || "None"}</Badge>
                        </CardDescription>
                     </CardHeader>
                     <CardContent className="px-5 py-5">
                        <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
                           {selfieImages.map((image) => (
                              <ImageSlot key={image.label} label={image.label} src={image.src} alt={image.alt} objectFit="object-contain" />
                           ))}
                        </div>
                     </CardContent>
                  </Card>

                  <Card className="gap-0 rounded-lg border-border/80 bg-card/95 py-0 shadow-sm">
                     <CardHeader className="border-b border-border/70 px-5 py-4">
                        <CardTitle className="text-base font-semibold">Profile Images</CardTitle>
                     </CardHeader>
                     <CardContent className="px-5 py-5">
                        <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
                           {Array.from({ length: 4 }).map((_, index) => {
                              const img = profileImages[index];
                              const imageUrl = img?.imageUrl ?? img?.url;

                              return (
                                 <ImageSlot
                                    key={img?.id ?? `profile-image-${index}`}
                                    label={`Image ${index + 1}`}
                                    src={imageUrl}
                                    alt={`Profile image ${index + 1}`}
                                    badge={img?.isPrimary ? <Badge>Primary</Badge> : null}
                                 />
                              );
                           })}
                        </div>
                        {profileImages.length === 0 && (
                           <div className="mt-4 rounded-md border border-dashed border-border/80 bg-muted/20 p-4 text-center">
                              <p className="text-sm text-muted-foreground">User hasn't uploaded any profile images.</p>
                           </div>
                        )}
                     </CardContent>
                  </Card>
               </div>
            </Section>
         </div>
      </div>
   );
}
