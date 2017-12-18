import * as React from 'react';
import { Navbar, Button } from 'react-bootstrap';
import Auth from '../model/auth';
import ServiceMap from '../model/service-map';
import { observer } from 'mobx-react';
import { observable } from 'mobx';

import ServiceDump from './components/service-dump';

class HomeState {
}

class HomeProps {
  public auth: Auth;
  public serviceMap: ServiceMap;
}

@observer
export default class Home extends React.Component<HomeProps, HomeState> {
  public render(): JSX.Element {
    return <Navbar fluid>
          <Navbar.Header>
            <Navbar.Brand>
              <a href="#">POCSCH</a>
            </Navbar.Brand>
            {
              !this.props.auth.authenticated && (
                  <Button
                    bsStyle="primary"
                    className="btn-margin"
                    onClick={this.props.auth.login.bind(this)}
                  >Log In</Button>
                )
            }
            {
              this.props.auth.authenticated && (
                <div>
                  <Button
                    bsStyle="primary"
                    className="btn-margin"
                    onClick={this.props.auth.logout.bind(this)}
                  >Log Out</Button>
                  <ul>
                  <li>{this.props.auth.accessToken}</li>
                  <li>{this.props.auth.idToken}</li>
                  <li>{this.props.auth.expiresAt}</li>
                  </ul>
                  <ServiceDump auth={this.props.auth} serviceMap={this.props.serviceMap} serviceName="carList" />
                  <ServiceDump auth={this.props.auth} serviceMap={this.props.serviceMap} serviceName="userInfo" />
                  <ServiceDump auth={this.props.auth} serviceMap={this.props.serviceMap} serviceName="serviceList" />
                </div>
                )
            }
          </Navbar.Header>
        </Navbar>;
  }
}
