library templateurl_spec;

import '../_specs.dart';

@NgComponent(
    selector: 'simple-url',
    templateUrl: 'simple.html')
class SimpleUrlComponent {
}

@NgComponent(
    selector: 'html-and-css',
    templateUrl: 'simple.html',
    cssUrl: 'simple.css')
class HtmlAndCssComponent {
}

@NgComponent(
    selector: 'html-and-css',
    templateUrl: 'simple.html',
    cssUrl: const ['simple.css', 'another.css'])
class HtmlAndMultipleCssComponent {
}

@NgComponent(
    selector: 'inline-with-css',
    template: '<div>inline!</div>',
    cssUrl: 'simple.css')
class InlineWithCssComponent {
}

@NgComponent(
    selector: 'only-css',
    cssUrl: 'simple.css')
class OnlyCssComponent {
}

class PrefixedUrlRewriter extends UrlRewriter {
  call(url) => "PREFIX:$url";
}

void main() {
  describe('template url', () {
    afterEach((MockHttpBackend backend) {
      backend.verifyNoOutstandingRequest();
    });

    describe('loading with http rewriting', () {
      beforeEachModule((Module module) {
        module
            ..type(HtmlAndCssComponent)
            ..type(UrlRewriter, implementedBy: PrefixedUrlRewriter);
      });

      it('should use the UrlRewriter for both HTML and CSS URLs', async(inject(
          (Http http, Compiler compile, Scope rootScope, Logger log,
           Injector injector, NgZone zone, MockHttpBackend backend,
           DirectiveMap directives) {

        backend
            ..whenGET('PREFIX:simple.html').respond('<div log="SIMPLE">Simple!</div>')
            ..whenGET('PREFIX:simple.css').respond('.hello{}');

        var element = e('<div><html-and-css log>ignore</html-and-css><div>');
        zone.run(() {
          compile([element], directives)(injector, [element]);
        });

        backend.flush();
        microLeap();

        expect(element).toHaveText('.hello{}Simple!');
        expect(element.children[0].shadowRoot).toHaveHtml(
            '<style>.hello{}</style><div log="SIMPLE">Simple!</div>'
        );
      })));
    });


    describe('async template loading', () {
      beforeEachModule((Module module) {
        module
            ..type(LogAttrDirective)
            ..type(SimpleUrlComponent)
            ..type(HtmlAndCssComponent)
            ..type(OnlyCssComponent)
            ..type(InlineWithCssComponent);
      });

      it('should replace element with template from url', async(inject(
          (Http http, Compiler compile, Scope rootScope,  Logger log,
           Injector injector, MockHttpBackend backend, DirectiveMap directives) {
        backend.expectGET('simple.html').respond('<div log="SIMPLE">Simple!</div>');

        var element = es('<div><simple-url log>ignore</simple-url><div>');
        compile(element, directives)(injector, element);

        backend.flush();
        microLeap();

        expect(element[0]).toHaveText('Simple!');
        rootScope.apply();
        // Note: There is no ordering.  It is who ever comes off the wire first!
        expect(log.result()).toEqual('LOG; SIMPLE');
      })));

      it('should load template from URL once', async(inject(
          (Http http, Compiler compile, Scope rootScope,  Logger log,
           Injector injector, MockHttpBackend backend, DirectiveMap directives) {
        backend.whenGET('simple.html').respond('<div log="SIMPLE">Simple!</div>');

        var element = es(
            '<div>'
            '<simple-url log>ignore</simple-url>'
            '<simple-url log>ignore</simple-url>'
            '<div>');
        compile(element, directives)(injector, element);

        backend.flush();
        microLeap();

        expect(element.first).toHaveText('Simple!Simple!');
        rootScope.apply();

        // Note: There is no ordering.  It is who ever comes off the wire first!
        expect(log.result()).toEqual('LOG; LOG; SIMPLE; SIMPLE');
      })));

      it('should load a CSS file into a style', async(inject(
          (Http http, Compiler compile, Scope rootScope, Logger log,
           Injector injector, MockHttpBackend backend, DirectiveMap directives) {
        backend
            ..expectGET('simple.css').respond('.hello{}')
            ..expectGET('simple.html').respond('<div log="SIMPLE">Simple!</div>');

        var element = e('<div><html-and-css log>ignore</html-and-css><div>');
        compile([element], directives)(injector, [element]);

        backend.flush();
        microLeap();

        expect(element).toHaveText('.hello{}Simple!');
        expect(element.children[0].shadowRoot).toHaveHtml(
            '<style>.hello{}</style><div log="SIMPLE">Simple!</div>'
        );
        rootScope.apply();
        // Note: There is no ordering.  It is who ever comes off the wire first!
        expect(log.result()).toEqual('LOG; SIMPLE');
      })));

      it('should load a CSS file with a \$template', async(inject(
          (Http http, Compiler compile, Scope rootScope, Injector injector,
           MockHttpBackend backend, DirectiveMap directives) {
        var element = es('<div><inline-with-css log>ignore</inline-with-css><div>');
        backend.expectGET('simple.css').respond('.hello{}');
        compile(element, directives)(injector, element);

        backend.flush();
        microLeap();
        expect(element[0]).toHaveText('.hello{}inline!');
      })));

      it('should ignore CSS load errors ', async(inject(
          (Http http, Compiler compile, Scope rootScope, Injector injector,
           MockHttpBackend backend, DirectiveMap directives) {
        var element = es('<div><inline-with-css log>ignore</inline-with-css><div>');
        backend.expectGET('simple.css').respond(500, 'some error');
        compile(element, directives)(injector, element);

        backend.flush();
        microLeap();
        expect(element.first).toHaveText(
            '/*\n'
            'HTTP 500: some error\n'
            '*/\n'
            'inline!');
      })));

      it('should load a CSS with no template', async(inject(
          (Http http, Compiler compile, Scope rootScope, Injector injector,
           MockHttpBackend backend, DirectiveMap directives) {
        var element = es('<div><only-css log>ignore</only-css><div>');
        backend.expectGET('simple.css').respond('.hello{}');
        compile(element, directives)(injector, element);

        backend.flush();
        microLeap();
        expect(element[0]).toHaveText('.hello{}');
      })));

      it('should load the CSS before the template is loaded', async(inject(
          (Http http, Compiler compile, Scope rootScope, Injector injector,
           MockHttpBackend backend, DirectiveMap directives) {
        backend
            ..expectGET('simple.css').respond('.hello{}')
            ..expectGET('simple.html').respond('<div>Simple!</div>');

        var element = es('<html-and-css>ignore</html-and-css>');
        compile(element, directives)(injector, element);

        backend.flush();
        microLeap();
        expect(element.first).toHaveText('.hello{}Simple!');
      })));
    });

    describe('multiple css loading', () {
      beforeEachModule((Module module) {
        module
            ..type(LogAttrDirective)
            ..type(HtmlAndMultipleCssComponent);
      });

      it('should load multiple CSS files into a style', async(inject(
          (Http http, Compiler compile, Scope rootScope, Logger log,
           Injector injector, MockHttpBackend backend, DirectiveMap directives) {
        backend
            ..expectGET('simple.css').respond('.hello{}')
            ..expectGET('another.css').respond('.world{}')
            ..expectGET('simple.html').respond('<div log="SIMPLE">Simple!</div>');

        var element = e('<div><html-and-css log>ignore</html-and-css><div>');
        compile([element], directives)(injector, [element]);

        backend.flush();
        microLeap();

        expect(element).toHaveText('.hello{}.world{}Simple!');
        expect(element.children[0].shadowRoot).toHaveHtml(
            '<style>.hello{}</style><style>.world{}</style><div log="SIMPLE">Simple!</div>'
        );
        rootScope.apply();
        // Note: There is no ordering.  It is who ever comes off the wire first!
        expect(log.result()).toEqual('LOG; SIMPLE');
      })));
    });
  });
}
