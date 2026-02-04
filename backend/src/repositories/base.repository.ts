export interface IBaseRepository<T> {
   create(data: T): Promise<T>;
   findAll(): Promise<T[]>;
   findById(id: number | string): Promise<T | null>;
   update(id: number | string, data: Partial<T>): Promise<T>;
   delete(id: number | string): Promise<T>;
}

export abstract class BaseRepository<T> implements IBaseRepository<T> {
   // Abstract methods or common logic can go here.
   // With Prisma, generic implementation is complex due to different delegates.
   // We will define the interface for consistency.
   abstract create(data: T): Promise<T>;
   abstract findAll(): Promise<T[]>;
   abstract findById(id: number | string): Promise<T | null>;
   abstract update(id: number | string, data: Partial<T>): Promise<T>;
   abstract delete(id: number | string): Promise<T>;
}
