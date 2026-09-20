import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import * as dns from 'dns';
import * as https from 'https';

const resolver = new dns.Resolver();
resolver.setServers(['8.8.8.8', '1.1.1.1']);

const customLookup = (hostname: string, opt: any, cb: any) => {
  const callback = typeof opt === 'function' ? opt : cb;
  const isAll = typeof opt === 'object' && opt && opt.all;
  resolver.resolve4(hostname, (err, addresses) => {
    if (!err && addresses && addresses.length > 0) {
      if (isAll) {
        callback(null, addresses.map((a) => ({ address: a, family: 4 })));
      } else {
        callback(null, addresses[0], 4);
      }
    } else {
      dns.lookup(hostname, typeof opt === 'object' ? opt : {}, callback);
    }
  });
};

const customFetch = (targetUrl: any, options: any = {}) => {
  const urlString = typeof targetUrl === 'string' ? targetUrl : targetUrl.toString();
  return new Promise<any>((resolve, reject) => {
    const parsedUrl = new URL(urlString);
    const headers: Record<string, string> = {};
    if (options.headers) {
      if (typeof options.headers.forEach === 'function') {
        options.headers.forEach((v: string, k: string) => {
          headers[k] = v;
        });
      } else {
        Object.assign(headers, options.headers);
      }
    }

    const reqOptions = {
      hostname: parsedUrl.hostname,
      port: 443,
      path: parsedUrl.pathname + parsedUrl.search,
      method: options.method || 'GET',
      headers,
      lookup: customLookup,
    };

    const req = https.request(reqOptions, (res) => {
      const chunks: Buffer[] = [];
      res.on('data', (chunk) => chunks.push(chunk));
      res.on('end', () => {
        const bodyBuffer = Buffer.concat(chunks);
        const text = () => Promise.resolve(bodyBuffer.toString('utf8'));
        const json = () => {
          try {
            return Promise.resolve(JSON.parse(bodyBuffer.toString('utf8')));
          } catch (e) {
            return Promise.reject(e);
          }
        };
        resolve({
          ok: (res.statusCode ?? 500) >= 200 && (res.statusCode ?? 500) < 300,
          status: res.statusCode,
          statusText: res.statusMessage,
          headers: new Headers(res.headers as any),
          text,
          json,
        });
      });
    });

    req.on('error', reject);
    if (options.body) {
      req.write(typeof options.body === 'string' ? options.body : JSON.stringify(options.body));
    }
    req.end();
  });
};

@Injectable()
export class SupabaseService {
  private readonly logger = new Logger(SupabaseService.name);
  private supabaseClient: SupabaseClient;
  private adminClient: SupabaseClient;

  constructor(private readonly configService: ConfigService) {
    const supabaseUrl = this.configService.get<string>('supabase.url');
    const anonKey = this.configService.get<string>('supabase.anonKey');
    const serviceRoleKey = this.configService.get<string>('supabase.serviceRoleKey');

    this.supabaseClient = createClient(supabaseUrl, anonKey, {
      global: {
        fetch: customFetch as any,
      },
    });

    this.adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
      global: {
        fetch: customFetch as any,
      },
    });

    this.logger.log('Supabase Service initialized.');
  }

  getClient(): SupabaseClient {
    return this.supabaseClient;
  }

  getAdminClient(): SupabaseClient {
    return this.adminClient;
  }

  // Helper to create client with user JWT context to strictly enforce RLS
  getClientForUser(accessToken: string): SupabaseClient {
    const supabaseUrl = this.configService.get<string>('supabase.url');
    const anonKey = this.configService.get<string>('supabase.anonKey');

    return createClient(supabaseUrl, anonKey, {
      global: {
        fetch: customFetch as any,
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      },
      auth: {
        persistSession: false,
      },
    });
  }
}
