import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Image as ImageIcon, MoreVertical, Plus } from "lucide-react";
import type { ImageAsset } from "../ImageAssetsPage";

interface ImageAssetsTableProps {
   data: ImageAsset[];
   isFetching: boolean;
   onAdd: () => void;
   onEdit: (asset: ImageAsset) => void;
   onDelete: (id: number) => void;
   sectionFilter: string;
   onSectionFilterChange: (value: string) => void;
}

const SECTIONS = ["BANNERS", "ADS", "ONBOARDING_SCREEN", "ICON"];

export function ImageAssetsTable({ data, isFetching, onAdd, onEdit, onDelete, sectionFilter, onSectionFilterChange }: ImageAssetsTableProps) {
   return (
      <div className="w-full space-y-4">
         <div className="flex items-center justify-between gap-4">
            <div className="flex items-center gap-2">
               <Select value={sectionFilter} onValueChange={onSectionFilterChange}>
                  <SelectTrigger className="w-50">
                     <SelectValue placeholder="Filter by Section" />
                  </SelectTrigger>
                  <SelectContent>
                     <SelectItem value="ALL">All Sections</SelectItem>
                     {SECTIONS.map((s) => (
                        <SelectItem key={s} value={s}>
                           {s.replace("_", " ")}
                        </SelectItem>
                     ))}
                  </SelectContent>
               </Select>
               {sectionFilter && sectionFilter !== "ALL" && (
                  <Button variant="ghost" onClick={() => onSectionFilterChange("")}>
                     Clear
                  </Button>
               )}
            </div>
            <Button onClick={onAdd} size="sm">
               <Plus className="mr-2 h-4 w-4" />
               Add Asset
            </Button>
         </div>

         <div className="rounded-md border bg-card">
            <Table>
               <TableHeader>
                  <TableRow>
                     <TableHead className="w-25">Preview</TableHead>
                     <TableHead>Title</TableHead>
                     <TableHead>Section</TableHead>
                     <TableHead>Order</TableHead>
                     <TableHead>Status</TableHead>
                     <TableHead className="w-25">Actions</TableHead>
                  </TableRow>
               </TableHeader>
               <TableBody>
                  {isFetching ? (
                     <TableRow>
                        <TableCell colSpan={6} className="h-24 text-center">
                           Loading assets...
                        </TableCell>
                     </TableRow>
                  ) : data.length === 0 ? (
                     <TableRow>
                        <TableCell colSpan={6} className="h-24 text-center text-muted-foreground">
                           No assets found.
                        </TableCell>
                     </TableRow>
                  ) : (
                     data.map((asset) => (
                        <TableRow key={asset.id}>
                           <TableCell>
                              {asset.imageUrl ? (
                                 <img src={asset.imageUrl} alt={asset.title} className="h-12 w-12 rounded object-cover border" />
                              ) : (
                                 <div className="h-12 w-12 rounded bg-muted flex items-center justify-center">
                                    <ImageIcon className="h-6 w-6 text-muted-foreground" />
                                 </div>
                              )}
                           </TableCell>
                           <TableCell className="font-medium">{asset.title}</TableCell>
                           <TableCell>
                              <Badge variant="outline">{asset.section}</Badge>
                           </TableCell>
                           <TableCell>{asset.displayOrder}</TableCell>
                           <TableCell>
                              <Badge variant={asset.isActive ? "default" : "secondary"}>{asset.isActive ? "Active" : "Inactive"}</Badge>
                           </TableCell>
                           <TableCell>
                              <DropdownMenu>
                                 <DropdownMenuTrigger asChild>
                                    <Button variant="ghost" className="h-8 w-8 p-0">
                                       <MoreVertical className="h-4 w-4" />
                                    </Button>
                                 </DropdownMenuTrigger>
                                 <DropdownMenuContent align="end">
                                    <DropdownMenuItem onClick={() => onEdit(asset)}>Edit</DropdownMenuItem>
                                    <DropdownMenuItem className="text-destructive" onClick={() => onDelete(asset.id)}>
                                       Delete
                                    </DropdownMenuItem>
                                 </DropdownMenuContent>
                              </DropdownMenu>
                           </TableCell>
                        </TableRow>
                     ))
                  )}
               </TableBody>
            </Table>
         </div>
      </div>
   );
}
