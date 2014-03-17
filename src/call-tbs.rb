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