import { NextFunction, Request, Response } from "express";
import userService from "../services/user.service";

class UserController {
   public getUsers = async (req: Request, res: Response, next: NextFunction) => {
      try {
         const findAllUsersData = await userService.getUsers();
         res.status(200).json({ data: findAllUsersData, message: "findAll" });
      } catch (error) {
         next(error);
      }
   };

   public getUserById = async (req: Request, res: Response, next: NextFunction) => {
      try {
         const userId = Number(req.params.id);
         const findOneUserData = await userService.getUserById(userId);
         res.status(200).json({ data: findOneUserData, message: "findOne" });
      } catch (error) {
         next(error);
      }
   };

   public createUser = async (req: Request, res: Response, next: NextFunction) => {
      try {
         const userData = req.body;
         const createUserData = await userService.createUser(userData);
         res.status(201).json({ data: createUserData, message: "created" });
      } catch (error) {
         next(error);
      }
   };
}

export default new UserController();
