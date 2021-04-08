#!/usr/bin/env ruby

# Copyright 2018 Stephen Checkoway
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# The output of this script should be compiled with ragel 6.10 which is the
# current stable version. Version 7 changes some stuff but what, precisely,
# isn't documented yet.

require 'psych'
require 'open-uri'

ENTITIES_URL = 'https://html.spec.whatwg.org/entities.json'

# Modify the json to remove the characters item because it contains surrogate
# pairs that Psych errors on.
entities = URI.parse(ENTITIES_URL).read
entities.gsub!(/, "characters"[^}]*/, '')
entities = Psych.safe_load(entities)

without_semicolon = {}
with_semicolon = {}
entities.each do |key, val|
  if key.end_with?(';')
    with_semicolon[key[1..-1]] = val['codepoints']
  else
    without_semicolon[key[1..-1]] = val['codepoints']
  end
end

without_semicolon.each do |entity, codepoints|
  puts "#{entity} has the wrong number of codepoints" unless [1,2].include?(codepoints.length)
  with = "#{entity};"
  unless with_semicolon.key?(with)
    puts("#{entity} but not #{with}")
    next
  end
  if codepoints != with_semicolon[with]
    puts("#{entity} and #{with} have different codepoints!")
  end
end

puts(<<-EOF)
// Generated from <#{ENTITIES_URL}> by entities.rb
#include "char_ref.h"
%%{
machine named_char_ref;
named_char_ref := |*
EOF
with_semicolon.each do |entity, codepoints|
  without = entity.chop
  if without_semicolon.key?(without)
    pattern = "'#{without}' . ';'?" 
  else
    pattern = "'#{entity}'"
  end
  code = codepoints.map.with_index { |cp, idx| sprintf("output[%d]=%#04x", idx, cp) }
  puts("  #{pattern} => {#{code.join('; ')}; fbreak;};")
end 
puts(<<-EOF)
*|;
write data noerror nofinal noentry noprefix;
}%%

size_t match_named_char_ref (
  const char *str,
  size_t size,
  int output[2]
) {
  int cs;
  int act;
  const char *p = str;
  const char *pe = str + size;
  const char *const eof = pe;
  const char *ts;
  const char *te;
  output[0] = output[1] = kGumboNoChar;
  %% write init;
  %% write exec;
  (void)ts;
  (void)act;
  size = p - str;
  return cs >= %%{ write first_final; }%%? size:0;
}
EOF
