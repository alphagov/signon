describe('A chosen module', function () {
  'use strict'

  var chosen
  var element

  beforeEach(function () {
    element = $('<div></div>')
    chosen = new GOVUKAdmin.Modules.Chosen()
  })

  it('creates a chosen select box when it starts', function () {
    spyOn(element, 'chosen')
    chosen.start(element)
    expect(element.chosen).toHaveBeenCalled()
  })
})
