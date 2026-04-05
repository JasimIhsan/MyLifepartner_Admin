import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { useEffect, useState } from "react";
import type { ImageAsset } from "../ImageAssetsPage";

interface ImageAssetModalProps {
   isOpen: boolean;
   onClose: () => void;
   onSave: (formData: FormData) => void;
   asset: ImageAsset | null;
}

const SECTIONS = ["LANDING_PAGE", "BANNERS", "ADS", "ONBOARDING", "ICON"];

export function ImageAssetModal({ isOpen, onClose, onSave, asset }: ImageAssetModalProps) {
   const [title, setTitle] = useState("");
   const [section, setSection] = useState("LANDING_PAGE");
   const [altText, setAltText] = useState("");
   const [redirectUrl, setRedirectUrl] = useState("");
   const [displayOrder, setDisplayOrder] = useState(0);
   const [isActive, setIsActive] = useState(true);
   const [file, setFile] = useState<File | null>(null);
   const [preview, setPreview] = useState<string | null>(null);

   useEffect(() => {
      if (asset) {
         setTitle(asset.title);
         setSection(asset.section);
         setAltText(asset.altText || "");
         setRedirectUrl(asset.redirectUrl || "");
         setDisplayOrder(asset.displayOrder);
         setIsActive(asset.isActive);
         setPreview(asset.imageUrl);
      } else {
         setTitle("");
         setSection("LANDING_PAGE");
         setAltText("");
         setRedirectUrl("");
         setDisplayOrder(0);
         setIsActive(true);
         setPreview(null);
      }
      setFile(null);
   }, [asset, isOpen]);

   const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
      const selectedFile = e.target.files?.[0];
      if (selectedFile) {
         setFile(selectedFile);
         const reader = new FileReader();
         reader.onloadend = () => {
            setPreview(reader.result as string);
         };
         reader.readAsDataURL(selectedFile);
      }
   };

   const handleSubmit = (e: React.FormEvent) => {
      e.preventDefault();
      const formData = new FormData();
      formData.append("title", title);
      formData.append("section", section);
      formData.append("altText", altText);
      formData.append("redirectUrl", redirectUrl);
      formData.append("displayOrder", displayOrder.toString());
      formData.append("isActive", isActive.toString());
      if (file) {
         formData.append("file", file);
      }
      onSave(formData);
   };

   return (
      <Dialog open={isOpen} onOpenChange={onClose}>
         <DialogContent className="sm:max-w-106.25">
            <form onSubmit={handleSubmit}>
               <DialogHeader>
                  <DialogTitle>{asset ? "Edit Asset" : "Add Image Asset"}</DialogTitle>
                  <DialogDescription>{asset ? "Update asset details and image." : "Fill in the details to add a new image asset."}</DialogDescription>
               </DialogHeader>
               <div className="grid gap-4 py-4">
                  <div className="grid grid-cols-4 items-center gap-4">
                     <Label htmlFor="title" className="text-right">
                        Title
                     </Label>
                     <Input id="title" value={title} onChange={(e) => setTitle(e.target.value)} className="col-span-3" required />
                  </div>
                  <div className="grid grid-cols-4 items-center gap-4">
                     <Label className="text-right">Section</Label>
                     <Select value={section} onValueChange={setSection}>
                        <SelectTrigger className="col-span-3">
                           <SelectValue placeholder="Select section" />
                        </SelectTrigger>
                        <SelectContent>
                           {SECTIONS.map((s) => (
                              <SelectItem key={s} value={s}>
                                 {s}
                              </SelectItem>
                           ))}
                        </SelectContent>
                     </Select>
                  </div>
                  <div className="grid grid-cols-4 items-center gap-4">
                     <Label htmlFor="image" className="text-right">
                        Image
                     </Label>
                     <div className="col-span-3 space-y-2">
                        <Input id="image" type="file" accept="image/*" onChange={handleFileChange} required={!asset} />
                        {preview && <img src={preview} alt="Preview" className="h-20 w-auto rounded border object-contain bg-muted" />}
                     </div>
                  </div>
                  <div className="grid grid-cols-4 items-center gap-4">
                     <Label htmlFor="altText" className="text-right">
                        Alt Text
                     </Label>
                     <Input id="altText" value={altText} onChange={(e) => setAltText(e.target.value)} className="col-span-3" />
                  </div>
                  <div className="grid grid-cols-4 items-center gap-4">
                     <Label htmlFor="redirectUrl" className="text-right">
                        Redirect URL
                     </Label>
                     <Input id="redirectUrl" value={redirectUrl} onChange={(e) => setRedirectUrl(e.target.value)} className="col-span-3" />
                  </div>
                  <div className="grid grid-cols-4 items-center gap-4">
                     <Label htmlFor="order" className="text-right">
                        Order
                     </Label>
                     <Input id="order" type="number" value={displayOrder} onChange={(e) => setDisplayOrder(parseInt(e.target.value) || 0)} className="col-span-3" />
                  </div>
                  <div className="grid grid-cols-4 items-center gap-4">
                     <Label className="text-right">Active</Label>
                     <div className="col-span-3 flex items-center">
                        <Switch checked={isActive} onCheckedChange={setIsActive} />
                     </div>
                  </div>
               </div>
               <DialogFooter>
                  <Button type="button" variant="outline" onClick={onClose}>
                     Cancel
                  </Button>
                  <Button type="submit">{asset ? "Update Asset" : "Save Asset"}</Button>
               </DialogFooter>
            </form>
         </DialogContent>
      </Dialog>
   );
}
