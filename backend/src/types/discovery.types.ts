import { MaritalStatus, ChildrenStatus, SmokingHabit, DrinkingHabit } from '@prisma/client';

export interface DiscoveryQueryOptions {
  page?: number;
  limit?: number;
  ageFrom?: number;
  ageTo?: number;
  languages?: string[];
  maritalStatus?: MaritalStatus[];
  childrenStatus?: ChildrenStatus;
  verifiedOnly?: boolean;
  smoking?: SmokingHabit[];
  drinking?: DrinkingHabit[];
  search?: string;
}
