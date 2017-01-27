# -*- coding: utf-8 -*-
require "helper"

module Nokogiri
  module HTML
    module SAX
      class TestParserText < Nokogiri::SAX::TestCase
        def setup
          super
          @doc    = Doc.new
          @parser = HTML::SAX::Parser.new @doc
        end

        def test_order
          html = "<div>
            text 0
            <p>
              text 1
              <span>text 2</span>
              text 3
            </p>
            text 4
            <p>
              text 5
              <span>text 6</span>
              text 7
            </p>
            text 8
          </div>"

          @parser.parse html
          calls = @doc.calls
          calls.filter! "body"
          calls.select! [:start_element, :end_element, :characters]
          calls.strip_text!

          assert_equal [
            [ :start_element, ["div", []] ],
            [ :characters,    ["text 0"]  ],
            [ :start_element, ["p", []]   ],

            [ :characters,    ["text 1"]   ],
            [ :start_element, ["span", []] ],
            [ :characters,    ["text 2"]   ],
            [ :end_element,   ["span"]     ],
            [ :characters,    ["text 3"]   ],

            [ :end_element,   ["p"]      ],
            [ :characters,    ["text 4"] ],
            [ :start_element, ["p", []]  ],

            [ :characters,    ["text 5"]   ],
            [ :start_element, ["span", []] ],
            [ :characters,    ["text 6"]   ],
            [ :end_element,   ["span"]     ],
            [ :characters,    ["text 7"]   ],

            [ :end_element, ["p"]      ],
            [ :characters,  ["text 8"] ],
            [ :end_element, ["div"]    ]
          ], calls.items
        end

        def text_whitespace
          html = "<div>
            <p>
              <span></span>
            </p>
            <p>
              <span> </span>
            </p>
          </div>"

          @parser.parse html
          calls = @doc.calls
          calls.filter! "body"
          calls.select! [:start_element, :end_element, :characters]
          calls.strip_text!

          assert_equal [
            [ :start_element, ["div", []] ],
            [ :characters,    [""]        ],
            [ :start_element, ["p", []]   ],

            [ :characters,    [""]         ],
            [ :start_element, ["span", []] ],
            [ :end_element,   ["span"]     ],
            [ :characters,    [""]         ],

            [ :end_element,   ["p"]     ],
            [ :characters,    [""]      ],
            [ :start_element, ["p", []] ],

            [ :characters,    [""]         ],
            [ :start_element, ["span", []] ],
            [ :characters,    [""]         ],
            [ :end_element,   ["span"]     ],
            [ :characters,    [""]         ],

            [ :end_element, ["p"]   ],
            [ :characters,  [""]    ],
            [ :end_element, ["div"] ]
          ], calls.items
        end

        def test_comment
          html = "<div>
            <p>
              text 1
              <!-- text 2 -->
              text 3
              <!--
              text 4
              -->
              text 5
            </p>
            <p>
              <!---->
              <!-- -->
              <!--
              
              -->
            </p>
          </div>"

          @parser.parse html
          calls = @doc.calls
          calls.filter! "body"
          calls.select! [:start_element, :end_element, :characters, :comment]
          calls.strip_text!

          assert_equal [
            [ :start_element, ["div", []] ],
            [ :characters,    [""]        ],
            [ :start_element, ["p", []]   ],

            [ :characters,  ["text 1"] ],
            [ :comment,     ["text 2"] ],
            [ :characters,  ["text 3"] ],
            [ :comment,     ["text 4"] ],
            [ :characters,  ["text 5"] ],

            [ :end_element,   ["p"]     ],
            [ :characters,    [""]      ],
            [ :start_element, ["p", []] ],

            [ :characters,  [""] ],
            [ :comment,     [""] ],
            [ :characters,  [""] ],
            [ :comment,     [""] ],
            [ :characters,  [""] ],
            [ :comment,     [""] ],
            [ :characters,  [""] ],

            [ :end_element, ["p"]   ],
            [ :characters,  [""]    ],
            [ :end_element, ["div"] ]
          ], calls.items
        end
      end
    end
  end
end
