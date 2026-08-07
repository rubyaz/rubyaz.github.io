module Code
  KEY = { r: 130, g: 200, b: 255 }.freeze
  VALUE = { r: 175, g: 220, b: 150 }.freeze
  PLAIN = { r: 225, g: 225, b: 225 }.freeze
  KEYWORD = { r: 205, g: 160, b: 245 }.freeze

  KEYWORDS = %w[require class module def end self return yield if elsif else unless
                do begin rescue ensure nil true false].freeze

  # Splits a single YAML line into its leading indent and coloured segments.
  # No regex (mruby has none) — a key is everything up to and including the
  # first colon, the value is whatever follows. Returns
  #   { indent: <spaces>, segments: [{ text:, role: }, ...] }
  # with role in :key, :value, :plain.
  def self.yaml_line(line)
    indent = line.length - line.lstrip.length
    stripped = line.strip
    colon = stripped.index(':')

    segments =
      if colon
        key = stripped[0, colon + 1]
        value = stripped[colon + 1, stripped.length]
        parts = [{ text: key, role: :key }]
        parts << { text: value, role: :value } unless value.strip.empty?
        parts
      else
        [{ text: stripped, role: :plain }]
      end

    { indent: indent, segments: segments }
  end

  # Splits a Ruby line into its indent and space-separated word segments,
  # colouring leading keywords. No regex: we tokenise on spaces (re-attaching a
  # trailing space to every word but the last, so the line renders unchanged)
  # and tint any token that is a bare keyword. Returns the same shape as
  # #yaml_line, with role in :keyword, :plain.
  def self.ruby_line(line)
    indent = line.length - line.lstrip.length
    words = line.lstrip.split(' ')
    return { indent: indent, segments: [{ text: '', role: :plain }] } if words.empty?

    last = words.length - 1
    segments = words.each_with_index.map do |word, i|
      text = i == last ? word : "#{word} "
      { text: text, role: KEYWORDS.include?(word) ? :keyword : :plain }
    end
    { indent: indent, segments: segments }
  end

  def self.color_for(role)
    case role
    when :key then KEY
    when :value then VALUE
    when :keyword then KEYWORD
    else PLAIN
    end
  end
end
