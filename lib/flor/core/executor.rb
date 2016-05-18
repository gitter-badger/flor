#--
# Copyright (c) 2015-2016, John Mettraux, jmettraux+flon@gmail.com
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

  class Executor

    attr_reader :execution
    attr_reader :unit

    def initialize(unit, execution)

      @unit = unit
      @execution = execution

      load_procedures('pcore')
    end

    def conf; @unit.conf; end

    protected

    def load_procedures(dir)

      dirpath =
        if dir.match(/\A[.\/]/)
          File.join(dir, '*.rb')
        else
          File.join(File.dirname(__FILE__), '..', dir, '*.rb')
        end

      Dir[dirpath].each { |path| require(path) }
    end

    def execute(message)

      nid = message['nid']

      now = Flor.tstamp

      node = {
        'nid' => nid,
        'parent' => message['from'],
        'ctime' => now,
        'mtime' => now }

      if vs = message['vars']
        node['vars'] = vs
      end
      if cnid = message['cnid']
        node['cnid'] = cnid
      end

      @execution['nodes'][nid] = node

      apply(node, message)
    end

    def apply(node, message)

      n = Flor::Node.new(@execution, node, message)

      mt = message['tree']
      nt = n.lookup_tree(node['nid'])
      node['tree'] = mt if mt && (mt != nt)
      tree = node['tree'] || nt

      t0 = tree[0]
      t0 = (t0.is_a?(Array) && t0[0] == '_dqs') ? n.expand(t0[1]) : t0

      heat = n.deref(t0)

      return error_reply(
        node, message, "don't know how to apply #{tree[0].inspect}"
      ) if heat == nil

      heak =
        if ! heat.is_a?(Array)
          Flor::Pro::Val
        elsif tree[1] == []
          Flor::Pro::Val
        elsif heat[0] == '_proc'
          Flor::Executor.procedures[heat[1]]
        elsif heat[0] == '_func'
          Flor::Pro::Apply
        else
          Flor::Pro::Val
        end

      head = heak.new(@execution, node, message)
      head.heat = heat if head.respond_to?(:heat=)

      head.send(message['point'])
    end

    def receive(message)

      from = message['from']

      fnode = @execution['nodes'][from]
      if fnode
        fnode['deleted'] = true # or should I use "status" => "deleted" ?
        @execution['nodes'].delete(from) if (fnode['closures'] || []).empty?
      end

      nid = message['nid']

      return [
        message.merge('point' => 'terminated', 'vars' => (fnode || {})['vars'])
      ] if nid == nil

      node = @execution['nodes'][nid]

      apply(node, message)
    end

    def error_reply(node, message, err)

      # TODO: use node (which may be nil)

      m = { 'point' => 'failed' }
      m['fpoint'] = message['point']
      m['exid'] = message['exid']
      m['nid'] = message['nid']
      m['from'] = message['from']
      m['payload'] = message['payload']
      m['tree'] = message['tree']
      m['error'] = Flor.to_error(err)

      [ m ]
    end

    def process(message)

      begin
        self.send(message['point'].to_sym, message)
      rescue => e
        error_reply(nil, message, e)
      end
    end
  end

  # class methods
  #
  class Executor

    def self.procedures

      @@procedures ||= {}
    end
  end
end
