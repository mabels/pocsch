import AwsBinding from '../aws-binding';

export default class Handler {
  constructor() {
    this.handle = this.handle.bind(this);
  }
  public handle(req: any, res: any): void {
    res.end(JSON.stringify([
      { brand: 'humbug', model: 't7', type: 'gt'},
      { brand: 'humbug', model: 't8', type: 'caprio'},
      { brand: 'humbug', model: 't9', type: 'laster'},
    ]));
  }
}

module.exports.action = AwsBinding(new Handler());
