class Slide
  attr_gtk

  # Distance between slides in shared world space. Columns (main slides) march
  # right; rows (drill-down detail) march down. Slides are 1280x720, so these
  # leave a 640px horizontal and a 280px vertical gutter.
  PITCH_X = 1920
  PITCH_Y = 1000

  WHITE = { r: 255, g: 255, b: 255 }.freeze
  MUTED = { r: 160, g: 165, b: 175 }.freeze
  ACCENT = { r: 236, g: 72, b: 72 }.freeze
  BACKGROUND = [18, 20, 26].freeze

  ATTRIBUTION_TONES = {
    light: { r: 215, g: 215, b: 215 },
    dark: { r: 30, g: 30, b: 30 }
  }.freeze

  def initialize(args, game, col, row)
    @args = args
    @game = game
    @col = col
    @row = row
    initialize_core
    outputs[target].set(w: 1280, h: 720, background_color: BACKGROUND)
  end

  def initialize_core; end

  attr_reader :col, :row

  # Clickable link regions in slide-local coordinates: [{ x:, y:, w:, h:, url: }].
  # Rebuilt each render by slides that draw links (see #attribution_primitives).
  def link_hotspots
    @link_hotspots ||= []
  end

  # Unique offscreen render target per slide, derived from the class name.
  def target
    self.class.name.to_sym
  end

  # Auto-placed on the grid: columns march right, detail rows march down.
  def rect
    Geometry.rect_props(x: @col * PITCH_X, y: -@row * PITCH_Y, w: 1280, h: 720)
  end

  def x
    rect.x
  end

  def y
    rect.y
  end

  def w
    rect.w
  end

  def h
    rect.h
  end

  def activate!
    @game.camera.target_scale = 1
  end

  def tick; end

  def primitives
    outputs[target].set(w: 1280, h: 720, background_color: BACKGROUND)
    outputs[target].primitives << slide_primitives
    outputs[target].primitives << drill_chevron if can_drill_down?
    { **rect, path: target }
  end

  # True when this slide has detail rows below it in its column.
  def can_drill_down?
    @game && Deck.drill_down?(@game.shape, @col, @row)
  end

  # A light-grey ↓ chevron centred along the bottom edge, hinting at ↓ detail.
  def drill_chevron
    cx = 640
    apex_y = 26
    arm_y = 48
    half = 24
    color = { r: 175, g: 180, b: 190 }
    (0..2).map do |i|
      [
        { x: cx - half, y: arm_y + i, x2: cx, y2: apex_y + i, **color },
        { x: cx, y: apex_y + i, x2: cx + half, y2: arm_y + i, **color }
      ]
    end.flatten
  end

  def slide_primitives
    [{ x: 640, y: 360, text: "Override :slide_primitives in #{self.class}", anchor_x: 0.5, anchor_y: 0.5, **WHITE }]
  end

  # Runtime pixel-width measurer for a given font size.
  def measure_at(size_px)
    ->(str) { $gtk.calcstringbox(str, size_px: size_px)[0] }
  end

  def heading(title)
    { x: 80, y: 655, text: title, size_px: 54, **WHITE }
  end

  def wrapped_lines(prims, text, x:, y:, size_px:, color:, max_width:, hang: 0, line_height: nil)
    step = line_height || size_px + 14
    Text.wrap(text, max_width, measure_at(size_px)).each_with_index do |line, i|
      prims << { x: x + (i.zero? ? 0 : hang), y: y, text: line, size_px: size_px, **color }
      y -= step
    end
    y
  end

  # Renders an optional lead, wrapped bullets (each a String or { text:, sub: }
  # Hash) and an optional closing aside into a column at x/max_width. Returns the
  # resulting y so callers can continue below it.
  def bullet_block(prims, bullets:, x:, y:, max_width:, size_px:, lead: nil, note: nil)
    y = wrapped_lines(prims, lead, x: x, y: y, size_px: size_px, color: MUTED, max_width: max_width) - 10 if lead

    bullets.each do |bullet|
      text = bullet.is_a?(Hash) ? bullet[:text] : bullet
      subs = bullet.is_a?(Hash) ? (bullet[:sub] || []) : []

      y = wrapped_lines(prims, "• #{text}", x: x, y: y, size_px: size_px, color: WHITE, max_width: max_width, hang: 36)
      subs.each do |sub|
        y = wrapped_lines(prims, "– #{sub}", x: x + 60, y: y, size_px: size_px - 4, color: MUTED, max_width: max_width - 60, hang: 32)
      end
      y -= 10
    end

    y = wrapped_lines(prims, note, x: x, y: y - 6, size_px: 28, color: ACCENT, max_width: max_width) if note
    y
  end

  # A heading, an optional lead paragraph, wrapped bullets (each a String or a
  # { text:, sub: [...] } Hash), and an optional closing aside.
  def bullet_list_primitives(title:, bullets:, lead: nil, note: nil, size_px: 34)
    prims = [heading(title)]
    bullet_block(prims, bullets: bullets, x: 80, y: 560, max_width: 1120, size_px: size_px, lead: lead, note: note)
    prims
  end

  # A heading, optional lead, a dark code panel with lightly-coloured YAML, and
  # an optional closing aside.
  def code_panel_primitives(title:, code_lines:, lead: nil, note: nil, size_px: 28, language: :yaml)
    prims = [heading(title)]
    y = 560

    y = wrapped_lines(prims, lead, x: 80, y: y, size_px: 32, color: MUTED, max_width: 1120, line_height: 42) - 40 if lead

    line_height = size_px + 12
    space_w = measure_at(size_px).call(' ')
    text_h = $gtk.calcstringbox('Xg', size_px: size_px)[1]

    first_y = y
    last_y = first_y - (code_lines.length - 1) * line_height
    panel_top = first_y + 18
    panel_bottom = last_y - text_h - 12
    prims << { x: 64, y: panel_bottom, w: 1152, h: panel_top - panel_bottom, path: :solid, r: 12, g: 14, b: 20 }

    code_lines.each do |raw|
      parsed = language == :ruby ? Code.ruby_line(raw) : Code.yaml_line(raw)
      x = 96 + parsed[:indent] * space_w
      parsed[:segments].each do |seg|
        prims << { x: x, y: y, text: seg[:text], size_px: size_px, **Code.color_for(seg[:role]) }
        x += measure_at(size_px).call(seg[:text])
      end
      y -= line_height
    end

    wrapped_lines(prims, note, x: 80, y: y - 24, size_px: 26, color: MUTED, max_width: 1120) if note

    prims
  end

  # A heading, an image letterbox-fitted on one side (with corner attribution),
  # and a bullet block on the other. `natural_wh` is the image's pixel size so
  # arbitrary photos fit without distortion. `frame_w` sets the image column's
  # width, so a narrow (e.g. portrait) image can leave the text more room.
  # `attribution` is { tone:, segments: [{ text:, url: }, ...] }.
  def image_bullets_primitives(title:, bullets:, image:, natural_wh:, image_side: :right,
                               frame_w: 540, attribution: nil, lead: nil, note: nil, size_px: 32)
    prims = [heading(title)]
    @link_hotspots = []

    margin = 80
    gap = 40
    frame_x = image_side == :left ? margin : 1280 - margin - frame_w
    frame = { x: frame_x, y: 60, w: frame_w, h: 470 }
    img = ImageFrame.fit(natural_wh[0], natural_wh[1], frame)

    prims << { x: img[:x] - 4, y: img[:y] - 4, w: img[:w] + 8, h: img[:h] + 8, path: :solid, r: 60, g: 64, b: 72 }
    prims << { x: img[:x], y: img[:y], w: img[:w], h: img[:h], path: image }
    prims.concat(attribution_primitives(img, attribution)) if attribution

    text_x = image_side == :left ? frame_x + frame_w + gap : margin
    text_w = image_side == :left ? 1280 - margin - text_x : frame_x - gap - text_x
    bullet_block(prims, bullets: bullets, x: text_x, y: 540, max_width: text_w, size_px: size_px, lead: lead, note: note)

    prims
  end

  # Lays out the attribution inline, right-aligned to the image's lower-right
  # corner. Segments with a :url get an underline and register a click hotspot
  # (in slide-local coordinates) so Game can openurl on click.
  def attribution_primitives(img, attribution)
    color = ATTRIBUTION_TONES[attribution[:tone] || :light]
    size_px = 18
    measure = measure_at(size_px)
    text_h = $gtk.calcstringbox('Xg', size_px: size_px)[1]
    segments = attribution[:segments]

    total = segments.sum { |seg| measure.call(seg[:text]) }
    x = img[:x] + img[:w] - 10 - total
    y = img[:y] + 10 + text_h

    prims = []
    segments.each do |seg|
      seg_w = measure.call(seg[:text])
      prims << { x: x, y: y, text: seg[:text], size_px: size_px, **color }
      if seg[:url]
        prims << { x: x, y: y - text_h, w: seg_w, h: 2, path: :solid, **color }
        link_hotspots << { x: x - 2, y: y - text_h - 4, w: seg_w + 4, h: text_h + 8, url: seg[:url] }
      end
      x += seg_w
    end
    prims
  end

  # A big centred title with subtitle, for the opening and closing slides.
  def centered_primitives(title:, subtitle:, accent:)
    [
      { x: 640, y: 430, text: title, size_px: 88, anchor_x: 0.5, anchor_y: 0.5, **WHITE },
      { x: 640, y: 320, text: accent, size_px: 128, anchor_x: 0.5, anchor_y: 0.5, **ACCENT },
      { x: 640, y: 190, text: subtitle, size_px: 40, anchor_x: 0.5, anchor_y: 0.5, **MUTED }
    ]
  end
end
