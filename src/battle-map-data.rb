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
    setup_start_locations
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
  def setup_start_locations
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