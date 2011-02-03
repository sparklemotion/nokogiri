/**
 * (The MIT License)
 *
 * Copyright (c) 2008 - 2011:
 *
 * * {Aaron Patterson}[http://tenderlovemaking.com]
 * * {Mike Dalessio}[http://mike.daless.io]
 * * {Charles Nutter}[http://blog.headius.com/]
 * * {Sergio Arbeo}[http://www.serabe.com/]
 * * {Patrick Mahoney}[http://polycrystal.org/]
 * * {Yoko Harada}[http://yokolet.blogspot.com/]
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * 'Software'), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

package nokogiri.internals;

import java.io.IOException;
import java.io.InputStream;
import java.nio.channels.ClosedChannelException;
import java.util.ArrayList;


/**
 * Implements a "push" InputStream.  An owner thread create an
 * InputStream and passes it to a second thread.  The owner thread
 * calls PushInputStream.write() to write data to the stream.  The
 * second thread calls PushInputStream.read() and other InputStream
 * methods.
 *
 * You should ensure that only one thread write to, and only one
 * thread reads to, this stream, though nothing enforces this
 * strictly.
 */
public class PushInputStream extends InputStream {
    /**
     * Current position in the stream relative to the start of the
     * buffer.
     */
    protected int pos;

    /**
     * Current mark position, or -1 if there is no mark.
     */
    protected int mark;

    protected int readlimit;

    /**
     * State is open or closed.
     */
    protected boolean isOpen;

    protected Buffer buffer;

    public PushInputStream() {
        pos = 0;
        mark = -1;
        readlimit = -1;
        isOpen = true;

        buffer = new Buffer(512);
    }

    protected synchronized void ensureOpen() throws IOException {
        if (!isOpen) {
            throw new ClosedChannelException();
        }
    }

    /**
     * Write data that can be read from the stream.
     */
    public synchronized void write(byte[] b) {
        if (buffer == null) System.out.println("BUFFER IS NULL");
        if (b == null) System.out.println("BYTE ARRAY IS NILL");
        buffer.put(b);
        notifyAll();            // notify readers waiting
    }

    /**
     * Write data and then wait until all the data has been read
     * (waits until the thread reading from this stream is blocked in
     * a read()).
     */
    public synchronized void writeAndWaitForRead(byte[] b) throws IOException {
        ensureOpen();
        write(b);
        for (;;) {
            try {
                wait();
                break;
            } catch (InterruptedException e) {
                // continue waiting
            }
        }
    }

    /*
     *------------------------------------------------------------
     * InputStream methods
     *------------------------------------------------------------
     */

    /**
     * @see InputStream.available()
     */
    @Override
    public synchronized int available() throws IOException {
        ensureOpen();
        return buffer.size() - pos;
    }

    int nClose = 0;
    /**
     * @see InputStream.close()
     */
    @Override
    public synchronized void close() throws IOException {
        if (!isOpen) return;
        isOpen = false;
        buffer = null;
        notifyAll();
    }

    /**
     * @see InputStream.mark()
     */
    @Override
    public synchronized void mark(int readlimit) {
        this.mark = pos;
        this.readlimit = readlimit;
    }

    /**
     * Mark the current position in this stream.  Supported by
     * PushInputStream.
     *
     * @see InputStream.markSupported()
     */
    @Override
    public synchronized boolean markSupported() {
        return true;
    }

    /**
     * @see InputStream.read()
     */
    @Override
    public synchronized int read() throws IOException {
        ensureOpen();
        byte[] b = new byte[1];
        read(b, 0, 1);
        return (int) b[0];
    }

    /**
     * @see InputStream.read(byte[])
     */
    @Override
    public synchronized int read(byte[] b) throws IOException {
        ensureOpen();
        return read(b, 0, b.length);
    }

    protected synchronized boolean markIsValid() {
        return (mark >= 0 && pos < mark+readlimit);
    }

    /**
     * @see InputStream.read(byte[], int, int)
     */
    @Override
    public synchronized int read(byte[] b, int off, int len) throws IOException {
        while (isOpen && available() == 0) {
            /* block until data available */
            try {
                notifyAll();    // notify writers waiting
                wait();
            } catch (InterruptedException e) {
                // continue waiting
            }
        }

        if (!isOpen) {
            return -1;
        }

        int readLen = Math.min(available(), len);

        buffer.get(pos, readLen, b, off);
        pos += readLen;

        int reduce;

        if (markIsValid()) {
            reduce = mark;
        } else {
            reduce = pos;
        }

        buffer.truncateFromStart(buffer.size - reduce);
        pos -= reduce;
        mark -= reduce;
        if (mark < 0) mark = -1; // don't wrap mark around?

        return readLen;
    }

    /**
     * @see InputStream.reset()
     */
    @Override
    public synchronized void reset() throws IOException {
        ensureOpen();
        if (markIsValid())
            pos = mark;
    }

    /**
     * @see InputStream.skip()
     */
    @Override
    public synchronized long skip(long n) throws IOException {
        ensureOpen();
        pos += n;
        return n;
    }

    /*
     *------------------------------------------------------------
     * Data Buffer
     *------------------------------------------------------------
     */

    public static class Block {
        protected byte[] data;

        public Block(int size) {
            data = new byte[size];
        }

        public void copyIn(byte[] src, int srcPos, int destPos, int length) {
            System.arraycopy(src, srcPos, data, destPos, length);
        }

        public void copyOut(int srcPos, byte[] dest, int destPos, int length) {
            System.arraycopy(data, srcPos, dest, destPos, length);
        }
    }

    public static class BlockList extends ArrayList<Block> {
        public BlockList() {
            super();
        }

        @Override
        public void removeRange(int fromIndex, int toIndex) {
            super.removeRange(fromIndex, toIndex);
        }
    }

    public static class Buffer {
        protected int blockSize;
        protected BlockList blocks;

        /**
         * Offset (position) to the first logical byte in the buffer.
         */
        protected int offset;

        /**
         * Logical size of the buffer.
         */
        protected int size;

        public Buffer(int blockSize) {
            this.blockSize = blockSize;
            this.blocks = new BlockList();
            this.offset = 0;
            this.size = 0;
        }

        public int size() {
            return size;
        }

        protected class Segment {
            /**
             * Block index.
             */
            protected int block;

            /**
             * Offset into the block.
             */
            protected int off;

            /**
             * Length of segment.
             */
            protected int len;

            /**
             * Calculate the block number and block offset given a position.
             */
            protected Segment(int pos) {
                int absPos = offset + pos;
                block = (int) (absPos / blockSize);
                off = (int) (absPos % blockSize);
                len = -1;
            }
        }

        protected Segment[] accessList(int pos, int size) {
            Segment start = new Segment(pos);
            Segment end = new Segment(pos + size);
            int nBlocks = end.block - start.block + 1;
            Segment[] segs = new Segment[nBlocks];

            start.len = Math.min(size, blockSize - start.off);
            segs[0] = start;
            int currPos = pos + start.len;
            int currSize = start.len;
            for (int i = 1; i < nBlocks; i++) {
                Segment seg = new Segment(currPos);
                seg.len = Math.min(blockSize, size - currSize);
                segs[i] = seg;
                currPos += seg.len;
                currSize += seg.len;
            }

            return segs;
        }

        protected void ensureCapacity(int pos) {
            Segment seg = new Segment(pos-1);

            while (blocks.size() < (seg.block + 1))
                blocks.add(new Block(blockSize));
        }

        public void put(byte b) {
            byte[] buf = new byte[1];
            buf[0] = b;
            put(buf);
        }

        public void put(byte[] b) {
            ensureCapacity(size + b.length);
            Segment[] segs = accessList(size, b.length);

            int off = 0;
            for (int i = 0; i < segs.length; i++) {
                Block block = blocks.get(segs[i].block);
                block.copyIn(b, off, segs[i].off, segs[i].len);
            }

            size += b.length;
        }

        public byte[] get(int pos, int len) {
            byte[] b = new byte[len];
            get(pos, len, b, 0);
            return b;
        }

        /**
         * Throws IndexOutOfBoundsException.
         */
        public void get(int pos, int len, byte[] b, int off) {
            Segment[] segs = accessList(pos, len);
            for (int i = 0; i < segs.length; i++) {
                Block block = blocks.get(segs[i].block);
                block.copyOut(segs[i].off, b, off, segs[i].len);
            }
        }

        /**
         * Truncate the buffer to <code>newSize</code> by removing
         * data from the start of the buffer.
         */
        public void truncateFromStart(int newSize) {
            if (newSize > size || newSize < 0)
                throw new RuntimeException("invalid size");

            Segment newStart = new Segment(size - newSize);
            blocks.removeRange(0, newStart.block);

            size = newSize;
            offset = newStart.off;
        }
    }
}
