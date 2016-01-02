
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


class Flor::Unit

#char *flon_conf_uid()
#{
#  char *gid = flon_conf_string("unit.gid", NULL);
#  char *uid = flon_conf_string("unit.id", NULL);
#
#  if (gid == NULL && uid == NULL) return strdup("u0");
#  if (gid == NULL) return uid;
#
#  char *r = flu_sprintf("%s.%s", gid, uid);
#
#  free(gid); free(uid);
#
#  return r;
#}

#char *flon_generate_exid(const char *domain)
#{
#  char *uid = flon_conf_uid();
#  short local = flon_conf_is("unit.time", "local");
#
#  struct timeval tv;
#  struct tm *tm;
#  char t[20];
#
#  gettimeofday(&tv, NULL);
#  tm = local ? localtime(&tv.tv_sec) : gmtime(&tv.tv_sec);
#  strftime(t, 20, "%Y%m%d.%H%M", tm);
#
#  char *sus =
#    fmne_to_s((tv.tv_sec % 60) * 100000000 + tv.tv_usec * 100 + counter);
#
#  char *r =
#    flu_sprintf("%s-%s-%s.%s", domain, uid, t, sus);
#
#  free(sus);
#  free(uid);
#
#  counter++; if (counter > 99) counter = 0;
#
#  return r;
#}

  def launch(domain, tree, payload, variables=nil)

    exid = generate_exid(domain)

    msg = { point: 'execute', domain: domain, exid: exid, payload: payload }
    msg[:vars] = variables if variables

    store_message(:dispatcher, msg)

    exid
  end

  protected

  def generate_exid(domain)

    @exid_counter ||= 0
    @exid_mutex ||= Mutex.new

    local = true

    uid = 'u0'

    t = Time.now
    t = t.utc unless local

    sus =
      @exid_mutex.synchronize do

        sus = t.sec * 100000000 + t.usec * 100 + @exid_counter

        @exid_counter = @exid_counter + 1
        @exid_counter = 0 if @exid_counter > 99

        Munemo.to_s(sus)
      end

    t = t.strftime('%Y%m%d.%H%M')

    "#{domain}-#{uid}-#{t}.#{sus}"
  end
end
