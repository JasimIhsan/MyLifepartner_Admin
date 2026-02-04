import { Prisma, User } from "@prisma/client";
import { BaseRepository } from "./base.repository";

import prisma from "../config/prisma";

export class UserRepository extends BaseRepository<User> {
   async create(data: Prisma.UserCreateInput): Promise<User> {
      return prisma.user.create({ data });
   }

   async findAll(): Promise<User[]> {
      return prisma.user.findMany();
   }

   async findById(id: number): Promise<User | null> {
      return prisma.user.findUnique({ where: { id } });
   }

   async findByEmail(email: string): Promise<User | null> {
      return prisma.user.findUnique({ where: { email } });
   }

   async update(id: number, data: Prisma.UserUpdateInput): Promise<User> {
      return prisma.user.update({ where: { id }, data });
   }

   async delete(id: number): Promise<User> {
      return prisma.user.delete({ where: { id } });
   }
}

export default new UserRepository();
