{Emitter, Disposable, CompositeDisposable} = require 'event-kit'

{Command, CommandError} = require './command'

class ExState
  constructor: (@editorElement, @globalExState) ->
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @editor = @editorElement.getModel()
    @opStack = []
    @history = []

    @registerOperationCommands
      open: (e) => new Command(@editor, @)

  destroy: ->
    @subscriptions.dispose()

  getExHistoryItem: (index) ->
    @globalExState.commandHistory[index]

  pushExHistory: (command) ->
    @globalExState.commandHistory.unshift command

  registerOperationCommands: (commands) ->
    for commandName, fn of commands
      do (fn) =>
        pushFn = (e) => @pushOperations(fn(e))
        @subscriptions.add(
          atom.commands.add(@editorElement, "ex-mode:#{commandName}", pushFn)
        )

  onDidFailToExecute: (fn) ->
    @emitter.on('failed-to-execute', fn)

  pushOperations: (operations) ->
    @opStack.push operations

    @processOpStack() if @opStack.length == 2

  clearOpStack: ->
    @opStack = []

  processOpStack: ->
    [command, input] = @opStack
    if input.characters.length > 0
      try
        command.execute(input)
        @history.unshift command
      catch e
        if (e instanceof CommandError)
          @emitter.emit('failed-to-execute')
        else
          throw e
    @clearOpStack()

module.exports = ExState
