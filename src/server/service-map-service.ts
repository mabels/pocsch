
export default class Service {
  constructor() {
    this.handle = this.handle.bind(this);
  }
  public handle(req: any, res: any): void {
    res.end(JSON.stringify({
      prod: {
        carList: ['/car-list'],
        userInfo: ['/user-info'],
        serviceList: ['/service-list'],
      }
    }));
  }
}
