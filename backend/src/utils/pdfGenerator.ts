import PDFDocument from "pdfkit";
import { Writable } from "stream";

// Brand Color Palette
const COLORS = {
   primary: "#FF3F3F",
   primaryDark: "#D63434",
   primaryLight: "#FFF5F5",
   primaryBorder: "#FECDD3",
   heading: "#0F172A",
   body: "#334155",
   muted: "#64748B",
   lightBg: "#F8FAFC",
   cardBorder: "#E2E8F0",
   white: "#FFFFFF",
   success: "#10B981",
};

interface KeyValueItem {
   label: string;
   value: string | number | boolean | null | undefined;
}

interface SectionData {
   title: string;
   items: KeyValueItem[];
   longText?: { label: string; text: string };
}

/**
 * Format string/enum/date value into clean user-readable text
 */
function formatDisplayValue(val: any): string {
   if (val === null || val === undefined || val === "") {
      return "Not specified";
   }
   if (typeof val === "boolean") {
      return val ? "Yes" : "No";
   }
   if (val instanceof Date) {
      return val.toLocaleDateString("en-US", {
         year: "numeric",
         month: "short",
         day: "numeric",
      });
   }
   if (typeof val === "string") {
      // Check if ISO Date string
      if (/^\d{4}-\d{2}-\d{2}T/.test(val)) {
         const d = new Date(val);
         if (!isNaN(d.getTime())) {
            return d.toLocaleDateString("en-US", {
               year: "numeric",
               month: "short",
               day: "numeric",
            });
         }
      }
      // Format Enum like NEVER_MARRIED -> Never Married
      if (val.includes("_") || /^[A-Z0-9_]+$/.test(val)) {
         return val
            .toLowerCase()
            .split("_")
            .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
            .join(" ");
      }
      return val;
   }
   if (Array.isArray(val)) {
      if (val.length === 0) return "None";
      return val.map((item) => formatDisplayValue(item)).join(", ");
   }
   return String(val);
}

export const generateUserExportPdf = (userData: any, writeStream: Writable): Promise<void> => {
   return new Promise((resolve, reject) => {
      // Page Dimensions (A4 standard: 595.28 x 841.89)
      const leftMargin = 45;
      const rightMargin = 45;
      const topMargin = 40;
      const bottomMargin = 45;

      const doc = new PDFDocument({
         size: "A4",
         margins: {
            top: topMargin,
            bottom: bottomMargin,
            left: leftMargin,
            right: rightMargin,
         },
         bufferPages: true,
         autoFirstPage: true,
      });

      doc.pipe(writeStream);

      doc.on("end", () => {
         resolve();
      });

      doc.on("error", (err) => {
         reject(err);
      });

      const pageWidth = 595.28;
      const pageHeight = 841.89;
      const contentWidth = pageWidth - leftMargin - rightMargin; // 505.28
      const maxContentY = pageHeight - bottomMargin - 20;

      const checkPageBreak = (neededHeight: number) => {
         if (doc.y + neededHeight > maxContentY) {
            doc.addPage();
            drawPageHeaderMini();
         }
      };

      const drawPageHeaderMini = () => {
         // Top red stripe
         doc.rect(0, 0, pageWidth, 5).fill(COLORS.primary);

         doc.fontSize(8)
            .font("Helvetica-Bold")
            .fillColor(COLORS.primary)
            .text("LIFE PARTNER AGAIN", leftMargin, 22, { continued: true })
            .font("Helvetica")
            .fillColor(COLORS.muted)
            .text("  •  PERSONAL DATA EXPORT", { align: "left" });

         doc.moveTo(leftMargin, 34).lineTo(pageWidth - rightMargin, 34).strokeColor(COLORS.cardBorder).lineWidth(0.75).stroke();
         doc.y = 44;
      };

      // ==========================================
      // 1. COVER / MAIN HEADER (PAGE 1)
      // ==========================================
      // Top accent bar
      doc.rect(0, 0, pageWidth, 6).fill(COLORS.primary);

      doc.y = 36;

      // Brand Title
      doc.fontSize(20).font("Helvetica-Bold").fillColor(COLORS.primary).text("LIFE PARTNER AGAIN", leftMargin, doc.y, {
         characterSpacing: 0.5,
      });

      doc.fontSize(10).font("Helvetica-Bold").fillColor(COLORS.heading).text("OFFICIAL PERSONAL DATA ARCHIVE", leftMargin, doc.y + 3, {
         characterSpacing: 0.8,
      });

      doc.y += 12;

      // Compliance & Metadata Banner Box
      const metaBoxY = doc.y;
      const metaBoxHeight = 72;

      // Card Background
      doc.roundedRect(leftMargin, metaBoxY, contentWidth, metaBoxHeight, 6)
         .fillColor(COLORS.lightBg)
         .fillAndStroke(COLORS.lightBg, COLORS.cardBorder);

      // Red left indicator
      doc.roundedRect(leftMargin, metaBoxY, 3.5, metaBoxHeight, 1.5).fill(COLORS.primary);

      const textInsetX = leftMargin + 14;
      let textY = metaBoxY + 10;

      doc.fontSize(8.5)
         .font("Helvetica-Bold")
         .fillColor(COLORS.primary)
         .text("GDPR (ART. 15) & PIPEDA DATA EXPORT SUMMARY", textInsetX, textY);

      textY += 12;
      doc.fontSize(8)
         .font("Helvetica")
         .fillColor(COLORS.body)
         .text(
            "This report includes all personal information, preferences, and security settings stored with your account.",
            textInsetX,
            textY,
            { width: contentWidth - 28 }
         );

      textY += 22;
      const exportDateStr = new Date().toLocaleDateString("en-US", {
         year: "numeric",
         month: "short",
         day: "numeric",
         hour: "2-digit",
         minute: "2-digit",
      });

      doc.fontSize(7.5)
         .font("Helvetica-Bold")
         .fillColor(COLORS.muted)
         .text(`USER ID: `, textInsetX, textY, { continued: true })
         .font("Helvetica")
         .fillColor(COLORS.heading)
         .text(`${userData.id || "N/A"}     `, { continued: true })
         .font("Helvetica-Bold")
         .fillColor(COLORS.muted)
         .text(`ACCOUNT: `, { continued: true })
         .font("Helvetica")
         .fillColor(COLORS.heading)
         .text(`${userData.email || "N/A"}     `, { continued: true })
         .font("Helvetica-Bold")
         .fillColor(COLORS.muted)
         .text(`EXPORT DATE: `, { continued: true })
         .font("Helvetica")
         .fillColor(COLORS.heading)
         .text(exportDateStr);

      doc.y = metaBoxY + metaBoxHeight + 14;

      // ==========================================
      // 2. DATA PREPARATION
      // ==========================================
      const profile = userData.profile || {};
      const preferences = userData.partnerPreference || {};
      const privacy = userData.privacySettings || {};

      const sections: SectionData[] = [
         {
            title: "1. Account & Security",
            items: [
               { label: "Account Email", value: userData.email },
               { label: "User ID", value: userData.id },
               { label: "Email Verified", value: userData.isVerified ? "Verified (Yes)" : "Unverified" },
               { label: "Founding Member", value: userData.isFoundingMember ? "Yes (Honored Member)" : "Standard User" },
               { label: "Account Status", value: userData.isBanned ? "Banned" : userData.isSuspended ? "Suspended" : "Active" },
               { label: "Member Since", value: userData.createdAt },
               { label: "Last Profile Update", value: userData.updatedAt },
            ],
         },
         {
            title: "2. Personal Profile",
            items: [
               { label: "Full Name", value: profile.name },
               { label: "Gender", value: profile.gender },
               { label: "Date of Birth", value: profile.dateOfBirth },
               { label: "Marital Status", value: profile.maritalStatus },
               { label: "Mother Tongue", value: profile.motherTongue },
               { label: "Children Status", value: profile.childrenStatus },
               { label: "Looking For", value: profile.lookingFor },
               { label: "Relationship Timeline", value: profile.relationshipTimeline },
            ],
            longText: profile.bio ? { label: "About Me", text: profile.bio } : undefined,
         },
         {
            title: "3. Location & Career",
            items: [
               { label: "City", value: profile.city },
               { label: "State / Province", value: profile.state },
               { label: "Country", value: profile.country },
               { label: "Highest Education", value: profile.highestEducation },
               { label: "Occupation / Job", value: profile.job?.name || profile.occupation || "Not specified" },
               { label: "Company", value: profile.companyName },
            ],
         },
         {
            title: "4. Lifestyle & Readiness",
            items: [
               { label: "Drinking Habit", value: profile.drinkingHabit },
               { label: "Smoking Habit", value: profile.smokingHabit },
               { label: "Languages Spoken", value: profile.languages },
               { label: "Emotional Readiness", value: profile.emotionalReadiness },
            ],
         },
         {
            title: "5. Partner Preferences",
            items: [
               {
                  label: "Preferred Age Range",
                  value:
                     preferences.ageFrom || preferences.ageTo
                        ? `${preferences.ageFrom || "Any"} - ${preferences.ageTo || "Any"} yrs`
                        : "Any Age",
               },
               { label: "Marital Status Preference", value: preferences.maritalStatus },
               { label: "Mother Tongue Preference", value: preferences.motherTongue },
            ],
         },
         {
            title: "6. Privacy & Security Settings",
            items: [
               { label: "Profile Privacy Enabled", value: privacy.privacyEnabled ? "Yes (Protected)" : "No (Public)" },
               { label: "Profile Blur Setting", value: privacy.blurredImageUrl ? "Enabled" : "Disabled" },
               { label: "Privacy Updated On", value: privacy.updatedAt || userData.updatedAt },
            ],
         },
      ];

      // ==========================================
      // 3. SECTION RENDERER
      // ==========================================
      const gridColWidth = (contentWidth - 10) / 2;
      const tileHeight = 31;
      const tileGap = 5;

      const renderSection = (sec: SectionData) => {
         const numRows = Math.ceil(sec.items.length / 2);
         const longTextHeight = sec.longText ? 42 : 0;
         const estimatedSectionHeight = 18 + numRows * (tileHeight + tileGap) + longTextHeight;

         checkPageBreak(Math.min(estimatedSectionHeight, 110));

         // Section Header
         const headerY = doc.y;
         doc.roundedRect(leftMargin, headerY, 3, 12, 1).fill(COLORS.primary);

         doc.fontSize(10)
            .font("Helvetica-Bold")
            .fillColor(COLORS.heading)
            .text(sec.title, leftMargin + 8, headerY + 1);

         doc.y = headerY + 17;

         // Draw Tiles
         for (let i = 0; i < sec.items.length; i += 2) {
            checkPageBreak(tileHeight + tileGap);
            const rowY = doc.y;

            // Column 1
            const item1 = sec.items[i];
            drawTile(leftMargin, rowY, gridColWidth, tileHeight, item1.label, formatDisplayValue(item1.value));

            // Column 2
            if (i + 1 < sec.items.length) {
               const item2 = sec.items[i + 1];
               drawTile(leftMargin + gridColWidth + 10, rowY, gridColWidth, tileHeight, item2.label, formatDisplayValue(item2.value));
            }

            doc.y = rowY + tileHeight + tileGap;
         }

         // Long text / Bio if present
         if (sec.longText) {
            checkPageBreak(40);
            const bioY = doc.y + 1;
            const bioHeight = 36;

            doc.roundedRect(leftMargin, bioY, contentWidth, bioHeight, 5)
               .fillColor(COLORS.lightBg)
               .fillAndStroke(COLORS.lightBg, COLORS.cardBorder);

            doc.fontSize(7)
               .font("Helvetica-Bold")
               .fillColor(COLORS.muted)
               .text(sec.longText.label.toUpperCase(), leftMargin + 9, bioY + 6);

            doc.fontSize(8)
               .font("Helvetica")
               .fillColor(COLORS.body)
               .text(`"${sec.longText.text}"`, leftMargin + 9, bioY + 17, {
                  width: contentWidth - 18,
                  height: 14,
                  ellipsis: true,
               });

            doc.y = bioY + bioHeight + tileGap;
         }

         doc.y += 8;
      };

      const drawTile = (x: number, y: number, width: number, height: number, label: string, val: string) => {
         doc.roundedRect(x, y, width, height, 4)
            .fillColor(COLORS.lightBg)
            .fillAndStroke(COLORS.lightBg, COLORS.cardBorder);

         // Label
         doc.fontSize(6.5)
            .font("Helvetica-Bold")
            .fillColor(COLORS.muted)
            .text(label.toUpperCase(), x + 8, y + 5, {
               width: width - 16,
               ellipsis: true,
            });

         // Value
         doc.fontSize(8)
            .font("Helvetica")
            .fillColor(COLORS.heading)
            .text(val, x + 8, y + 15, {
               width: width - 16,
               ellipsis: true,
            });
      };

      // Render All Sections
      for (const section of sections) {
         renderSection(section);
      }

      // ==========================================
      // 4. FOOTER & PAGE NUMBERING
      // ==========================================
      const range = doc.bufferedPageRange();
      for (let i = range.start; i < range.start + range.count; i++) {
         doc.switchToPage(i);

         const footerY = pageHeight - bottomMargin + 10;

         // Footer line
         doc.moveTo(leftMargin, footerY).lineTo(pageWidth - rightMargin, footerY).strokeColor(COLORS.cardBorder).lineWidth(0.5).stroke();

         // Left text
         doc.fontSize(7)
            .font("Helvetica")
            .fillColor(COLORS.muted)
            .text("Life Partner Again  •  Confidential Personal Data Archive", leftMargin, footerY + 6);

         // Right page numbering
         doc.fontSize(7)
            .font("Helvetica-Bold")
            .fillColor(COLORS.primary)
            .text(`PAGE ${i + 1} OF ${range.count}`, leftMargin, footerY + 6, {
               width: contentWidth,
               align: "right",
            });
      }

      doc.end();
   });
};

