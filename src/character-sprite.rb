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