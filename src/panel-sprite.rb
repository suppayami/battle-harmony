# Use for movement, cast range, ... panels on battle field

#==============================================================================
# ■ Cache
#==============================================================================

module Cache
  
  #--------------------------------------------------------------------------
  # panel_bitmap
  #--------------------------------------------------------------------------
  def self.panel_bitmap(symbol)
    @panel_bitmaps ||= {}
    panel_include?(symbol) ? @panel_bitmaps[symbol] : create_panel(symbol)
  end
  
  #--------------------------------------------------------------------------
  # panel_include?
  #--------------------------------------------------------------------------
  def self.panel_include?(symbol)
    @panel_bitmaps[symbol] && !@panel_bitmaps[symbol].disposed?
  end
  
  #--------------------------------------------------------------------------
  # create_panel
  #--------------------------------------------------------------------------
  def self.create_panel(symbol)
    hash = HARMONY::VISUAL::PANEL_COLORS
    color = hash[symbol] ? hash[symbol] : hash[:other]
    #---
    bitmap = Bitmap.new(32, 32)
    rect = bitmap.rect.dup
    #---
    if HARMONY::VISUAL::PANEL_OUTLINE
      rect.width -= 2
      rect.height -= 2
      rect.x += 1
      rect.y += 1
      bitmap.fill_rect(rect, Color.new(0, 0, 0, color[3]))
    end
    #---
    rect.width -= 2
    rect.height -= 2
    rect.x += 1
    rect.y += 1
    #---
    bitmap.fill_rect(rect, Color.new(color[0], color[1], color[2], color[3]))
    @panel_bitmaps[symbol] = bitmap
    @panel_bitmaps[symbol]
  end
  
end # Cache

#==============================================================================
# ■ Sprite_Panel
#==============================================================================

class Sprite_Panel < Sprite
    
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :active

  #--------------------------------------------------------------------------
  # * Class Variable
  #--------------------------------------------------------------------------
  @@ani_frame = 0
  
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  def initialize(viewport)
    super(viewport)
    self.visible = false
    #---
    @map_x = @real_x = 0
    @map_y = @real_y = 0
    #---
    @symbol = nil
    #---
    @active = false
    @handler = {}
  end
  
  #--------------------------------------------------------------------------
  # show
  #--------------------------------------------------------------------------
  def show(symbol)
    self.visible = true
    self.bitmap = Cache.panel_bitmap(symbol)
    #---
    self.ox = self.width / 2
    self.oy = self.height
    #---
    @symbol = symbol
  end
  
  #--------------------------------------------------------------------------
  # hide
  #--------------------------------------------------------------------------
  def hide
    self.visible = false
    self.bitmap.dispose if self.bitmap && !self.bitmap.disposed?
    self.bitmap = nil
    #---
    @symbol = nil
  end
  
  #--------------------------------------------------------------------------
  # activate
  #--------------------------------------------------------------------------
  def activate
    @active = true
    self
  end
  
  #--------------------------------------------------------------------------
  # deactivate
  #--------------------------------------------------------------------------
  def deactivate
    @active = false
    self
  end
  
  #--------------------------------------------------------------------------
  # screen_x
  #--------------------------------------------------------------------------
  def screen_x
    $game_map.adjust_x(@real_x) * 32 + 16
  end

  #--------------------------------------------------------------------------
  # screen_y
  #--------------------------------------------------------------------------
  def screen_y
    $game_map.adjust_y(@real_y) * 32 + 32
  end
  
  #--------------------------------------------------------------------------
  # screen_z
  #--------------------------------------------------------------------------
  def screen_z
    @symbol == :cursor ? 95 : 90
  end
  
  #--------------------------------------------------------------------------
  # center_x
  #--------------------------------------------------------------------------
  def center_x
    (Graphics.width / 32 - 1) / 2.0
  end

  #--------------------------------------------------------------------------
  # center_y
  #--------------------------------------------------------------------------
  def center_y
    (Graphics.height / 32 - 1) / 2.0
  end
  
  #--------------------------------------------------------------------------
  # position
  #--------------------------------------------------------------------------
  def position
    [@map_x, @map_y]
  end
  
  #--------------------------------------------------------------------------
  # distance_per_frame
  #--------------------------------------------------------------------------
  def distance_per_frame
    0.25
  end
  
  #--------------------------------------------------------------------------
  # moveto
  #--------------------------------------------------------------------------
  def moveto(x, y)
    @map_x = @real_x = x
    @map_y = @real_y = y
    update
  end
  
  #--------------------------------------------------------------------------
  # moveto
  #--------------------------------------------------------------------------
  def moveto_smooth(x, y)
    @map_x = x
    @map_y = y
    update
  end
  
  #--------------------------------------------------------------------------
  # self.animate
  #--------------------------------------------------------------------------
  def self.animate
    @@ani_frame = (@@ani_frame + 1) % 48
  end
  
  #--------------------------------------------------------------------------
  # move_cursor
  #--------------------------------------------------------------------------
  def move_cursor(d)
    temp_x = $game_map.round_x_with_direction(@map_x, d)
    temp_y = $game_map.round_y_with_direction(@map_y, d)
    return unless $game_map.valid?(temp_x, temp_y)
    @map_x = temp_x
    @map_y = temp_y
  end
  
  #--------------------------------------------------------------------------
  # update
  #--------------------------------------------------------------------------
  def update
    super
    return unless bitmap
    update_animation
    update_position
    update_center
    update_input
    update_handling
    update_move
  end
  
  #--------------------------------------------------------------------------
  # update_animation
  #--------------------------------------------------------------------------
  def update_animation
    self.opacity = 255 - (24 - @@ani_frame).abs * 2
  end
  
  #--------------------------------------------------------------------------
  # update_position
  #--------------------------------------------------------------------------
  def update_position
    self.x = screen_x
    self.y = screen_y
    self.z = screen_z
  end
  
  #--------------------------------------------------------------------------
  # update_center
  #--------------------------------------------------------------------------
  def update_center
    return unless self.visible
    return unless @symbol == :cursor
    $game_map.set_display_pos(@real_x - center_x, @real_y - center_y)
  end
  
  #--------------------------------------------------------------------------
  # update_input
  #--------------------------------------------------------------------------
  def update_input
    return unless @symbol == :cursor
    return unless @active
    move_cursor(2) if Input.repeat?(:DOWN)
    move_cursor(4) if Input.repeat?(:LEFT)
    move_cursor(6) if Input.repeat?(:RIGHT)
    move_cursor(8) if Input.repeat?(:UP)
  end
  
  #--------------------------------------------------------------------------
  # update_handling
  #--------------------------------------------------------------------------
  def update_handling
    return unless @symbol == :cursor
    return unless @active
    return process_ok     if ok_enabled?     && Input.trigger?(:C)
    return process_cancel if cancel_enabled? && Input.trigger?(:B)
  end
  
  #--------------------------------------------------------------------------
  # update_move
  #--------------------------------------------------------------------------
  def update_move
    return unless @symbol == :cursor
    @real_x = [@real_x - distance_per_frame, @map_x].max if @real_x > @map_x
    @real_x = [@real_x + distance_per_frame, @map_x].min if @real_x < @map_x
    @real_y = [@real_y - distance_per_frame, @map_y].max if @real_y > @map_y
    @real_y = [@real_y + distance_per_frame, @map_y].min if @real_y < @map_y
  end
  
  #--------------------------------------------------------------------------
  # is_moving?
  #--------------------------------------------------------------------------
  def is_moving?
    return false unless @symbol == :cursor
    @real_x != @map_x || @real_y != @map_y
  end
  
  #--------------------------------------------------------------------------
  # process_ok
  #--------------------------------------------------------------------------
  def process_ok
    Sound.play_ok
    Input.update
    deactivate
    call_ok_handler
  end

  #--------------------------------------------------------------------------
  # call_ok_handler
  #--------------------------------------------------------------------------
  def call_ok_handler
    call_handler(:ok)
  end

  #--------------------------------------------------------------------------
  # process_cancel
  #--------------------------------------------------------------------------
  def process_cancel
    Sound.play_cancel
    Input.update
    deactivate
    call_cancel_handler
  end

  #--------------------------------------------------------------------------
  # call_cancel_handler
  #--------------------------------------------------------------------------
  def call_cancel_handler
    call_handler(:cancel)
  end
  
  #--------------------------------------------------------------------------
  # set_handler
  #--------------------------------------------------------------------------
  def set_handler(symbol, method)
    @handler[symbol] = method
  end
  
  #--------------------------------------------------------------------------
  # handle?
  #--------------------------------------------------------------------------
  def handle?(symbol)
    @handler.include?(symbol)
  end
  
  #--------------------------------------------------------------------------
  # ok_enabled?
  #--------------------------------------------------------------------------
  def ok_enabled?
    handle?(:ok)
  end

  #--------------------------------------------------------------------------
  # cancel_enabled?
  #--------------------------------------------------------------------------
  def cancel_enabled?
    handle?(:cancel)
  end
    
  #--------------------------------------------------------------------------
  # call_handler
  #--------------------------------------------------------------------------
  def call_handler(symbol)
    @handler[symbol].call if handle?(symbol)
  end
  
end # Sprite_Panel