export type CanViewOriginalImageParams = {
   viewerUserId: number;
   viewerPrivacyEnabled: boolean;
   targetUserId: number;
   targetPrivacyEnabled: boolean;
   hasApprovedAccess: boolean;
};

export interface IPrivacyPolicyService {
   canViewOriginalImage(params: CanViewOriginalImageParams): boolean;
}
