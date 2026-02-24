export interface OtpResponseDto {
   otp: string;
}

export const toOtpResponseDto = (otp: string): OtpResponseDto => ({
   otp,
});

export interface VerfiyOtpResponseDto {
   isValid: boolean;
}

export const toVerfiyOtpResponseDto = (isValid: boolean): VerfiyOtpResponseDto => ({
   isValid,
});
