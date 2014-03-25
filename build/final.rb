$imported ||= {}

module HARMONY
  module VISUAL
    PANEL_COLORS = { # Start.
      :start          => [32 , 32 , 255, 128],
      :move           => [16 , 16 , 255, 128],
      :enemy_target   => [255, 32 , 32 , 128],
      :ally_target    => [32 , 255, 32 , 128],
      :cursor         => [255, 255, 32 , 192],
      :other          => [255, 255, 255, 128],
    } # End.
    PANEL_OUTLINE = false
  end # VISUAL
  
  module ENGINE
    DEFAULT_PROPERTIES = { # Start.
      # Initialize Range for Movement, Attack, Skill and Item.
      :move_range     =>  4,
      :attack_range   =>  1,
      :skill_range    =>  1,
      :item_range     =>  1,
    } # End.
    
    PARTY_START_REGION = 30
    DEFAULT_BATTLE_MEMBERS = 4
    BATTLE_START_CAMERA = true
    
    DEFAULT_MAX_ACTOR = 4
    
    DEBUG_ASTAR = false
  end # ENGINE
end # HARMONY

module Vocab
  
  def self.tbs_place
    # Place Command
    "Place"
  end
  
  def self.tbs_fight
    # Start Battle Command
    "Fight"
  end
  
  def self.tbs_placed
    # Use to note which actor has been placed
    "Placed"
  end
  
  def self.tbs_move
    # Actor command Move
    "Move"
  end
  
  def self.tbs_wait
    # Actor command Wait
    "Wait"
  end
  
  def self.tbs_attack
    # Actor command Attack
    "Attack"
  end
  
end # Vocab
# Use for parsing database and events by notetag and comment-tag

#==============================================================================
# ■ Regular Expression
#==============================================================================

module REGEXP
  module HARMONY
    # Notetags
    SETUP_RANGE = /<(.*) range:[ ]*(\d+)>/i
    CHARSET = /<(?:BATTLER_SET|battler set):[ ]*(.*)>/i
  end
end

#==============================================================================
# ■ DataManager
#==============================================================================

module DataManager
  
  #--------------------------------------------------------------------------
  # alias method: load_database
  #--------------------------------------------------------------------------
  class <<self; alias load_database_beh load_database; end
  def self.load_database
    load_database_beh
    load_notetags_beh
  end
  
  #--------------------------------------------------------------------------
  # new method: load_notetags_beh
  #--------------------------------------------------------------------------
  def self.load_notetags_beh
    groups = [$data_actors, $data_classes, $data_skills, 
              $data_items, $data_weapons, $data_enemies]
    groups.each { |group|
      group.each { |obj|
        next if obj.nil?
        obj.battle_harmony_initialize
      }
    }
  end
  
end # DataManager

#==============================================================================
# ■ RPG::BaseItem
#==============================================================================

class RPG::BaseItem
  
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :harmony_properties
  attr_accessor :character_name 
  attr_accessor :character_index
  
  #--------------------------------------------------------------------------
  # new method: battle_harmony_initialize
  #--------------------------------------------------------------------------
  def battle_harmony_initialize
    create_harmony_default
    create_harmony_data
    create_harmony_sprite
  end
  
  #--------------------------------------------------------------------------
  # new method: create_harmony_default
  #--------------------------------------------------------------------------
  def create_harmony_default
    hash = HARMONY::ENGINE::DEFAULT_PROPERTIES
    @harmony_properties = {}
    #---
    @harmony_properties[:mrange] = hash[:move_range]
    @harmony_properties[:arange] = hash[:attack_range]
    @harmony_properties[:srange] = hash[:skill_range]
    @harmony_properties[:irange] = hash[:item_range]
  end
  
  #--------------------------------------------------------------------------
  # new method: create_harmony_data
  #--------------------------------------------------------------------------
  def create_harmony_data
    self.note.split(/[\r\n]+/).each { |line|
      case line
      when REGEXP::HARMONY::SETUP_RANGE
        property = $1.upcase
        value = $2.to_i
        #---
        case property
        when "MOVE"
          @harmony_properties[:mrange] = value
        when "ATTACK"
          @harmony_properties[:arange] = value
        when "SKILL"
          @harmony_properties[:srange] = value
        when "ITEM"
          @harmony_properties[:irange] = value
        end
      end
    }
  end
  
  #--------------------------------------------------------------------------
  # new method: move_range
  #--------------------------------------------------------------------------
  def move_range
    @harmony_properties[:mrange]
  end
  
  #--------------------------------------------------------------------------
  # new method: attack_range
  #--------------------------------------------------------------------------
  def attack_range
    @harmony_properties[:arange]
  end
  
  #--------------------------------------------------------------------------
  # new method: use_range
  #--------------------------------------------------------------------------
  def use_range
    result = 0
    #---
    case self.class.name
    when "RPG::Weapon"
      result = @harmony_properties[:arange]
    when "RPG::Skill"
      result = @harmony_properties[:srange]
    when "RPG::Item"
      result = @harmony_properties[:irange]
    end
    #---
    result
  end
  
  #--------------------------------------------------------------------------
  # new method: create_harmony_sprite
  #--------------------------------------------------------------------------
  def create_harmony_sprite
    @character_name ||= ""
    @character_index ||= 0
    self.note.split(/[\r\n]+/).each { |line|
      case line
      when REGEXP::HARMONY::CHARSET
        str_scan = $1.scan(/[^,]+/i)
        @character_name = str_scan[0]
        @character_index = str_scan[1].to_i
      end
    }
  end
    
end # RPG::BaseItem
# Add things for Sprite_Character

#==============================================================================
# ■ Game_Enemy
#==============================================================================

class Game_Enemy < Game_Battler
  
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :character_name
  attr_reader   :character_index

  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias beh_initialize initialize
  def initialize(index, enemy_id)
    beh_initialize(index, enemy_id)
    @character_name = enemy.character_name
    @character_index = enemy.character_index
  end
  
end # Game_Enemy

#==============================================================================
# ■ Sprite_Character
#==============================================================================

class Sprite_Character < Sprite_Base
  
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :battler
  
  #--------------------------------------------------------------------------
  # alias method: update
  #--------------------------------------------------------------------------
  alias beh_update update
  def update
    beh_update
    setup_new_animation
  end
  
  #--------------------------------------------------------------------------
  # new method: setup_new_animation
  #--------------------------------------------------------------------------
  def setup_new_animation
    return unless character.battler
    battler = character.battler
    if battler.animation_id > 0
      animation = $data_animations[battler.animation_id]
      mirror = battler.animation_mirror
      start_animation(animation, mirror)
      battler.animation_id = 0
    end
  end
    
end # Sprite_Character

#==============================================================================
# ■ Game_Character
#==============================================================================

class Game_Character < Game_CharacterBase
  
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :battler
  
end # Game_Character

#==============================================================================
# ■ Game_CharacterBattler
#==============================================================================

class Game_CharacterBattler < Game_Character
  
  #--------------------------------------------------------------------------
  # refresh
  #--------------------------------------------------------------------------
  def refresh
    @battler ? refresh_battler : false
  end
  
  #--------------------------------------------------------------------------
  # refresh_battler
  #--------------------------------------------------------------------------
  def refresh_battler
    @character_name = @battler.character_name
    @character_index = @battler.character_index
    @step_anime = true
  end
  
  #--------------------------------------------------------------------------
  # collide_with_battler?
  #--------------------------------------------------------------------------
  def collide_with_battler?(x, y)
    $game_party.in_battle && $game_map.battler_xy?(x, y) &&
      opposite_unit?($game_map.battler_xy(x, y))
  end
  
  #--------------------------------------------------------------------------
  # collide_with_characters?
  #--------------------------------------------------------------------------
  def collide_with_characters?(x, y)
    super(x, y) || collide_with_battler?(x, y)
  end
  
  #--------------------------------------------------------------------------
  # opposite_unit?
  #--------------------------------------------------------------------------
  def opposite_unit?(battler)
    character = battler.character
    return false unless character
    (self.battler.actor? && character.battler.enemy?) ||
      (self.battler.enemy? && character.battler.actor?)
  end
  
  #--------------------------------------------------------------------------
  # force_path
  #--------------------------------------------------------------------------
  def force_path(target_x, target_y)
    start  = ANode.new(@x, @y)
    target = ANode.new(target_x, target_y)
    #---
    PanelManager.findpath(self.battler, start, target)
    PanelManager.print_path(target) # Debug pathfinding.
    #---
    path = PanelManager.move_path(target)
    move_route = RPG::MoveRoute.new
    move_route.list = path
    move_route.repeat = false
    force_move_route(move_route)
  end
  
  #--------------------------------------------------------------------------
  # is_moving?
  #--------------------------------------------------------------------------
  def is_moving?
    (@move_route && @move_route.list.size > 0) || 
      (@x != @real_x || @y != @real_y)
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
  # camera_follow
  #--------------------------------------------------------------------------
  def camera_follow(flag = true)
    @camera_follow = flag
  end
  
  #--------------------------------------------------------------------------
  # update
  #--------------------------------------------------------------------------
  def update
    super
    update_camera
  end
  
  #--------------------------------------------------------------------------
  # update
  #--------------------------------------------------------------------------
  def update_camera
    return unless @camera_follow
    $game_map.set_display_pos(@real_x - center_x, @real_y - center_y)
  end
  
end # Game_Character
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
# Panel Manager, use to find targetable grids.

#==============================================================================
# ■ PanelManager
#==============================================================================

module PanelManager
  
  #--------------------------------------------------------------------------
  # clear
  #--------------------------------------------------------------------------
  def self.clear
    @selection ||= []; @selection.clear
    @open ||= []; @open.clear
    @close ||= []; @close.clear
    @cost ||= []; @cost.clear
    (0...$game_map.width).each { |x|
      (0...$game_map.height).each { |y|
        @cost[x] ||= []
        @cost[x][y] = 0
      }
    }
  end
  
  #--------------------------------------------------------------------------
  # selection
  #--------------------------------------------------------------------------
  def self.selection
    @selection
  end
  
  #--------------------------------------------------------------------------
  # block_moves
  #--------------------------------------------------------------------------
  def self.block_moves
    result = []
    objects = $game_map.actor_party + $game_map.enemy_troop
    objects.each { |object| result.push([object.x, object.y]) }
    result
  end
  
  #--------------------------------------------------------------------------
  # check_last
  #--------------------------------------------------------------------------
  def self.check_last(battler, action, base)
    @last_battler == battler && @last_action == action && 
      @last_position == base
  end
  
  #--------------------------------------------------------------------------
  # check_passable?
  #--------------------------------------------------------------------------
  def self.check_passable?(battler, x, y, d)
    return false unless battler.character.passable?(x, y, d)
    return false unless passable?(x, y, d)
    return true
  end
  
  #--------------------------------------------------------------------------
  # passable?
  #--------------------------------------------------------------------------
  def self.passable?(x, y, d)
    panel = get_panel(x, y, d)
    #---
    return false unless $game_map.valid?(panel[0], panel[1])
    return true
  end
  
  #--------------------------------------------------------------------------
  # get_panel
  #--------------------------------------------------------------------------
  def self.get_panel(x, y, d)
    case d
    when 1; return [x - 1, y + 1]
    when 2; return [x    , y + 1]
    when 3; return [x + 1, y + 1]
    when 4; return [x - 1, y    ]
    when 6; return [x + 1, y    ]
    when 7; return [x - 1, y - 1]
    when 8; return [x    , y - 1]
    when 9; return [x + 1, y - 1]
    end
  end
  
  #--------------------------------------------------------------------------
  # move_selection
  #--------------------------------------------------------------------------
  def self.move_selection(battler, fly = false)
    action = fly ? :fly : :move
    base = [battler.x, battler.y]
    return @selection if check_last(battler, action, base)
    @last_battler = battler
    @last_action = action
    @last_position = base
    #---
    clear
    @max = battler.move_range
    setup_selection(base, !fly)
    @selection -= block_moves
    #---
    return @selection
  end
  
  #--------------------------------------------------------------------------
  # item_selection
  #--------------------------------------------------------------------------
  def self.item_selection(battler, item)
    base = [battler.x, battler.y]
    return @selection if check_last(battler, item, base)
    @last_battler = battler
    @last_action = item
    @last_position = base
    #---
    case item.class.name
    when "RPG::Skill"
      if item.id == battler.attack_skill_id
        range = battler.attack_range
      else
        range = battler.skill_range(item)
      end
    when "RPG::Item"
      range = battler.item_range(item)
    end
    clear
    @max = range
    setup_selection(base, false)
    #---
    return @selection
  end
  
  #--------------------------------------------------------------------------
  # setup_selection
  #--------------------------------------------------------------------------
  def self.setup_selection(base, block = true)
    @close.push(base)
    @selection.push(base) unless @selection.include?(base)
    #---
    directions = [2, 4, 6, 8]
    #---
    directions.each { |d|
      block_cond = check_passable?(@last_battler, base[0], base[1], d)
      non_block  = !block && passable?(base[0], base[1], d)
      if block_cond || non_block
        panel = get_panel(base[0], base[1], d)
        @selection.push(panel) unless @selection.include?(panel)
        temp_1 = @cost[panel[0]][panel[1]]
        temp_2 = @cost[base[0]][base[1]] + 1
        if !@open.include?(panel); 
          @cost[panel[0]][panel[1]] = temp_2
        else
          @cost[panel[0]][panel[1]] = [temp_1, temp_2].min 
        end
        @open.push(panel) unless @close.include?(panel)
      end
    }
    #---
    @open.uniq!
    while @open.size > 0
      o = @open.shift
      if @close.include?(o) || @cost[o[0]][o[1]] >= @max
        @open.delete(o)
        @close.push(o)
      else
        setup_selection(o, block)
      end
    end
  end
    
end # PanelManager
#==============================================================================
# ■ ANode
#==============================================================================

class ANode
  
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :parent
  attr_accessor :g
  attr_accessor :h
  attr_accessor :f
  attr_accessor :points
  
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  def initialize(x, y)
    @parent = nil
    @g = 0
    @h = 0
    @f = 0
    @points = [x, y]
  end
  
end # ANode

#==============================================================================
# ■ PanelManager
#==============================================================================

module PanelManager
  
  #--------------------------------------------------------------------------
  # Initialize Variables
  #--------------------------------------------------------------------------
  @aopen = []
  @aclose = []
  DIRECTION = [2, 4, 6, 8]
    
  #--------------------------------------------------------------------------
  # self.distance
  #--------------------------------------------------------------------------
  def self.distance(node1, node2)
    p1 = node1.points; p2 = node2.points
    ((p1[0] - p2[0]).abs + (p1[1] - p2[1]).abs)
  end
  
  #--------------------------------------------------------------------------
  # self.cost
  #--------------------------------------------------------------------------
  def self.cost(node1, node2)
    p1 = node1.points; p2 = node2.points
    return 0 if p1 == p2
    (p1[0] == p2[0] || p1[1] == p2[1]) ? 1 : 2
  end
  
  #--------------------------------------------------------------------------
  # self.findpath
  #--------------------------------------------------------------------------
  def self.findpath(battler, p1, p2)
    @aopen.clear
    @aclose.clear
    #---
    p1.g = 0
    p1.h = distance(p1, p2)
    p1.f = p1.h
    #---
    @aopen.push(p1)
    #---
    while @aopen.size > 0
      top = @aopen.shift
      @aclose.push(top) if !@aclose.any? { |x| x.points == top.points }
      #---
      if top.points == p2.points
        p2.parent = @aclose.pop
        return true
      end
      #---
      DIRECTION.each { |i|
        next_point = get_panel(top.points[0], top.points[1], i)
        topConnect = (@aopen + @aclose).select { |i| i.points == next_point }[0]
        topConnect = ANode.new(next_point[0], next_point[1]) if topConnect.nil?
        #---
        if !@aclose.any? { |x| x.points == topConnect.points } && 
          check_passable?(battler, top.points[0], top.points[1], i)
          if !@aopen.any? { |x| x.points == topConnect.points }
            topConnect.g = top.g + cost(top, topConnect)
            topConnect.h = distance(p2, topConnect)
            topConnect.f = topConnect.g + topConnect.h
            topConnect.parent = top
            @aopen.push(topConnect)
          else
            tempG = top.g + cost(top, topConnect)
            if tempG < topConnect.g
              topConnect.g = tempG
              topConnect.f = topConnect.g + topConnect.h
              topConnect.parent = top
            end
          end
        end
      }
      #---
      @aopen.sort! { |a,b| a.f <=> b.f }
    end
    #---
    return false
  end
  
  #--------------------------------------------------------------------------
  # self.move_path
  #--------------------------------------------------------------------------
  def self.move_path(final_node)
    path = []
    node = final_node
    nodes = []
    #---
    while node.parent
      node = node.parent
      nodes.push(node.points)
    end
    nodes.shift
    #---
    target_x = final_node.points[0]
    target_y = final_node.points[1]
    #---
    start_x = nodes.reverse[0][0]
    start_y = nodes.reverse[0][1]
    #---
    while nodes.size > 0
      points = nodes.shift
      parent_x = points[0]
      parent_y = points[1]
      if    target_x < parent_x; code = 2
      elsif target_x > parent_x; code = 3
      else; code = target_y < parent_y ? 4 : 1
      end
      path.push(RPG::MoveCommand.new(code))
      target_x = parent_x
      target_y = parent_y
      break if target_x == start_x && target_y == start_y
    end
    return path.reverse + [RPG::MoveCommand.new(0)]
  end
  
  #--------------------------------------------------------------------------
  # self.print_path
  # Use for debug
  #--------------------------------------------------------------------------
  def self.print_path(node)
    return unless HARMONY::ENGINE::DEBUG_ASTAR
    nodes = [node.points]
    while node.parent
      node = node.parent
      nodes.push(node.points)
    end
    nodes.shift
    nodes.reverse.each {|a| print a; print "  "}
  end
  
end # PanelManager
#==============================================================================
# ■ Game_Battler
#==============================================================================

class Game_Battler < Game_BattlerBase
  
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :character
  
  #--------------------------------------------------------------------------
  # new method: move_range
  #--------------------------------------------------------------------------
  def move_range
    enemy? ? enemy.move_range : actor_move_range
  end 
  
  #--------------------------------------------------------------------------
  # new method: actor_move_range
  #--------------------------------------------------------------------------
  def actor_move_range
    range_actor   = self.actor.move_range
    range_class   = self.class.move_range
    range_default = HARMONY::ENGINE::DEFAULT_PROPERTIES[:move_range]
    if range_class != range_default
      return range_class
    else
      return range_actor
    end
  end
  
  #--------------------------------------------------------------------------
  # new method: attack_range
  #--------------------------------------------------------------------------
  def attack_range
    enemy? ? enemy.attack_range : actor_attack_range
  end 
  
  #--------------------------------------------------------------------------
  # new method: actor_attack_range
  #--------------------------------------------------------------------------
  def actor_attack_range
    range_actor   = self.actor.attack_range
    range_class   = self.class.attack_range
    range_weapon  = self.weapons.collect{|w|w.attack_range}.max
    range_default = HARMONY::ENGINE::DEFAULT_PROPERTIES[:attack_range]
    if range_weapon
      return range_weapon
    elsif range_class != range_default
      return range_class
    else
      return range_actor
    end
  end
  
  #--------------------------------------------------------------------------
  # new method: skill_range
  #--------------------------------------------------------------------------
  def skill_range(skill)
    skill.use_range
  end
  
  #--------------------------------------------------------------------------
  # new method: item_range
  #--------------------------------------------------------------------------
  def item_range(item)
    item.use_range
  end
  
  #--------------------------------------------------------------------------
  # alias method: make_actions
  #--------------------------------------------------------------------------
  alias beh_make_actions make_actions
  def make_actions
    beh_make_actions
    @moved = false
    @acted = false
  end
  
  #--------------------------------------------------------------------------
  # new method: moveto
  #--------------------------------------------------------------------------
  def moveto(target_x, target_y)
    @old_position = [x, y]
    @character.force_path(target_x, target_y)
    @moved = true
  end
  
  #--------------------------------------------------------------------------
  # new method: end_action
  #--------------------------------------------------------------------------
  def end_action
    @acted = true
  end
  
  #--------------------------------------------------------------------------
  # new method: return_position
  #--------------------------------------------------------------------------
  def return_position
    return unless returnable?
    @character.moveto(@old_position[0], @old_position[1])
    @old_position.clear
    @moved = false
  end
  
  #--------------------------------------------------------------------------
  # new method: camera_follow
  #--------------------------------------------------------------------------
  def camera_follow(flag = true)
    @character.camera_follow(flag)
  end
  
  #--------------------------------------------------------------------------
  # new method: moved?
  #--------------------------------------------------------------------------
  def moved?
    @moved
  end
  
  #--------------------------------------------------------------------------
  # new method: acted?
  #--------------------------------------------------------------------------
  def acted?
    @acted
  end
  
  #--------------------------------------------------------------------------
  # new method: returnable?
  #--------------------------------------------------------------------------
  def returnable?
    moved? && !acted?
  end
  
  #--------------------------------------------------------------------------
  # new method: is_moving?
  #--------------------------------------------------------------------------
  def is_moving?
    @character.is_moving?
  end
  
  #--------------------------------------------------------------------------
  # opposite_unit?
  #--------------------------------------------------------------------------
  def opposite_unit?(battler)
    (self.actor? && battler.enemy?) || (self.enemy? && battler.actor?)
  end
  
  #--------------------------------------------------------------------------
  # new method: usable_on?
  #--------------------------------------------------------------------------
  def usable_on?(user, item)
    flag = item.for_opponent? && opposite_unit?(user)
    flag = flag || (item.for_friend? && !opposite_unit?(user))
    flag = flag || (item.for_user? && user == self)
    flag
  end
  
  #--------------------------------------------------------------------------
  # new method: x
  #--------------------------------------------------------------------------
  def x
    @character ? @character.x : 0
  end
  
  #--------------------------------------------------------------------------
  # new method: y
  #--------------------------------------------------------------------------
  def y
    @character ? @character.y : 0
  end
  
end # Game_Battler
#==============================================================================
# ■ Game_Temp
#==============================================================================

class Game_Temp
  
  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias beh_initialize initialize
  def initialize
    beh_initialize
    @tbs_troop = []
  end
  
  #--------------------------------------------------------------------------
  # new method: add_enemy
  #--------------------------------------------------------------------------
  def add_enemy(id, x, y)
    @tbs_troop.push([id, x, y])
  end
  
  #--------------------------------------------------------------------------
  # new method: reset_enemy
  #--------------------------------------------------------------------------
  def reset_enemy
    @tbs_troop.clear
  end
  
  #--------------------------------------------------------------------------
  # new method: tbs_troop
  #--------------------------------------------------------------------------
  def tbs_troop
    @tbs_troop
  end
  
  #--------------------------------------------------------------------------
  # new method: prepare_map
  #--------------------------------------------------------------------------
  def prepare_map
    @backup_map = $game_map
    $game_map = Game_BattleMap.new
  end
  
  #--------------------------------------------------------------------------
  # new method: restore_map
  #--------------------------------------------------------------------------
  def restore_map
    $game_map = @backup_map
    @backup_map = nil
  end
  
end # Game_Temp

#==============================================================================
# ■ Game_Unit
#==============================================================================

class Game_Unit
  
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :in_tbs
  
  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias beh_initialize initialize
  def initialize
    beh_initialize
    @in_tbs = false
  end
  
  #--------------------------------------------------------------------------
  # new method: on_tbs_start
  #--------------------------------------------------------------------------
  def on_tbs_start
    on_battle_start
    @in_tbs = true
  end
  
  #--------------------------------------------------------------------------
  # new method: on_tbs_end
  #--------------------------------------------------------------------------
  def on_tbs_end
    on_battle_end
    @in_tbs = false
  end
  
end # Game_Unit

#==============================================================================
# ■ Game_Party
#==============================================================================

class Game_Party < Game_Unit
  
  #--------------------------------------------------------------------------
  # alias method: battle_members
  #--------------------------------------------------------------------------
  alias beh_battle_members battle_members
  def battle_members
    @in_tbs ? tbs_battle_members : beh_battle_members
  end
  
  #--------------------------------------------------------------------------
  # new method: tbs_battle_members
  #--------------------------------------------------------------------------
  def tbs_battle_members
    $game_map.actor_party ? $game_map.actor_party.compact : []
  end
  
  #--------------------------------------------------------------------------
  # new method: max_tbs_members
  #--------------------------------------------------------------------------
  def max_tbs_members
    HARMONY::ENGINE::DEFAULT_BATTLE_MEMBERS
  end
  
end # Game_Party

#==============================================================================
# ■ Game_Troop
#==============================================================================

class Game_Troop < Game_Unit
  
  #--------------------------------------------------------------------------
  # new method: setup_tbs
  #--------------------------------------------------------------------------
  def setup_tbs(enemies)
    enemies.each { |member| @enemies.push(member) }
    make_unique_names
  end
  
end # Game_Troop
# Use for setup battle map data

#==============================================================================
# ■ Game_BattleMap
#==============================================================================

class Game_BattleMap < Game_Map
  
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :actor_party
  attr_reader   :enemy_troop
  attr_reader   :start_locations
  
  #--------------------------------------------------------------------------
  # setup_battle
  #--------------------------------------------------------------------------
  def setup_battle
    setup_actors
    setup_enemies
    setup_map_data
  end
  
  #--------------------------------------------------------------------------
  # end_battle
  #--------------------------------------------------------------------------
  def end_battle
    flush_battlers
  end
  
  #--------------------------------------------------------------------------
  # setup_actor
  #--------------------------------------------------------------------------
  def setup_actors
    @actor_party ||= []
    @actor_party.clear
  end
  
  #--------------------------------------------------------------------------
  # add_actor
  #--------------------------------------------------------------------------
  def add_actor(actor, position)
    if battler_xy?(position[0], position[1])
      if actor != battler_xy(position[0], position[1])
        remove_actor(battler_xy(position[0], position[1]))
      end
    end
    return move_actor(actor, position) if @actor_party.include?(actor)
    character = Game_CharacterBattler.new
    character.moveto(position[0], position[1])
    #---
    actor.character = character
    #---
    character.battler = actor
    character.refresh
    #---
    @actor_party.push(actor)
  end
  
  #--------------------------------------------------------------------------
  # remove_actor
  #--------------------------------------------------------------------------
  def remove_actor(actor)
    actor.character = nil
    @actor_party.delete(actor)
  end
  
  #--------------------------------------------------------------------------
  # move_actor
  #--------------------------------------------------------------------------
  def move_actor(actor, position)
    return false unless actor.character
    actor.character.moveto(position[0], position[1])
  end
  
  #--------------------------------------------------------------------------
  # empty_position
  #--------------------------------------------------------------------------
  def empty_position
    return [0, 0] if @start_locations.size == 0
    @start_locations.each { |location|
      next if battler_xy?(location[0], location[1])
      return location
    }
    return @start_locations[0]
  end
  
  #--------------------------------------------------------------------------
  # setup_enemies
  #--------------------------------------------------------------------------
  def setup_enemies
    @enemy_troop ||= []
    @enemy_troop.clear
    #---
    $game_temp.tbs_troop.each_with_index { |data, index|
      character = Game_CharacterBattler.new
      character.moveto(data[1], data[2])
      #---
      enemy = Game_Enemy.new(index, data[0])
      enemy.character = character
      #---
      character.battler = enemy
      character.refresh
      #---
      @enemy_troop.push(enemy)
    }
    #---
    $game_temp.reset_enemy
  end
  
  #--------------------------------------------------------------------------
  # setup_start_locations
  #--------------------------------------------------------------------------
  def setup_map_data
    @start_locations ||= []
    @start_locations.clear
    #---
    start_id = HARMONY::ENGINE::PARTY_START_REGION
    (0...width).each { |x|
      (0...height).each { |y|
        @start_locations.push([x, y]) if region_id(x, y) == start_id
      }
    }
  end
  
  #--------------------------------------------------------------------------
  # flush_battlers
  #--------------------------------------------------------------------------
  def flush_battlers
    (@actor_party + @enemy_troop).each { |battler| battler.character = nil }
    #---
    @actor_party.clear
    @enemy_troop.clear
  end
  
  #--------------------------------------------------------------------------
  # battler_xy?
  #--------------------------------------------------------------------------
  def battler_xy?(x, y)
    (@actor_party + @enemy_troop).any? { |battler|
      battler.x == x && battler.y == y
    }
  end
  
  #--------------------------------------------------------------------------
  # battler_xy
  #--------------------------------------------------------------------------
  def battler_xy(x, y)
    result = (@actor_party + @enemy_troop).select { |battler|
      battler.x == x && battler.y == y
    }
    result[0]
  end
  
  #--------------------------------------------------------------------------
  # max_actor?
  #--------------------------------------------------------------------------
  def max_actor?
    @actor_party.size >= BattleManager.max_actor
  end
  
  #--------------------------------------------------------------------------
  # update_events
  #--------------------------------------------------------------------------
  def update_events
    super
    @actor_party.each { |battler| battler.character.update }
    @enemy_troop.each { |battler| battler.character.update }
  end
    
end # Game_BattleMap
#==============================================================================
# ■ Spriteset_BattleMap
#==============================================================================

class Spriteset_BattleMap < Spriteset_Map
  
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  def initialize
    super
    init_camera
  end
  
  #--------------------------------------------------------------------------
  # create_characters
  #--------------------------------------------------------------------------
  def create_characters
    @character_sprites ||= []
    @character_sprites.clear
    #---
    create_map_events
    create_battlers
    clear_panels
    #---
    @map_id = $game_map.map_id
  end
  
  #--------------------------------------------------------------------------
  # create_map_events
  #--------------------------------------------------------------------------
  def create_map_events
    $game_map.events.values.each { |event|
      @character_sprites.push(Sprite_Character.new(@viewport1, event))
    }
  end
  
  #--------------------------------------------------------------------------
  # create_battlers
  #--------------------------------------------------------------------------
  def create_battlers
    # Create Enemy Sprites.
    $game_map.enemy_troop.each { |enemy|
      sprite = Sprite_Character.new(@viewport1, enemy.character)
      @character_sprites.push(sprite)
    }
  end
  
  #--------------------------------------------------------------------------
  # refresh_actors
  #--------------------------------------------------------------------------
  def refresh_actors
    $game_map.actor_party.each { |actor|
      next if @character_sprites.any? { |c| c.character.battler == actor }
      sprite = Sprite_Character.new(@viewport1, actor.character)
      @character_sprites.push(sprite)
    }
    #---
    @character_sprites.each { |sprite|
      battler = sprite.character.battler
      next if all_battlers.include?(battler)
      @character_sprites.delete(sprite)
      sprite.dispose
    }
  end
      
  #--------------------------------------------------------------------------
  # init_camera
  #--------------------------------------------------------------------------
  def init_camera
    return unless HARMONY::ENGINE::BATTLE_START_CAMERA
    first_place = $game_map.start_locations[0]
    activate_cursor
    move_cursor(first_place[0], first_place[1])
    hide_cursor
  end
  
  #--------------------------------------------------------------------------
  # start_locations
  #--------------------------------------------------------------------------
  def start_locations
    $game_map.start_locations.each { |xy|
      sprite = Sprite_Panel.new(@viewport1)
      sprite.show(:start)
      sprite.moveto(xy[0], xy[1])
      @panel_sprites.push(sprite)
    }
  end
  
  #--------------------------------------------------------------------------
  # clear_panels
  #--------------------------------------------------------------------------
  def clear_panels
    @panel_sprites ||= []
    @panel_sprites.each { |sprite| sprite.dispose }
    @panel_sprites.clear
    @cursor ||= Sprite_Panel.new(@viewport1)
  end
  
  #--------------------------------------------------------------------------
  # start_move
  #--------------------------------------------------------------------------
  def start_move(battler)
    PanelManager.move_selection(battler, false)
    PanelManager.selection.each { |xy|
      sprite = Sprite_Panel.new(@viewport1)
      sprite.show(:move)
      sprite.moveto(xy[0], xy[1])
      @panel_sprites.push(sprite)
    }
  end
  
  #--------------------------------------------------------------------------
  # start_item
  #--------------------------------------------------------------------------
  def start_item(battler, item)
    PanelManager.item_selection(battler, item)
    PanelManager.selection.each { |xy|
      sprite = Sprite_Panel.new(@viewport1)
      sprite.show(:move)
      sprite.moveto(xy[0], xy[1])
      @panel_sprites.push(sprite)
    }
  end
  
  #--------------------------------------------------------------------------
  # update
  #--------------------------------------------------------------------------
  def update
    super
    update_panels
  end
  
  #--------------------------------------------------------------------------
  # update_panels
  #--------------------------------------------------------------------------
  def update_panels
    @panel_sprites ||= []
    @panel_sprites.each { |sprite| sprite.update }
    #---
    @cursor.update
    #---
    Sprite_Panel.animate
  end

  #--------------------------------------------------------------------------
  # all_battlers
  #--------------------------------------------------------------------------
  def all_battlers
    $game_map.actor_party + $game_map.enemy_troop
  end
  
  #--------------------------------------------------------------------------
  # battler_sprites
  #--------------------------------------------------------------------------
  def battler_sprites
    @character_sprites.select { |sprite| sprite.character.battler }
  end
  
  #--------------------------------------------------------------------------
  # animation?
  #--------------------------------------------------------------------------
  def animation?
    battler_sprites.any? { |sprite| sprite.animation? }
  end
  
  #--------------------------------------------------------------------------
  # activate_cursor
  #--------------------------------------------------------------------------
  def activate_cursor
    @cursor.show(:cursor)
    @cursor.activate
  end
  
  #--------------------------------------------------------------------------
  # deactivate_cursor
  #--------------------------------------------------------------------------
  def deactivate_cursor
    @cursor.deactivate
  end
  
  #--------------------------------------------------------------------------
  # show_cursor
  #--------------------------------------------------------------------------
  def show_cursor
    @cursor.show(:cursor)
  end
  
  #--------------------------------------------------------------------------
  # hide_cursor
  #--------------------------------------------------------------------------
  def hide_cursor
    @cursor.deactivate.hide
  end
  
  #--------------------------------------------------------------------------
  # cursor_handler
  #--------------------------------------------------------------------------
  def cursor_handler(symbol, method)
    @cursor.set_handler(symbol, method)
  end
  
  #--------------------------------------------------------------------------
  # move_cursor
  #--------------------------------------------------------------------------
  def move_cursor(x, y)
    @cursor.moveto(x, y)
  end
  
  #--------------------------------------------------------------------------
  # move_cursor_smooth
  #--------------------------------------------------------------------------
  def move_cursor_smooth(x, y)
    @cursor.moveto_smooth(x, y)
  end
  
  #--------------------------------------------------------------------------
  # cursor_position
  #--------------------------------------------------------------------------
  def cursor_position
    @cursor.position
  end
  
  #--------------------------------------------------------------------------
  # cursor_screen
  #--------------------------------------------------------------------------
  def cursor_screen
    [@cursor.screen_x, @cursor.screen_y]
  end
  
  #--------------------------------------------------------------------------
  # cursor_moving?
  #--------------------------------------------------------------------------
  def cursor_moving?
    @cursor.is_moving?
  end
  
  #--------------------------------------------------------------------------
  # cursor_active?
  #--------------------------------------------------------------------------
  def cursor_active?
    @cursor.active
  end
    
end # Spriteset_BattleMap
#==============================================================================
# ■ BattleManager
#==============================================================================

module BattleManager
  
  #--------------------------------------------------------------------------
  # self.setup_tbs
  #--------------------------------------------------------------------------
  def self.setup_tbs(can_escape, can_lose, max_actor)
    @can_escape = can_escape
    @can_lose   = can_lose
    @max_actor  = max_actor
    init_tbs
  end
  
  #--------------------------------------------------------------------------
  # self.max_actor
  #--------------------------------------------------------------------------
  def self.max_actor
    @max_actor
  end
  
  #--------------------------------------------------------------------------
  # self.init_tbs
  #--------------------------------------------------------------------------
  def self.init_tbs
    $game_troop.setup_tbs($game_map.enemy_troop)
    make_escape_ratio
    #---
    @phase = :init
    @map_bgm = nil
    @map_bgs = nil 
    @action_battlers = []   
  end
  
  #--------------------------------------------------------------------------
  # self.tbs_start
  #--------------------------------------------------------------------------
  def self.tbs_start
    $game_system.battle_count += 1
    $game_party.on_tbs_start
    $game_troop.on_tbs_start
    $game_troop.enemy_names.each do |name|
      $game_message.add(sprintf(Vocab::Emerge, name))
    end
    wait_for_message
  end
  
  #--------------------------------------------------------------------------
  # self.tbs_turn_start
  #--------------------------------------------------------------------------
  def self.tbs_turn_start
    @phase = :turn
  end
  
  #--------------------------------------------------------------------------
  # self.setup_tbs_order
  #--------------------------------------------------------------------------
  def self.setup_tbs_order
    @action_battlers.clear
    #---
    @action_battlers += $game_party.members
    @action_battlers += $game_troop.members
    @action_battlers.sort! { |a, b| b.agi <=> b.agi }
  end
  
  #--------------------------------------------------------------------------
  # self.setup_tbs_order_test
  #--------------------------------------------------------------------------
  def self.setup_tbs_order_test
    @action_battlers.clear
    #---
    @action_battlers += $game_party.members
    @action_battlers.sort! { |a, b| b.agi <=> a.agi }
  end
  
  #--------------------------------------------------------------------------
  # self.get_active_battler
  #--------------------------------------------------------------------------
  def self.get_active_battler
    setup_tbs_order_test if @action_battlers.nil? || @action_battlers.size == 0
    loop do
      battler = @action_battlers.shift
      setup_tbs_order_test if battler.nil?
      next unless battler
      next unless battler.index && battler.alive?
      return battler
    end
  end
  
  #--------------------------------------------------------------------------
  # self.phase
  #--------------------------------------------------------------------------
  def self.phase
    @phase
  end
    
end # BattleManager
#==============================================================================
# ■ HARMONY
#==============================================================================

module HARMONY
  module POPUP
    
    BATTLE_POPUP = {
      # Basic Configuration.
      :basic_setting  =>  {
        :enable     =>  true,       # Set to false to disable popup.
        :delay      =>  6,          # Delay between each popup.
        :no_delay   =>  [:critical, :drained, :weakpoint, :resistant, :absorbed],
      },
      
      # Configuration for words.
      :word_setting   =>  {
        :default    => "%s",        # SprintF for Default.
        :hp_dmg     => "-%s ",      # SprintF for HP damage.
        :hp_heal    => "+%s ",      # SprintF for HP healing.
        :mp_dmg     => "-%s MP",    # SprintF for MP damage.
        :mp_heal    => "+%s MP",    # SprintF for MP healing.
        :tp_dmg     => "-%s TP",    # SprintF for MP damage.
        :tp_heal    => "+%s TP",    # SprintF for MP healing.
        :drained    => "DRAIN",     # Text display for draining HP/MP.
        :critical   => "CRITICAL!", # Text display for critical hit.
        :missed     => "MISS",      # Text display for missed attack.
        :evaded     => "EVADE!",    # Text display for evaded attack.
        :nulled     => "NULL",      # Text display for nulled attack.
        :failed     => "FAILED",    # Text display for a failed attack.
        :add_state  => "+%s",       # SprintF for added states.
        :rem_state  => "-%s",       # SprintF for removed states.
        :dur_state  => "%s",        # SprintF for during states.
        :weakpoint  => "WEAKPOINT", # Appears if foe is weak to element.
        :resistant  => "RESIST",    # Appears if foe is resistant to element.
        :immune     => "IMMUNE",    # Appears if foe is immune to element.
        :absorbed   => "ABSORB",    # Appears if foe can absorb the element.
        :add_buff   => "%s",        # Appears when a positive buff is applied.
        :add_debuff => "%s",        # Appears when a negative buff is applied.
      },
      
      # Configuration for popup visual.
      :style_setting  =>  {
        # Type      => [Red, Green, Blue, Size, Bold, Italic, Font],
        :default    => [255,   255,  255,   32, true,  false, Font.default_name],
        :hp_dmg     => [255,   255,  255,   32, true,  false, Font.default_name],
        :hp_heal    => [255,   255,  255,   32, true,  false, Font.default_name],
        :mp_dmg     => [255,   255,  255,   32, true,  false, Font.default_name],
        :mp_heal    => [255,   255,  255,   32, true,  false, Font.default_name],
        :tp_dmg     => [255,   255,  255,   32, true,  false, Font.default_name],
        :tp_heal    => [255,   255,  255,   32, true,  false, Font.default_name],
        :drained    => [255,   255,  255,   32, true,  false, Font.default_name],
        :critical   => [255,   255,  255,   32, true,  false, Font.default_name],
        :missed     => [255,   255,  255,   32, true,  false, Font.default_name],
        :evaded     => [255,   255,  255,   32, true,  false, Font.default_name],
        :nulled     => [255,   255,  255,   32, true,  false, Font.default_name],
        :failed     => [255,   255,  255,   32, true,  false, Font.default_name],
        :add_state  => [255,   255,  255,   32, true,  false, Font.default_name],
        :rem_state  => [255,   255,  255,   32, true,  false, Font.default_name],
        :dur_state  => [255,   255,  255,   32, true,  false, Font.default_name],
        :weakpoint  => [255,   255,  255,   32, true,  false, Font.default_name],
        :resistant  => [255,   255,  255,   32, true,  false, Font.default_name],
        :immune     => [255,   255,  255,   32, true,  false, Font.default_name],
        :absorbed   => [255,   255,  255,   32, true,  false, Font.default_name],
        :add_buff   => [255,   255,  255,   32, true,  false, Font.default_name],
        :add_debuff => [255,   255,  255,   32, true,  false, Font.default_name],
        :lvup       => [255,   255,  255,   20, false, false, Font.default_name],
      },
      
      # Configuration for popup effect.
      :effect_setting =>  {
        # Type      => [Effect sequence],
        :default    => [:up, :wait],
        :hp_dmg     => [:jump_1, :jump_2, :wait],
        :hp_heal    => [:jump_1, :jump_2, :wait],
        :mp_dmg     => [:jump_1, :jump_2, :wait],
        :mp_heal    => [:jump_1, :jump_2, :wait],
        :tp_dmg     => [:jump_1, :jump_2, :wait],
        :tp_heal    => [:jump_1, :jump_2, :wait],
        :drained    => [:affect, :up    , :wait],
        :critical   => [:affect, :up    , :wait],
        :missed     => [:up    , :wait],
        :evaded     => [:up    , :wait],
        :nulled     => [:up    , :wait],
        :failed     => [:up    , :wait],
        :add_state  => [:affect, :up    , :wait],
        :rem_state  => [:affect, :up    , :wait],
        :dur_state  => [:affect, :up    , :wait],
        :weakpoint  => [:affect, :up    , :wait],
        :resistant  => [:affect, :up    , :wait],
        :immune     => [:up    , :wait],
        :absorbed   => [:affect, :up    , :wait],
        :add_buff   => [:affect, :up    , :wait],
        :add_debuff => [:affect, :up    , :wait],
        :lvup       => [:up, :wait],
      },
      
      :effect_setup   =>  {
        #:type   => [ZoomX, ZoomY, StartX, StartY, MoveX, MoveY, Gravt, Opacity, Dur, Random],
        :up      => [1.0  , 1.0  , 0.0   , 0.0   , 0.0  , -1.0 , 0.0  , 255    , 32 , false ],
        :jump_1  => [1.0  , 1.0  , 0.0   , 0.0   , 0.0  , -6.4 , 0.4  , 255    , 33 , false ],
        :jump_2  => [1.0  , 1.0  , 0.0   , 0.0   , 0.0  , -3.2 , 0.2  , 255    , 33 , false ],
        :wait    => [1.0  , 1.0  , 0.0   , 0.0   , 0.0  , 0.0  , 0.0  , 0      , 20 , false ],
        :affect  => [1.0  , 1.0  , 0.0   , -32.0 , 0.0  , 0.0  , 0.0  , 255    , 1  , false ],
      },
      
    } # End BATTLE_POPUP.
    
  end # POPUP
end # HARMONY

#==============================================================================
# ■ Game_BattlerBase
#==============================================================================

class Game_BattlerBase
  
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :popups
  
  #--------------------------------------------------------------------------
  # new method: create_popup
  #--------------------------------------------------------------------------
  def create_popup(data, rule = :default)
    in_battle = SceneManager.scene_is?(Scene_Battle)
    in_battle = in_battle || SceneManager.scene_is?(Scene_BattleTactics)
    return unless in_battle
    return unless HARMONY::POPUP::BATTLE_POPUP[:basic_setting][:enable]
    @popups ||= []
    @popups.push([data, rule])
  end
  
  #--------------------------------------------------------------------------
  # new method: make_damage_popups
  #--------------------------------------------------------------------------
  def make_damage_popups(user)
    if @result.hp_drain != 0
      rule = :drained
      user.create_popup(["", nil], rule)
      rule = :hp_dmg  if @result.hp_drain < 0
      rule = :hp_heal if @result.hp_drain > 0
      value = @result.hp_drain.abs
      user.create_popup(["#{value}", nil], rule)
    end
    if @result.mp_drain != 0
      rule = :drained
      user.create_popup(["", nil], rule)
      rule = :mp_dmg  if @result.mp_drain < 0
      rule = :mp_heal if @result.mp_drain > 0
      value = @result.mp_drain.abs
      user.create_popup(["#{value}", nil], rule)
    end
    #---
    rule = :critical
    create_popup(["", nil], rule) if @result.critical
    if @result.hp_damage != 0
      rule = :hp_dmg  if @result.hp_damage > 0
      rule = :hp_heal if @result.hp_damage < 0
      value = @result.hp_damage.abs
      create_popup(["#{value}", nil], rule)
    end
    if @result.mp_damage != 0
      rule = :mp_dmg  if @result.mp_damage > 0
      rule = :mp_heal if @result.mp_damage < 0
      value = @result.mp_damage.abs
      create_popup(["#{value}", nil], rule)
    end
    if @result.tp_damage != 0
      rule = :tp_dmg  if @result.tp_damage > 0
      rule = :tp_heal if @result.tp_damage < 0
      value = @result.tp_damage.abs
      create_popup(["#{value}", nil], rule)
    end
  end
  
  #--------------------------------------------------------------------------
  # alias method: erase_state
  #--------------------------------------------------------------------------
  alias battle_harmony_dp_erase_state erase_state unless $imported["YEA-BattleEngine"]
  def erase_state(state_id)
    make_state_popup(state_id, :rem_state) if @states.include?(state_id)
    if $imported["YEA-BattleEngine"]
      game_battlerbase_erase_state_abe(state_id)
    else
      battle_harmony_dp_erase_state(state_id)
    end
  end
  
  #--------------------------------------------------------------------------
  # new method: make_during_state_popup
  #--------------------------------------------------------------------------
  def make_during_state_popup
    state_id = most_important_state_id
    return if state_id == 0
    make_state_popup(state_id, :dur_state)
  end
  
  #--------------------------------------------------------------------------
  # new method: most_important_state_id
  #--------------------------------------------------------------------------
  def most_important_state_id
    states.each {|state| return state.id unless state.message3.empty? }
    return 0
  end
  
  #--------------------------------------------------------------------------
  # new method: make_state_popup
  #--------------------------------------------------------------------------
  def make_state_popup(state_id, type)
    state = $data_states[state_id]
    return if state.icon_index == 0
    create_popup(["#{state.name}", state.icon_index], type)
  end
  
  #--------------------------------------------------------------------------
  # new method: make_miss_popups
  #--------------------------------------------------------------------------
  def make_miss_popups(user, item)
    return if dead?
    if @result.missed
      rule = :missed
      create_popup(["", nil], rule)
    end
    if @result.evaded
      rule = :evaded
      create_popup(["", nil], rule)
    end
    if @result.hit? && !@result.success
      rule = :failed
      create_popup(["", nil], rule)
    end
    if @result.hit? && item.damage.to_hp?
      if @result.hp_damage == 0 && @result.mp_damage == 0
        rule = :nulled
        create_popup(["", nil], rule)
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # new method: make_rate_popup
  #--------------------------------------------------------------------------
  def make_rate_popup(rate)
    return if rate == 1.0
    if rate > 1.0
      rule = :weakpoint
    elsif rate == 0.0
      rule = :immune
    elsif rate < 0.0
      rule = :absorbed
    else
      rule = :resistant
    end
    create_popup(["", nil], rule)
  end
  
  #--------------------------------------------------------------------------
  # new method: make_buff_popup
  #--------------------------------------------------------------------------
  def make_buff_popup(param_id, positive = true)
    in_battle = SceneManager.scene_is?(Scene_Battle)
    in_battle = in_battle || SceneManager.scene_is?(Scene_BattleTactics)
    return unless in_battle
    return unless alive?
    name = Vocab::param(param_id)
    if positive
      rule = :add_buff
      buff_level = 1
    else
      rule = :add_debuff
      buff_level = -1
    end
    icon = buff_icon_index(buff_level, param_id)
    create_popup(["#{name}", icon], rule)
  end

end # Game_BattlerBase

#==============================================================================
# ■ Game_Battler
#==============================================================================

class Game_Battler < Game_BattlerBase
  
  #--------------------------------------------------------------------------
  # alias method: on_battle_end
  #--------------------------------------------------------------------------
  alias battle_harmony_dp_on_battle_end on_battle_end
  def on_battle_end
    battle_harmony_dp_on_battle_end
    @popups ||= []
    @popups.clear
  end
  
  #--------------------------------------------------------------------------
  # alias method: item_apply
  #--------------------------------------------------------------------------
  alias battle_harmony_dp_item_apply item_apply unless $imported["YEA-BattleEngine"]
  def item_apply(user, item)
    if $imported["YEA-BattleEngine"]
      game_battler_item_apply_abe(user, item)
    else
      battle_harmony_dp_item_apply(user, item)
    end    
    make_miss_popups(user, item)
  end
  
  #--------------------------------------------------------------------------
  # alias method: make_damage_value
  #--------------------------------------------------------------------------
  alias battle_harmony_dp_make_damage_value make_damage_value unless $imported["YEA-BattleEngine"]
  def make_damage_value(user, item)
    if $imported["YEA-BattleEngine"]
      game_battler_make_damage_value_abe(user, item)
    else
      battle_harmony_dp_make_damage_value(user, item)
    end    
    rate = item_element_rate(user, item)
    make_rate_popup(rate)
  end
  
  #--------------------------------------------------------------------------
  # alias method: execute_damage
  #--------------------------------------------------------------------------
  alias battle_harmony_dp_execute_damage execute_damage unless $imported["YEA-BattleEngine"]
  def execute_damage(user)
    if $imported["YEA-BattleEngine"]
      game_battler_execute_damage_abe(user)
    else
      battle_harmony_dp_execute_damage(user)
    end    
    make_damage_popups(user)
  end
  
  #--------------------------------------------------------------------------
  # alias method: item_effect_recover_hp
  #--------------------------------------------------------------------------
  alias battle_harmony_dp_item_effect_recover_hp item_effect_recover_hp unless $imported["YEA-BattleEngine"]
  def item_effect_recover_hp(user, item, effect)
    if $imported["YEA-BattleEngine"]
      game_battler_item_effect_recover_hp_abe(user, item, effect)
    else
      battle_harmony_dp_item_effect_recover_hp(user, item, effect)
    end    
    make_damage_popups(user)
  end
  
  #--------------------------------------------------------------------------
  # alias method: item_effect_recover_mp
  #--------------------------------------------------------------------------
  alias battle_harmony_item_effect_recover_mp item_effect_recover_mp unless $imported["YEA-BattleEngine"]
  def item_effect_recover_mp(user, item, effect)
    if $imported["YEA-BattleEngine"]
      game_battler_item_effect_recover_mp_abe(user, item, effect)
    else
      battle_harmony_item_effect_recover_mp(user, item, effect)
    end  
    make_damage_popups(user)
  end
  
  #--------------------------------------------------------------------------
  # alias method: item_effect_gain_tp
  #--------------------------------------------------------------------------
  alias battle_harmony_item_effect_gain_tp item_effect_gain_tp unless $imported["YEA-BattleEngine"]
  def item_effect_gain_tp(user, item, effect)
    if $imported["YEA-BattleEngine"]
      game_battler_item_effect_gain_tp_abe(user, item, effect)
    else
      battle_harmony_item_effect_gain_tp(user, item, effect)
    end  
    make_damage_popups(user)
  end
  
  #--------------------------------------------------------------------------
  # alias method: add_new_state
  #--------------------------------------------------------------------------
  alias battle_harmony_dp_add_new_state add_new_state unless $imported["YEA-BattleEngine"]
  def add_new_state(state_id)
    if $imported["YEA-BattleEngine"]
      game_battler_add_new_state_abe(state_id)
    else
      battle_harmony_dp_add_new_state(state_id)
    end  
    make_state_popup(state_id, :add_state) if @states.include?(state_id)
  end
  
  #--------------------------------------------------------------------------
  # alias method: add_buff
  #--------------------------------------------------------------------------
  alias battle_harmony_dp_add_buff add_buff unless $imported["YEA-BattleEngine"]
  def add_buff(param_id, turns)
    make_buff_popup(param_id, true)
    if $imported["YEA-BattleEngine"]
      game_battler_add_buff_abe(param_id, turns)
    else
      battle_harmony_dp_add_buff(param_id, turns)
    end  
  end
  
  #--------------------------------------------------------------------------
  # alias method: add_debuff
  #--------------------------------------------------------------------------
  alias battle_harmony_dp_add_debuff add_debuff unless $imported["YEA-BattleEngine"]
  def add_debuff(param_id, turns)
    make_buff_popup(param_id, false)
    if $imported["YEA-BattleEngine"]
      game_battler_add_debuff_abe(param_id, turns)
    else
      battle_harmony_dp_add_debuff(param_id, turns)
    end  
  end
  
  #--------------------------------------------------------------------------
  # alias method: regenerate_all
  #--------------------------------------------------------------------------
  alias battle_harmony_dp_regenerate_all regenerate_all unless $imported["YEA-BattleEngine"]
  def regenerate_all
    if $imported["YEA-BattleEngine"]
      game_battler_regenerate_all_abe
    else
      battle_harmony_dp_regenerate_all
    end  
    return unless alive?
    make_damage_popups(self)
  end
  
end # Game_Battler

#==============================================================================
# ■ Sprite_Character
#==============================================================================

class Sprite_Character < Sprite_Base
  
  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias battle_harmony_dp_initialize initialize
  def initialize(viewport, character = nil)
    @popups = []
    @popup_delay = 0
    battle_harmony_dp_initialize(viewport, character)
  end
  
  #--------------------------------------------------------------------------
  # alias method: setup_new_effect
  #--------------------------------------------------------------------------
  alias battle_harmony_dp_setup_new_effect setup_new_effect
  def setup_new_effect
    battle_harmony_dp_setup_new_effect
    setup_popups
  end
  
  #--------------------------------------------------------------------------
  # new method: setup_popups
  #--------------------------------------------------------------------------
  def setup_popups
    setting = HARMONY::POPUP::BATTLE_POPUP
    battler = character ? character.battler : nil
    return unless battler
    battler.popups ||= []
    @popup_delay -= 1
    return if @popup_delay > 0
    array = battler.popups.shift
    return if array.nil?
    create_new_popup(array[0], array[1])
    return if battler.popups.size == 0
    return if setting[:basic_setting][:no_delay].include?(array[1])
    @popup_delay = setting[:basic_setting][:delay]
  end
  
  #--------------------------------------------------------------------------
  # new method: create_new_popup
  #--------------------------------------------------------------------------
  def create_new_popup(data, rule)
    battler = character ? character.battler : nil
    return unless battler
    in_battle = SceneManager.scene_is?(Scene_Battle)
    in_battle = in_battle || SceneManager.scene_is?(Scene_BattleTactics)
    return unless in_battle
    viewport = self.viewport
    popup = Sprite_PopupHarmony.new(viewport, battler, data, rule)
    @popups.push(popup)
  end
  
  #--------------------------------------------------------------------------
  # alias method: update
  #--------------------------------------------------------------------------
  alias battle_harmony_dp_update update
  def update
    battle_harmony_dp_update
    update_popups
  end
  
  #--------------------------------------------------------------------------
  # new method: update_popups
  #--------------------------------------------------------------------------
  def update_popups
    @popups.each { |popup| popup.update }
    @popups.each_with_index { |sprite, index|
      next unless sprite.disposed?
      @popups[index] = nil
    }
    @popups.compact!
  end
  
  #--------------------------------------------------------------------------
  # alias method: dispose
  #--------------------------------------------------------------------------
  alias battle_harmony_dp_dispose dispose
  def dispose
    @popups.each { |popup| popup.dispose }
    @popups.clear
    battle_harmony_dp_dispose
  end
  
end # Sprite_Character

#==============================================================================
# ■ Sprite_PopupHarmony
#==============================================================================

class Sprite_PopupHarmony < Sprite
  
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  def initialize(viewport, battler, data, rule)
    super(viewport)
    @data = data
    @rule = rule
    #---
    @style = rule
    @style = :default unless setting[:style_setting].has_key?(@style)
    @style = setting[:style_setting][@style]
    #---
    @effects = rule
    @effects = :default unless setting[:effect_setting].has_key?(@effects)
    @effects = setting[:effect_setting][@effects].dup
    #---
    @current_effect = nil
    @duration = 0
    @battler = battler
    #---
    start_popup
    start_effect
    update
  end
  
  #--------------------------------------------------------------------------
  # setting
  #--------------------------------------------------------------------------
  def setting
    HARMONY::POPUP::BATTLE_POPUP
  end
  
  #--------------------------------------------------------------------------
  # start_popup
  #--------------------------------------------------------------------------
  def start_popup
    self.bitmap = create_bitmap
    self.x = @battler.character.screen_x
    self.y = @battler.character.screen_y
    self.ox = self.bitmap.width / 2
    self.oy = self.bitmap.height
    self.z = @battler.character.screen_z + 350
  end
  
  #--------------------------------------------------------------------------
  # create_bitmap
  #--------------------------------------------------------------------------
  def create_bitmap
    bw = Graphics.width
    bw = bw + 48 if @data[1]
    bh = @style[3] * 2
    bitmap = Bitmap.new(bw, bh)
    #---
    bitmap.font.color.set(@style[0], @style[1], @style[2])
    bitmap.font.size   = @style[3]
    bitmap.font.bold   = @style[4]
    bitmap.font.italic = @style[5]
    bitmap.font.name   = @style[6]
    #---
    dx = @data[1] ? 24 : 0; dy = 0
    text = setting[:word_setting][@rule]
    text = setting[:word_setting][:default] unless text
    text = sprintf(text, @data[0])
    bitmap.draw_text(dx, dy, bw - dx, bh, text, 1)
    #---
    text_width = bitmap.text_size(text).width
    if @data[1]
      icon_bitmap = Cache.system("Iconset")
      icon_index = @data[1].to_i
      rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
      bitmap.blt((bw-text_width)/2-32, (bh - 24)/2, icon_bitmap, rect)
    end
    bitmap
  end
  
  #--------------------------------------------------------------------------
  # start_effect
  #--------------------------------------------------------------------------
  def start_effect
    @current_effect = @effects.shift
    return dispose if @current_effect.nil?
    effect = setting[:effect_setup][@current_effect]
    @duration = effect[8]
    #---
    @zoom_x_rate = (effect[0] - self.zoom_x) / @duration
    @zoom_y_rate = (effect[1] - self.zoom_y) / @duration
    #---
    @move_x = effect[4]
    @move_y = effect[5]
    if effect[9]
      @move_x = @move_x * rand(0)
      @move_x = rand(10) % 2 == 0 ? -@move_x : @move_x
    end
    #---
    @gravity = effect[6]
    #---
    @opacity_rate = (effect[7] - self.opacity) / @duration.to_f
    #---
    self.x += effect[2]
    self.y += effect[3]
  end
  
  #--------------------------------------------------------------------------
  # update
  #--------------------------------------------------------------------------
  def update
    super
    update_zoom
    update_move
    update_opacity
    update_effect
  end
  
  #--------------------------------------------------------------------------
  # update_effect
  #--------------------------------------------------------------------------
  def update_effect
    @duration -= 1
    return if @duration > 0
    start_effect
  end
  
  #--------------------------------------------------------------------------
  # update_zoom
  #--------------------------------------------------------------------------
  def update_zoom
    self.zoom_x += @zoom_x_rate
    self.zoom_y += @zoom_y_rate
  end
  
  #--------------------------------------------------------------------------
  # update_move
  #--------------------------------------------------------------------------
  def update_move
    self.x += @move_x
    self.y += @move_y
    @move_y += @gravity
  end
  
  #--------------------------------------------------------------------------
  # update_opacity
  #--------------------------------------------------------------------------
  def update_opacity
    self.opacity += @opacity_rate
  end
  
  #--------------------------------------------------------------------------
  # dispose
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose if self.bitmap
    super
  end
  
end # Sprite_PopupHarmony
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
#==============================================================================
# ■ Scene_BattleTactics
#==============================================================================

class Scene_BattleTactics < Scene_Base
  
  #--------------------------------------------------------------------------
  # start
  #--------------------------------------------------------------------------
  def start
    super
    $game_map.refresh
    create_spriteset
    create_all_windows
    BattleManager.method_wait_for_message = method(:wait_for_message)
  end
  
  #--------------------------------------------------------------------------
  # post_start
  #--------------------------------------------------------------------------
  def post_start
    super
    prepare_battle
  end
  
  #--------------------------------------------------------------------------
  # create_spriteset
  #--------------------------------------------------------------------------
  def create_spriteset
    @spriteset = Spriteset_BattleMap.new
    @spriteset.cursor_handler(:ok    , method(:on_place_ok    ))
    @spriteset.cursor_handler(:cancel, method(:on_place_cancel))
  end
  
  #--------------------------------------------------------------------------
  # create_all_windows
  #--------------------------------------------------------------------------
  def create_all_windows
    create_message_window
    create_members_window
    create_status_window
    create_tactical_command_window
    create_actor_command_window
    create_info_viewport
  end
  
  #--------------------------------------------------------------------------
  # create_info_viewport
  #--------------------------------------------------------------------------
  def create_info_viewport
    @info_viewport = Viewport.new
    @info_viewport.rect.y = Graphics.height - @members_window.height
    @info_viewport.rect.height = @members_window.height
    @info_viewport.z = 100
    @members_window.viewport = @info_viewport
    @tactical_command_window.viewport = @info_viewport
    @actor_command_window.viewport = @info_viewport
    @status_window.viewport = @info_viewport
  end
  
  #--------------------------------------------------------------------------
  # create_all_windows
  #--------------------------------------------------------------------------
  def create_message_window
    @message_window = Window_Message.new
  end
  
  #--------------------------------------------------------------------------
  # create_members_window
  #--------------------------------------------------------------------------
  def create_members_window
    @members_window = Window_PartyBattlers.new
    #---
    @members_window.set_handler(:ok    , method(:start_place))
    @members_window.set_handler(:cancel, method(:cancel_place))
  end
  
  #--------------------------------------------------------------------------
  # create_status_window
  #--------------------------------------------------------------------------
  def create_status_window
    @status_window = Window_StatusTBS.new
  end
  
  #--------------------------------------------------------------------------
  # create_tactical_command_window
  #--------------------------------------------------------------------------
  def create_tactical_command_window
    @tactical_command_window = Window_TacticalCommand.new
    #---
    wx = @members_window.width
    @tactical_command_window.x = wx
    #---
    @tactical_command_window.set_handler(:place, method(:command_place))
    @tactical_command_window.set_handler(:fight, method(:command_fight))
  end
  
  #--------------------------------------------------------------------------
  # create_tactical_command_window
  #--------------------------------------------------------------------------
  def create_actor_command_window
    @actor_command_window = Window_ActorCommandTBS.new
    #---
    wx = @members_window.width
    @actor_command_window.x = wx
    @actor_command_window.set_handler(:move  , method(:command_move))
    @actor_command_window.set_handler(:attack, method(:command_attack))
    @actor_command_window.set_handler(:wait  , method(:command_wait))
    @actor_command_window.set_handler(:cancel, method(:command_actor_cancel))
  end
  
  #--------------------------------------------------------------------------
  # start_place
  #--------------------------------------------------------------------------
  def start_place
    first_place = $game_map.empty_position
    #---
    @spriteset.activate_cursor
    @spriteset.move_cursor(first_place[0], first_place[1])
  end
  
  #--------------------------------------------------------------------------
  # cancel_place
  #--------------------------------------------------------------------------
  def cancel_place
    @tactical_command_window.activate
    @members_window.unselect
  end
  
  #--------------------------------------------------------------------------
  # command_place
  #--------------------------------------------------------------------------
  def command_place
    @members_window.activate.select_last
  end
  
  #--------------------------------------------------------------------------
  # command_fight
  #--------------------------------------------------------------------------
  def command_fight
    BattleManager.tbs_turn_start
    start_battle
  end
    
  #--------------------------------------------------------------------------
  # command_move
  #--------------------------------------------------------------------------
  def command_move
    @spriteset.activate_cursor
    @spriteset.start_move(@subject)
  end
  
  #--------------------------------------------------------------------------
  # command_attack
  #--------------------------------------------------------------------------
  def command_attack
    atk_id = @subject.attack_skill_id
    atk_skill = $data_skills[atk_id]
    #---
    @spriteset.activate_cursor
    @spriteset.start_item(@subject, atk_skill)
    #---
    @subject.input.set_attack
  end
  
  #--------------------------------------------------------------------------
  # command_wait
  #--------------------------------------------------------------------------
  def command_wait
    @spriteset.hide_cursor
    @subject = nil
  end
  
  #--------------------------------------------------------------------------
  # command_actor_cancel
  #--------------------------------------------------------------------------
  def command_actor_cancel
    if @subject.returnable?
      @subject.return_position
      @actor_command_window.activate.refresh
      @spriteset.move_cursor(@subject.x, @subject.y)
    end
  end
  
  #--------------------------------------------------------------------------
  # terminate
  #--------------------------------------------------------------------------
  def terminate
    super
    dispose_spriteset
    $game_temp.restore_map
  end
  
  #--------------------------------------------------------------------------
  # dispose_spriteset
  #--------------------------------------------------------------------------
  def dispose_spriteset
    @spriteset.dispose
  end
    
  #--------------------------------------------------------------------------
  # update
  #--------------------------------------------------------------------------
  def update
    super
    update_viewport
    update_subject
    update_status
  end
  
  #--------------------------------------------------------------------------
  # update_basic
  #--------------------------------------------------------------------------
  def update_basic
    super
    $game_map.update(true)
    $game_timer.update
    @spriteset.update
  end
    
  #--------------------------------------------------------------------------
  # update_for_wait
  #--------------------------------------------------------------------------
  def update_for_wait
    update_basic
  end
  
  #--------------------------------------------------------------------------
  # wait_for_message
  #--------------------------------------------------------------------------
  def wait_for_message
    @message_window.update
    update_for_wait while $game_message.visible
  end
  
  #--------------------------------------------------------------------------
  # wait_for_camera
  #--------------------------------------------------------------------------
  def wait_for_camera
    update_for_wait
    update_for_wait while camera_moving?
  end
  
  #--------------------------------------------------------------------------
  # wait_for_animation
  #--------------------------------------------------------------------------
  def wait_for_animation
    update_for_wait
    update_for_wait while @spriteset.animation?
  end
  
  #--------------------------------------------------------------------------
  # camera_moving?
  #--------------------------------------------------------------------------
  def camera_moving?
    @spriteset.cursor_moving? || @subject && @subject.is_moving?
  end
  
  #--------------------------------------------------------------------------
  # refresh_status
  #--------------------------------------------------------------------------
  def refresh_status
    @status_window.refresh
  end
  
  #--------------------------------------------------------------------------
  # prepare_battle
  #--------------------------------------------------------------------------
  def prepare_battle
    BattleManager.tbs_start
    start_locations
  end
  
  #--------------------------------------------------------------------------
  # start_locations
  #--------------------------------------------------------------------------
  def start_locations
    @spriteset.start_locations
    @members_window.open
    @tactical_command_window.open.activate
  end
  
  #--------------------------------------------------------------------------
  # start_battle
  #--------------------------------------------------------------------------
  def start_battle
    @spriteset.clear_panels
    @members_window.close
    @tactical_command_window.close
    @status_window.open
  end
  
  #--------------------------------------------------------------------------
  # setup_active_battler
  #--------------------------------------------------------------------------
  def setup_active_battler
    @subject = BattleManager.get_active_battler
    return unless @subject
    @subject.make_actions
    @status_window.subject = @subject
    @spriteset.show_cursor
    @spriteset.move_cursor_smooth(@subject.x, @subject.y)
    #---
    wait_for_camera
    #---
    if @subject.actor?
      @actor_command_window.setup(@subject)
    end
  end
  
  #--------------------------------------------------------------------------
  # update_viewport
  #--------------------------------------------------------------------------
  def update_viewport
    center_x = Graphics.width / 2 + 64
    center_y = Graphics.height / 2 + 64
    #---
    cursor_x = @spriteset.cursor_screen[0]
    cursor_y = @spriteset.cursor_screen[1]
    #---
    if cursor_y > center_y
      @info_viewport.rect.y = 0 
    else
      @info_viewport.rect.y = Graphics.height - @members_window.height
    end
  end
  
  #--------------------------------------------------------------------------
  # update_subject
  #--------------------------------------------------------------------------
  def update_subject
    @subject = nil if @subject && @subject.dead?
    return if @subject
    return unless BattleManager.in_turn?
    setup_active_battler
  end
  
  #--------------------------------------------------------------------------
  # update_status
  #--------------------------------------------------------------------------
  def update_status
    position = @spriteset.cursor_position
    return unless @status_window
    return unless @spriteset.cursor_active?
    battler = $game_map.battler_xy(position[0], position[1])
    @status_window.target = battler
  end
  
  #--------------------------------------------------------------------------
  # on_place_ok
  #--------------------------------------------------------------------------
  def on_place_ok
    case BattleManager.phase
    when :init
      on_init_position_ok
    when :turn
      on_turn_position_ok
    end
  end
  
  #--------------------------------------------------------------------------
  # on_place_cancel
  #--------------------------------------------------------------------------
  def on_place_cancel
    @spriteset.hide_cursor
    case BattleManager.phase
    when :init
      on_init_position_cancel
    when :turn
      on_turn_position_cancel
    end
  end
  
  #--------------------------------------------------------------------------
  # on_init_position_ok
  #--------------------------------------------------------------------------
  def on_init_position_ok
    case @tactical_command_window.current_symbol
    when :place
      place_actor_init
    end
  end
  
  #--------------------------------------------------------------------------
  # place_actor_init
  #--------------------------------------------------------------------------
  def place_actor_init
    actor = @members_window.actor
    position = @spriteset.cursor_position
    if $game_map.start_locations.include?(position)
      $game_map.add_actor(actor, position)
      @spriteset.refresh_actors
      @spriteset.hide_cursor
      @tactical_command_window.refresh
      check_max_actor
    else
      @spriteset.activate_cursor
    end
  end
  
  #--------------------------------------------------------------------------
  # check_max_actor
  #--------------------------------------------------------------------------
  def check_max_actor
    if $game_map.max_actor?
      @tactical_command_window.select_fight
      @tactical_command_window.activate
      @members_window.refresh
      @members_window.unselect
    else
      @members_window.activate.refresh
      @members_window.select_next
    end
  end
  
  #--------------------------------------------------------------------------
  # on_turn_position_ok
  #--------------------------------------------------------------------------
  def on_turn_position_ok
    case @actor_command_window.current_symbol
    when :move
      move_actor
    else
      item_actor
    end
  end
  
  #--------------------------------------------------------------------------
  # move_actor
  #--------------------------------------------------------------------------
  def move_actor
    position = @spriteset.cursor_position
    if PanelManager.selection.include?(position)
      @subject.camera_follow(true)
      @subject.moveto(position[0], position[1])
      wait_for_camera
      @subject.camera_follow(false)
      #---
      @spriteset.clear_panels
      @actor_command_window.activate.refresh
    else
      @spriteset.activate_cursor
    end
  end
  
  #--------------------------------------------------------------------------
  # item_actor
  #--------------------------------------------------------------------------
  def item_actor
    position = @spriteset.cursor_position
    if PanelManager.selection.include?(position)
      # Need fix
      @subject.input.target_index = $game_map.battler_xy(position[0], position[1]).index
      execute_action
      # End Need fix
      @subject.end_action
      @spriteset.clear_panels
      @actor_command_window.activate.refresh
    else
      @spriteset.activate_cursor
    end
  end
  
  #--------------------------------------------------------------------------
  # on_init_position_cancel
  #--------------------------------------------------------------------------
  def on_init_position_cancel
    @tactical_command_window.open
    @members_window.open.activate
  end
  
  #--------------------------------------------------------------------------
  # on_turn_position_cancel
  #--------------------------------------------------------------------------
  def on_turn_position_cancel
    @spriteset.clear_panels
    @spriteset.show_cursor
    @spriteset.move_cursor(@subject.x, @subject.y)
    @actor_command_window.activate
  end
  
  #--------------------------------------------------------------------------
  # execute_action
  #--------------------------------------------------------------------------
  def execute_action
    item = @subject.current_action.item
    @subject.use_item(item)
    refresh_status
    targets = @subject.current_action.make_targets.compact
    show_animation(targets, item.animation_id)
    targets.each {|target| item.repeats.times { invoke_item(target, item) } }
  end
  
  #--------------------------------------------------------------------------
  # invoke_item
  #--------------------------------------------------------------------------
  def invoke_item(target, item)
    apply_item_effects(target, item)
    @subject.last_target_index = target.index
  end
  
  #--------------------------------------------------------------------------
  # apply_item_effects
  #--------------------------------------------------------------------------
  def apply_item_effects(target, item)
    target.item_apply(@subject, item)
    refresh_status
  end
  
  #--------------------------------------------------------------------------
  # show_animation
  #--------------------------------------------------------------------------
  def show_animation(targets, animation_id)
    if animation_id < 0
      show_attack_animation(targets)
    else
      show_normal_animation(targets, animation_id)
    end
    wait_for_animation
  end
  
  #--------------------------------------------------------------------------
  # show_attack_animation
  #--------------------------------------------------------------------------
  def show_attack_animation(targets)
    show_normal_animation(targets, @subject.atk_animation_id1, false)
    wait_for_animation
    show_normal_animation(targets, @subject.atk_animation_id2, true)
  end
  
  #--------------------------------------------------------------------------
  # show_normal_animation
  #--------------------------------------------------------------------------
  def show_normal_animation(targets, animation_id, mirror = false)
    animation = $data_animations[animation_id]
    if animation
      targets.each do |target|
        target.animation_id = animation_id
        target.animation_mirror = mirror
      end
    end
  end
  
end # Scene_BattleTactics
#==============================================================================
# ■ Game_Interpreter
#==============================================================================

class Game_Interpreter
  
  #--------------------------------------------------------------------------
  # new method: add_enemy
  #--------------------------------------------------------------------------
  def add_enemy(id, x, y)
    $game_temp.add_enemy(id, x, y)
  end
  
  #--------------------------------------------------------------------------
  # new method: reset_enemy
  #--------------------------------------------------------------------------
  def reset_enemy
    $game_temp.reset_enemy
  end
  
  #--------------------------------------------------------------------------
  # new method: reset_enemy
  #--------------------------------------------------------------------------
  def start_tbs(map_id, can_escape, can_lose, max_actor = nil)
    max_actor = HARMONY::ENGINE::DEFAULT_MAX_ACTOR if max_actor.nil?
    $game_temp.prepare_map
    $game_map.setup(map_id)
    $game_map.setup_battle
    BattleManager.setup_tbs(can_escape, can_lose, max_actor)
    SceneManager.call(Scene_BattleTactics)
  end
  
end # Game_Interpreter
