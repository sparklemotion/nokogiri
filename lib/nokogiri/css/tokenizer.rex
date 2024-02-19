class Nokogiri::CSS::Tokenizer

option
  lineno
  column

inner

  def do_parse
    # next_token # HACK! this should be provided by the parser or _something_
  end

macro
  NL        /\n|\r\n|\r|\f/
  W         /[\s]*/
  NONASCII  /[^\0-\177]/
  NUM       /-?([0-9]+|[0-9]*\.[0-9]+)/
  UNICODE   /\\[0-9A-Fa-f]{1,6}(\r\n|[\s])?/

  ESCAPE    /#{UNICODE}|\\[^\n\r\f0-9A-Fa-f]/
  NMCHAR    /[_A-Za-z0-9-]|#{NONASCII}|#{ESCAPE}/
  NMSTART   /[_A-Za-z]|#{NONASCII}|#{ESCAPE}/
  IDENT     /-?(#{NMSTART})(#{NMCHAR})*/
  NAME      /(#{NMCHAR})+/
  STRING1   /"([^\n\r\f"]|#{NL}|#{NONASCII}|#{ESCAPE})*(?<!\\)(?:\\{2})*"/
  STRING2   /'([^\n\r\f']|#{NL}|#{NONASCII}|#{ESCAPE})*(?<!\\)(?:\\{2})*'/
  STRING    /#{STRING1}|#{STRING2}/

rule

            # TODO: consider using something like this and drop all the \s's
            # /[\ \t\r\f\v]+/  { next }

            /has\(#{W}/      { [:HAS, text] }
            /#{NUM}/         { [:NUMBER, text] }
            /#{IDENT}\(#{W}/ { [:FUNCTION, text] }
            /#{IDENT}/       { [:IDENT, text] }
            /##{NAME}/       { [:HASH, text] }
            /#{W}\~=#{W}/    { [:INCLUDES, text] }
            /#{W}\|=#{W}/    { [:DASHMATCH, text] }
            /#{W}\^=#{W}/    { [:PREFIXMATCH, text] }
            /#{W}\$=#{W}/    { [:SUFFIXMATCH, text] }
            /#{W}\*=#{W}/    { [:SUBSTRINGMATCH, text] }
            /#{W}!=#{W}/     { [:NOT_EQUAL, text] }
            /#{W}=#{W}/      { [:EQUAL, text] }
            /#{W}\)/         { [:RPAREN, text] }
            /\[#{W}/         { [:LSQUARE, text] }
            /#{W}\]/         { [:RSQUARE, text] }
            /#{W}\+#{W}/     { [:PLUS, text] }
            /#{W}>#{W}/      { [:GREATER, text] }
            /#{W},#{W}/      { [:COMMA, text] }
            /#{W}~#{W}/      { [:TILDE, text] }
            /:not\(#{W}/     { [:NOT, text] }
            /#{W}\/\/#{W}/   { [:DOUBLESLASH, text] }
            /#{W}\/#{W}/     { [:SLASH, text] }

            /U\+[0-9a-f?]{1,6}(-[0-9a-f]{1,6})?/  {[:UNICODE_RANGE, text] }

            /[\s]+/          { [:S, text] }
            /#{STRING}/      { [:STRING, text] }
            /./              { [text, text] }
end
