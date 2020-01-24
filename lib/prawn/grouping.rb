require "prawn"
require "prawn/grouping/version"

module Prawn
  module Grouping

    # Groups a given block vertiacally within the current context, if possible.
    #
    # Parameters are:
    #
    # <tt>options</tt>:: A hash for grouping options.
    #     <tt>:too_tall</tt>:: A proc called before the content is rendered and
    #                          does not fit a single context.
    #     <tt>:fits_new_context</tt>:: A proc called before the content is
    #                                  rendered and does fit a single context.
    #     <tt>:fits_current_context</tt>:: A proc called before the content is
    #                                      rendered and does fit context.
    #
    def group(options = {})
      too_tall             = options[:too_tall]
      fits_new_context     = options[:fits_new_context]
      fits_current_context = options[:fits_current_context]

      # create a temporary document with current context and offset
      pdf = create_box_clone
      pdf.y = y
      yield pdf

      if pdf.page_count > 1
        # create a temporary document without offset
        pdf = create_box_clone
        yield pdf

        if pdf.page_count > 1
          # does not fit new context
          too_tall.call if too_tall
          yield self
        else
          fits_new_context.call if fits_new_context
          bounds.move_past_bottom
          yield self
        end
        return false
      else
        # just render it
        fits_current_context.call if fits_current_context
        yield self
        return true
      end
    end

    private

    def create_box_clone
      # the box clone will have the same height and vertical margins
      # as the original, but no left and right margins, and its width
      # is set to the current bounding box's width. This should ensure
      # accurate widths also when the bounding box is a ColumnBox
      opts = {
        top_margin:    state.page.margins[:top],
        bottom_margin: state.page.margins[:bottom],
        left_margin:   0,
        right_margin:  0,
        page_size: [@bounding_box.width, state.page.dimensions[-1]],
        page_layout: state.page.layout
      }
      Prawn::Document.new(opts) do |pdf|
        pdf.text_formatter = @text_formatter.dup
        pdf.font_families.update font_families
        pdf.font font.family
        pdf.font_size font_size
        pdf.default_leading = default_leading
      end
    end
  end
end

Prawn::Document.extensions << Prawn::Grouping
