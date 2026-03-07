export interface IAdminAuthService {
   login(username: string, password: string): Promise<{ user: { id: number; username: string; role: string }; accessToken: string; refreshToken: string }>;
   refreshTokens(refreshToken: string): Promise<{ accessToken: string; refreshToken: string }>;
   logout(adminId: number): Promise<boolean>;
}
