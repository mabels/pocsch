
export default class Handler {
  constructor() {
    this.handle = this.handle.bind(this);
  }
  public handle(req: any, res: any): void {
    res.end(JSON.stringify(
      [{
        firstName: 'Terminator',
        lastName: 'John',
        email: 'john@terminator.de'
      }]));
  }
}

import AwsBinding from '../aws-binding';
module.exports.action = AwsBinding(new Handler());
