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


class Flor::Pro::Cond < Flor::Procedure

  name 'cond'

  def receive_non_att

    return execute_child(0) if @message['point'] == 'execute'
    return reply if @node['found']

    tf2 = tree[1][@fcid + 2]

    if Flor.true?(payload['ret'])
      @node['found'] = true
      execute_child(@fcid + 1)
    elsif tf2 && tf2[0, 2] == [ 'else', [] ]
      @node['found'] = true
      execute_child(@fcid + 3)
    else
      execute_child(@fcid + 2)
    end
  end

  protected

  def execute_child(i)

    payload['ret'] = node_payload_ret unless tree[1][i]

    super(i)
  end
end

