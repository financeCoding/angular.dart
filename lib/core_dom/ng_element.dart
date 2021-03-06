part of angular.core.dom_internal;

@NgInjectableService()
class NgElement {
  static const _TO_BE_REMOVED = const Object();

  final dom.Element node;
  final Scope _scope;
  final NgAnimate _animate;

  final _classesToUpdate = <String, bool>{};
  final _attributesToUpdate = <String, dynamic>{};

  bool _writeScheduled = false;

  NgElement(this.node, this._scope, this._animate);

  void addClass(String className) {
    _scheduleDomWrite();
    _classesToUpdate[className] = true;
  }

  void removeClass(String className) {
    _scheduleDomWrite();
    _classesToUpdate[className] = false;
  }

  // todo(vicb) add tests
  void setAttribute(String attrName, [value = '']) {
    _scheduleDomWrite();
    _attributesToUpdate[attrName] = value == null ? '' : value;
  }

  void removeAttribute(String attrName) {
    _scheduleDomWrite();
    _attributesToUpdate[attrName] = _TO_BE_REMOVED;
  }

  _scheduleDomWrite() {
    if (!_writeScheduled) {
      _writeScheduled = true;
      _scope.rootScope.domWrite(() {
        _writeToDom();
        _writeScheduled = false;
      });
    }
  }

  _writeToDom() {
    _classesToUpdate.forEach((String className, bool toBeAdded) {
      toBeAdded
        ? _animate.addClass(node, className)
        : _animate.removeClass(node, className);
    });
    _classesToUpdate.clear();

    _attributesToUpdate.forEach((String attrName, value) {
      if (value == _TO_BE_REMOVED) {
        node.attributes.remove(attrName);
      } else {
        node.attributes[attrName] = value;
      }
    });
    _attributesToUpdate.clear();
  }
}
