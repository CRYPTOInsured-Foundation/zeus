import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';

@Injectable()
export class WalletSignatureGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest();
    // dev: expect headers `x-wallet-addr` and `x-wallet-sig` and accept any non-empty
    const addr = req.headers['x-wallet-addr'];
    const sig = req.headers['x-wallet-sig'];
    return !!addr && !!sig;
  }
}
