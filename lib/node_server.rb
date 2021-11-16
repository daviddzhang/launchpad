# An instance of this class represents a running Node process, which can accept
# JS code as input (via the `evaluate` method) and returns its result as a
# string. It also supports automatic restart based on multiple expiration keys.
# See `evaluate` method for more details on this.
#
# The impetus behind this is to speed up our server-side rendering. Previously
# we were starting a new Node process for every single render. This resulted in
# about 300ms startup time (I'm guessing most of that goes into loading React),
# and while it wasn't perfect, it was acceptable, and we were able to live with
# it for a long while. But now that we're trying to up our SEO game, load times
# become increasingly important, and 300ms suddenly doesn't look so good. By
# reusing the same Node process for all renders we were able to bring down the
# time to under 10ms. Impressive efficiency, Node!
class NodeServer
  # Arguments:
  #   cwd:
  #       root directory for Node environment. This is where `node_modules` is located.
  #   tmp_dir:
  #       a temp directory where we'll put a file with Node Server's JS code.
  #   log:
  #       optional, a lambda taking a String. This class will call it when it needs
  #       to print some trace info.
  def initialize(cwd:, tmp_dir:, log: nil)
    @cwd = cwd
    @log = log
    @tmp_dir = tmp_dir
    Dir.mkdir @tmp_dir unless Dir.exist? @tmp_dir
    @server_file = Tempfile.new ["node_server", ".js"], tmp_dir
    @server_file.write NODE_SERVER_CODE
    @server_file.close
    @mutex = Mutex.new
  end

  # Takes JS code, executes it, and returns its output as a string. Note that if
  # an error happens during evaluation, the error text will be returned as
  # output, and there is no way to distinguish an evaluation error from
  # successful output. This is by design. It is expected that the consumer
  # implements their own communication protocol on top of this class. For now
  # this is sufficient for our purposes.
  #
  # Note also that the output length is limited to 5,000 characters. If the JS
  # code produces more output than that, the future behavior of NodeServer is
  # undefined: the remainder of output may leak into the next evaluation result
  # or not. Once again, this behavior is sufficient for our current purposes.
  #
  # Besides JS code to evaluate, this method takes a `key` and `key_timestamp`.
  # These are used to decide whether the Node server should be restarted or the
  # existing instance can be used. If the timestamp is more recent (i.e.
  # "greater") than the one that was used when the Node process was first
  # started, we will restart the process. Otherwise, we use the existing one.
  #
  # A restart may be necessary when a module has changed on disk. Node itself
  # will not watch/reload modules, so we have to help it out by restarting the
  # process when we detect that a module we're interested in has changed.
  #
  # The expected consumer scenario is to pass the module name as `key` and its
  # last modification time as `key_timestamp`. This will ensure that Node
  # instance is restarted whenever the module is changed, but no earlier than
  # the changed module is actually required.
  #
  # Note that NodeServer internally maintains multiple keys and their
  # timestamps, so that a restart will happen only if this particular key has
  # expired. This allows us to keep the Node instance around longer - until we
  # actually need to work with the changed module again, but no earlier.
  def evaluate(js_code, key:, key_timestamp:, timeout: 10.seconds)
    @mutex.synchronize do
      Dir.mkdir @tmp_dir unless Dir.exist? @tmp_dir
      input_file = Tempfile.new ["node_server_input", ".js"], @tmp_dir
      input_file.write js_code
      input_file.close

      p = process key: key, key_timestamp: key_timestamp
      p.input.puts input_file.path
      read = ->(_) { p.output.readpartial(10_000) }
      result = timeout ? Timeout.timeout(timeout, &read) : read.call(0)

      # When result is too big, it might mean that we haven't read all of it,
      # which means that the next call might get the remainder of this output
      # mixed in with its own output, so to avoid that we kill the process, so
      # it gets recreated on next call. Note that we're comparing to 5K while
      # the argument to `readpartial` above is 10K. This discrepancy is by
      # design: `readpartial` argument is in bytes, while `String.length`
      # returns length in characters. So we cut the result off at 5K just to be
      # on the safe side.
      kill_process if result.length > 5_000

      result || { huh: "readpartial returned nil" }
    rescue Timeout::Error
      kill_process
      raise "JS code execution in Node Server timed out after #{timeout / 1.second}s"
    rescue StandardError => e
      # If we got any errors here, the Node process might be in a bad state, so
      # we're killing and recreating it just to be safe.
      kill_process
      { huh: "killed the process", error: e.to_s }
    ensure
      input_file&.unlink
    end
  end

  def cleanup
    @mutex.synchronize do
      kill_process
      @server_file&.unlink
    end
  end

  private

  def process(key:, key_timestamp:)
    if @process
      ts = @process.keys[key]
      if ts && ts < key_timestamp
        @log&.call "Restarting Node server because '#{key}' has changed since last restart"
        kill_process
      elsif !ts
        @process.keys[key] = key_timestamp
      end
    else
      @log&.call "Starting Node server to handle '#{key}'"
    end

    @process ||=
      begin
        out_r, out_w = IO.pipe
        in_r, in_w = IO.pipe
        pid = spawn "node #{@server_file.path}", chdir: @cwd, in: in_r, out: out_w
        Process.new(pid: pid, input: in_w, output: out_r, keys: { key => key_timestamp })
      end
  end

  def kill_process
    @process&.kill
    @process = nil
  end

  Process = Struct.new(:pid, :input, :output, :keys, keyword_init: true) do
    def kill
      input.close
      output.close
      ::Process.kill("HUP", pid)
    rescue StandardError # rubocop:disable Lint/HandleExceptions
      # An error sometimes happens here when the Node process is already gone
      # because it was killed by the console as a result of hitting Ctrl+C
    end
  end

  NODE_SERVER_CODE = "
    const fs = require('fs')
    console.log = () => {}

    require('readline')
      .createInterface({ input: process.stdin, terminal: false })
      .on('line', inputPath => {
        try {
          const code = fs.readFileSync(inputPath)
          const res = eval(code.toString())
          process.stdout.write(res === null || res === undefined ? 'null' : res.toString())
        }
        catch(e) {
          process.stdout.write(e.stack)
        }
      })
  ".freeze
end
