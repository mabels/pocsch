import { WebAuth, Auth0DecodedHash } from 'auth0-js';
import { computed, observable } from 'mobx';
import { clearTimeout } from 'timers';

export default class Auth {

  private readonly auth0: WebAuth;

  @observable public accessToken: string;
  @observable public idToken: string;
  @observable public expiresAt: number;

  public expireTimer: any;

  constructor(options = {
    domain: 'advisercom.eu.auth0.com',
    clientID: 'XUZ7LR6icfI5QX2o69nkUxJHqdaNfahM',
    redirectUri: window.location.href,
    // audience: 'https://advisercom.eu.auth0.com/userinfo',
    responseType: 'token id_token',
    // scope: 'openid'
  }) {
    console.log('Auth0:', options);
    this.auth0 = new WebAuth(options);
    this.login = this.login.bind(this);
    this.logout = this.logout.bind(this);
    this.setAuthenticated(
      localStorage.getItem('access_token'),
      localStorage.getItem('id_token'),
      parseInt(localStorage.getItem('expires_at'), 10)
    );
    this.readFromHash();
  }

  private setAuthenticated(at?: string, id?: string, expires_at = 0): void {
    console.log(`setAuthenticated:enter:`, this);
    if (this.expireTimer) {
      window.clearTimeout(this.expireTimer);
      this.expireTimer = null;
    }
    this.accessToken = at;
    this.idToken = id;
    this.expiresAt = expires_at;
    if (at && id && expires_at > 0) {
      this.expireTimer = window.setTimeout(this.logout, this.diffMs());
      console.log('start:authenticated:', this.diffMs(),  this.expireTimer);
    } else {
      console.log('stop:authenticated');
    }
    console.log(`setAuthenticated:leave:`, this);
  }

  public readFromHash(): void {
    this.auth0.parseHash((err, authResult) => {
      if (authResult && authResult.accessToken && authResult.idToken) {
        this.setSession(authResult);
        window.location.hash = '';
        // history.replace('/home');
      } else if (err) {
        this.setAuthenticated();
        console.log(err);
      }
    });
  }

  public setSession(authResult: Auth0DecodedHash): void {
    // Set the time that the access token will expire at
    const expiresAt = (authResult.expiresIn * 1000) + new Date().getTime();
    localStorage.setItem('access_token', authResult.accessToken);
    localStorage.setItem('id_token', authResult.idToken);
    localStorage.setItem('expires_at', JSON.stringify(expiresAt));
    this.setAuthenticated(authResult.accessToken, authResult.idToken, expiresAt);
  }

  public logout(): void {
    // Clear access token and ID token from local storage
    localStorage.removeItem('access_token');
    localStorage.removeItem('id_token');
    localStorage.removeItem('expires_at');
    console.log(`authenticated:false`);
    this.setAuthenticated();
  }

  private diffMs(): number {
    return this.expiresAt - new Date().getTime();
  }

  @computed public get authenticated(): boolean {
    // Check whether the current time is past the
    // access token's expiry time
    return this.diffMs() > 0;
  }

  public login(): void {
    this.auth0.authorize();
  }

}
