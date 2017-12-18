
export default class Service {
  constructor() {
    this.handle = this.handle.bind(this);
  }
  public handle(req: any, res: any): void {
    res.end(JSON.stringify({
      prod: {
        'car-list': ['/car-list'],
        'user-info': ['/user-info'],
        'service-list': ['/service-list'],
      }
    }));
  }
}
