class Nokogiri::CSS::GeneratedParser

token FUNCTION INCLUDES DASHMATCH LBRACE HASH PLUS GREATER S STRING IDENT
token COMMA URI CDO CDC NUMBER PERCENTAGE LENGTH EMS EXS ANGLE TIME FREQ
token IMPORTANT_SYM IMPORT_SYM MEDIA_SYM PAGE_SYM CHARSET_SYM DIMENSION

rule
  selector
    : simple_selector_1toN { result = val.flatten.first }
    ;
  combinator
    : PLUS s_0toN { result = :DIRECT_ADJACENT_SELECTOR }
    | GREATER s_0toN { result = :CHILD_SELECTOR }
    | S { result = :DESCENDANT_SELECTOR }
    ;
  simple_selector
    : element_name hcap_0toN {
        result =  if val[1].nil?
                    val.first
                  else
                    Node.new(:CONDITIONAL_SELECTOR, [val.first, val[1]])
                  end
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
        result = AttributeCondition.build(val[2], val[4])
      }
    ;
  function
    : FUNCTION s_0toN ')' s_0toN {
        ### We only support 0 argument functions for now....
        result = Function.new(val[0], val[2].flatten.select { |x| x !~ /,/ })
      }
    ;
  pseudo
    : ':' function {
        result = PseudoClassCondition.new(val[1])
      }
    | ':' IDENT { result = Node.new(:PSEUDO_CLASS, [val[1]]) }
    ;
  hcap_0toN
    : hcap_1toN
    |
    ;
  hcap_1toN
    : attribute_id hcap_1toN {
        result = CombinatorCondition.new(val[0], val[1])
      }
    | class hcap_1toN {
        result = Node.new(:COMBINATOR, val)
      }
    | attrib hcap_1toN {
        result = CombinatorCondition.new(val[0], val[1])
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
    : HASH { result = IDCondition.new(val.first) }
    ;
  attrib_val_0or1
    : eql_incl_dash s_0toN IDENT s_0toN { result = [val.first, val[2]] }
    | eql_incl_dash s_0toN STRING s_0toN { result = [val.first, val[2]] }
    |
    ;
  eql_incl_dash
    : '='
    | INCLUDES
    | DASHMATCH
    ;
  s_0toN
    : S s_0toN
    |
    ;
end

---- header

