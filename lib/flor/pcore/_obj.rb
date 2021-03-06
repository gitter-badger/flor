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


class Flor::Pro::Obj < Flor::Procedure

  name '_obj'

  def pre_execute

    @node['rets'] = []
  end

  def receive_first

    return reply('ret' => {}) if children == 0

    cn = children
      .inject([]) { |a, e| a << (a.size.even? ? stringify(e) : e); a }

    @node['tree'] = [ tree[0], cn, tree[2] ] if children != cn

    super
  end

  def receive_last

    payload['ret'] =
      @node['rets']
        .each_slice(2)
        .inject({}) { |h, (k, v)| h[k.to_s] = v; h }

    reply
  end

  protected

  def stringify(t)

    return t unless t[1] == [] && t[0].is_a?(String)
    [ '_sqs', deref(t[0]) || t[0], t[2] ]
  end
end

