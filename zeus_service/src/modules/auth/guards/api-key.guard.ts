import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';

@Injectable()
export class ApiKeyGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest();
    const key = req.headers['x-api-key'] || req.headers['authorization'];
    const expected = process.env.API_KEY ?? 'dev-api-key';
    if (!key) return false;
    if (typeof key === 'string' && key.startsWith('Bearer ')) {
      return key.slice(7) === expected;
    }
    return String(key) === expected;
  }
}
