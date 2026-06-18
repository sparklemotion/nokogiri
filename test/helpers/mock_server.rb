# frozen_string_literal: true

require "socket"

require_relative "memory_debugger"

module Nokogiri
  module MockServer
    def self.listener_class
      Nokogiri.jruby? ? ThreadListener : ProcessListener
    end

    def self.supported?
      listener_class.supported?
    end

    # Accepts and immediately closes TCP connections on an ephemeral port,
    # counting them. Runs in a forked child process because on CRuby a parse
    # that accesses the network blocks in a C call that holds the GVL, so an
    # in-process listener thread would be starved and could never accept the
    # connection. The child writes one byte per connection to a pipe, and the
    # parent counts the bytes after reaping the child.
    class ProcessListener
      # Process.fork rules out platforms like Windows, and we also avoid
      # forking under memory debuggers, where children are traced too.
      def self.supported?
        Process.respond_to?(:fork) && !MemoryDebugger.active?
      end

      attr_reader :port

      def initialize
        server = TCPServer.new("127.0.0.1", 0)
        @port = server.addr[1]
        @reader, writer = IO.pipe
        @pid = Process.fork do
          @reader.close
          writer.sync = true
          loop do
            client = server.accept
            writer.write(".")
            client.close
          end
        end
        writer.close
        server.close
      end

      def stop
        Process.kill(:TERM, @pid)
        Process.wait(@pid)
        @reader.read.length
      ensure
        @reader.close
      end
    end

    # Same API as ProcessListener, but runs in an in-process thread. JRuby has
    # no GVL, so the listener thread can accept connections while a parse is
    # blocked, and avoiding process spawn keeps the tests fast on the JVM.
    class ThreadListener
      def self.supported?
        true
      end

      attr_reader :port

      def initialize
        @server = TCPServer.new("127.0.0.1", 0)
        @port = @server.addr[1]
        @connections = 0
        @thread = Thread.new do
          loop do
            client = @server.accept
            @connections += 1
            client.close
          end
        rescue IOError, Errno::EBADF
        end
      end

      def stop
        @server.close
        @thread.join
        @connections
      end
    end
  end
end
