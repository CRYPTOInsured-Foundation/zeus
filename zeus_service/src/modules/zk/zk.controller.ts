import { Controller, Post, Body } from '@nestjs/common';
import { ZkService } from './zk.service';

@Controller('zk')
export class ZkController {
  constructor(private readonly zk: ZkService) {}

  @Post('generate')
  async generate(@Body() body: any) {
    return this.zk.generateProof(body);
  }

  @Post('verify')
  async verify(@Body() body: any) {
    return this.zk.verifyProof(body);
  }
}
