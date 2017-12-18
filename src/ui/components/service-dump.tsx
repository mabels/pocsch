import * as React from 'react';
import Auth from '../../model/auth';
import ServiceMap from '../../model/service-map';
import { observer } from 'mobx-react';
import { observable, observe } from 'mobx';

class ServiceDumpState {
  @observable public list: any[] = [];
}

class ServiceDumpProps {
  public auth: Auth;
  public serviceMap: ServiceMap;
  public serviceName: string;
}

@observer
export default class ServiceDump extends React.Component<ServiceDumpProps, ServiceDumpState> {

  constructor() {
    super();
    this.state = new ServiceDumpState();
  }

  public componentDidMount(): void {
    observe(this.props.serviceMap, 'loaded', (changed) => {
      if (!changed.newValue) {
        return;
      }
      this.props.serviceMap.fetch(this.props.serviceName)
        .then((response) => {
          this.state.list.push.apply(this.state.list, response.data);
          console.log('update list:', response.data);
        })
        .catch((error) => {
          console.log(error);
        });
    }, true);
  }
  public render(): JSX.Element {
    return <div>
      <h1>{this.props.serviceName}</h1>
      <ul>
        {this.state.list.map(i => <li key={Math.random()}><pre>{JSON.stringify(i)}</pre></li>)}
      </ul>
    </div>;
  }
}
