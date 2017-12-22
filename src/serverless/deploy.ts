import * as fs from 'fs-extra';
import * as yamljs from 'yamljs';
import * as BlueBird from 'bluebird';
import * as path from 'path';
import * as shelljs from 'shelljs';

function createServerlessYml(sname: string, cb: () => any, template?: string): BlueBird<string> {
  return new BlueBird<string>((rs, rj) => {
    const templateFname = `src/serverless/${template ? template : sname}.yml`;
    fs.ensureDir(`dist/${sname}.serverless`, err => {
      fs.readFile(templateFname)
        .then(yamlStr => {
          const yml = yamljs.parse(yamlStr.toString('utf-8'));
          Object.assign(yml, cb());
          const fname = `dist/${sname}.serverless/serverless.yml`;
          fs.writeFile(fname, yamljs.stringify(yml, 8, 2))
            .then(() => rs(fname))
            .catch((e) => { console.error(e); rj(e); });
        }).catch(console.error);
    });
  });
}

function deployService(sname: string, basename: string): BlueBird<string> {
  const name = `${sname}-${basename}`;
  return createServerlessYml(sname, () => ({
    service: name,
  }), 'service');
}

function deployJsFrontend(basename: string): BlueBird<string> {
  return createServerlessYml('js-frontend', () => ({
    service: `${basename}-js-frontend`,
    custom: {
      client: {
        bucketName: `${basename}-js-frontend`,
        distributionFolder: '../js-frontend'
      }
    }
  }));
}

import * as crypto from 'crypto';
// import { Promise } from 'bluebird';

function findService(so: string): void {
  const ymlStr: string[] = [];
  let found = false;
  so.split(/[\n\r]+/).forEach(i => {
    if (i == 'Service Information') {
      found = true;
    } else if (found) {
      ymlStr.push(i);
    }
  });
  const yml = yamljs.parse(ymlStr.join('\n'));
  const url = yml.endpoints.split(/\s+/)[2];
  console.log(url);
  return url;
}

function deployJsWithServiceMap(basename: string, sMap: any): void {
  // deployIndexHtml
  fs.ensureDir(`dist/js-frontend`, err => {
    fs.writeFile(`dist/js-frontend/service-map.json`, JSON.stringify(sMap))
      .then(() => {
        deployJsFrontend(basename).then(serverlessYml => {
          const cmd = `cd ${path.dirname(serverlessYml)} && serverless client deploy`;
          console.log(cmd);
          shelljs.exec(cmd, { silent: true }, (code: number, stdout: string, stderr: string) => {
            console.log(`done`);
            stdout.split(/[\n\r]+/).forEach(i => {
              if (i.endsWith('index.html')) {
                console.log(i);
              }
            });
          });
        });
      })
      .catch ((e) => { console.error(e);  });
  });
}

export function deployServerLess(): void {
  const hash = crypto.createHash('sha1'); // no fears this is safer
  hash.update(`${process.env.USER} ${process.cwd()}`);
  const basename = `pocsch-${hash.digest('base64').replace(/[^a-zA-Z0-9]/g, '').slice(0, 12).toLocaleLowerCase()}`;
  // hash.end();
  console.log(`Create Service Infrastructur:[${basename}]`);

  const serviceMap: any = { prod: {} };
  // deployService
  ['car-list', 'service-list', 'user-info'].forEach((i, _, arr) => {
    deployService(i, basename).then(serverlessYml => {
      const cmd = `cd ${path.dirname(serverlessYml)} && serverless deploy`;
      console.log(cmd);
      shelljs.exec(cmd, { silent: true }, (code: number, stdout: string, stderr: string) => {
        serviceMap.prod[i] = serviceMap.prod[i] || [];
        serviceMap.prod[i].push(findService(stdout));
        let count = 0;
        for (let __ in serviceMap.prod) {
          count++;
        }
        if (count >= arr.length) {
          console.log(serviceMap);
          deployJsWithServiceMap(basename, serviceMap);
        }
      });
    });
  });

}
