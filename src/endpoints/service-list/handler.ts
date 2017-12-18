
export default class Handler {
  constructor() {
    this.handle = this.handle.bind(this);
  }
  public handle(req: any, res: any): void {
    res.end(JSON.stringify([
      { name: 'DE-Map', price: '10.10' },
      { name: 'TrafficPilot', price: '10.10' },
      { name: 'Leihwagen', price: '10.10' }
    ]));
  }
}

import AwsBinding from '../aws-binding';
module.exports.action = AwsBinding(new Handler());
