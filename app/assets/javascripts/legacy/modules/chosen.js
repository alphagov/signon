(function (Modules) {
  'use strict'
  Modules.Chosen = function () {
    var that = this
    that.start = function (element) {
      element.chosen()
    }
  }
})(window.GOVUKAdmin.Modules)
