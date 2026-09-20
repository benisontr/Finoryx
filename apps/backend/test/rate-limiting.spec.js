"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const throttler_1 = require("@nestjs/throttler");
describe('Rate Limiting & Throttler Verification (DoS Mitigation)', () => {
    let storageService;
    beforeEach(() => {
        storageService = new throttler_1.ThrottlerStorageService();
    });
    it('should track and increment request counts in throttler storage', async () => {
        const key = 'test-client-ip-1';
        const ttl = 60000;
        const res1 = await storageService.increment(key, ttl);
        expect(res1.totalHits).toBe(1);
        expect(res1.timeToExpire).toBeGreaterThan(0);
        const res2 = await storageService.increment(key, ttl);
        expect(res2.totalHits).toBe(2);
        const res3 = await storageService.increment(key, ttl);
        expect(res3.totalHits).toBe(3);
        const res4 = await storageService.increment(key, ttl);
        expect(res4.totalHits).toBe(4);
        const res5 = await storageService.increment(key, ttl);
        expect(res5.totalHits).toBe(5);
    });
    it('should continue accurate hit count tracking when exceeding rate limit threshold', async () => {
        const key = 'test-client-ip-1';
        const ttl = 60000;
        for (let i = 0; i < 5; i++) {
            await storageService.increment(key, ttl);
        }
        const res6 = await storageService.increment(key, ttl);
        expect(res6.totalHits).toBe(6);
        expect(res6.totalHits).toBeGreaterThan(5);
    });
    it('should isolate hit tracking for independent client IP keys', async () => {
        const keyUser1 = 'test-client-ip-1';
        const keyUser2 = 'test-client-ip-2';
        const ttl = 60000;
        const resUser1 = await storageService.increment(keyUser1, ttl);
        const resUser2 = await storageService.increment(keyUser2, ttl);
        expect(resUser1.totalHits).toBe(1);
        expect(resUser2.totalHits).toBe(1);
    });
});
//# sourceMappingURL=rate-limiting.spec.js.map