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