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