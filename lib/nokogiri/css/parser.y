class Nokogiri::CSS::GeneratedParser

token FUNCTION INCLUDES DASHMATCH LBRACE HASH PLUS GREATER S STRING IDENT
token COMMA URI CDO CDC NUMBER PERCENTAGE LENGTH EMS EXS ANGLE TIME FREQ
token IMPORTANT_SYM IMPORT_SYM MEDIA_SYM PAGE_SYM CHARSET_SYM DIMENSION
token PREFIXMATCH SUFFIXMATCH SUBSTRINGMATCH TILDE NOT_EQUAL SLASH DOUBLESLASH
token NOT

rule
  selector
    : selector COMMA s_0toN simple_selector_1toN {
        result = [val.first, val.last].flatten
      }
    | simple_selector_1toN { result = val.flatten }
    ;
  combinator
    : PLUS s_0toN { result = :DIRECT_ADJACENT_SELECTOR }
    | GREATER s_0toN { result = :CHILD_SELECTOR }
    | TILDE s_0toN { result = :PRECEDING_SELECTOR }
    | S { result = :DESCENDANT_SELECTOR }
    | DOUBLESLASH s_0toN { result = :DESCENDANT_SELECTOR }
    | SLASH s_0toN { result = :CHILD_SELECTOR }
    ;
  simple_selector
    : element_name hcap_0toN {
        result =  if val[1].nil?
                    val.first
                  else
                    Node.new(:CONDITIONAL_SELECTOR, [val.first, val[1]])
                  end
      }
    | element_name negation {
        result = Node.new(:CONDITIONAL_SELECTOR, val)
      }
    | function
    | function attrib {
        result = Node.new(:CONDITIONAL_SELECTOR, val)
      }
    | hcap_1toN {
        result = Node.new(:CONDITIONAL_SELECTOR,
          [Node.new(:ELEMENT_NAME, ['*']), val.first]
        )
      }
    ;
  simple_selector_1toN
    : simple_selector combinator simple_selector_1toN {
        result = Node.new(val[1], [val.first, val.last])
      }
    | simple_selector
    ;
  class
    : '.' IDENT { result = Node.new(:CLASS_CONDITION, [val[1]]) }
    ;
  element_name
    : IDENT { result = Node.new(:ELEMENT_NAME, val) }
    | '*' { result = Node.new(:ELEMENT_NAME, val) }
    ;
  attrib
    : '[' s_0toN IDENT s_0toN attrib_val_0or1 ']' {
        result = Node.new(:ATTRIBUTE_CONDITION,
          [Node.new(:ELEMENT_NAME, [val[2]])] + (val[4] || [])
        )
      }
    | '[' s_0toN function s_0toN attrib_val_0or1 ']' {
        result = Node.new(:ATTRIBUTE_CONDITION,
          [val[2]] + (val[4] || [])
        )
      }
    | '[' s_0toN NUMBER s_0toN ']' {
        # Non standard, but hpricot supports it.
        result = Node.new(:PSEUDO_CLASS,
          [Node.new(:FUNCTION, ['nth-child(', val[2]])]
        )
      }
    ;
  function
    : FUNCTION ')' {
        result = Node.new(:FUNCTION, [val.first.strip])
      }
    | FUNCTION expr ')' {
        result = Node.new(:FUNCTION, [val.first.strip, val[1]].flatten)
      }
    | FUNCTION an_plus_b ')' {
        result = Node.new(:FUNCTION, [val.first.strip, val[1]].flatten)
      }
    | NOT expr ')' {
        result = Node.new(:FUNCTION, [val.first.strip, val[1]].flatten)
      }
    ;
  expr
    : NUMBER
    | STRING
    ;
  an_plus_b
    : NUMBER IDENT PLUS NUMBER          # 5n+3 -5n+3
      {
        if val[1] == 'n'
          result = Node.new(:AN_PLUS_B, val)
        else
          raise Racc::ParseError, "parse error on IDENT '#{val[1]}'"
        end
      }
    | IDENT PLUS NUMBER {               # n+3, -n+3
        if val[0] == 'n'
          val.unshift("1")
          result = Node.new(:AN_PLUS_B, val)
        elsif val[0] == '-n'
          val[0] = 'n'
          val.unshift("-1")
          result = Node.new(:AN_PLUS_B, val)
        else
          raise Racc::ParseError, "parse error on IDENT '#{val[1]}'"
        end
      }
    | NUMBER IDENT                      # 5n, -5n
      {
        if val[1] == 'n'
          val << "+"
          val << "0"
          result = Node.new(:AN_PLUS_B, val)
        else
          raise Racc::ParseError, "parse error on IDENT '#{val[1]}'"
        end
      }
    | IDENT                             # even, odd
      {
        if val[0] == 'even'
          val = ["2","n","+","0"]
          result = Node.new(:AN_PLUS_B, val)
        elsif val[0] == 'odd'
          val = ["2","n","+","1"]
          result = Node.new(:AN_PLUS_B, val)
        else
          raise Racc::ParseError, "parse error on IDENT '#{val[0]}'"
        end
      }
    ;
  pseudo
    : ':' function {
        result = Node.new(:PSEUDO_CLASS, [val[1]])
      }
    | ':' IDENT { result = Node.new(:PSEUDO_CLASS, [val[1]]) }
    ;
  hcap_0toN
    : hcap_1toN
    |
    ;
  hcap_1toN
    : attribute_id hcap_1toN {
        result = Node.new(:COMBINATOR, val)
      }
    | class hcap_1toN {
        result = Node.new(:COMBINATOR, val)
      }
    | attrib hcap_1toN {
        result = Node.new(:COMBINATOR, val)
      }
    | pseudo hcap_1toN {
        result = Node.new(:COMBINATOR, val)
      }
    | attribute_id
    | class
    | attrib
    | pseudo
    ;
  attribute_id
    : HASH { result = Node.new(:ID, val) }
    ;
  attrib_val_0or1
    : eql_incl_dash s_0toN IDENT s_0toN { result = [val.first, val[2]] }
    | eql_incl_dash s_0toN STRING s_0toN { result = [val.first, val[2]] }
    |
    ;
  eql_incl_dash
    : '='
    | PREFIXMATCH
    | SUFFIXMATCH
    | SUBSTRINGMATCH
    | NOT_EQUAL
    | INCLUDES
    | DASHMATCH
    ;
  negation
    : NOT s_0toN negation_arg s_0toN ')' {
        result = Node.new(:NOT, [val[2]])
      }
    ;
  negation_arg
    : hcap_1toN
    ;
  s_0toN
    : S s_0toN
    |
    ;
end

---- header

