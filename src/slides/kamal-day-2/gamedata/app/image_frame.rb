module ImageFrame
  # Letterbox-fit a natural-size image inside a frame, preserving aspect ratio
  # and centring it. Returns { x:, y:, w:, h: } in the frame's coordinate space.
  def self.fit(natural_w, natural_h, frame)
    scale = [frame[:w].fdiv(natural_w), frame[:h].fdiv(natural_h)].min
    w = natural_w * scale
    h = natural_h * scale
    {
      x: frame[:x] + (frame[:w] - w) / 2,
      y: frame[:y] + (frame[:h] - h) / 2,
      w: w,
      h: h
    }
  end
end
