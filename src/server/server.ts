
import * as fs from 'fs';
import * as http from 'http';
import * as https from 'https';
import * as path from 'path';

import CarListService from '../endpoints/car-list/handler';
import UserInfoService from '../endpoints/user-info/handler';
import ServiceListService from '../endpoints/service-list/handler';
import ServiceMapService from './service-map-service';
import { deployServerLess } from '../serverless/deploy';

let privateKey: string = null;
let certificate: string = null;
try {
  privateKey = fs.readFileSync('/etc/letsencrypt/live/<POCSCH>/privkey.pem', 'utf8');
  certificate = fs.readFileSync('/etc/letsencrypt/live/<POCSCH>/fullchain.pem', 'utf8');
} catch (e) {
  /* */
}
const credentials = { key: privateKey, cert: certificate };
import * as express from 'express';

function starter(): void {
  let redirectPort = 8080;
  let applicationPort = process.env.PORT || 8443;
  if (process.getuid() == 0) {
    redirectPort = 80;
    applicationPort = process.env.PORT || 443;
  }

  const redirectHttp = express();
  redirectHttp.get('/*', (req, res, next) => {
    res.location('https://<POCSCH>');
    res.sendStatus(302);
    res.end('<a href="https://<POCSCH>">https://<POCSCH></a>');
  });
  redirectHttp.listen(redirectPort);
  console.log(`Started redirectPort on ${redirectPort}`);

  let httpServer: https.Server | http.Server;
  if (privateKey) {
    httpServer = https.createServer(credentials);
    console.log(`Listen on: https ${applicationPort} ${process.env.PORT}`);
  } else {
    httpServer = http.createServer();
    console.log(`Listen on: http ${applicationPort} ${process.env.PORT}`);
  }

  const app = express();

  app.get('/service-map.json', new ServiceMapService().handle);
  app.get('/car-list', new CarListService().handle);
  app.get('/user-info', new UserInfoService().handle);
  app.get('/service-list', new ServiceListService().handle);

  app.use(express.static(path.join(process.cwd(), 'dist/js-frontend')));
  app.get('/', (req: express.Request, res: express.Response) => res.redirect('/index.html'));

  httpServer.on('request', app);
  httpServer.listen(applicationPort);
}

if (process.argv.find(i => i == 'serverless')) {
  deployServerLess();
} else {
  starter();
}
