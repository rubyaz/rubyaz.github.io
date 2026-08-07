module Text
  # Greedy word-wrap. `measure` is a ->(str) { pixel_width } lambda so this stays
  # pure and testable — the runtime injects one backed by $gtk.calcstringbox.
  # A single word wider than max_width is left on its own line (no char splitting).
  def self.wrap(text, max_width, measure)
    lines = []
    current = ''

    text.split(' ').each do |word|
      candidate = current.empty? ? word : "#{current} #{word}"
      if current.empty? || measure.call(candidate) <= max_width
        current = candidate
      else
        lines << current
        current = word
      end
    end

    lines << current unless current.empty?
    lines
  end
end
