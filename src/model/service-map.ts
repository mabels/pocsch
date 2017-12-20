import { computed, observable, action, observe } from 'mobx';
import Auth from '../model/auth';
import { clearTimeout } from 'timers';
import axios, { AxiosPromise } from 'axios';
import { IValueDidChange } from 'mobx/lib/types/observablevalue';

export default class ServiceMap {

  @observable public loaded: boolean;
  public serviceMap: any;

  constructor(auth: Auth) {
    this.loaded = false;
    this.serviceMap = {};
    observe(auth, 'authenticated', this.loadServiceMap.bind(this), true);
  }

  private loadServiceMap(change: IValueDidChange<boolean>): void {
    console.log('ServiceMap:authenticated:', change.newValue);
    if (change.newValue == false) {
      return;
    }
    axios.get('/service-map.json')
      .then((response) => {
        // console.log('0-loaded service-map', response.data, this);
        this.serviceMap = response.data;
        try {
          this.loaded = true;
          // console.log('2-loaded service-map', response.data, this);
        } catch (e) {
          // console.log('e-loaded service-map', response.data, this);
          console.error(e);
        }
        // console.log('1-loaded service-map', response.data, this);
      })
      .catch((error) => {
        console.log(error);
      });
  }

  public fetch(name: string): AxiosPromise<any> {
    console.log('ServiceMap:fetch:', name, this.serviceMap);
    return axios.get(this.serviceMap['prod'][name][0]);
  }

}
