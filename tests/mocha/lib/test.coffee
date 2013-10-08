buildString = (reference, arr) ->
  return _.map(arr, (elem) =>
    return if _.isNumber(elem) then reference[elem] else elem
  ).join('')


class ScribeHtmlTest
  @DEFAULTS:
    checker       : ->
    fn            : ->
    initial       : []
    expected      : []
    ignoreExpect  : false
    pre           : -> []

  @cleanHtml: (html, keepIdClass = false) ->
    html = Scribe.Normalizer.normalizeHtml(html)
    unless keepIdClass == true
      html = html.replace(/\ (class|id)="[a-z0-9\-_]+"/gi, '')
      html = html.replace(/\ (class|id)=[a-z0-9\-_]+ /gi, '')
      html = html.replace(/\ (class|id)=[a-z0-9\-_]+>/gi, '>')
    return html

  constructor: (options = {}) ->
    throw new Error("Invalid options passed into constructor") unless _.isObject(options)
    @settings = _.defaults(options, ScribeHtmlTest.DEFAULTS)

  run: (name, options, args...) ->
    it(name, =>
      this.runWithoutIt(options, args...)
    )

  runWithoutIt: (options, args...) ->
    options = _.defaults(options, @settings)
    options.initial = [options.initial] if _.isString(options.initial)
    options.expected = buildString(options.initial, if options.expected? then options.expected else @settings.expected)
    options.initial = options.initial.join('') if _.isArray(options.initial)
    options.initial = ScribeHtmlTest.cleanHtml(options.initial, true)
    options.expected = ScribeHtmlTest.cleanHtml(options.expected, true)
    testContainer = $('#test-container').html(options.initial).get(0)
    expectedContainer = $('#expected-container').html(options.expected).get(0)
    newArgs = options.pre.call(this, testContainer, expectedContainer)
    newArgs = [newArgs] unless _.isArray(newArgs)
    options.fn.call(null, testContainer, expectedContainer, newArgs..., args...)
    testHtml = ScribeHtmlTest.cleanHtml(testContainer.innerHTML)
    expectedHtml = ScribeHtmlTest.cleanHtml(expectedContainer.innerHTML)
    expect(testHtml).to.equal(expectedHtml) unless options.ignoreExpect
    options.checker.call(null, testContainer, expectedContainer, newArgs..., args...)


class ScribeEditorTest extends ScribeHtmlTest
  @DEFAULTS:
    ignoreExpect  : false

  constructor: (options = {}) ->
    @settings = _.defaults(options, ScribeEditorTest.DEFAULTS)
    super(@settings)

  run: (name, options, args...) ->
    it(name, =>
      this.runWithoutIt(options, args...)
    )

  runWithoutIt: (options, args...) ->
    throw new Error("Invalid options passed into run") unless _.isObject(options)
    @options = _.defaults(options, @settings)
    testEditor = expectedEditor = null
    htmlOptions = _.clone(@options)
    htmlOptions.initial = '' if Tandem.Delta.isDelta(htmlOptions.initial)
    htmlOptions.expected = '' if Tandem.Delta.isDelta(htmlOptions.expected)
    htmlOptions.fn = (testContainer, expectedContainer, args...) =>
      testEditor = new Scribe.Editor(testContainer)
      expectedEditor = new Scribe.Editor(expectedContainer)
      testEditor.setDelta(@options.initial) if Tandem.Delta.isDelta(@options.initial)
      expectedEditor.setDelta(@options.expected) if Tandem.Delta.isDelta(@options.expected)
      @options.fn.call(null, testEditor, expectedEditor, args...)
    htmlOptions.checker = (testContainer, expectedContainer, args...) =>
      @options.checker.call(this, testEditor, expectedEditor, args...)
      unless @options.ignoreExpect
        testDelta = testEditor.getDelta()
        expectedDelta = expectedEditor.getDelta()
        expect(testDelta.isEqual(expectedDelta)).to.be(true)
        consistent = Scribe.Debug.checkDocumentConsistency(testEditor.doc)
        expect(consistent).to.be(true)
    super(htmlOptions, args...)

    

window.Scribe or= {}
window.Scribe.Test = 
  EditorTest  : ScribeEditorTest
  HtmlTest    : ScribeHtmlTest