/* import { Injectable, Logger } from '@nestjs/common';
import { SqsMessageHandler } from '@ssut/nestjs-sqs';

@Injectable()
export class MessageHandler {
  private readonly logger = new Logger(MessageHandler.name);

  @SqsMessageHandler('gabriel-test2', false)
  public async handle(message: AWS.SQS.Message) {
    this.logger.log(
      '######################## starting new process:, ',
      message.Body,
    );
    this.processMessage(message);
  }

  private async processMessage(message: AWS.SQS.Message) {
    await this.wait(6000);
    this.logger.log('processed: ', message.Body);
  }

  async wait(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}
 */
