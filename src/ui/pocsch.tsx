import * as React from 'react';
import './pocsch.less';
import Auth from '../model/auth';
import ServiceMap from '../model/service-map';
import Home from './home';
import { BrowserRouter, Route, Switch } from 'react-router-dom';
import { observable } from 'mobx';
import { observer } from 'mobx-react';

class PocschViewState {
  @observable public readonly auth: Auth;
  @observable public readonly serviceMap: ServiceMap;
  constructor() {
    this.auth = new Auth();
    this.serviceMap = new ServiceMap(this.auth);
  }
}

@observer
export class Pocsch extends React.Component<{}, PocschViewState> {

  constructor() {
    super();
    this.state = new PocschViewState(); // { auth: new Auth() };
  }

  public render(): JSX.Element {
    console.log('render:Pocsch');
    return (
      <BrowserRouter>
        <Switch>
          <Route path="/" render={() =>  <Home auth={this.state.auth} serviceMap={this.state.serviceMap} /> } />
        </Switch>
      </BrowserRouter>
    );
  }

}

export default Pocsch;
