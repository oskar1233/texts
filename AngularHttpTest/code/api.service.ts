import { Injectable } from '@angular/core';
import { Http, Response } from '@angular/http';

@Injectable()
export class ApiService {

  private url: string = 'https://some_api:4000';

  constructor(
    private http: Http
  ) { }

  request(method: string) {
    return this.http.request(this.url, {
      method: method
    });
  }

}
