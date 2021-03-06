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


class Flor::Pro::Push < Flor::Procedure

  name 'push', 'pushr'

  def pre_execute

    unatt_unkeyed_children
    stringify_first_child
  end

  def receive_non_att

    @node['arr'] ||= payload['ret']

    super
  end

  def receive_last

    arr = @node['arr']

    if arr.is_a?(String)
      payload.copy if arr[0, 1] == 'f'
      arr = lookup(arr)
    end

    fail Flor::FlorError.new(
      "cannot push to given target (#{arr.class})", self
    ) unless arr.respond_to?(:push)

    val =
      unkeyed_children.size > 1 ?
      payload['ret'] :
      node_payload_ret

    arr.push(val)

    payload['ret'] = node_payload_ret \
      unless tree[0] == 'pushr'

    reply
  end
end

