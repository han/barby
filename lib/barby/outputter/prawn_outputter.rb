require 'barby/outputter'
require 'prawn'

module Barby

  class PrawnOutputter < Outputter

    register :to_pdf, :annotate_pdf

    attr_accessor :xdim, :ydim, :x, :y, :height, :margin, :unbleed, :guard_bar_size, :print_code


    def to_pdf(opts={})
      doc_opts = opts.delete(:document) || {}
      doc_opts[:page_size] ||= 'A4'
      annotate_pdf(Prawn::Document.new(doc_opts), opts).render
    end


    def annotate_pdf(pdf, opts={})
      with_options opts do
        xpos, ypos = x, y
        orig_xpos = xpos

        if barcode.two_dimensional?
          boolean_groups.reverse_each do |groups|
            groups.each do |bar,amount|
              if bar
                pdf.move_to(xpos+unbleed, ypos+unbleed)
                pdf.line_to(xpos+unbleed, ypos+ydim-unbleed)
                pdf.line_to(xpos+(xdim*amount)-unbleed, ypos+ydim-unbleed)
                pdf.line_to(xpos+(xdim*amount)-unbleed, ypos+unbleed)
                pdf.line_to(xpos+unbleed, ypos+unbleed)
                pdf.fill
              end
              xpos += (xdim*amount)
            end
            xpos = orig_xpos
            ypos += ydim
          end
        else
          line = 0
          xpos += 5*xdim
          ypos += [0,text_size - guard_bar_size].max if print_code

          boolean_groups.each do |bar,amount|
            if bar
              drop = guard_bars.include?(line) ? 0 : guard_bar_drop
              pdf.move_to(xpos+unbleed, ypos+drop)
              pdf.line_to(xpos+unbleed, ypos+height)
              pdf.line_to(xpos+(xdim*amount)-unbleed, ypos+height)
              pdf.line_to(xpos+(xdim*amount)-unbleed, ypos+drop)
              pdf.line_to(xpos+unbleed, ypos+drop)
              pdf.fill
            end
            line += amount
            xpos += (xdim*amount)
          end
          if print_code
            0.upto(barcode.code.length) do |i|
              pdf.draw_text(barcode.code[i], :at => [text_x(i), 0], :size => text_size)
            end
          end
        end

      end

      pdf
    end

    def print_code
      @print_code || false
    end

    def text_size
      4 + 7*xdim
    end

    def length
      two_dimensional? ? encoding.first.length : encoding.length
    end

    def width
      length * xdim
    end

    def height
      two_dimensional? ? (ydim * encoding.length) : (@height || 50)
    end

    def full_width
      width + (margin * 2)
    end

    def full_height
      height + (margin * 2)
    end

    #Margin is used for x and y if not given explicitly, effectively placing the barcode
    #<margin> points from the [left,bottom] of the page.
    #If you define x and y, there will be no margin. And if you don't define margin, it's 0.
    def margin
      @margin || 0
    end

    def x
      @x || margin
    end

    def y
      @y || margin
    end

    def xdim
      @xdim || 1
    end

    def ydim
      @ydim || xdim
    end

    #Defines an amount to reduce black bars/squares by to account for "ink bleed"
    #If xdim = 3, unbleed = 0.2, a single/width black bar will be 2.6 wide
    #For 2D, both x and y dimensions are reduced.
    def unbleed
      @unbleed || 0
    end

    def guard_bar_size
      @guard_bar_size || 10
    end

    def guard_bar_drop
      return 0 if guard_bars == nil || guard_bars.length == 0
      [guard_bar_size, height / 2].min
    end

    def char_spacing
      @char_spacing ||= (encoding.length - guard_bars.length) / barcode.data.length
    end

    #ToDo: specific for EAN-13
    def text_x(pos)
      unless @text_pos
        @text_pos = []
        0.upto(13) do |i|
          @text_pos[i] = x + i * char_spacing * xdim + (i >= 7 ? 6 : (i >= 1 ? 2 : 0))*xdim
        end
      end
      @text_pos[pos]
    end


  private

    def page_size(xdim, height, margin)
      [width(xdim,margin), height(height,margin)]
    end


  end

end
