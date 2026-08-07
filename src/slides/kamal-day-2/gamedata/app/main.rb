require 'app/text.rb'
require 'app/code.rb'
require 'app/image_frame.rb'
require 'app/deck.rb'
require 'app/slide.rb'
require 'app/slides.rb'

class Game
  attr_gtk

  attr_reader :camera, :col, :row

  # On-screen width of a slide at the :mid zoom level.
  MIN_SLIDE_PX = 200

  # Each entry is a column: a single slide class, or an array whose first slide
  # is the main slide and the rest are drill-down detail (reached with ↓).
  DECK = [
    TitleSlide,
    WhoAmISlide,
    Day0ProfitSlide,
    Day2ProblemSlide,
    BeyondBasicsSlide,
    ObservabilityGoalSlide,
    [ContainerNameProblemSlide,
     ServiceDiscoverySlide,
     PrometheusDiscoveryConfigSlide,
     DockerSocketAccessSlide,
     TargetsDebuggingSlide],
    [SidekiqMetricsSlide,
     WebrickToPumaSlide,
     MetricsServerCodeSlide],
    [AlertingAsCodeSlide,
     AlertRuleAnatomySlide,
     AlertQueriesDetailSlide],
    AlertDeliverySlide,
    [WatchmenSlide,
     WatchmenAspirationSlide],
    [ParanoiaSlide,
     ThreatModelSlide,
     SecretlessRunnerSlide,
     SandboxBoundarySlide,
     EgressLockdownSlide],
    WireGuardSlide,
    WireGuardBackstopSlide,
    [UnattendedSecuritySlide, RebootWiringDetailSlide],
    BackupsSlide,
    ProvisioningSlide,
    SecretsSlide,
    [MaintenanceCalendarSlide, EventQueueSlide],
    StillToLearnSlide,
    DemoSlide,
    QRCodeSlide,
    QASlide
  ].freeze

  def initialize(args, camera: nil, col: nil, row: nil)
    @args = args
    @col = col || 0
    @row = row || 0
    @zoom = :slide
    @camera = camera || { x: 640, y: 360, scale: 1, target_x: 640, target_y: 360, target_scale: 1 }

    @columns = DECK.each_with_index.map do |entry, c|
      classes = entry.is_a?(Array) ? entry : [entry]
      classes.each_with_index.map { |klass, r| klass.new(args, self, c, r) }
    end
    @slides = @columns.flatten

    goto_position!(@col, @row, recenter: false)
  end

  def shape
    @columns.map(&:length)
  end

  def goto_position!(col, row, recenter: true)
    @col = col
    @row = row
    center_on_current! if recenter
    current_slide.activate!
  end

  def center_on_current!
    r = current_slide.rect
    @camera.target_x = r.x + r.w.fdiv(2)
    @camera.target_y = r.y + r.h.fdiv(2)
  end

  # Moves the selection. At :slide the camera pans to the new slide; at :mid it
  # pans to keep the selection centred; at :full the framing holds and only the
  # highlight moves.
  def move!(dir)
    col, row = Deck.move(shape, @col, @row, dir)
    if @zoom == :slide
      goto_position!(col, row)
    else
      @col = col
      @row = row
      center_on_current! if @zoom == :mid
    end
  end

  def current_slide
    @columns[@col][@row]
  end

  def overview?
    @zoom != :slide
  end

  # `z` steps one level out along the zoom ladder (slide → mid → full).
  def zoom_out!
    @zoom = Deck.zoom_out(@zoom)
    case @zoom
    when :mid
      @camera.target_scale = Deck.slide_scale(MIN_SLIDE_PX, 1280)
      center_on_current!
    when :full
      frame_deck!
    end
  end

  def frame_deck!
    ov = Deck.overview(shape, Camera.viewport_w, Camera.viewport_h, Slide::PITCH_X, Slide::PITCH_Y)
    @camera.target_x = ov[:x]
    @camera.target_y = ov[:y]
    @camera.target_scale = ov[:scale]
  end

  def zoom_to_current!
    @zoom = :slide
    goto_position!(@col, @row, recenter: true)
  end

  # In overview, a click jumps to whichever slide the cursor is over.
  def select_slide_at_mouse
    world = Camera.to_world_space(@camera, { x: inputs.mouse.x, y: inputs.mouse.y })
    slide = @slides.find { |s| Deck.contains?(s.rect, world.x, world.y) }
    return unless slide

    @col = slide.col
    @row = slide.row
    zoom_to_current!
  end

  # Maps the mouse into the current slide's local space and opens the URL of any
  # attribution link it lands on.
  def open_link_at_mouse
    slide = current_slide
    return if slide.link_hotspots.empty?

    world = Camera.to_world_space(@camera, { x: inputs.mouse.x, y: inputs.mouse.y })
    lx = world.x - slide.rect.x
    ly = world.y - slide.rect.y

    hit = slide.link_hotspots.find do |box|
      lx >= box[:x] && lx <= box[:x] + box[:w] && ly >= box[:y] && ly <= box[:y] + box[:h]
    end
    $gtk.openurl(hit[:url]) if hit
  end

  def calc_camera
    ease = 0.1
    @camera.scale = @camera.scale.lerp(@camera.target_scale, ease)
    @camera.x = @camera.x.lerp(@camera.target_x, ease, tolerance: 1)
    @camera.y = @camera.y.lerp(@camera.target_y, ease, tolerance: 1)
  end

  def calc
    GTK.request_quit if inputs.keyboard.key_down.q

    if inputs.keyboard.key_down.f
      $fullscreen = !$fullscreen
      GTK.set_window_fullscreen($fullscreen)
    end

    zoom_out! if inputs.keyboard.key_down.z

    if inputs.keyboard.key_down.right || inputs.controller_one.key_down.r1
      move!(:right)
    elsif inputs.keyboard.key_down.left || inputs.controller_one.key_down.l1
      move!(:left)
    elsif inputs.keyboard.key_down.down || inputs.controller_one.key_down.b
      move!(:down)
    elsif inputs.keyboard.key_down.up || inputs.controller_one.key_down.a
      move!(:up)
    end

    zoom_to_current! if inputs.keyboard.key_down.escape
    zoom_to_current! if overview? && (inputs.keyboard.key_down.enter || inputs.controller_one.key_down.start)

    zoom_to_current! if inputs.keyboard.key_down.zero

    if inputs.mouse.wheel
      @camera.target_scale /= 1.1 if inputs.mouse.wheel.y > 0
      @camera.target_scale *= 1.1 if inputs.mouse.wheel.y < 0
    end

    if inputs.mouse.buttons.left.buffered_held && inputs.mouse.moved
      @camera.target_x -= (inputs.mouse.x - inputs.mouse.previous_x) / @camera.scale
      @camera.target_y -= (inputs.mouse.y - inputs.mouse.previous_y) / @camera.scale
    end

    if inputs.mouse.click
      overview? ? select_slide_at_mouse : open_link_at_mouse
    end

    calc_camera
    visible_slides.each do |slide|
      slide.args = args
      slide.tick
    end
  end

  def render
    outputs.background_color = Slide::BACKGROUND
    outputs[:scene].w = Camera.viewport_w
    outputs[:scene].h = Camera.viewport_h
    outputs[:scene].background_color = Slide::BACKGROUND
    outputs[:scene].primitives << visible_slides.map { |slide| Camera.to_screen_space(@camera, slide.primitives) }
    outputs[:scene].primitives << overview_highlight if overview?
    outputs.primitives << { **Camera.viewport, path: :scene }
  end

  # A gold frame around the current slide, so it's findable while zoomed out.
  def overview_highlight
    r = current_slide.rect
    t = 12
    color = { r: 245, g: 200, b: 60, path: :solid }
    Camera.to_screen_space(@camera, [
                             { x: r.x - t, y: r.y + r.h, w: r.w + 2 * t, h: t, **color },
                             { x: r.x - t, y: r.y - t, w: r.w + 2 * t, h: t, **color },
                             { x: r.x - t, y: r.y - t, w: t, h: r.h + 2 * t, **color },
                             { x: r.x + r.w, y: r.y - t, w: t, h: r.h + 2 * t, **color }
                           ])
  end

  def tick
    calc
    render
  end

  def visible_slides
    Camera.find_all_intersect_viewport(@camera, @slides)
  end
end

def boot(args)
  args.state = {}
  # $fullscreen = !$gtk.argv.include?('--test')
  # GTK.set_window_fullscreen($fullscreen)
end

def tick(args)
  $game ||= Game.new(args, camera: $camera, col: $deck_col, row: $deck_row)
  $game.args = args
  $game.tick
end

def reset(_args)
  $camera = $game&.camera
  $deck_col = $game&.col
  $deck_row = $game&.row
  $game = nil
end

class Camera
  class << self
    def viewport_w
      Grid.allscreen_w
    end

    def viewport_h
      Grid.allscreen_h
    end

    def viewport_w_half
      Grid.origin_center? ? 0 : Grid.allscreen_w.fdiv(2).ceil
    end

    def viewport_h_half
      Grid.origin_center? ? 0 : Grid.allscreen_h.fdiv(2).ceil
    end

    def viewport_offset_x
      Grid.origin_center? ? 0 : Grid.allscreen_x
    end

    def viewport_offset_y
      Grid.origin_center? ? 0 : Grid.allscreen_y
    end

    def __to_screen_space__(camera, rect)
      return nil unless rect

      x = rect.x * camera.scale - camera.x * camera.scale + viewport_w_half
      y = rect.y * camera.scale - camera.y * camera.scale + viewport_h_half

      if rect.w
        { **rect, x: x, y: y, w: rect.w * camera.scale, h: rect.h * camera.scale }
      else
        { **rect, x: x, y: y }
      end
    end

    def to_screen_space(camera, rect)
      return unless rect

      if rect.is_a?(Array)
        rect.map { |r| to_screen_space(camera, r) }
      else
        __to_screen_space__(camera, rect)
      end
    end

    def __to_world_space__(camera, rect)
      return nil unless rect

      x = (rect.x - viewport_w_half + camera.x * camera.scale - viewport_offset_x) / camera.scale
      y = (rect.y - viewport_h_half + camera.y * camera.scale - viewport_offset_y) / camera.scale

      if rect.w
        { **rect, x: x, y: y, w: rect.w / camera.scale, h: rect.h / camera.scale }
      else
        { **rect, x: x, y: y }
      end
    end

    def to_world_space(camera, rect)
      if rect.is_a?(Array)
        rect.map { |r| to_world_space(camera, r) }
      else
        __to_world_space__(camera, rect)
      end
    end

    def viewport
      base = { x: viewport_offset_x, y: viewport_offset_y, w: viewport_w, h: viewport_h }
      Grid.origin_center? ? base.merge(anchor_x: 0.5, anchor_y: 0.5) : base
    end

    def viewport_world(camera)
      to_world_space(camera, viewport)
    end

    def find_all_intersect_viewport(camera, slides)
      Geometry.find_all_intersect_rect(viewport_world(camera), slides)
    end
  end
end
