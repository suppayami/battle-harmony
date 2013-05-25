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