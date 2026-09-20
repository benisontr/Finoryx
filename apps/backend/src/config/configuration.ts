export default () => ({
  port: parseInt(process.env.PORT, 10) || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  apiPrefix: process.env.API_PREFIX || 'api/v1',
  supabase: {
    url: process.env.SUPABASE_URL || 'https://mock.supabase.co',
    anonKey: process.env.SUPABASE_ANON_KEY || 'mock-anon-key',
    serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY || 'mock-service-key',
    jwtSecret: process.env.SUPABASE_JWT_SECRET || 'mock-jwt-secret',
  },
  ai: {
    apiKey: process.env.GEMINI_API_KEY || process.env.LLM_API_KEY || '',
    model: process.env.LLM_MODEL || process.env.GEMINI_MODEL || 'gemini-1.5-flash',
  },
  throttler: {
    ttl: parseInt(process.env.THROTTLE_TTL, 10) || 60,
    limit: parseInt(process.env.THROTTLE_LIMIT, 10) || 100,
  },
});
