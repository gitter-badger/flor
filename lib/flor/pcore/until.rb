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


class Flor::Pro::Until < Flor::Procedure

  names 'until', 'while'

  def pre_execute

    @node['subs'] = []

    unatt_first_unkeyed_child
  end

  def receive_first

    @node['vars'] =
      {}
    @node['vars']['break'] =
      [ '_proc', { 'proc' => 'break', 'nid' => nid }, tree[-1] ]
    @node['vars']['continue'] =
      [ '_proc', { 'proc' => 'continue', 'nid' => nid }, tree[-1] ]

    super
  end

  def receive_non_att
    #
    # receiving from a non_att child (condition or block)

    if @fcid == first_unkeyed_child_id

      t0 = tree[0]
      tru = Flor.true?(payload['ret'])

      if (tru && t0 == 'until') || ( ! tru && t0 == 'while')
        #
        # over

        ret = @node.has_key?('cret') ? @node['cret'] : node_payload_ret
        reply('ret' => ret)

      else
        #
        # condition yield false, enter "block"

        payload['ret'] = node_payload_ret
        execute_child(@ncid, @node['subs'].last)
      end

    elsif @ncid >= children.size
      #
      # block over, increment counter and head back to condition

      @node['subs'] << counter_next('subs')

      @node['cret'] = payload['ret']
      payload['ret'] = node_payload_ret
      execute_child(first_unkeyed_child_id, @node['subs'].last)

    else
      #
      # we're in the middle of the "block", let's carry on

      # no need to set 'ret', we're in some kind of sequence
      execute_child(@ncid, @node['subs'].last)
    end
  end

  def cancel_when_closed

    return [] unless @message['flavour'] == 'break'

    cancel
  end

  def cancel

    fla = @message['flavour']

    if fla == 'continue'

      pl = node_payload.copy_current
      pl = pl.merge!(payload.copy_current)

      @node['subs'] << counter_next('subs')

      @node['on_receive_last'] =
        execute_child(
          first_unkeyed_child_id, @node['subs'].last, 'payload' => pl)

    else

      @node['on_receive_last'] = nil
    end

    super
  end
end

