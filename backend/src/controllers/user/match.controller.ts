import { IMatchService, SwipeAction } from "@/interfaces/services/match.service.interface";
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

   getProfileDetail = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
      try {
         const userId = req.user?.id;
         if (!userId) {
            res.status(401).json({ success: false, message: "Unauthorized" });
            return;
         }

         const profileId = Number(req.params.profileId);
         if (isNaN(profileId)) {
            res.status(400).json({ success: false, message: "Invalid profileId" });
            return;
         }

         const detail = await this.matchService.getProfileDetail(userId, profileId);
         if (!detail) {
            res.status(404).json({ success: false, message: "Profile not found" });
            return;
         }

         res.status(200).json({ success: true, data: detail });
      } catch (err) {
         next(err);
      }
   };

   getSentInterests = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
      try {
         const userId = req.user?.id;
         if (!userId) {
            res.status(401).json({ success: false, message: "Unauthorized" });
            return;
         }

         const sentInterests = await this.matchService.getSentInterests(userId);
         res.status(200).json({
            success: true,
            data: sentInterests,
         });
      } catch (err) {
         next(err);
      }
   };

   getReceivedInterests = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
      try {
         const userId = req.user?.id;
         if (!userId) {
            res.status(401).json({ success: false, message: "Unauthorized" });
            return;
         }

         const receivedInterests = await this.matchService.getReceivedInterests(userId);
         res.status(200).json({
            success: true,
            data: receivedInterests,
         });
      } catch (err) {
         next(err);
      }
   };

   getMutualMatches = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
      try {
         const userId = req.user?.id;
         if (!userId) {
            res.status(401).json({ success: false, message: "Unauthorized" });
            return;
         }

         const mutualMatches = await this.matchService.getMutualMatches(userId);
         res.status(200).json({
            success: true,
            data: mutualMatches,
         });
      } catch (err) {
         next(err);
      }
   };
}
