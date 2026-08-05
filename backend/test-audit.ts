import * as dotenv from 'dotenv';
dotenv.config();
import prisma from './src/config/prisma';

async function main() {
    try {
        const where: any = {};
        const search = "test";
        where.OR = [
            { message: { contains: search, mode: "insensitive" } },
            { correlationId: { contains: search, mode: "insensitive" } },
            { transactionId: { contains: search, mode: "insensitive" } },
            { revenueCatEventId: { contains: search, mode: "insensitive" } },
        ];
        
        where.module = "AUTH";

        console.log("Testing Prisma count...");
        const count = await prisma.auditLog.count({ where });
        console.log("Count:", count);
        
        console.log("Testing Prisma findMany...");
        const logs = await prisma.auditLog.findMany({ where, take: 1 });
        console.log("Logs:", logs.length);
    } catch (error) {
        console.error("Prisma error:", error);
    } finally {
        await prisma.$disconnect();
    }
}
main();
