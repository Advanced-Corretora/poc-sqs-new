import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHello(): string {
    return `Mudanca Gabtech Hello World from: ${process.env.AWS_REGION} | -> ${process.env.INTEGRATION_REGISTER_SERVICE_BASE_PATH}`;
  }
}
