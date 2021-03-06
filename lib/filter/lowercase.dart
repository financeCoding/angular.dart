part of angular.filter;

/**
 * Converts string to lowercase.
 *
 * Usage:
 *
 *     {{ lowercase_expression | lowercase }}
 */
@NgFilter(name:'lowercase')
class Lowercase implements Function {
  call(String text) => text == null ? text : text.toLowerCase();
}
