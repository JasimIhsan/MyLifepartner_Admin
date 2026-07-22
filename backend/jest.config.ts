import type { Config } from "jest";

const config: Config = {
   preset: "ts-jest",
   testEnvironment: "node",
   roots: ["<rootDir>/src"],
   testMatch: ["**/__tests__/**/*.test.ts"],
   moduleNameMapper: {
      "^@/(.*)$": "<rootDir>/src/$1",
   },
   collectCoverageFrom: [
      "src/services/**/*.ts",
      "!src/**/__tests__/**",
   ],
   clearMocks: true,
};

export default config;
