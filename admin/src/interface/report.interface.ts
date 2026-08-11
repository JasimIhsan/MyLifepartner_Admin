export interface UserReport {
  id: number;
  reporterUserId: number;
  reportedUserId: number;
  reason: string;
  description?: string;
  evidenceScreenshotsUrls?: string[];
  source: string;
  status: string;
  priority: string;
  assignedAdminId?: number;
  adminNotes?: string;
  resolution?: string;
  actionTaken?: string;
  createdAt: string;
  updatedAt: string;
  reporterUser?: {
    id: number;
    email: string;
    profile?: { name?: string; profileStatus?: string };
  };
  reportedUser?: {
    id: number;
    email: string;
    isBlocked?: boolean;
    profile?: { name?: string; profileStatus?: string };
  };
  moderationLogs?: ModerationActionLog[];
}

export interface ModerationActionLog {
  id: number;
  userId: number;
  reportId?: number;
  adminId: number;
  action: string;
  reason?: string;
  notes?: string;
  createdAt: string;
  admin?: {
    id: number;
    username: string;
  };
}
