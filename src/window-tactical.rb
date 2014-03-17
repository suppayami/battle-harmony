#==============================================================================
# ■ Window_PartyBattlers
#==============================================================================

class Window_PartyBattlers < Window_Selectable
  
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0, window_width, window_height)
    refresh
    self.openness = 0
    @last_id = 0
  end
  
  #--------------------------------------------------------------------------
  # window_width
  #--------------------------------------------------------------------------
  def window_width
    Graphics.width - 128
  end
  
  #--------------------------------------------------------------------------
  # window_height
  #--------------------------------------------------------------------------
  def window_height
    fitting_height(visible_line_number)
  end
  
  #--------------------------------------------------------------------------
  # item_height
  #--------------------------------------------------------------------------
  def item_height
    height - standard_padding * 2
  end
  
  #--------------------------------------------------------------------------
  # contents_width
  #--------------------------------------------------------------------------
  def contents_width
    (item_width + spacing) * item_max - spacing
  end
  
  #--------------------------------------------------------------------------
  # contents_height
  #--------------------------------------------------------------------------
  def contents_height
    item_height
  end
  
  #--------------------------------------------------------------------------
  # visible_line_number
  #--------------------------------------------------------------------------
  def visible_line_number
    return 4
  end
  
  #--------------------------------------------------------------------------
  # col_max
  #--------------------------------------------------------------------------
  def col_max
    return ((window_width - standard_padding * 2) / 96).to_i
  end
  
  #--------------------------------------------------------------------------
  # item_max
  #--------------------------------------------------------------------------
  def spacing
    return 2
  end
  
  #--------------------------------------------------------------------------
  # item_max
  #--------------------------------------------------------------------------
  def item_max
    members.size
  end
  
  #--------------------------------------------------------------------------
  # members
  #--------------------------------------------------------------------------
  def members
    $game_party.all_members
  end
  
  #--------------------------------------------------------------------------
  # actor
  #--------------------------------------------------------------------------
  def actor
    members[@index]
  end
  
  #--------------------------------------------------------------------------
  # in_battle?
  #--------------------------------------------------------------------------
  def in_battle?(actor)
    $game_map.actor_party.include?(actor)
  end
  
  #--------------------------------------------------------------------------
  # select_last
  #--------------------------------------------------------------------------
  def select_last
    select(@last_id)
  end
  
  #--------------------------------------------------------------------------
  # select_next
  #--------------------------------------------------------------------------
  def select_next
    select((@index + 1) % item_max)
  end
  
  #--------------------------------------------------------------------------
  # process_ok
  #--------------------------------------------------------------------------
  def process_ok
    super
    @last_id = @index
  end
  
  #--------------------------------------------------------------------------
  # draw_item
  #--------------------------------------------------------------------------
  def draw_item(index)
    return if index.nil?
    clear_item(index)
    actor = members[index]
    rect = item_rect(index)
    return if actor.nil?
    draw_actor_face(actor, rect.x+2, rect.y+2, actor.alive?)
    draw_actor_name(actor, rect.x, rect.y, rect.width-8)
    draw_placement(actor, rect.x, rect.y + line_height)
    draw_actor_hp(actor, rect.x+2, line_height*2, rect.width-4)
    draw_actor_mp(actor, rect.x+2, line_height*3, rect.width-4)
  end
  
  #--------------------------------------------------------------------------
  # draw_face
  #--------------------------------------------------------------------------
  def draw_face(face_name, face_index, dx, dy, enabled = true)
    bitmap = Cache.face(face_name)
    fx = [(96 - item_rect(0).width + 1) / 2, 0].max
    fy = face_index / 4 * 96 + 2
    fw = [item_rect(0).width - 4, 92].min
    rect = Rect.new(fx, fy, fw, 92)
    rect = Rect.new(face_index % 4 * 96 + fx, fy, fw, 92)
    contents.blt(dx, dy, bitmap, rect, enabled ? 255 : translucent_alpha)
    bitmap.dispose
  end
  
  #--------------------------------------------------------------------------
  # draw_face
  #--------------------------------------------------------------------------
  def draw_placement(actor, dx, dy)
    return unless in_battle?(actor)
    change_color(system_color)
    contents.font.size -= 4
    draw_text(dx, dy, item_width, line_height, Vocab.tbs_placed)
    reset_font_settings
  end
  
  #--------------------------------------------------------------------------
  # item_rect
  #--------------------------------------------------------------------------
  def item_rect(index)
    rect = super
    rect.x = index * (item_width + spacing)
    rect.y = 0
    rect
  end
  
  #--------------------------------------------------------------------------
  # top_col
  #--------------------------------------------------------------------------
  def top_col
    ox / (item_width + spacing)
  end
  
  #--------------------------------------------------------------------------
  # top_col=
  #--------------------------------------------------------------------------
  def top_col=(col)
    col = 0 if col < 0
    col = col_max - 1 if col > col_max - 1
    self.ox = col * (item_width + spacing)
  end
  
  #--------------------------------------------------------------------------
  # bottom_col
  #--------------------------------------------------------------------------
  def bottom_col
    top_col + col_max - 1
  end
  
  #--------------------------------------------------------------------------
  # bottom_col=
  #--------------------------------------------------------------------------
  def bottom_col=(col)
    self.top_col = col - (col_max - 1)
  end
  
  #--------------------------------------------------------------------------
  # ensure_cursor_visible
  #--------------------------------------------------------------------------
  def ensure_cursor_visible
    self.top_col = index if index < top_col
    self.bottom_col = index if index > bottom_col
  end
  
  #--------------------------------------------------------------------------
  # cursor_down
  #--------------------------------------------------------------------------
  def cursor_down(wrap = false)
  end
  
  #--------------------------------------------------------------------------
  # cursor_up
  #--------------------------------------------------------------------------
  def cursor_up(wrap = false)
  end
  
  #--------------------------------------------------------------------------
  # cursor_pagedown
  #--------------------------------------------------------------------------
  def cursor_pagedown
  end
  
  #--------------------------------------------------------------------------
  # cursor_pageup
  #--------------------------------------------------------------------------
  def cursor_pageup
  end

end # Window_PartyBattlers

#==============================================================================
# ■ Window_TacticalCommand
#==============================================================================

class Window_TacticalCommand < Window_Command
  
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0)
    self.openness = 0
    deactivate
  end
  
  #--------------------------------------------------------------------------
  # window_width
  #--------------------------------------------------------------------------
  def window_width
    return 128
  end
  
  #--------------------------------------------------------------------------
  # visible_line_number
  #--------------------------------------------------------------------------
  def visible_line_number
    4
  end
  
  #--------------------------------------------------------------------------
  # make_command_list
  #--------------------------------------------------------------------------
  def make_command_list
    add_command(Vocab.tbs_place, :place)
    add_command(Vocab.tbs_fight, :fight, enable_fight?)
  end
  
  #--------------------------------------------------------------------------
  # fight_index
  #--------------------------------------------------------------------------
  def fight_index
    1
  end
  
  #--------------------------------------------------------------------------
  # select_fight
  #--------------------------------------------------------------------------
  def select_fight
    select(fight_index)
  end
  
  #--------------------------------------------------------------------------
  # enable_fight?
  #--------------------------------------------------------------------------
  def enable_fight?
    $game_party.battle_members.size > 0
  end
  
  #--------------------------------------------------------------------------
  # activate
  #--------------------------------------------------------------------------
  def activate
    refresh
    super
  end
  
end # Window_TacticalCommand

#==============================================================================
# ■ Window_ActorCommandTBS
#==============================================================================

class Window_ActorCommandTBS < Window_ActorCommand
  
  #--------------------------------------------------------------------------
  # make_command_list
  #--------------------------------------------------------------------------
  def make_command_list
    return unless @actor
    add_move_command
    add_attack_command
#~     add_skill_commands
#~     add_item_command
#~     add_guard_command
    add_wait_command
  end
  
  #--------------------------------------------------------------------------
  # add_move_command
  #--------------------------------------------------------------------------
  def add_move_command
    add_command(Vocab.tbs_move, :move, movable?)
  end
    
  #--------------------------------------------------------------------------
  # add_attack_command
  #--------------------------------------------------------------------------
  def add_attack_command
    add_command(Vocab.tbs_attack, :attack, @actor.attack_usable? && actable?)
  end
  
  #--------------------------------------------------------------------------
  # add_wait_command
  #--------------------------------------------------------------------------
  def add_wait_command
    add_command(Vocab.tbs_wait, :wait)
  end
  
  #--------------------------------------------------------------------------
  # movable?
  #--------------------------------------------------------------------------
  def movable?
    !@actor.moved? && @actor.movable?
  end
  
  #--------------------------------------------------------------------------
  # actable?
  #--------------------------------------------------------------------------
  def actable?
    !@actor.acted? && @actor.movable?
  end
  
end # Window_ActorCommandTBS

#==============================================================================
# ■ Window_StatusTBS
#==============================================================================

class Window_StatusTBS < Window_Selectable
  
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0, window_width, window_height)
    refresh
    self.openness = 0
    @subject = nil
    @target  = nil
  end
  
  #--------------------------------------------------------------------------
  # window_width
  #--------------------------------------------------------------------------
  def window_width
    Graphics.width - 128
  end
  
  #--------------------------------------------------------------------------
  # window_height
  #--------------------------------------------------------------------------
  def window_height
    fitting_height(visible_line_number)
  end
  
  #--------------------------------------------------------------------------
  # item_height
  #--------------------------------------------------------------------------
  def item_height
    height - standard_padding * 2
  end
  
  #--------------------------------------------------------------------------
  # visible_line_number
  #--------------------------------------------------------------------------
  def visible_line_number
    4
  end
  
  #--------------------------------------------------------------------------
  # col_max
  #--------------------------------------------------------------------------
  def col_max
    2
  end
  
  #--------------------------------------------------------------------------
  # item_max
  #--------------------------------------------------------------------------
  def item_max
    2
  end
  
  #--------------------------------------------------------------------------
  # draw_item
  #--------------------------------------------------------------------------
  def draw_item(index)
    return if index.nil?
    clear_item(index)
    rect = item_rect(index)
    battler = index == 0 ? @subject : @target
    return if battler.nil?
    draw_actor_face(battler, rect.x+2, rect.y+2, battler.alive?)
    draw_actor_name(battler, rect.x+96, rect.y, rect.width-8)
    draw_actor_icons(battler, rect.x+96, line_height, rect.width-100)
    draw_actor_hp(battler, rect.x+96, line_height*2, rect.width-100)
    cost_width = (rect.width - 100) / 2
    draw_actor_mp(battler, rect.x+96, line_height*3, cost_width)
    draw_actor_tp(battler, rect.x+96+cost_width, line_height*3, cost_width)
  end
  
  #--------------------------------------------------------------------------
  # draw_face
  #--------------------------------------------------------------------------
  def draw_actor_face(actor, x, y, enabled = true)
    if actor.actor?
      draw_face(actor.face_name, actor.face_index, x, y, enabled)
    else
      draw_face_enemy(actor, x, y, enabled)
    end
  end
  
  #--------------------------------------------------------------------------
  # draw_face
  #--------------------------------------------------------------------------
  def draw_face(face_name, face_index, dx, dy, enabled = true)
    bitmap = Cache.face(face_name)
    fx = [(96 - item_rect(0).width + 1) / 2, 0].max
    fy = face_index / 4 * 96 + 2
    fw = [item_rect(0).width - 4, 92].min
    rect = Rect.new(fx, fy, fw, 92)
    rect = Rect.new(face_index % 4 * 96 + fx, fy, fw, 92)
    contents.blt(dx, dy, bitmap, rect, enabled ? 255 : translucent_alpha)
    bitmap.dispose
  end
  
  #--------------------------------------------------------------------------
  # draw_face
  #--------------------------------------------------------------------------
  def draw_face_enemy(actor, dx, dy, enabled = true)
    bitmap = Cache.battler(actor.battler_name, actor.battler_hue)
    fx = (bitmap.width - 92).abs / 2
    rect = Rect.new(fx, 0, 92, 92)
    dy = [dy, 92 - bitmap.height].max
    contents.blt(dx, dy, bitmap, rect, enabled ? 255 : translucent_alpha)
    bitmap.dispose
  end
  
  #--------------------------------------------------------------------------
  # subject=
  #--------------------------------------------------------------------------
  def subject=(battler)
    return if @subject == battler
    @subject = battler
    draw_item(0)
  end
  
  #--------------------------------------------------------------------------
  # target=
  #--------------------------------------------------------------------------
  def target=(battler)
    return if @target == battler
    @target = battler
    draw_item(1)
  end
  
end # Window_StatusTBS