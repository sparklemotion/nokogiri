module Nokogiri
module CSS
class GeneratedTokenizer

macro
  nl        \n|\r\n|\r|\f
  w         [\s\r\n\f]*
  nonascii  [^\\\\0-\\\\177]
  num       -?([0-9]+|[0-9]*\.[0-9]+)
  unicode   \\\\\\\\\[0-9a-f]{1,6}(\r\n|[\s\n\r\t\f])?

  escape    {unicode}|\\\\\\\[^\n\r\f0-9a-f]
  nmchar    [_a-z0-9-]|{nonascii}|{escape}
  nmstart   [_a-z]|{nonascii}|{escape}
  ident     [-]?({nmstart})({nmchar})*
  name      ({nmchar})+
  string1   "([^\n\r\f"]|\\{nl}|{nonascii}|{escape})*"
  string2   '([^\n\r\f']|\\{nl}|{nonascii}|{escape})*'
  string    {string1}|{string2}
  invalid1  \"([^\n\r\f\\"]|\\{nl}|{nonascii}|{escape})*
  invalid2  \'([^\n\r\f\\']|\\{nl}|{nonascii}|{escape})*
  invalid   {invalid1}|{invalid2}
  Comment   \/\*(.|[\r\n])*?\*\/

rule

# [:state]  pattern  [actions]

            ~=               { [:INCLUDES, text] }
            \|=              { [:DASHMATCH, text] }
            \^=              { [:PREFIXMATCH, text] }
            \$=              { [:SUFFIXMATCH, text] }
            \*=              { [:SUBSTRINGMATCH, text] }
            !=               { [:NOT_EQUAL, text] }
            {ident}\(\s*     { [:FUNCTION, text] }
            @{ident}         { [:IDENT, text] }
            {ident}          { [:IDENT, text] }
            {num}            { [:NUMBER, text] }
            \#{name}         { [:HASH, text] }
            {w}\+            { [:PLUS, text] }
            {w}>             { [:GREATER, text] }
            {w},             { [:COMMA, text] }
            {w}~             { [:TILDE, text] }
            \:not\(          { [:NOT, text] }
            @{ident}         { [:ATKEYWORD, text] }
            {num}%           { [:PERCENTAGE, text] }
            {num}{ident}     { [:DIMENSION, text] }
            <!--             { [:CDO, text] }
            -->              { [:CDC, text] }
            {w}\/\/          { [:DOUBLESLASH, text] }
            {w}\/            { [:SLASH, text] }
            
            U\+[0-9a-f?]{1,6}(-[0-9a-f]{1,6})?  {[:UNICODE_RANGE, text] }
            
            {Comment}                    /* ignore comments */
            [\s\t\r\n\f]+    { [:S, text] }
            [\.*:\[\]=\)]    { [text, text] }
            {string}         { [:STRING, text] }
            {invalid}        { [:INVALID, text] }
            .                { [text, text] }
end
end
end
