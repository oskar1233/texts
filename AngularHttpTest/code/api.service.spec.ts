import { TestBed, inject } from '@angular/core/testing';
import { HttpModule, XHRBackend, RequestMethod, Response, ResponseOptions } from '@angular/http';
import { MockBackend, MockConnection } from '@angular/http/testing';

import { ApiService } from './api.service';

describe('ApiService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [
        HttpModule
      ],
      providers: [
        ApiService,
        { provide: XHRBackend, useClass: MockBackend }
      ]
    });

    this.service = TestBed.get(ApiService);
    this.mockBackend = TestBed.get(XHRBackend);
  });

  it('should be created', () => {
    expect(this.service).toBeTruthy();
  });

  describe('#request', () => {
    it('should exist', () => {
      expect(this.service.request).toBeDefined();
    });

    it('should use get http method when provided', () => {

      this.mockBackend.connections.subscribe(
        (connection: MockConnection) => {
          expect(connection.request.method).toBe(RequestMethod.Get);

          connection.mockRespond(new Response(
            new ResponseOptions({ body: "foo" })
          ));
        }
      );

      this.service.request('get').subscribe(res => {
        expect(res).toBeDefined();
      });
    });

  });

});
