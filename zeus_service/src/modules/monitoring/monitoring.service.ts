import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class MonitoringService {
  private readonly logger = new Logger(MonitoringService.name);

  async recordMetric(name: string, value: any) {
    this.logger.debug(`metric ${name}=${JSON.stringify(value)}`);
    return true;
  }
}
