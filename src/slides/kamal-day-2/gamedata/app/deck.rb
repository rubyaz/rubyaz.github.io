module Deck
  # Given the length of each column, returns the [col, row] reached by moving
  # `dir` from (col, row). Horizontal moves land on the top (row 0) of the
  # adjacent column, reveal.js-style; vertical moves walk the current column's
  # detail stack. Every move clamps at the deck's edges.
  def self.move(column_lengths, col, row, dir)
    case dir
    when :right then col < column_lengths.length - 1 ? [col + 1, 0] : [col, row]
    when :left then col > 0 ? [col - 1, 0] : [col, row]
    when :down then row < column_lengths[col] - 1 ? [col, row + 1] : [col, row]
    when :up then row > 0 ? [col, row - 1] : [col, row]
    else [col, row]
    end
  end

  # Camera target (x, y, scale) that frames the whole 1280x720-per-slide grid
  # within the viewport, centred, with a little breathing room (margin < 1).
  def self.overview(column_lengths, viewport_w, viewport_h, pitch_x, pitch_y, margin: 0.9)
    max_row = column_lengths.max - 1
    deck_w = (column_lengths.length - 1) * pitch_x + 1280
    deck_h = max_row * pitch_y + 720
    {
      x: deck_w.fdiv(2),
      y: (720 - max_row * pitch_y).fdiv(2),
      scale: [viewport_w.fdiv(deck_w), viewport_h.fdiv(deck_h)].min * margin
    }
  end

  # True when (col, row) has a detail row beneath it — i.e. ↓ goes somewhere.
  def self.drill_down?(column_lengths, col, row)
    row < column_lengths[col] - 1
  end

  # True when the point (x, y) falls inside a rect (a hash with :x, :y, :w, :h).
  def self.contains?(rect, x, y)
    x >= rect[:x] && x <= rect[:x] + rect[:w] && y >= rect[:y] && y <= rect[:y] + rect[:h]
  end

  # The zoom ladder, from fully in to fully out. :slide fills the viewport with
  # the current slide; :mid pins slides to a fixed size and pans to follow the
  # selection; :full frames the whole deck.
  ZOOM_LEVELS = %i[slide mid full].freeze

  # From :slide, the first step out is :mid; thereafter `z` cycles the two
  # zoomed-out levels (:mid ↔ :full). `enter`/`esc` returns to :slide.
  def self.zoom_out(level)
    case level
    when :slide then :mid
    when :mid then :full
    else :mid
    end
  end

  # Camera scale that renders a slide_w-wide slide at min_px on screen.
  def self.slide_scale(min_px, slide_w)
    min_px.fdiv(slide_w)
  end
end
