#--
# Copyright (c) 2015-2017, John Mettraux, jmettraux+flor@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++

module Flor

  class Ganger

    # NB: tasker configuration entries start with "gan_"

    attr_reader :unit

    def initialize(unit)

      @unit = unit
    end

    def shutdown
    end

    def has_tasker?(exid, name)

      domain = exid.split('-', 2).first

      !! @unit.loader.tasker(domain, name)
    end

    def task(executor, message)

      domain = message['exid'].split('-', 2).first
      tname = message['tasker']

      tconf =
        ( ! message['routed'] && @unit.loader.tasker(domain, 'tasker')) ||
        @unit.loader.tasker(domain, tname)
          #
          # TODO `.tasker(domain, 'ganger')`

      fail ArgumentError.new(
        "tasker #{tname.inspect} not found"
      ) unless tconf

      message['tconf'] = tconf \
        unless tconf['on_task']['include_tconf'] == false

      message['vars'] = gather_vars(executor, tconf, message)

      cot = tconf['on_task']

      return ruby_task(message, tconf) if cot['require'] || cot['class']
      return cmd_task(message, tconf) if cot['cmd']

      fail ArgumentError.new(
        "don't know how to use tasker at #{tconf['_path']}"
      )
    end

    def cancel(tasker_name, fei)

      # TODO use on_cancel || on_task

      fail NotImplementedError
    end

    def reply(message)

      @unit.queue({
        'point' => 'return',
        'exid' => message['exid'],
        'nid' => message['nid'],
        'payload' => message['payload'],
        'tasker' => message['tasker'] })

      nil
    end

    protected

    def is_a_message_array?(o)

      o.is_a?(Array) &&
      o.first.is_a?(Hash) &&
      o.first['point'].is_a?(String)
    end

    def ruby_task(message, tconf)

      root = File.dirname(tconf['_path'])

      Array(tconf['on_task']['require'])
        .each { |pa|
          fail ArgumentError.new('".." not allowed in paths') if pa =~ /\.\./
          require(File.join(root, pa)) }
      Array(tconf['on_task']['load'])
        .each { |pa|
          fail ArgumentError.new('".." not allowed in paths') if pa =~ /\.\./
          load(File.join(root, pa)) }

      k = tconf['on_task']['class']
      k = Flor.const_lookup(k)

      ka = k.instance_method(:initialize).arity

      m =
        message['point'] == 'detask' ?
        :cancel :
        :task

      r =
        if ka == 2
          k.new(self, tconf).send(m, message)
        else # ka == 3
          k.new(self, tconf, message).send(m)
        end

      # if the tasker returns something intelligible, use it
      # else reply with "nothing further to do" (empty message array)

      if is_a_message_array?(r)
        r
      else
        []
      end
    end

    def cmd_task(message, tconf)

      fail NotImplementedError

      []
    end

    def var_match(k, filter)

      filter.each { |f| return true if (f.is_a?(String) ? k == f : f.match(k)) }
      false
    end

    def expand_filter(f)

      return f unless f.is_a?(Array)

      f.collect { |e|
        if e.is_a?(String)
          e
        elsif e.is_a?(Array) && e[0] == '_rxs' && e[1].is_a?(String)

          s = e[1]
          li, ri = s.index('/'), s.rindex('/')
          tail = s[ri + 1..-1]
          ops =
            (tail.index('i') ? Regexp::IGNORECASE : 0) |
            (tail.index('x') ? Regexp::EXTENDED : 0)
          Regexp.new(s[li + 1..ri - 1], ops)
        else
          nil
        end
      }.compact
    end

    def gather_vars(executor, tconf, message)

      ot = tconf['on_task']

      # try to return before calling executor.vars(nid) which my be costly...

      return nil if (ot.keys & %w[ include_vars exclude_vars ]).empty?
        # default behaviour, don't pass variables to taskers

      iv = expand_filter(ot['include_vars'])
      return nil if iv == false

      ev = expand_filter(ot['exclude_vars'])
      return {} if ev == true

      vars = executor.vars(message['nid'])

      return vars if iv == true

      vars = vars.select { |k, v| var_match(k, iv) } if iv
      vars = vars.reject { |k, v| var_match(k, ev) } if ev

      vars
    end
  end
end

