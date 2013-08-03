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
    PANEL_OUTLINE = true
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
  
end # Vocab

# Use for parsing database and events by notetag and comment-tag

#==============================================================================
# Å° Regular Expression
#==============================================================================

module REGEXP
  module HARMONY
    # Notetags
    SETUP_RANGE = /<(.*) range:[ ]*(\d+)>/i
    CHARSET = /<(?:BATTLER_SET|battler set):[ ]*(.*)>/i
  end
end

#==============================================================================
# Å° DataManager
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
# Å° RPG::BaseItem
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
        when "MOVE"
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
# Å° Game_Enemy
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
# Å° Sprite_Character
#==============================================================================

class Sprite_Character < Sprite_Base
  
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :battler
    
end # Sprite_Character

#==============================================================================
# Å° Game_Character
#==============================================================================

class Game_Character < Game_CharacterBase
  
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :battler

  #--------------------------------------------------------------------------
  # new method: refresh
  #--------------------------------------------------------------------------
  def refresh
    @battler ? refresh_battler : false
  end
  
  #--------------------------------------------------------------------------
  # new method: refresh_battler
  #--------------------------------------------------------------------------
  def refresh_battler
    @character_name = @battler.character_name
    @character_index = @battler.character_index
    @step_anime = true
  end
  
  #--------------------------------------------------------------------------
  # new method: collide_with_battler?
  #--------------------------------------------------------------------------
  def collide_with_battler?(x, y)
    $game_party.in_battle && $game_map.battler_xy?(x, y)
  end
  
  #--------------------------------------------------------------------------
  # alias method: collide_with_characters?
  #--------------------------------------------------------------------------
  alias beh_collide_with_characters? collide_with_characters?
  def collide_with_characters?(x, y)
    beh_collide_with_characters?(x, y) || collide_with_battler?(x, y)
  end
  
end # Game_Character
# Use for movement, cast range, ... panels on battle field

#==============================================================================
# Å° Cache
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
# Å° Sprite_Panel
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
    @map_x = 0
    @map_y = 0
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
    $game_map.adjust_x(@map_x) * 32 + 16
  end

  #--------------------------------------------------------------------------
  # screen_y
  #--------------------------------------------------------------------------
  def screen_y
    $game_map.adjust_y(@map_y) * 32 + 32
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
  # moveto
  #--------------------------------------------------------------------------
  def moveto(x, y)
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
    $game_map.set_display_pos(@map_x - center_x, @map_y - center_y)
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
# Å° PanelManager
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
  # check_last
  #--------------------------------------------------------------------------
  def self.check_last(character, action, base)
    @last_character == character && @last_action == action && 
      @last_position == base
  end
  
  #--------------------------------------------------------------------------
  # check_passable?
  #--------------------------------------------------------------------------
  def self.check_passable?(character, x, y, d)
    return false unless character.passable?(x, y, d)
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
    when 4; return [x - 1, y]
    when 6; return [x + 1, y]
    when 7; return [x - 1, y - 1]
    when 8; return [x    , y - 1]
    when 9; return [x + 1, y - 1]
    end
  end
  
  #--------------------------------------------------------------------------
  # move_selection
  #--------------------------------------------------------------------------
  def self.move_selection(character, fly = false)
    action = fly ? :fly : :move
    base = [character.x, character.y]
    return @selection if check_last(character, action, base)
    @last_character = character
    @last_action = action
    @last_position = base
    #---
    clear
    @cost[base[0]][base[1]] = 0
    @max = character.move_range
    setup_selection(base, character.move_range, !fly)
    #---
    return @selection
  end
  
  #--------------------------------------------------------------------------
  # skill_selection
  #--------------------------------------------------------------------------
  def self.skill_selection(character, item)
    base = [character.x, character.y]
    return @selection if check_last(character, item, base)
    @last_character = character
    @last_action = item
    @last_position = base
    #---
    case item.class.name
    when "RPG::Skill"
      range = character.skill_range(item)
    when "RPG::Item"
      range = character.item_range(item)
    end
    clear
    setup_selection(base, range, false)
    #---
    return @selection
  end
  
  #--------------------------------------------------------------------------
  # setup_selection
  #--------------------------------------------------------------------------
  def self.setup_selection(base, range, block = true)
    @close.push(base)
    @selection.push(base) unless @selection.include?(base)
    #---
    directions = [2, 4, 6, 8]
    #---
    directions.each { |d|
      block_cond = check_passable?(@last_character, base[0], base[1], d)
      non_block  = !block && map_bound?(base[0], base[1], d)
      if block_cond || non_block
        panel = get_panel(base[0], base[1], d)
        @selection.push(panel) unless @selection.include?(panel)
        @cost[panel[0]][panel[1]] = @cost[base[0]][base[1]] + 1
        @open.push(panel) unless @close.include?(panel)
      end
    }
    #---
    @open.uniq!
    @open.each { |o|
      if @close.include?(o) || @cost[o[0]][o[1]] && @cost[o[0]][o[1]] == @max
        @open.delete(o)
        @close.push(o)
      else
        setup_selection(o, range - 1, block)
      end
    }
  end
    
end # PanelManager
#==============================================================================
# Å° ANode
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
# Å° PanelManager
#==============================================================================

module PanelManager
  
  #--------------------------------------------------------------------------
  # Initialize Variables
  #--------------------------------------------------------------------------
  @aopen = []
  @aclose = []
  DIRECTION = [4,8,6,2]
    
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
  def self.findpath(character, p1, p2)
    @aopen.clear
    @aclose.clear
    #---
    p1.g = 0
    p1.h = distance(p2, p1)
    p1.f = p1.h
    #---
    @aopen.push(p1)
    #---
    while @aopen.size > 0
      top = @aopen.shift
      #---
      if top.points == p2.points
        p2.parent = @aclose[@aclose.size - 1]
        return true
      end
      #---
      DIRECTION.each { |i|
        next_point = get_panel(top.points[0], top.points[1], i)
        topConnect = (@aopen + @aclose).select { |i| i.points == next_point }[0]
        topConnect = ANode.new(next_point[0], next_point[1]) if topConnect.nil?
        #---
        if !@aclose.include?(topConnect) && 
          check_passable?(top.points[0], top.points[1], i)
          if !@aopen.include?(topConnect)
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
      #---
      @aclose.push(top)
    end
    #---
    return false
  end
  
end # PanelManager
#==============================================================================
# Å° Game_Battler
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
    range_actor   = self.actor.move_range
    range_class   = self.class.move_range
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
# Å° Game_Temp
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
# Å° Game_Unit
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
# Å° Game_Party
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
# Å° Game_Troop
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
# Å° Game_BattleMap
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
      remove_actor(battler_xy(position[0], position[1]))
    end
    return move_actor(actor, position) if @actor_party.include?(actor)
    character = Game_Character.new
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
  # setup_enemies
  #--------------------------------------------------------------------------
  def setup_enemies
    @enemy_troop ||= []
    @enemy_troop.clear
    #---
    $game_temp.tbs_troop.each_with_index { |data, index|
      character = Game_Character.new
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
  # update_events
  #--------------------------------------------------------------------------
  def update_events
    super
    @actor_party.each { |battler| battler.character.update }
    @enemy_troop.each { |battler| battler.character.update }
  end
    
end # Game_BattleMap
#==============================================================================
# Å° Spriteset_BattleMap
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
  # all_battlers
  #--------------------------------------------------------------------------
  def all_battlers
    $game_map.actor_party + $game_map.enemy_troop
  end
  
  #--------------------------------------------------------------------------
  # init_camera
  #--------------------------------------------------------------------------
  def init_camera
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
    @panel_sprites.clear
    @cursor ||= Sprite_Panel.new(@viewport1)
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
  
end # Spriteset_BattleMap
#==============================================================================
# Å° BattleManager
#==============================================================================

module BattleManager
  
  #--------------------------------------------------------------------------
  # self.setup_tbs
  #--------------------------------------------------------------------------
  def self.setup_tbs(can_escape, can_lose)
    @can_escape = can_escape
    @can_lose   = can_lose
    init_tbs
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
    
end # BattleManager
#==============================================================================
# Å° Window_PartyBattlers
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
# Å° Window_TacticalCommand
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
# Å° Scene_BattleTactics
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
    battle_start
  end
  
  #--------------------------------------------------------------------------
  # create_spriteset
  #--------------------------------------------------------------------------
  def create_spriteset
    @spriteset = Spriteset_BattleMap.new
  end
  
  #--------------------------------------------------------------------------
  # create_all_windows
  #--------------------------------------------------------------------------
  def create_all_windows
    create_message_window
    create_members_window
    create_tactical_command_window
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
  # create_tactical_command_window
  #--------------------------------------------------------------------------
  def create_tactical_command_window
    @tactical_command_window = Window_TacticalCommand.new
    #---
    wx = @members_window.width
    @tactical_command_window.x = wx
    #---
    @tactical_command_window.set_handler(:place, method(:command_place))
  end
  
  #--------------------------------------------------------------------------
  # start_place
  #--------------------------------------------------------------------------
  def start_place
    first_place = $game_map.start_locations[0]
    #---
    @spriteset.activate_cursor
    @spriteset.move_cursor(first_place[0], first_place[1])
    @spriteset.cursor_handler(:ok    , method(:on_place_ok    ))
    @spriteset.cursor_handler(:cancel, method(:on_place_cancel))
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
  # on_place_ok
  #--------------------------------------------------------------------------
  def on_place_ok
    actor = @members_window.actor
    position = @spriteset.cursor_position
    $game_map.add_actor(actor, position)
    #---
    @spriteset.refresh_actors
    @spriteset.hide_cursor
    @tactical_command_window.refresh
    @members_window.activate.refresh
    @members_window.select_next
  end
  
  #--------------------------------------------------------------------------
  # on_place_cancel
  #--------------------------------------------------------------------------
  def on_place_cancel
    @spriteset.hide_cursor
    @tactical_command_window.open
    @members_window.open.activate
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
  # battle_start
  #--------------------------------------------------------------------------
  def battle_start
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
  
end # Scene_BattleTactics
#==============================================================================
# Å° Game_Interpreter
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
  def start_tbs(map_id, can_escape, can_lose)
    $game_temp.prepare_map
    $game_map.setup(map_id)
    $game_map.setup_battle
    BattleManager.setup_tbs(can_escape, can_lose)
    SceneManager.call(Scene_BattleTactics)
  end
  
end # Game_Interpreter
