import { IMatchService } from "@/interfaces/services/match.service.interface";
import { SwipeAction } from "@prisma/client";
import { NextFunction, Request, Response } from "express";

export class MatchController {
   constructor(private readonly matchService: IMatchService) {}

   getRecommendations = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
      try {
         const userId = req.user?.id;
         if (!userId) {
            res.status(401).json({ success: false, message: "Unauthorized" });
            return;
         }

         const recommendations = await this.matchService.getRecommendations(userId);
         res.status(200).json({
            success: true,
            data: recommendations,
         });
      } catch (err) {
         next(err);
      }
   };

   swipeProfile = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
      try {
         const userId = req.user?.id;
         if (!userId) {
            res.status(401).json({ success: false, message: "Unauthorized" });
            return;
         }

         const { targetProfileId, action } = req.body as {
            targetProfileId: number;
            action: string;
         };

         if (!targetProfileId || !action) {
            res.status(400).json({ success: false, message: "targetProfileId and action are required" });
            return;
         }

         const validActions: SwipeAction[] = [SwipeAction.LEFT, SwipeAction.RIGHT, SwipeAction.UP];
         if (!validActions.includes(action as SwipeAction)) {
            res.status(400).json({
               success: false,
               message: `action must be one of: ${validActions.join(", ")}`,
            });
            return;
         }

         await this.matchService.swipeProfile({
            userId,
            targetProfileId: Number(targetProfileId),
            action: action as SwipeAction,
         });

         res.status(200).json({ success: true, message: "Swipe recorded" });
      } catch (err) {
         next(err);
      }
   };
}
